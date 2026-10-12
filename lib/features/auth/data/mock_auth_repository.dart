import 'dart:async';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class MockAuthRepository implements AuthRepository {
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  MockAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = AuthUser(
      uid: 'mock_google_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: 'student.engineer@gmail.com',
      displayName: 'Alex Rivers',
      photoUrl: null,
    );
    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
