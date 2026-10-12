import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, current) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSigningIn = state.matchedLocation == '/sign-in';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (authState is UnauthenticatedState || authState is AuthErrorState) {
        return isSigningIn ? null : '/sign-in';
      }

      if (authState is NeedsOnboardingState) {
        return isOnboarding ? null : '/onboarding';
      }

      if (authState is AuthenticatedState) {
        return (isSigningIn || isOnboarding) ? '/home' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final authState = ref.read(authNotifierProvider);
          if (authState is NeedsOnboardingState) {
            return OnboardingScreen(user: authState.user);
          }
          return const SignInScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final authState = ref.read(authNotifierProvider);
          if (authState is AuthenticatedState) {
            return HomeScreen(profile: authState.profile);
          }
          return const SignInScreen();
        },
      ),
    ],
  );
});
