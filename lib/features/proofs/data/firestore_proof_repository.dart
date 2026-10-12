import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/image_proof_service.dart';
import '../domain/proof.dart';
import '../domain/proof_repository.dart';

class FirestoreProofRepository implements ProofRepository {
  final FirebaseFirestore _firestore;
  final ImageProofService _imageService = ImageProofService();

  FirestoreProofRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _proofsRef =>
      _firestore.collection('proofs');

  @override
  Future<void> submitProof(Proof proof) async {
    await _proofsRef.doc(proof.id).set(proof.toMap());
  }

  @override
  Future<Proof?> getProof(String proofId) async {
    final doc = await _proofsRef.doc(proofId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Proof.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<Proof?> getProofByNonce(String tokenNonce) async {
    final query = await _proofsRef
        .where('tokenNonce', isEqualTo: tokenNonce)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Proof.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  @override
  Future<bool> isDuplicateHash(String uid, String perceptualHash) async {
    // Check against recent user proofs
    final query = await _proofsRef.where('uid', isEqualTo: uid).get();
    for (final doc in query.docs) {
      final existingHash = doc.data()['perceptualHash'] as String?;
      if (existingHash != null) {
        if (_imageService.isDuplicate(existingHash, perceptualHash)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Stream<Proof?> watchProof(String proofId) {
    return _proofsRef.doc(proofId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Proof.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Stream<List<Proof>> watchProofsForDate(String uid, String date) {
    return _proofsRef
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Proof.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> updateProofStatus(
    String proofId,
    String status, {
    String? rejectionReason,
  }) async {
    final updateData = <String, dynamic>{'status': status};
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    await _proofsRef.doc(proofId).update(updateData);
  }
}
