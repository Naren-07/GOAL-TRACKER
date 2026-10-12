import 'dart:async';
import '../domain/habit_task.dart';
import '../domain/task_repository.dart';

class MockTaskRepository implements TaskRepository {
  final Map<String, List<HabitTask>> _tasksByUser = {};
  final StreamController<Map<String, List<HabitTask>>> _tasksStream =
      StreamController<Map<String, List<HabitTask>>>.broadcast();

  MockTaskRepository([Map<String, List<HabitTask>>? initialTasks]) {
    if (initialTasks != null) {
      _tasksByUser.addAll(initialTasks);
    }
  }

  @override
  Future<List<HabitTask>> fetchTasks(String uid) async {
    return List.unmodifiable(_tasksByUser[uid] ?? []);
  }

  @override
  Stream<List<HabitTask>> watchTasks(String uid) {
    late final StreamController<List<HabitTask>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<HabitTask>>.broadcast(
      onListen: () {
        controller.add(List.unmodifiable(_tasksByUser[uid] ?? []));
        sub = _tasksStream.stream.listen((map) {
          controller.add(List.unmodifiable(map[uid] ?? []));
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> saveTask(String uid, HabitTask task) async {
    final list = _tasksByUser.putIfAbsent(uid, () => []);
    final index = list.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      list[index] = task;
    } else {
      list.add(task);
    }
    _tasksStream.add(Map.unmodifiable(_tasksByUser));
  }

  @override
  Future<void> deleteTask(String uid, String taskId) async {
    final list = _tasksByUser[uid];
    if (list != null) {
      list.removeWhere((t) => t.id == taskId);
      _tasksStream.add(Map.unmodifiable(_tasksByUser));
    }
  }

  void dispose() {
    _tasksStream.close();
  }
}
