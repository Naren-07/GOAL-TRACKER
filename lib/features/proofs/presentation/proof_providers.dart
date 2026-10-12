import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_proof_repository.dart';
import '../data/mock_proof_storage_repository.dart';
import '../domain/image_proof_service.dart';
import '../domain/proof_repository.dart';
import '../domain/proof_storage_repository.dart';

final proofRepositoryProvider = Provider<ProofRepository>((ref) {
  return MockProofRepository();
});

final proofStorageRepositoryProvider = Provider<ProofStorageRepository>((ref) {
  return MockProofStorageRepository();
});

final imageProofServiceProvider = Provider<ImageProofService>((ref) {
  return ImageProofService();
});
