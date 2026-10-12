import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/domain/user_profile.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import '../domain/image_proof_service.dart';
import '../domain/proof.dart';
import '../domain/proof_repository.dart';
import '../domain/proof_storage_repository.dart';
import 'proof_providers.dart';

class ProofState {
  final bool isLoading;
  final bool isUploading;
  final bool isSubmitted;
  final bool isDuplicateRejected;
  final String? errorMessage;
  final Uint8List? rawBytes;
  final Uint8List? previewWatermarkedBytes;
  final String? perceptualHash;
  final Proof? submittedProof;

  const ProofState({
    this.isLoading = false,
    this.isUploading = false,
    this.isSubmitted = false,
    this.isDuplicateRejected = false,
    this.errorMessage,
    this.rawBytes,
    this.previewWatermarkedBytes,
    this.perceptualHash,
    this.submittedProof,
  });

  ProofState copyWith({
    bool? isLoading,
    bool? isUploading,
    bool? isSubmitted,
    bool? isDuplicateRejected,
    String? errorMessage,
    Uint8List? rawBytes,
    Uint8List? previewWatermarkedBytes,
    String? perceptualHash,
    Proof? submittedProof,
  }) {
    return ProofState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isDuplicateRejected: isDuplicateRejected ?? this.isDuplicateRejected,
      errorMessage: errorMessage,
      rawBytes: rawBytes ?? this.rawBytes,
      previewWatermarkedBytes:
          previewWatermarkedBytes ?? this.previewWatermarkedBytes,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      submittedProof: submittedProof ?? this.submittedProof,
    );
  }
}

final proofNotifierProvider =
    NotifierProvider<ProofNotifier, ProofState>(ProofNotifier.new);

class ProofNotifier extends Notifier<ProofState> {
  late final ProofRepository _proofRepo;
  late final ProofStorageRepository _storageRepo;
  late final ImageProofService _imageService;
  StreamSubscription<Proof?>? _proofSub;

  @override
  ProofState build() {
    _proofRepo = ref.watch(proofRepositoryProvider);
    _storageRepo = ref.watch(proofStorageRepositoryProvider);
    _imageService = ref.watch(imageProofServiceProvider);

    ref.onDispose(() {
      _proofSub?.cancel();
    });

    return const ProofState();
  }

  /// Takes captured photo, stamps date/time watermark, compresses to <350KB, and calculates perceptual hash
  void processCapturedPhoto(Uint8List rawBytes) {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final now = DateTime.now();
      final watermarked = _imageService.compressAndWatermark(
        imageBytes: rawBytes,
        timestamp: now,
      );

      final hash = _imageService.computePerceptualHash(watermarked);

      state = state.copyWith(
        isLoading: false,
        rawBytes: rawBytes,
        previewWatermarkedBytes: watermarked,
        perceptualHash: hash,
        isDuplicateRejected: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  /// Validates perceptual hash, uploads to Firebase Storage, and saves pending Proof document to Firestore
  Future<bool> submitProof({
    required String uid,
    required String taskId,
    required String date,
    AccountabilityFriend? friend,
  }) async {
    final bytes = state.previewWatermarkedBytes;
    final hash = state.perceptualHash;

    if (bytes == null || hash == null) {
      state = state.copyWith(errorMessage: 'No photo captured yet');
      return false;
    }

    state = state.copyWith(isUploading: true, errorMessage: null);

    try {
      // 1. Perceptual hash duplicate check
      final isDuplicate = await _proofRepo.isDuplicateHash(uid, hash);
      if (isDuplicate) {
        state = state.copyWith(
          isUploading: false,
          isDuplicateRejected: true,
          errorMessage:
              'Duplicate photo detected. Please capture a fresh live photo at the gym.',
        );
        return false;
      }

      // 2. Upload photo to Firebase Storage under proofs/{uid}/{proofId}.jpg
      final now = DateTime.now();
      final proofId = 'proof_${now.millisecondsSinceEpoch}';
      final photoUrl = await _storageRepo.uploadProofImage(
        uid: uid,
        proofId: proofId,
        imageBytes: bytes,
      );

      // 3. Generate secure token nonce and 10:00 AM next morning expiration
      final nonce = _imageService.generateTokenNonce();
      final expiresAt = _imageService.calculateGraceCutoff(now);

      final proof = Proof(
        id: proofId,
        uid: uid,
        taskId: taskId,
        date: date,
        photoUrl: photoUrl,
        perceptualHash: hash,
        status: 'pending',
        tokenNonce: nonce,
        expiresAt: expiresAt,
        createdAt: now,
        friendPhone: friend?.phoneE164,
        friendName: friend?.name,
        friendVpa: friend?.upiVpa,
      );

      // 4. Save to Firestore
      await _proofRepo.submitProof(proof);

      // 5. Watch for friend approval in real-time and auto-complete Gym task
      _watchApproval(proofId, taskId);

      state = state.copyWith(
        isUploading: false,
        isSubmitted: true,
        submittedProof: proof,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed: ${e.toString()}',
      );
      return false;
    }
  }

  void _watchApproval(String proofId, String taskId) {
    _proofSub?.cancel();
    _proofSub = _proofRepo.watchProof(proofId).listen((updatedProof) {
      if (updatedProof != null) {
        state = state.copyWith(submittedProof: updatedProof);
        if (updatedProof.isApproved) {
          // Immediately complete Gym task in student's app in real-time
          ref.read(todayTasksNotifierProvider.notifier).toggleTask(taskId, true);
        }
      }
    });
  }

  void clearCapture() {
    _proofSub?.cancel();
    state = const ProofState();
  }
}
