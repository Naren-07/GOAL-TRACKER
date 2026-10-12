import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../onboarding/domain/user_profile.dart';
import '../../onboarding/domain/user_profile_repository.dart';

class ProfileState {
  final bool isLoading;
  final bool isSaved;
  final String? errorMessage;
  final UserProfile? userProfile;

  const ProfileState({
    this.isLoading = false,
    this.isSaved = false,
    this.errorMessage,
    this.userProfile,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaved,
    String? errorMessage,
    UserProfile? userProfile,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileState> {
  late final UserProfileRepository _userProfileRepo;

  @override
  ProfileState build() {
    _userProfileRepo = ref.watch(userProfileRepositoryProvider);
    final authState = ref.watch(authNotifierProvider);

    if (authState is AuthenticatedState) {
      _loadProfile(authState.profile.uid);
    }

    return const ProfileState(isLoading: true);
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final profile = await _userProfileRepo.fetchProfile(uid);
      state = state.copyWith(isLoading: false, userProfile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateAccountabilityFriend({
    required String name,
    required String phoneE164,
    required String upiVpa,
  }) async {
    final current = state.userProfile;
    if (current == null) return false;

    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Friend name is required');
      return false;
    }
    if (!phoneE164.startsWith('+') || phoneE164.length < 10) {
      state = state.copyWith(
          errorMessage: 'Phone must include country code (e.g. +91...)');
      return false;
    }
    if (!upiVpa.contains('@')) {
      state = state.copyWith(errorMessage: 'Invalid UPI VPA (e.g. name@upi)');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSaved: false);
    try {
      final updatedFriend = AccountabilityFriend(
        name: name.trim(),
        phoneE164: phoneE164.trim(),
        upiVpa: upiVpa.trim(),
        firstProofViewed: current.accountabilityFriend?.firstProofViewed ?? false,
      );

      final updatedProfile = current.copyWith(
        accountabilityFriend: updatedFriend,
      );

      await _userProfileRepo.saveProfile(updatedProfile);
      state = state.copyWith(
        isLoading: false,
        isSaved: true,
        userProfile: updatedProfile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
