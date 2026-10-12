import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/day_log.dart';
import '../domain/day_log_repository.dart';
import '../domain/habit_task.dart';
import '../domain/task_repository.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  throw UnimplementedError('taskRepositoryProvider must be initialized');
});

final dayLogRepositoryProvider = Provider<DayLogRepository>((ref) {
  throw UnimplementedError('dayLogRepositoryProvider must be initialized');
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthenticatedState) {
    return authState.profile.uid;
  }
  if (authState is NeedsOnboardingState) {
    return authState.user.uid;
  }
  return null;
});

class TodayTasksState {
  final String date;
  final List<HabitTask> tasks;
  final DayLog? dayLog;
  final int totalWeight;
  final int completedWeight;
  final int completionPercent;
  final bool isLoading;

  const TodayTasksState({
    required this.date,
    this.tasks = const [],
    this.dayLog,
    this.totalWeight = 0,
    this.completedWeight = 0,
    this.completionPercent = 0,
    this.isLoading = false,
  });

  bool isTaskCompleted(String taskId) {
    return dayLog?.taskOutcomes[taskId]?.isCompleted ?? false;
  }

  TodayTasksState copyWith({
    String? date,
    List<HabitTask>? tasks,
    DayLog? dayLog,
    int? totalWeight,
    int? completedWeight,
    int? completionPercent,
    bool? isLoading,
  }) {
    return TodayTasksState(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      dayLog: dayLog ?? this.dayLog,
      totalWeight: totalWeight ?? this.totalWeight,
      completedWeight: completedWeight ?? this.completedWeight,
      completionPercent: completionPercent ?? this.completionPercent,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TodayTasksNotifier extends Notifier<TodayTasksState> {
  TaskRepository? _taskRepository;
  DayLogRepository? _dayLogRepository;
  String? _uid;
  StreamSubscription? _tasksSub;
  StreamSubscription? _dayLogSub;

  List<HabitTask> _allTasks = [];
  DayLog? _currentDayLog;

  static String todayDateString([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  TodayTasksState build() {
    _taskRepository = ref.watch(taskRepositoryProvider);
    _dayLogRepository = ref.watch(dayLogRepositoryProvider);
    _uid = ref.watch(currentUserIdProvider);

    final date = todayDateString();

    ref.onDispose(() {
      _tasksSub?.cancel();
      _dayLogSub?.cancel();
    });

    if (_uid != null) {
      _initStreams(_uid!, date);
    }

    return TodayTasksState(date: date);
  }

  void _initStreams(String uid, String date) {
    _tasksSub?.cancel();
    _dayLogSub?.cancel();

    _tasksSub = _taskRepository?.watchTasks(uid).listen((tasks) {
      _allTasks = tasks;
      _recalculate(date);
    });

    _dayLogSub = _dayLogRepository?.watchDayLog(uid, date).listen((dayLog) {
      _currentDayLog = dayLog;
      _recalculate(date);
    });
  }

  void _recalculate(String date) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    // Filter tasks active and scheduled for today
    final todayTasks = _allTasks
        .where((t) => t.active && t.isScheduledForWeekday(todayWeekday))
        .toList();

    int totalWeight = 0;
    int completedWeight = 0;

    final outcomes = _currentDayLog?.taskOutcomes ?? {};
    for (final task in todayTasks) {
      final outcome = outcomes[task.id] ?? const TaskOutcome(status: 'pending');
      if (!outcome.isExcused) {
        totalWeight += task.weight;
      }
      if (outcome.isCompleted) {
        completedWeight += task.weight;
      }
    }

    final percent = totalWeight == 0
        ? 0
        : ((completedWeight / totalWeight) * 100).round().clamp(0, 100);

    state = state.copyWith(
      date: date,
      tasks: todayTasks,
      dayLog: _currentDayLog,
      totalWeight: totalWeight,
      completedWeight: completedWeight,
      completionPercent: percent,
      isLoading: false,
    );
  }

  Future<void> toggleTask(String taskId, [bool? forceCompleted]) async {
    if (_uid == null || _dayLogRepository == null) return;
    final isCurrentlyCompleted = state.isTaskCompleted(taskId);
    final nextStatus = forceCompleted ?? !isCurrentlyCompleted;

    // Persist to repository
    final updatedLog = await _dayLogRepository!.recordTaskToggle(
      uid: _uid!,
      date: state.date,
      taskId: taskId,
      isCompleted: nextStatus,
      scheduledTasks: state.tasks,
    );

    _currentDayLog = updatedLog;
    _recalculate(state.date);
  }

  static int _idCounter = 0;

  Future<void> createTask({
    required String title,
    required String category,
    required int weight,
    required List<int> repeatDays,
    String? reminderTime,
    String type = 'standard',
  }) async {
    if (_uid == null || _taskRepository == null) return;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final newTask = HabitTask(
      id: 'task_${timestamp}_${_idCounter++}',
      title: title,
      category: category,
      weight: weight.clamp(1, 10),
      repeatDays: repeatDays,
      reminderTime: reminderTime,
      type: type,
      createdAt: DateTime.now(),
    );

    await _taskRepository!.saveTask(_uid!, newTask);
    final index = _allTasks.indexWhere((t) => t.id == newTask.id);
    if (index >= 0) {
      _allTasks = List.from(_allTasks)..[index] = newTask;
    } else {
      _allTasks = [..._allTasks, newTask];
    }
    _recalculate(state.date);
  }

  Future<void> deleteTask(String taskId) async {
    if (_uid == null || _taskRepository == null) return;
    await _taskRepository!.deleteTask(_uid!, taskId);
    _allTasks = _allTasks.where((t) => t.id != taskId).toList();
    _recalculate(state.date);
  }
}

final todayTasksNotifierProvider =
    NotifierProvider<TodayTasksNotifier, TodayTasksState>(
  TodayTasksNotifier.new,
);
