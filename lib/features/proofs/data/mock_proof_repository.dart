import 'dart:async';
import '../domain/image_proof_service.dart';
import '../domain/proof.dart';
import '../domain/proof_repository.dart';

class MockProofRepository implements ProofRepository {
  final Map<String, Proof> _proofs = {};
  final _proofsStreamController = StreamController<Map<String, Proof>>.broadcast();
  final ImageProofService _imageService = ImageProofService();

  @override
  Future<void> submitProof(Proof proof) async {
    _proofs[proof.id] = proof;
    _proofsStreamController.add(Map.unmodifiable(_proofs));
  }

  @override
  Future<Proof?> getProof(String proofId) async {
    return _proofs[proofId];
  }

  @override
  Future<Proof?> getProofByNonce(String tokenNonce) async {
    try {
      return _proofs.values.firstWhere((p) => p.tokenNonce == tokenNonce);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isDuplicateHash(String uid, String perceptualHash) async {
    for (final proof in _proofs.values) {
      if (proof.uid == uid) {
        if (_imageService.isDuplicate(proof.perceptualHash, perceptualHash)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Stream<Proof?> watchProof(String proofId) async* {
    yield _proofs[proofId];
    yield* _proofsStreamController.stream.map((map) => map[proofId]);
  }

  @override
  Stream<List<Proof>> watchProofsForDate(String uid, String date) async* {
    yield _proofs.values
        .where((p) => p.uid == uid && p.date == date)
        .toList();
    yield* _proofsStreamController.stream.map((map) => map.values
        .where((p) => p.uid == uid && p.date == date)
        .toList());
  }

  @override
  Future<void> updateProofStatus(
    String proofId,
    String status, {
    String? rejectionReason,
  }) async {
    final existing = _proofs[proofId];
    if (existing != null) {
      _proofs[proofId] = existing.copyWith(
        status: status,
        rejectionReason: rejectionReason,
      );
      _proofsStreamController.add(Map.unmodifiable(_proofs));
    }
  }

  void dispose() {
    _proofsStreamController.close();
  }
}
