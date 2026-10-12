import 'dart:async';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class MockUserProfileRepository implements UserProfileRepository {
  final Map<String, UserProfile> _profiles = {};
  final StreamController<Map<String, UserProfile>> _profilesStream =
      StreamController<Map<String, UserProfile>>.broadcast();

  MockUserProfileRepository([Map<String, UserProfile>? initialProfiles]) {
    if (initialProfiles != null) {
      _profiles.addAll(initialProfiles);
    }
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    return _profiles[uid];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
    _profilesStream.add(Map.unmodifiable(_profiles));
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profiles[uid];
    yield* _profilesStream.stream.map((map) => map[uid]);
  }

  void dispose() {
    _profilesStream.close();
  }
}
