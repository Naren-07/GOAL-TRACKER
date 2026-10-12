import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/proof_storage_repository.dart';

class FirebaseStorageProofRepository implements ProofStorageRepository {
  final FirebaseStorage _storage;

  FirebaseStorageProofRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadProofImage({
    required String uid,
    required String proofId,
    required Uint8List imageBytes,
  }) async {
    final ref = _storage.ref().child('proofs/$uid/$proofId.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'proofId': proofId, 'uid': uid},
    );
    final task = await ref.putData(imageBytes, metadata);
    return await task.ref.getDownloadURL();
  }
}
