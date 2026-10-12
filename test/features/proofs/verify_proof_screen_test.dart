import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_repository.dart';
import 'package:growthstreak/features/proofs/domain/proof.dart';
import 'package:growthstreak/features/proofs/presentation/proof_providers.dart';
import 'package:growthstreak/features/proofs/presentation/verify_proof_screen.dart';

void main() {
  group('VerifyProofScreen Friend Review Flow', () {
    late MockProofRepository mockProofRepo;

    setUp(() {
      mockProofRepo = MockProofRepository();
    });

    tearDown(() {
      mockProofRepo.dispose();
    });

    Widget createTestApp({required String proofId, String? token}) {
      return ProviderScope(
        overrides: [
          proofRepositoryProvider.overrideWithValue(mockProofRepo),
        ],
        child: MaterialApp(
          home: VerifyProofScreen(proofId: proofId, token: token),
        ),
      );
    }

    testWidgets('shows unauthorized error if token nonce does not match', (tester) async {
      final proof = Proof(
        id: 'proof_1',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: 'hash1',
        tokenNonce: 'secret_nonce_valid',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
        createdAt: DateTime.now(),
      );
      await mockProofRepo.submitProof(proof);

      await tester.pumpWidget(createTestApp(proofId: 'proof_1', token: 'wrong_nonce'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid or unauthorized verification token.'), findsOneWidget);
    });

    testWidgets('shows Link Expired card if grace period has passed', (tester) async {
      final expiredProof = Proof(
        id: 'proof_expired',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-11',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: 'hash1',
        tokenNonce: 'nonce_valid',
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)), // 2 hours in past
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      );
      await mockProofRepo.submitProof(expiredProof);

      await tester.pumpWidget(createTestApp(proofId: 'proof_expired', token: 'nonce_valid'));
      await tester.pumpAndSettle();

      expect(find.text('Link Expired'), findsOneWidget);
      expect(find.textContaining('10:00 AM grace cutoff passed'), findsOneWidget);
    });

    testWidgets('friend approves workout proof and transitions to celebratory confirmation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final validProof = Proof(
        id: 'proof_valid',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: 'hash1',
        tokenNonce: 'nonce_valid',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
        createdAt: DateTime.now(),
        friendName: 'Alex',
      );
      await mockProofRepo.submitProof(validProof);

      await tester.pumpWidget(createTestApp(proofId: 'proof_valid', token: 'nonce_valid'));
      await tester.pumpAndSettle();

      // Verify buttons
      final approveButton = find.byKey(const Key('approve_proof_button'));
      expect(approveButton, findsOneWidget);
      await tester.ensureVisible(approveButton);

      // Tap Approve
      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      // Celebratory screen
      expect(find.text('Gym Proof Approved! 🎉'), findsOneWidget);

      // Verify updated in repository
      final updated = await mockProofRepo.getProof('proof_valid');
      expect(updated?.isApproved, isTrue);
    });

    testWidgets('friend rejects workout proof with specific reason', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final validProof = Proof(
        id: 'proof_reject_test',
        uid: 'user_1',
        taskId: 'gym_task',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: 'hash1',
        tokenNonce: 'nonce_valid',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
        createdAt: DateTime.now(),
      );
      await mockProofRepo.submitProof(validProof);

      await tester.pumpWidget(createTestApp(proofId: 'proof_reject_test', token: 'nonce_valid'));
      await tester.pumpAndSettle();

      // Tap Reject button to open bottom sheet
      final rejectButton = find.byKey(const Key('reject_proof_button'));
      await tester.ensureVisible(rejectButton);
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      expect(find.text('Select Rejection Reason'), findsOneWidget);
      expect(find.text('Not at gym'), findsOneWidget);

      // Select "Not at gym"
      await tester.tap(find.text('Not at gym'));
      await tester.pumpAndSettle();

      // Status card
      expect(find.text('Proof Rejected'), findsOneWidget);

      // Verify rejected in repository with reason
      final updated = await mockProofRepo.getProof('proof_reject_test');
      expect(updated?.isRejected, isTrue);
      expect(updated?.rejectionReason, 'Not at gym');
    });
  });
}
