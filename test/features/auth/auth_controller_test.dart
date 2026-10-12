import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/auth/domain/auth_user.dart';
import 'package:growthstreak/features/auth/data/mock_auth_repository.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';
import 'package:growthstreak/features/auth/presentation/auth_state.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';

void main() {
  group('AuthNotifier / AuthState Seam', () {
    late MockAuthRepository authRepo;
    late MockUserProfileRepository profileRepo;
    late ProviderContainer container;

    setUp(() {
      authRepo = MockAuthRepository();
      profileRepo = MockUserProfileRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          userProfileRepositoryProvider.overrideWithValue(profileRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      authRepo.dispose();
      profileRepo.dispose();
    });

    test('initial state is Unauthenticated', () {
      final state = container.read(authNotifierProvider);
      expect(state, isA<UnauthenticatedState>());
    });

    test('sign in without existing profile transitions to NeedsOnboardingState', () async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();

      final state = container.read(authNotifierProvider);
      expect(state, isA<NeedsOnboardingState>());
      final onboardingState = state as NeedsOnboardingState;
      expect(onboardingState.user.email, contains('@'));
      expect(onboardingState.user.displayName, equals('Alex Rivers'));
    });

    test('completing onboarding creates profile and transitions to AuthenticatedState', () async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      expect(container.read(authNotifierProvider), isA<NeedsOnboardingState>());

      await container.read(authNotifierProvider.notifier).completeOnboarding(
            name: 'Alex Engineer',
            stepGoal: 10000,
            friendName: 'Samir',
            friendPhone: '+919999999999',
            friendUpi: 'samir@oksbi',
          );

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthenticatedState>());
      final authState = state as AuthenticatedState;
      expect(authState.profile.name, equals('Alex Engineer'));
      expect(authState.profile.stepGoal, equals(10000));
      expect(authState.profile.accountabilityFriend?.name, equals('Samir'));

      final storedProfile = await profileRepo.fetchProfile(authState.profile.uid);
      expect(storedProfile, isNotNull);
      expect(storedProfile!.name, equals('Alex Engineer'));
    });

    test('sign in with existing profile transitions directly to AuthenticatedState', () async {
      final existingProfile = UserProfile(
        uid: 'user_returning',
        name: 'Returning Student',
        email: 'returning@example.com',
        stepGoal: 8000,
        createdAt: DateTime(2026, 1, 1),
      );
      await profileRepo.saveProfile(existingProfile);

      final mockRepoWithUser = MockAuthRepository(
        initialUser: const AuthUser(
          uid: 'user_returning',
          email: 'returning@example.com',
          displayName: 'Returning Student',
        ),
      );

      final localContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepoWithUser),
          userProfileRepositoryProvider.overrideWithValue(profileRepo),
        ],
      );

      // Read notifier to trigger subscription
      localContainer.read(authNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = localContainer.read(authNotifierProvider);
      expect(state, isA<AuthenticatedState>());
      final authState = state as AuthenticatedState;
      expect(authState.profile.uid, equals('user_returning'));

      localContainer.dispose();
      mockRepoWithUser.dispose();
    });

    test('signOut resets state to UnauthenticatedState', () async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      await container.read(authNotifierProvider.notifier).signOut();

      final state = container.read(authNotifierProvider);
      expect(state, isA<UnauthenticatedState>());
    });
  });
}
