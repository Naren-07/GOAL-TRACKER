import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('TodayTasksNotifier Seam', () {
    late MockTaskRepository taskRepo;
    late MockDayLogRepository dayLogRepo;
    late ProviderContainer container;
    const testUid = 'user_777';

    setUp(() {
      taskRepo = MockTaskRepository();
      dayLogRepo = MockDayLogRepository();

      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          dayLogRepositoryProvider.overrideWithValue(dayLogRepo),
          currentUserIdProvider.overrideWithValue(testUid),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      taskRepo.dispose();
      dayLogRepo.dispose();
    });

    test('initial state has 0 total weight and 0 percent completion', () async {
      final state = container.read(todayTasksNotifierProvider);
      expect(state.tasks, isEmpty);
      expect(state.totalWeight, 0);
      expect(state.completedWeight, 0);
      expect(state.completionPercent, 0);
    });

    test('createTask adds scheduled task and recalculates total weight', () async {
      final todayWeekday = DateTime.now().weekday;

      await container.read(todayTasksNotifierProvider.notifier).createTask(
            title: 'Deep Work 2 Hours',
            category: 'Academics',
            weight: 3,
            repeatDays: [todayWeekday],
          );

      final state = container.read(todayTasksNotifierProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.title, 'Deep Work 2 Hours');
      expect(state.totalWeight, 3);
      expect(state.completedWeight, 0);
      expect(state.completionPercent, 0);
    });

    test('toggleTask instantly updates completionPercent and completedWeight in real time', () async {
      final todayWeekday = DateTime.now().weekday;

      // Create two tasks: weight 2 and weight 3
      await container.read(todayTasksNotifierProvider.notifier).createTask(
            title: 'Gym Workout',
            category: 'Health',
            weight: 2,
            repeatDays: [todayWeekday],
          );

      await container.read(todayTasksNotifierProvider.notifier).createTask(
            title: 'DSA Practice',
            category: 'Technical Skills',
            weight: 3,
            repeatDays: [todayWeekday],
          );

      var state = container.read(todayTasksNotifierProvider);
      expect(state.totalWeight, 5);
      expect(state.completedWeight, 0);
      expect(state.completionPercent, 0);

      final gymTask = state.tasks.firstWhere((t) => t.title == 'Gym Workout');
      final dsaTask = state.tasks.firstWhere((t) => t.title == 'DSA Practice');

      // Toggle Gym (weight 2 of 5 = 40%)
      await container.read(todayTasksNotifierProvider.notifier).toggleTask(gymTask.id);
      state = container.read(todayTasksNotifierProvider);
      expect(state.isTaskCompleted(gymTask.id), isTrue);
      expect(state.completedWeight, 2);
      expect(state.completionPercent, 40);

      // Toggle DSA (weight 2 + 3 = 5 of 5 = 100%)
      await container.read(todayTasksNotifierProvider.notifier).toggleTask(dsaTask.id);
      state = container.read(todayTasksNotifierProvider);
      expect(state.isTaskCompleted(dsaTask.id), isTrue);
      expect(state.completedWeight, 5);
      expect(state.completionPercent, 100);

      // Untoggle Gym (weight 3 of 5 = 60%)
      await container.read(todayTasksNotifierProvider.notifier).toggleTask(gymTask.id);
      state = container.read(todayTasksNotifierProvider);
      expect(state.isTaskCompleted(gymTask.id), isFalse);
      expect(state.completedWeight, 3);
      expect(state.completionPercent, 60);

      // Verify persistence to DayLogRepository
      final persisted = await dayLogRepo.fetchDayLog(testUid, state.date);
      expect(persisted, isNotNull);
      expect(persisted!.completionPercent, 60);
      expect(persisted.taskOutcomes[dsaTask.id]?.isCompleted, isTrue);
      expect(persisted.taskOutcomes[gymTask.id]?.isCompleted, isFalse);
    });
  });
}
