import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_repository.dart';
import 'package:growthstreak/features/proofs/data/mock_proof_storage_repository.dart';
import 'package:growthstreak/features/proofs/domain/proof.dart';

void main() {
  group('ProofRepository Seam', () {
    late MockProofRepository repository;
    late MockProofStorageRepository storageRepository;

    setUp(() {
      repository = MockProofRepository();
      storageRepository = MockProofStorageRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('submitProof stores record and retrieves by ID and tokenNonce', () async {
      final now = DateTime(2026, 10, 12, 18, 30);
      final proof = Proof(
        id: 'proof_123',
        uid: 'user_abc',
        taskId: 'gym_proof',
        date: '2026-10-12',
        photoUrl: 'https://example.com/proof.jpg',
        perceptualHash: '0123456789abcdef',
        tokenNonce: 'nonce_abc12345',
        expiresAt: DateTime(2026, 10, 13, 10, 0),
        createdAt: now,
      );

      await repository.submitProof(proof);

      final fetched = await repository.getProof('proof_123');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'proof_123');
      expect(fetched.isPending, isTrue);

      final fetchedByNonce = await repository.getProofByNonce('nonce_abc12345');
      expect(fetchedByNonce, isNotNull);
      expect(fetchedByNonce!.id, 'proof_123');
    });

    test('isDuplicateHash returns true when near-duplicate hash submitted for same user', () async {
      final proof = Proof(
        id: 'proof_1',
        uid: 'user_abc',
        taskId: 'gym_proof',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p1.jpg',
        perceptualHash: '0123456789abcdef',
        tokenNonce: 'nonce_1',
        expiresAt: DateTime(2026, 10, 13, 10, 0),
        createdAt: DateTime.now(),
      );
      await repository.submitProof(proof);

      // Exact match
      final isDupExact = await repository.isDuplicateHash('user_abc', '0123456789abcdef');
      expect(isDupExact, isTrue);

      // Distinct image
      final isDupDistinct = await repository.isDuplicateHash('user_abc', 'ffffffffffffffff');
      expect(isDupDistinct, isFalse);

      // Different user should not collide
      final isDupOtherUser = await repository.isDuplicateHash('user_xyz', '0123456789abcdef');
      expect(isDupOtherUser, isFalse);
    });

    test('updateProofStatus transitions proof to approved and emits to watcher', () async {
      final proof = Proof(
        id: 'proof_999',
        uid: 'user_abc',
        taskId: 'gym_proof',
        date: '2026-10-12',
        photoUrl: 'https://example.com/p999.jpg',
        perceptualHash: 'aabbccddeeff0011',
        tokenNonce: 'nonce_999',
        expiresAt: DateTime(2026, 10, 13, 10, 0),
        createdAt: DateTime.now(),
      );
      await repository.submitProof(proof);

      final events = <String>[];
      final sub = repository.watchProof('proof_999').listen((p) {
        if (p != null) events.add(p.status);
      });
      await Future<void>.delayed(Duration.zero);

      await repository.updateProofStatus('proof_999', 'approved');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events, containsAllInOrder(['pending', 'approved']));
      final updated = await repository.getProof('proof_999');
      expect(updated?.isApproved, isTrue);
    });

    test('uploadProofImage stores bytes under proofs/{uid}/{proofId}.jpg', () async {
      final bytes = [1, 2, 3, 4, 5];
      final url = await storageRepository.uploadProofImage(
        uid: 'user_abc',
        proofId: 'proof_123',
        imageBytes: Uint8List.fromList(bytes),
      );

      expect(url, contains('proofs%2Fuser_abc%2Fproof_123.jpg'));
      expect(storageRepository.uploadedImages.containsKey('proofs/user_abc/proof_123.jpg'), isTrue);
    });
  });
}
