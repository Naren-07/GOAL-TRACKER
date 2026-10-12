import 'user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> fetchProfile(String uid);
  Future<void> saveProfile(UserProfile profile);
  Stream<UserProfile?> watchProfile(String uid);
}
