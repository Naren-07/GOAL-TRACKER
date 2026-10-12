import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/excuses/domain/excuse.dart';
import 'package:growthstreak/features/proofs/domain/proof.dart';
import 'package:growthstreak/features/tasks/domain/day_finalizer_service.dart';
import 'package:growthstreak/features/tasks/domain/day_log.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';

void main() {
  group('DayFinalizerService Seam (Asymmetric Resolution Engine)', () {
    late DayFinalizerService service;

    final gymTask = HabitTask(
      id: 'gym_task',
      title: 'Morning Gym',
      category: 'Health',
      type: 'gym_photo',
      weight: 3,
      createdAt: DateTime.now(),
    );

    final readingTask = HabitTask(
      id: 'reading_task',
      title: 'Read 20 pages',
      category: 'Academics',
      type: 'standard',
      weight: 1,
      createdAt: DateTime.now(),
    );

    setUp(() {
      service = DayFinalizerService();
    });

    test('asymmetric resolution: pending photo proof auto-approves past 10 AM grace without penalty', () {
      final proof = Proof(
        id: 'proof_1',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: 'hash1',
        tokenNonce: 'nonce1',
        expiresAt: DateTime(2026, 10, 13, 10, 0),
        createdAt: DateTime(2026, 10, 12, 19, 0),
        status: 'pending',
      );

      final initialLog = DayLog(
        date: '2026-10-12',
        totalWeight: 4,
        completedWeight: 0,
        completionPercent: 0,
        taskOutcomes: {
          'gym_task': const TaskOutcome(status: 'pending'),
        },
      );

      final resolution = service.resolvePastGraceDeadline(
        date: '2026-10-12',
        scheduledTasks: [gymTask],
        dayLog: initialLog,
        proofs: [proof],
        excuses: [],
      );

      expect(resolution.updatedProofStatuses['proof_1'], 'auto_approved');
      expect(resolution.finalDayLog.taskOutcomes['gym_task']?.isCompleted, isTrue);
      expect(resolution.penaltiesOwed, 0);
    });

    test('asymmetric resolution: pending excuse past 10 AM grace finalizes as missed with ₹10 penalty', () {
      final excuse = Excuse(
        id: 'excuse_1',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-12',
        monthKey: '2026-10',
        category: 'Illness',
        note: 'High fever and doctor advised rest for 24h.',
        status: 'pending',
        tokenNonce: 'nonce_ex',
        expiresAt: DateTime(2026, 10, 13, 10, 0),
        createdAt: DateTime(2026, 10, 12, 20, 0),
      );

      final initialLog = DayLog(
        date: '2026-10-12',
        totalWeight: 3,
        completedWeight: 0,
        completionPercent: 0,
        taskOutcomes: {
          'gym_task': const TaskOutcome(status: 'pending'),
        },
      );

      final resolution = service.resolvePastGraceDeadline(
        date: '2026-10-12',
        scheduledTasks: [gymTask],
        dayLog: initialLog,
        proofs: [],
        excuses: [excuse],
      );

      expect(resolution.updatedExcuseStatuses['excuse_1'], 'missed');
      expect(resolution.finalDayLog.taskOutcomes['gym_task']?.isMissed, isTrue);
      expect(resolution.penaltiesOwed, 10);
    });

    test('asymmetric resolution: neither photo nor excuse submitted marks task missed with ₹10 penalty', () {
      final initialLog = DayLog(
        date: '2026-10-12',
        totalWeight: 4,
        completedWeight: 0,
        completionPercent: 0,
        taskOutcomes: {
          'gym_task': const TaskOutcome(status: 'pending'),
          'reading_task': const TaskOutcome(status: 'pending'),
        },
      );

      final resolution = service.resolvePastGraceDeadline(
        date: '2026-10-12',
        scheduledTasks: [gymTask, readingTask],
        dayLog: initialLog,
        proofs: [],
        excuses: [],
      );

      expect(resolution.finalDayLog.taskOutcomes['gym_task']?.isMissed, isTrue);
      expect(resolution.finalDayLog.taskOutcomes['reading_task']?.isMissed, isTrue);
      expect(resolution.penaltiesOwed, 20); // 2 tasks * ₹10
    });
  });
}
