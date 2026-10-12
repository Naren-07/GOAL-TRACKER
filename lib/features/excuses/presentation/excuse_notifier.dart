import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/domain/user_profile.dart';
import '../../proofs/domain/image_proof_service.dart';
import '../../proofs/presentation/proof_providers.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import '../domain/excuse.dart';
import '../domain/excuse_repository.dart';
import 'excuse_providers.dart';

class ExcuseState {
  final bool isLoading;
  final bool isSubmitted;
  final String? errorMessage;
  final int monthlyUsedCount;
  final Excuse? submittedExcuse;

  const ExcuseState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.monthlyUsedCount = 0,
    this.submittedExcuse,
  });

  ExcuseState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    String? errorMessage,
    int? monthlyUsedCount,
    Excuse? submittedExcuse,
  }) {
    return ExcuseState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage,
      monthlyUsedCount: monthlyUsedCount ?? this.monthlyUsedCount,
      submittedExcuse: submittedExcuse ?? this.submittedExcuse,
    );
  }
}

final excuseNotifierProvider =
    NotifierProvider<ExcuseNotifier, ExcuseState>(ExcuseNotifier.new);

class ExcuseNotifier extends Notifier<ExcuseState> {
  late final ExcuseRepository _excuseRepo;
  late final ImageProofService _imageProofService;
  StreamSubscription<Excuse?>? _excuseSub;

  @override
  ExcuseState build() {
    _excuseRepo = ref.watch(excuseRepositoryProvider);
    _imageProofService = ref.watch(imageProofServiceProvider);

    ref.onDispose(() {
      _excuseSub?.cancel();
    });

    return const ExcuseState();
  }

  Future<void> checkMonthlyUsage(String uid, String monthKey) async {
    try {
      final count = await _excuseRepo.countAcceptedExcusesInMonth(uid, monthKey);
      state = state.copyWith(monthlyUsedCount: count);
    } catch (_) {}
  }

  Future<bool> submitExcuse({
    required String uid,
    required String taskId,
    required String date,
    required String category,
    required String note,
    AccountabilityFriend? friend,
    DateTime? submissionTime,
  }) async {
    final now = submissionTime ?? DateTime.now();

    final trimmed = note.trim();
    if (trimmed.length < 10) {
      state = state.copyWith(
        errorMessage: 'Excuse note must be at least 10 characters long.',
      );
      return false;
    }
    if (trimmed.length > 300) {
      state = state.copyWith(
        errorMessage: 'Excuse note must not exceed 300 characters.',
      );
      return false;
    }

    // Month key: YYYY-MM
    final monthKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Enforce hard monthly cap of 3 accepted excuses
      final usedCount = await _excuseRepo.countAcceptedExcusesInMonth(uid, monthKey);
      if (usedCount >= 3) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Monthly excuse limit reached (3/3 used for this month). Please complete your workout.',
        );
        return false;
      }

      // 2. Compute 10:00 AM next morning expiration & nonce
      final expiresAt = _imageProofService.calculateGraceCutoff(now);
      final tokenNonce = _imageProofService.generateTokenNonce();
      final excuseId = 'excuse_${now.millisecondsSinceEpoch}';

      final excuse = Excuse(
        id: excuseId,
        uid: uid,
        taskId: taskId,
        date: date,
        monthKey: monthKey,
        category: category,
        note: trimmed,
        status: 'pending',
        tokenNonce: tokenNonce,
        expiresAt: expiresAt,
        createdAt: now,
        friendName: friend?.name,
        friendPhone: friend?.phoneE164,
      );

      await _excuseRepo.submitExcuse(excuse);

      // Watch for friend acceptance in real-time
      _watchExcuseDecision(excuseId, uid, date, taskId);

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        monthlyUsedCount: usedCount,
        submittedExcuse: excuse,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Submission failed: ${e.toString()}',
      );
      return false;
    }
  }

  void _watchExcuseDecision(
    String excuseId,
    String uid,
    String date,
    String taskId,
  ) {
    _excuseSub?.cancel();
    _excuseSub = _excuseRepo.watchExcuse(excuseId).listen((updated) async {
      if (updated != null) {
        state = state.copyWith(submittedExcuse: updated);
        if (updated.isAccepted) {
          // Update task outcome in DayLog to excused
          final dayLogRepo = ref.read(dayLogRepositoryProvider);
          await dayLogRepo.recordTaskOutcome(
            uid: uid,
            date: date,
            taskId: taskId,
            status: 'excused',
          );
        }
      }
    });
  }

  void reset() {
    _excuseSub?.cancel();
    state = const ExcuseState();
  }
}
