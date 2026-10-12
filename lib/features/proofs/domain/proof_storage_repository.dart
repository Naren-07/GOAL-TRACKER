import 'dart:typed_data';

abstract class ProofStorageRepository {
  Future<String> uploadProofImage({
    required String uid,
    required String proofId,
    required Uint8List imageBytes,
  });
}
