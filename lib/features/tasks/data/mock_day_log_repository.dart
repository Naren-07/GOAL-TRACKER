import 'dart:async';
import '../domain/day_log.dart';
import '../domain/day_log_repository.dart';
import '../domain/habit_task.dart';

class MockDayLogRepository implements DayLogRepository {
  final Map<String, DayLog> _dayLogs = {};
  final StreamController<Map<String, DayLog>> _streamController =
      StreamController<Map<String, DayLog>>.broadcast();

  String _key(String uid, String date) => '$uid:$date';

  @override
  Future<DayLog?> fetchDayLog(String uid, String date) async {
    return _dayLogs[_key(uid, date)];
  }

  @override
  Stream<DayLog?> watchDayLog(String uid, String date) {
    late final StreamController<DayLog?> controller;
    StreamSubscription? sub;

    controller = StreamController<DayLog?>.broadcast(
      onListen: () {
        controller.add(_dayLogs[_key(uid, date)]);
        sub = _streamController.stream.listen((map) {
          controller.add(map[_key(uid, date)]);
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> saveDayLog(String uid, DayLog dayLog) async {
    _dayLogs[_key(uid, dayLog.date)] = dayLog;
    _streamController.add(Map.unmodifiable(_dayLogs));
  }

  @override
  Future<DayLog> recordTaskToggle({
    required String uid,
    required String date,
    required String taskId,
    required bool isCompleted,
    required List<HabitTask> scheduledTasks,
  }) async {
    final key = _key(uid, date);
    final existingLog = _dayLogs[key] ?? DayLog(date: date);

    final outcomes = Map<String, TaskOutcome>.from(existingLog.taskOutcomes);
    outcomes[taskId] = TaskOutcome(
      status: isCompleted ? 'completed' : 'pending',
      proofId: existingLog.taskOutcomes[taskId]?.proofId,
      excuseId: existingLog.taskOutcomes[taskId]?.excuseId,
      penaltyId: existingLog.taskOutcomes[taskId]?.penaltyId,
    );

    // Ensure all scheduled tasks have an outcome in the map
    for (final task in scheduledTasks) {
      outcomes.putIfAbsent(task.id, () => const TaskOutcome(status: 'pending'));
    }

    int totalWeight = 0;
    int completedWeight = 0;

    for (final task in scheduledTasks) {
      final outcome = outcomes[task.id] ?? const TaskOutcome(status: 'pending');
      if (!outcome.isExcused) {
        totalWeight += task.weight;
      }
      if (outcome.isCompleted) {
        completedWeight += task.weight;
      }
    }

    final completionPercent = totalWeight == 0
        ? 0
        : ((completedWeight / totalWeight) * 100).round().clamp(0, 100);

    final updatedLog = existingLog.copyWith(
      taskOutcomes: outcomes,
      totalWeight: totalWeight,
      completedWeight: completedWeight,
      completionPercent: completionPercent,
    );

    await saveDayLog(uid, updatedLog);
    return updatedLog;
  }

  void dispose() {
    _streamController.close();
  }
}
