import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Stream<AuthUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_mapFirebaseUser);

  @override
  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final fb.UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    final fb.User? fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Failed to sign in with Firebase.');
    }

    return _mapFirebaseUser(fbUser)!;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  AuthUser? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
