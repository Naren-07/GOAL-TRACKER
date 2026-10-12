import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../../onboarding/domain/user_profile.dart';
import '../../onboarding/domain/user_profile_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be initialized');
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  throw UnimplementedError('userProfileRepositoryProvider must be initialized');
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final UserProfileRepository _userProfileRepository;
  StreamSubscription<AuthUser?>? _authSubscription;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _userProfileRepository = ref.watch(userProfileRepositoryProvider);

    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user == null) {
        state = const UnauthenticatedState();
      } else {
        await _resolveUser(user);
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    final current = _authRepository.currentUser;
    if (current != null) {
      // Begin resolving synchronously
      Future.microtask(() => _resolveUser(current));
    }

    return const UnauthenticatedState();
  }

  Future<void> _resolveUser(AuthUser user) async {
    state = const AuthLoadingState('Checking profile...');
    try {
      final profile = await _userProfileRepository.fetchProfile(user.uid);
      if (profile == null) {
        state = NeedsOnboardingState(user);
      } else {
        state = AuthenticatedState(profile);
      }
    } catch (e) {
      state = AuthErrorState('Failed to load profile: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoadingState('Signing in with Google...');
    try {
      final user = await _authRepository.signInWithGoogle();
      await _resolveUser(user);
    } catch (e) {
      state = AuthErrorState('Google Sign-In failed: $e');
    }
  }

  Future<void> completeOnboarding({
    required String name,
    required int stepGoal,
    String? friendName,
    String? friendPhone,
    String? friendUpi,
  }) async {
    final currentState = state;
    if (currentState is! NeedsOnboardingState) {
      throw StateError('Cannot complete onboarding from state: $state');
    }

    state = const AuthLoadingState('Saving profile...');
    try {
      final user = currentState.user;
      final friend = (friendName != null && friendName.trim().isNotEmpty)
          ? AccountabilityFriend(
              name: friendName.trim(),
              phoneE164: friendPhone?.trim() ?? '',
              upiVpa: friendUpi?.trim() ?? '',
            )
          : null;

      final newProfile = UserProfile(
        uid: user.uid,
        name: name.trim().isNotEmpty ? name.trim() : (user.displayName ?? 'Student'),
        email: user.email,
        photoUrl: user.photoUrl,
        accountabilityFriend: friend,
        stepGoal: stepGoal,
        currentStreak: 0,
        bestStreak: 0,
        unresolvedPenaltiesCount: 0,
        createdAt: DateTime.now(),
      );

      await _userProfileRepository.saveProfile(newProfile);
      state = AuthenticatedState(newProfile);
    } catch (e) {
      state = AuthErrorState('Failed to save profile: $e');
    }
  }

  Future<void> signOut() async {
    state = const AuthLoadingState('Signing out...');
    try {
      await _authRepository.signOut();
      state = const UnauthenticatedState();
    } catch (e) {
      state = AuthErrorState('Failed to sign out: $e');
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
