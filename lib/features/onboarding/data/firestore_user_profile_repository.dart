import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final docSnapshot = await _usersCollection.doc(uid).get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return UserProfile.fromMap(docSnapshot.data()!, uid);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _usersCollection.doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromMap(snapshot.data()!, uid);
    });
  }
}
