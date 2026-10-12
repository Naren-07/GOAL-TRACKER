import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}
