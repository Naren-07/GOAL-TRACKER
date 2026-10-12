import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile_repository.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';

void main() {
  group('UserProfileRepository Seam', () {
    late UserProfileRepository repository;

    setUp(() {
      repository = MockUserProfileRepository();
    });

    test('fetchProfile returns null when profile does not exist', () async {
      final profile = await repository.fetchProfile('non_existent_uid');
      expect(profile, isNull);
    });

    test('saveProfile persists profile and allows retrieval via fetchProfile', () async {
      final newProfile = UserProfile(
        uid: 'user_123',
        name: 'Naren Kumar',
        email: 'naren@example.com',
        stepGoal: 8000,
        currentStreak: 0,
        bestStreak: 0,
        unresolvedPenaltiesCount: 0,
        createdAt: DateTime(2026, 10, 12),
        accountabilityFriend: const AccountabilityFriend(
          name: 'Priya',
          phoneE164: '+919876543210',
          upiVpa: 'priya@oksbi',
        ),
      );

      await repository.saveProfile(newProfile);

      final fetched = await repository.fetchProfile('user_123');
      expect(fetched, isNotNull);
      expect(fetched!.uid, equals('user_123'));
      expect(fetched.name, equals('Naren Kumar'));
      expect(fetched.email, equals('naren@example.com'));
      expect(fetched.stepGoal, equals(8000));
      expect(fetched.accountabilityFriend?.name, equals('Priya'));
      expect(fetched.accountabilityFriend?.upiVpa, equals('priya@oksbi'));
    });

    test('watchProfile emits updated profile when saved', () async {
      final initial = await repository.watchProfile('user_456').first;
      expect(initial, isNull);

      final profile = UserProfile(
        uid: 'user_456',
        name: 'Dev Student',
        email: 'dev@example.com',
        stepGoal: 10000,
        createdAt: DateTime.now(),
      );

      await repository.saveProfile(profile);

      final updated = await repository.watchProfile('user_456').first;
      expect(updated, isNotNull);
      expect(updated!.stepGoal, equals(10000));
    });
  });
}
