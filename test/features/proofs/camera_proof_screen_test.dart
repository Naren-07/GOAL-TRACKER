import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/auth/domain/auth_user.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/auth/presentation/auth_state.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_repository.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_storage_repository.dart';
import 'package:growthstreak/features/proofs/presentation/camera_proof_screen.dart';
import 'package:growthstreak/features/proofs/presentation/proof_providers.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('CameraProofScreen Widget Flow', () {
    late MockProofRepository mockProofRepo;
    late MockProofStorageRepository mockStorageRepo;
    late MockTaskRepository mockTaskRepo;
    late MockDayLogRepository mockDayLogRepo;

    final testTask = HabitTask(
      id: 'gym_task_1',
      title: 'Morning Gym Session',
      category: 'Health',
      type: 'gym_photo',
      weight: 3,
      createdAt: DateTime.now(),
    );

    final testProfile = UserProfile(
      uid: 'user_123',
      name: 'Naren Student',
      email: 'naren@example.com',
      accountabilityFriend: const AccountabilityFriend(
        name: 'Friend Bob',
        phoneE164: '+919876543210',
        upiVpa: 'bob@upi',
      ),
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockProofRepo = MockProofRepository();
      mockStorageRepo = MockProofStorageRepository();
      mockTaskRepo = MockTaskRepository();
      mockDayLogRepo = MockDayLogRepository();
    });

    tearDown(() {
      mockProofRepo.dispose();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          proofRepositoryProvider.overrideWithValue(mockProofRepo),
          proofStorageRepositoryProvider.overrideWithValue(mockStorageRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogRepo),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(testProfile),
          ),
          currentUserIdProvider.overrideWithValue(testProfile.uid),
        ],
        child: MaterialApp(
          home: CameraProofScreen(task: testTask),
        ),
      );
    }

    testWidgets('shows viewfinder, captures photo, previews watermarked image and submits', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Viewfinder and Live Only indicator
      expect(find.text('LIVE ONLY'), findsOneWidget);
      expect(find.byKey(const Key('camera_viewfinder')), findsOneWidget);
      expect(find.byKey(const Key('shutter_button')), findsOneWidget);

      // Tap Shutter
      await tester.tap(find.byKey(const Key('shutter_button')));
      await tester.pumpAndSettle();

      // Viewfinder is replaced with preview and controls
      expect(find.byKey(const Key('camera_viewfinder')), findsNothing);
      expect(find.byKey(const Key('proof_preview_container')), findsOneWidget);
      expect(find.byKey(const Key('retake_button')), findsOneWidget);
      expect(find.byKey(const Key('submit_proof_button')), findsOneWidget);

      // Tap Submit Proof
      await tester.tap(find.byKey(const Key('submit_proof_button')));
      await tester.pumpAndSettle();

      // Verify success overlay
      expect(find.text('Proof Submitted!'), findsOneWidget);
      expect(find.textContaining('Expires at 10:00 AM tomorrow'), findsOneWidget);
      expect(find.textContaining('Friend Bob'), findsOneWidget);

      // Verify Proof is in MockProofRepository
      final proofs = await mockProofRepo.watchProofsForDate('user_123', TodayTasksNotifier.todayDateString()).first;
      expect(proofs.length, 1);
      expect(proofs.first.status, 'pending');
      expect(proofs.first.expiresAt.hour, 10);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final UserProfile _profile;
  _FakeAuthNotifier(this._profile);

  @override
  AuthState build() {
    return AuthenticatedState(_profile);
  }
}
