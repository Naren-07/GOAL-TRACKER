import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_repository.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_storage_repository.dart';
import 'package:growthstreak/features/proofs/presentation/proof_notifier.dart';
import 'package:growthstreak/features/proofs/presentation/proof_providers.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('ProofNotifier Seam', () {
    late MockProofRepository mockProofRepo;
    late MockProofStorageRepository mockStorageRepo;
    late MockTaskRepository mockTaskRepo;
    late MockDayLogRepository mockDayLogRepo;
    late ProviderContainer container;

    Uint8List createSampleImageBytes() {
      final image = img.Image(width: 200, height: 200);
      for (var y = 0; y < 200; y++) {
        for (var x = 0; x < 200; x++) {
          image.setPixelRgb(x, y, x, y, 100);
        }
      }
      return Uint8List.fromList(img.encodeJpg(image));
    }

    setUp(() async {
      mockProofRepo = MockProofRepository();
      mockStorageRepo = MockProofStorageRepository();
      mockTaskRepo = MockTaskRepository();
      mockDayLogRepo = MockDayLogRepository();

      // Seed a gym task for user_123
      await mockTaskRepo.saveTask(
        'user_123',
        HabitTask(
          id: 'gym_task_1',
          title: 'Gym Workout',
          category: 'Health',
          type: 'gym_photo',
          weight: 3,
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          createdAt: DateTime.now(),
        ),
      );

      container = ProviderContainer(
        overrides: [
          proofRepositoryProvider.overrideWithValue(mockProofRepo),
          proofStorageRepositoryProvider.overrideWithValue(mockStorageRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogRepo),
          currentUserIdProvider.overrideWithValue('user_123'),
        ],
      );
    });

    tearDown(() {
      mockProofRepo.dispose();
      container.dispose();
    });

    test('processCapturedPhoto watermarks image and calculates perceptual hash', () {
      final notifier = container.read(proofNotifierProvider.notifier);
      final rawBytes = createSampleImageBytes();

      notifier.processCapturedPhoto(rawBytes);

      final state = container.read(proofNotifierProvider);
      expect(state.previewWatermarkedBytes, isNotNull);
      expect(state.previewWatermarkedBytes!.lengthInBytes, lessThan(358400));
      expect(state.perceptualHash, isNotEmpty);
      expect(state.errorMessage, isNull);
    });

    test('submitProof uploads image, sets pending status, and computes next morning expiration', () async {
      final notifier = container.read(proofNotifierProvider.notifier);
      notifier.processCapturedPhoto(createSampleImageBytes());

      final success = await notifier.submitProof(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
        friend: const AccountabilityFriend(
          name: 'Bob',
          phoneE164: '+919876543210',
          upiVpa: 'bob@upi',
        ),
      );

      expect(success, isTrue);
      final state = container.read(proofNotifierProvider);
      expect(state.isSubmitted, isTrue);
      expect(state.submittedProof, isNotNull);
      expect(state.submittedProof!.status, 'pending');
      expect(state.submittedProof!.tokenNonce, isNotEmpty);
      expect(state.submittedProof!.expiresAt.hour, 10);
      expect(state.submittedProof!.photoUrl, contains('proofs%2Fuser_123%2F'));
    });

    test('submitProof rejects duplicate photo submission', () async {
      final notifier = container.read(proofNotifierProvider.notifier);
      final rawBytes = createSampleImageBytes();

      // Submit first time
      notifier.processCapturedPhoto(rawBytes);
      await notifier.submitProof(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
      );

      // Attempt to submit identical photo second time
      notifier.clearCapture();
      notifier.processCapturedPhoto(rawBytes);
      final secondSuccess = await notifier.submitProof(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
      );

      expect(secondSuccess, isFalse);
      final state = container.read(proofNotifierProvider);
      expect(state.isDuplicateRejected, isTrue);
      expect(state.errorMessage, contains('Duplicate photo detected'));
    });

    test('approving proof in repository automatically completes Gym task in TodayTasksNotifier', () async {
      // Initialize today's tasks
      container.read(todayTasksNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final notifier = container.read(proofNotifierProvider.notifier);
      notifier.processCapturedPhoto(createSampleImageBytes());
      await notifier.submitProof(
        uid: 'user_123',
        taskId: 'gym_task_1',
        date: '2026-10-12',
      );

      final proofId = container.read(proofNotifierProvider).submittedProof!.id;

      // Verify task is initially not completed
      var tasksState = container.read(todayTasksNotifierProvider);
      expect(tasksState.isTaskCompleted('gym_task_1'), isFalse);

      // External approval occurs (e.g. from friend web review)
      await mockProofRepo.updateProofStatus(proofId, 'approved');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Task must now be automatically completed!
      tasksState = container.read(todayTasksNotifierProvider);
      expect(tasksState.isTaskCompleted('gym_task_1'), isTrue);
      expect(tasksState.completionPercent, 100);
    });
  });
}
