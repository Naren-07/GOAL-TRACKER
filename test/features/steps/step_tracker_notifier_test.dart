import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/steps/data/mock_step_sensor_repository.dart';
import 'package:growthstreak/features/steps/domain/step_tracker_service.dart';
import 'package:growthstreak/features/steps/presentation/step_tracker_notifier.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('StepTrackerNotifier Seam', () {
    late MockStepSensorRepository sensorRepo;
    late StepTrackerService trackerService;
    late MockTaskRepository taskRepo;
    late MockDayLogRepository dayLogRepo;
    late ProviderContainer container;
    const testUid = 'user_step_test';

    setUp(() {
      sensorRepo = MockStepSensorRepository(initialPermissionGranted: true);
      trackerService = StepTrackerService();
      taskRepo = MockTaskRepository();
      dayLogRepo = MockDayLogRepository();

      container = ProviderContainer(
        overrides: [
          stepSensorRepositoryProvider.overrideWithValue(sensorRepo),
          stepTrackerServiceProvider.overrideWithValue(trackerService),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          dayLogRepositoryProvider.overrideWithValue(dayLogRepo),
          currentUserIdProvider.overrideWithValue(testUid),
          userStepGoalProvider.overrideWithValue(8000),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      sensorRepo.dispose();
      taskRepo.dispose();
      dayLogRepo.dispose();
    });

    test('initial steps count is 0 and isGoalReached is false', () {
      final state = container.read(stepTrackerNotifierProvider);
      expect(state.todaySteps, 0);
      expect(state.stepGoal, 8000);
      expect(state.isGoalReached, isFalse);
    });

    test('incoming step counts update todaySteps and progress percentage', () async {
      container.read(stepTrackerNotifierProvider);

      // First event establishes baseline: e.g. 10000
      sensorRepo.emitSteps(10000);
      await Future.delayed(const Duration(milliseconds: 20));

      // Second event: 13500 (3,500 steps today)
      sensorRepo.emitSteps(13500);
      await Future.delayed(const Duration(milliseconds: 20));

      final state = container.read(stepTrackerNotifierProvider);
      expect(state.todaySteps, 3500);
      expect(state.progress, closeTo(3500 / 8000, 0.01));
      expect(state.isGoalReached, isFalse);
    });

    test('reaching stepGoal auto-completes the steps_auto task and updates hero ring', () async {
      container.read(stepTrackerNotifierProvider);
      final todayWeekday = DateTime.now().weekday;

      // 1. Create a steps_auto task with weight 2
      await container.read(todayTasksNotifierProvider.notifier).createTask(
            title: 'Daily 8,000 Steps',
            category: 'Health',
            weight: 2,
            type: 'steps_auto',
            repeatDays: [todayWeekday],
          );

      // Verify task exists and is not yet completed
      final initialToday = container.read(todayTasksNotifierProvider);
      expect(initialToday.tasks.length, 1);
      final stepTaskId = initialToday.tasks.first.id;
      expect(initialToday.isTaskCompleted(stepTaskId), isFalse);
      expect(initialToday.completionPercent, 0);

      // 2. Emit initial baseline: 5000
      sensorRepo.emitSteps(5000);
      await Future.delayed(const Duration(milliseconds: 20));

      // 3. Emit 13000 (8,000 steps today -> goal reached!)
      sensorRepo.emitSteps(13000);
      await Future.delayed(const Duration(milliseconds: 50));

      // 4. Verify stepTracker state reached goal
      final stepState = container.read(stepTrackerNotifierProvider);
      expect(stepState.todaySteps, 8000);
      expect(stepState.isGoalReached, isTrue);

      // 5. Verify the task in TodayTasksNotifier automatically marked completed!
      final updatedToday = container.read(todayTasksNotifierProvider);
      expect(updatedToday.isTaskCompleted(stepTaskId), isTrue);
      expect(updatedToday.completedWeight, 2);
      expect(updatedToday.completionPercent, 100);
    });
  });
}
