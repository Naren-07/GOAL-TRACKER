import 'day_log.dart';
import 'habit_task.dart';

abstract class DayLogRepository {
  Future<DayLog?> fetchDayLog(String uid, String date);
  Stream<DayLog?> watchDayLog(String uid, String date);
  Future<void> saveDayLog(String uid, DayLog dayLog);

  Future<DayLog> recordTaskToggle({
    required String uid,
    required String date,
    required String taskId,
    required bool isCompleted,
    required List<HabitTask> scheduledTasks,
  });

  Future<DayLog> recordTaskOutcome({
    required String uid,
    required String date,
    required String taskId,
    required String status,
    String? proofId,
    String? excuseId,
    List<HabitTask>? scheduledTasks,
  });
}
