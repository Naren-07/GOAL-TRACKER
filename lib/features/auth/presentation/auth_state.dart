import 'package:flutter/foundation.dart';
import '../domain/auth_user.dart';
import '../../onboarding/domain/user_profile.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

class AuthLoadingState extends AuthState {
  final String? message;
  const AuthLoadingState([this.message]);
}

class NeedsOnboardingState extends AuthState {
  final AuthUser user;
  const NeedsOnboardingState(this.user);
}

class AuthenticatedState extends AuthState {
  final UserProfile profile;
  const AuthenticatedState(this.profile);
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
}
