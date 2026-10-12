import 'dart:typed_data';
import '../domain/proof_storage_repository.dart';

class MockProofStorageRepository implements ProofStorageRepository {
  final Map<String, Uint8List> uploadedImages = {};

  @override
  Future<String> uploadProofImage({
    required String uid,
    required String proofId,
    required Uint8List imageBytes,
  }) async {
    final path = 'proofs/$uid/$proofId.jpg';
    uploadedImages[path] = imageBytes;
    return 'https://firebasestorage.googleapis.com/v0/b/growthstreak.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
  }
}
