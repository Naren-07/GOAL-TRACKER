import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import '../domain/step_sensor_repository.dart';
import '../domain/step_tracker_service.dart';

final stepSensorRepositoryProvider = Provider<StepSensorRepository>((ref) {
  throw UnimplementedError('stepSensorRepositoryProvider must be initialized');
});

final stepTrackerServiceProvider = Provider<StepTrackerService>((ref) {
  return StepTrackerService();
});

final userStepGoalProvider = Provider<int>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthenticatedState) {
    return authState.profile.stepGoal;
  }
  return 8000;
});

class StepTrackerState {
  final int todaySteps;
  final int stepGoal;
  final bool isPermissionGranted;

  const StepTrackerState({
    this.todaySteps = 0,
    this.stepGoal = 8000,
    this.isPermissionGranted = false,
  });

  bool get isGoalReached => todaySteps >= stepGoal;
  double get progress => stepGoal == 0 ? 0.0 : (todaySteps / stepGoal).clamp(0.0, 1.0);

  StepTrackerState copyWith({
    int? todaySteps,
    int? stepGoal,
    bool? isPermissionGranted,
  }) {
    return StepTrackerState(
      todaySteps: todaySteps ?? this.todaySteps,
      stepGoal: stepGoal ?? this.stepGoal,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
    );
  }
}

class StepTrackerNotifier extends Notifier<StepTrackerState> {
  StepSensorRepository? _sensorRepo;
  StepTrackerService? _trackerService;
  StreamSubscription<int>? _sensorSub;
  final Map<String, int> _baselines = {};

  @override
  StepTrackerState build() {
    _sensorRepo = ref.watch(stepSensorRepositoryProvider);
    _trackerService = ref.watch(stepTrackerServiceProvider);
    final goal = ref.watch(userStepGoalProvider);

    ref.onDispose(() {
      _sensorSub?.cancel();
    });

    _startListening();
    _checkPermissionAsync();

    return StepTrackerState(stepGoal: goal);
  }

  Future<void> _checkPermissionAsync() async {
    if (_sensorRepo == null) return;
    final granted = await _sensorRepo!.checkPermission();
    state = state.copyWith(isPermissionGranted: granted);
  }

  void _startListening() {
    _sensorSub?.cancel();
    _sensorSub = _sensorRepo?.rawStepCountStream.listen((rawSteps) {
      _processRawSteps(rawSteps);
    });
  }

  void _processRawSteps(int rawSteps) {
    if (_trackerService == null) return;
    final today = TodayTasksNotifier.todayDateString();
    final result = _trackerService!.calculateSteps(
      rawSensorSteps: rawSteps,
      date: today,
      baselines: _baselines,
    );

    _baselines.addAll(result.updatedBaselines);
    state = state.copyWith(todaySteps: result.todaySteps);

    // Auto-complete if goal is reached
    if (state.isGoalReached) {
      _autoCompleteStepsTask();
    }
  }

  void _autoCompleteStepsTask() {
    final todayTasksState = ref.read(todayTasksNotifierProvider);
    final stepTask = todayTasksState.tasks.cast().firstWhere(
      (task) =>
          task.type == 'steps_auto' ||
          task.title.toLowerCase().contains('step'),
      orElse: () => null,
    );

    if (stepTask != null && !todayTasksState.isTaskCompleted(stepTask.id)) {
      ref.read(todayTasksNotifierProvider.notifier).toggleTask(stepTask.id);
    }
  }

  Future<bool> requestPermission() async {
    if (_sensorRepo == null) return false;
    final granted = await _sensorRepo!.requestPermission();
    state = state.copyWith(isPermissionGranted: granted);
    if (granted) {
      _startListening();
    }
    return granted;
  }

  void setSimulatedSteps(int steps) {
    state = state.copyWith(todaySteps: steps);
    if (state.isGoalReached) {
      _autoCompleteStepsTask();
    }
  }
}

final stepTrackerNotifierProvider =
    NotifierProvider<StepTrackerNotifier, StepTrackerState>(
  StepTrackerNotifier.new,
);
