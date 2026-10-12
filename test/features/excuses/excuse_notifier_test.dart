import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/excuses/data/mock_excuse_repository.dart';
import 'package:growthstreak/features/excuses/domain/excuse.dart';
import 'package:growthstreak/features/excuses/presentation/excuse_notifier.dart';
import 'package:growthstreak/features/excuses/presentation/excuse_providers.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('ExcuseNotifier & ExcuseRepository Seam', () {
    late MockExcuseRepository mockExcuseRepo;
    late MockDayLogRepository mockDayLogRepo;
    late MockTaskRepository mockTaskRepo;
    late ProviderContainer container;

    setUp(() async {
      mockExcuseRepo = MockExcuseRepository();
      mockDayLogRepo = MockDayLogRepository();
      mockTaskRepo = MockTaskRepository();

      // Seed a gym task
      await mockTaskRepo.saveTask(
        'user_123',
        HabitTask(
          id: 'gym_task_1',
          title: 'Daily Gym Workout',
          category: 'Health',
          type: 'gym_photo',
          weight: 3,
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          createdAt: DateTime.now(),
        ),
      );

      container = ProviderContainer(
        overrides: [
          excuseRepositoryProvider.overrideWithValue(mockExcuseRepo),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          currentUserIdProvider.overrideWithValue('user_123'),
        ],
      );
    });

    tearDown(() {
      mockExcuseRepo.dispose();
      container.dispose();
    });

    test('valid excuse note (10 to 300 chars) submits successfully with 10:00 AM next morning expiration', () async {
      final notifier = container.read(excuseNotifierProvider.notifier);

      final success = await notifier.submitExcuse(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
        category: 'Illness',
        note: 'Severe viral fever and doctor strictly advised bed rest.',
        submissionTime: DateTime(2026, 10, 12, 21, 30),
      );

      expect(success, isTrue);
      final state = container.read(excuseNotifierProvider);
      expect(state.isSubmitted, isTrue);
      expect(state.submittedExcuse, isNotNull);
      expect(state.submittedExcuse!.status, 'pending');
      expect(state.submittedExcuse!.expiresAt.hour, 10);
      expect(state.submittedExcuse!.tokenNonce, isNotEmpty);
    });

    test('rejects note with fewer than 10 characters', () async {
      final notifier = container.read(excuseNotifierProvider.notifier);

      final success = await notifier.submitExcuse(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
        category: 'Travel',
        note: 'Too tired', // 9 characters
      );

      expect(success, isFalse);
      final state = container.read(excuseNotifierProvider);
      expect(state.errorMessage, contains('at least 10 characters'));
    });

    test('enforces hard monthly cap of maximum 3 accepted excuses', () async {
      // Seed 3 already-accepted excuses for this month
      for (var i = 1; i <= 3; i++) {
        await mockExcuseRepo.submitExcuse(
          Excuse(
            id: 'old_excuse_$i',
            uid: 'user_123',
            taskId: 'gym_task_1',
            date: '2026-10-0$i',
            monthKey: '2026-10',
            category: 'Exams',
            note: 'Final semester exam preparation session.',
            status: 'accepted',
            tokenNonce: 'nonce_$i',
            expiresAt: DateTime(2026, 10, 13, 10, 0),
            createdAt: DateTime.now(),
          ),
        );
      }

      final notifier = container.read(excuseNotifierProvider.notifier);

      // Attempt to submit 4th excuse in same month
      final success = await notifier.submitExcuse(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
        category: 'Emergency',
        note: 'Family emergency out of town unexpectedly.',
        submissionTime: DateTime(2026, 10, 12, 19, 0),
      );

      expect(success, isFalse);
      final state = container.read(excuseNotifierProvider);
      expect(state.errorMessage, contains('Monthly excuse limit reached (3/3 used'));
    });

    test('friend accepting excuse marks task outcome excused in DayLog', () async {
      final notifier = container.read(excuseNotifierProvider.notifier);

      await notifier.submitExcuse(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
        category: 'Illness',
        note: 'Doctor advised bed rest for flu and congestion.',
        submissionTime: DateTime(2026, 10, 12, 20, 0),
      );

      final excuseId = container.read(excuseNotifierProvider).submittedExcuse!.id;

      // Friend accepts excuse via review page
      await mockExcuseRepo.updateExcuseStatus(excuseId, 'accepted');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final dayLog = await mockDayLogRepo.fetchDayLog('user_123', '2026-10-12');
      expect(dayLog, isNotNull);
      expect(dayLog!.taskOutcomes['gym_task_1']?.isExcused, isTrue);
    });
  });
}
