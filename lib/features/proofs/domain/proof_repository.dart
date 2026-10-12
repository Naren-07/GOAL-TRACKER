import 'proof.dart';

abstract class ProofRepository {
  Future<void> submitProof(Proof proof);
  Future<Proof?> getProof(String proofId);
  Future<Proof?> getProofByNonce(String tokenNonce);
  Future<bool> isDuplicateHash(String uid, String perceptualHash);
  Stream<Proof?> watchProof(String proofId);
  Stream<List<Proof>> watchProofsForDate(String uid, String date);
  Future<void> updateProofStatus(
    String proofId,
    String status, {
    String? rejectionReason,
  });
}
