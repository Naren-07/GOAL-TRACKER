import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/domain/task_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';

void main() {
  group('TaskRepository Seam', () {
    late TaskRepository repository;
    const testUid = 'user_abc_123';

    setUp(() {
      repository = MockTaskRepository();
    });

    test('initial task list is empty', () async {
      final tasks = await repository.fetchTasks(testUid);
      expect(tasks, isEmpty);
    });

    test('saveTask creates a new task with custom weight and schedule', () async {
      final task = HabitTask(
        id: 'task_gym',
        title: 'Morning Gym Session',
        category: 'Health',
        weight: 3,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7], // Daily
        createdAt: DateTime(2026, 10, 12),
      );

      await repository.saveTask(testUid, task);

      final fetched = await repository.fetchTasks(testUid);
      expect(fetched.length, 1);
      expect(fetched.first.id, 'task_gym');
      expect(fetched.first.title, 'Morning Gym Session');
      expect(fetched.first.category, 'Health');
      expect(fetched.first.weight, 3);
      expect(fetched.first.isScheduledForWeekday(1), isTrue); // Monday
    });

    test('watchTasks emits updated list upon saving or deleting', () async {
      final stream = repository.watchTasks(testUid);
      expect(await stream.first, isEmpty);

      final task1 = HabitTask(
        id: 'task_flutter',
        title: 'Flutter DSA Practice',
        category: 'Technical Skills',
        weight: 2,
        repeatDays: const [1, 2, 3, 4, 5], // Weekdays
        createdAt: DateTime.now(),
      );

      await repository.saveTask(testUid, task1);
      final updated = await stream.first;
      expect(updated.length, 1);
      expect(updated.first.title, 'Flutter DSA Practice');

      await repository.deleteTask(testUid, 'task_flutter');
      final afterDelete = await stream.first;
      expect(afterDelete, isEmpty);
    });
  });
}
