import 'habit_task.dart';

abstract class TaskRepository {
  Future<List<HabitTask>> fetchTasks(String uid);
  Stream<List<HabitTask>> watchTasks(String uid);
  Future<void> saveTask(String uid, HabitTask task);
  Future<void> deleteTask(String uid, String taskId);
}
