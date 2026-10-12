import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/day_log.dart';
import '../domain/day_log_repository.dart';
import '../domain/habit_task.dart';

class FirestoreDayLogRepository implements DayLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreDayLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _dayLogDoc(String uid, String date) =>
      _firestore.collection('users').doc(uid).collection('dayLogs').doc(date);

  @override
  Future<DayLog?> fetchDayLog(String uid, String date) async {
    final snapshot = await _dayLogDoc(uid, date).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return DayLog.fromMap(snapshot.data()!, date);
  }

  @override
  Stream<DayLog?> watchDayLog(String uid, String date) {
    return _dayLogDoc(uid, date).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return DayLog.fromMap(snapshot.data()!, date);
    });
  }

  @override
  Future<void> saveDayLog(String uid, DayLog dayLog) async {
    await _dayLogDoc(uid, dayLog.date).set(
          dayLog.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<DayLog> recordTaskToggle({
    required String uid,
    required String date,
    required String taskId,
    required bool isCompleted,
    required List<HabitTask> scheduledTasks,
  }) async {
    final existingLog = await fetchDayLog(uid, date) ?? DayLog(date: date);

    final outcomes = Map<String, TaskOutcome>.from(existingLog.taskOutcomes);
    outcomes[taskId] = TaskOutcome(
      status: isCompleted ? 'completed' : 'pending',
      proofId: existingLog.taskOutcomes[taskId]?.proofId,
      excuseId: existingLog.taskOutcomes[taskId]?.excuseId,
      penaltyId: existingLog.taskOutcomes[taskId]?.penaltyId,
    );

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

  @override
  Future<DayLog> recordTaskOutcome({
    required String uid,
    required String date,
    required String taskId,
    required String status,
    String? proofId,
    String? excuseId,
    List<HabitTask>? scheduledTasks,
  }) async {
    final existingLog = await fetchDayLog(uid, date) ?? DayLog(date: date);

    final outcomes = Map<String, TaskOutcome>.from(existingLog.taskOutcomes);
    outcomes[taskId] = TaskOutcome(
      status: status,
      proofId: proofId ?? existingLog.taskOutcomes[taskId]?.proofId,
      excuseId: excuseId ?? existingLog.taskOutcomes[taskId]?.excuseId,
      penaltyId: existingLog.taskOutcomes[taskId]?.penaltyId,
    );

    final tasks = scheduledTasks ?? [];
    int totalWeight = 0;
    int completedWeight = 0;

    for (final task in tasks) {
      final outcome = outcomes[task.id] ?? const TaskOutcome(status: 'pending');
      if (!outcome.isExcused) {
        totalWeight += task.weight;
      }
      if (outcome.isCompleted) {
        completedWeight += task.weight;
      }
    }

    final completionPercent = totalWeight == 0
        ? existingLog.completionPercent
        : ((completedWeight / totalWeight) * 100).round().clamp(0, 100);

    final updatedLog = existingLog.copyWith(
      taskOutcomes: outcomes,
      totalWeight: totalWeight > 0 ? totalWeight : existingLog.totalWeight,
      completedWeight:
          completedWeight > 0 ? completedWeight : existingLog.completedWeight,
      completionPercent: completionPercent,
    );

    await saveDayLog(uid, updatedLog);
    return updatedLog;
  }
}
