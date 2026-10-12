import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/domain/day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';

void main() {
  group('DayLogRepository Seam', () {
    late DayLogRepository dayLogRepo;
    const testUid = 'user_student_1';
    const testDate = '2026-10-12';

    final tasks = [
      HabitTask(
        id: 'task_gym',
        title: 'Gym Session',
        category: 'Health',
        weight: 3,
        createdAt: DateTime.now(),
      ),
      HabitTask(
        id: 'task_dsa',
        title: 'LeetCode 2 Problems',
        category: 'Technical Skills',
        weight: 2,
        createdAt: DateTime.now(),
      ),
      HabitTask(
        id: 'task_reading',
        title: 'Read 10 pages',
        category: 'Custom',
        weight: 1,
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() {
      dayLogRepo = MockDayLogRepository();
    });

    test('fetchDayLog returns null when no day log has been recorded yet', () async {
      final log = await dayLogRepo.fetchDayLog(testUid, testDate);
      expect(log, isNull);
    });

    test('recordTaskToggle computes totalWeight, completedWeight, and completionPercent correctly', () async {
      // Toggle gym (weight 3) to completed
      final updatedLog = await dayLogRepo.recordTaskToggle(
        uid: testUid,
        date: testDate,
        taskId: 'task_gym',
        isCompleted: true,
        scheduledTasks: tasks,
      );

      // Total weight = 3 + 2 + 1 = 6
      // Completed weight = 3
      // completionPercent = (3 / 6) * 100 = 50%
      expect(updatedLog.totalWeight, 6);
      expect(updatedLog.completedWeight, 3);
      expect(updatedLog.completionPercent, 50);
      expect(updatedLog.taskOutcomes['task_gym']?.status, 'completed');
      expect(updatedLog.taskOutcomes['task_dsa']?.status, 'pending');

      // Now toggle dsa (weight 2) to completed
      final secondLog = await dayLogRepo.recordTaskToggle(
        uid: testUid,
        date: testDate,
        taskId: 'task_dsa',
        isCompleted: true,
        scheduledTasks: tasks,
      );

      // Completed weight = 3 + 2 = 5
      // completionPercent = (5 / 6) * 100 = 83%
      expect(secondLog.totalWeight, 6);
      expect(secondLog.completedWeight, 5);
      expect(secondLog.completionPercent, 83);

      // Untoggle gym
      final untoggledLog = await dayLogRepo.recordTaskToggle(
        uid: testUid,
        date: testDate,
        taskId: 'task_gym',
        isCompleted: false,
        scheduledTasks: tasks,
      );

      // Completed weight = 2
      // completionPercent = (2 / 6) * 100 = 33%
      expect(untoggledLog.completedWeight, 2);
      expect(untoggledLog.completionPercent, 33);
      expect(untoggledLog.taskOutcomes['task_gym']?.status, 'pending');
    });

    test('watchDayLog emits updates when task is toggled', () async {
      final stream = dayLogRepo.watchDayLog(testUid, testDate);
      expect(await stream.first, isNull);

      await dayLogRepo.recordTaskToggle(
        uid: testUid,
        date: testDate,
        taskId: 'task_reading',
        isCompleted: true,
        scheduledTasks: tasks,
      );

      final emission = await stream.first;
      expect(emission, isNotNull);
      expect(emission!.completedWeight, 1);
      expect(emission.completionPercent, 17); // (1/6 * 100).round()
    });
  });
}
