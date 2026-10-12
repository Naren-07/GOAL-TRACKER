import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/auth/presentation/auth_state.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile_repository.dart';
import 'package:growthstreak/features/profile/presentation/profile_screen.dart';

void main() {
  group('ProfileScreen Flow', () {
    late MockUserProfileRepository mockUserRepo;

    final initialProfile = UserProfile(
      uid: 'user_123',
      name: 'Naren Student',
      email: 'naren@example.com',
      accountabilityFriend: const AccountabilityFriend(
        name: 'Initial Friend',
        phoneE164: '+919123456789',
        upiVpa: 'initial@upi',
      ),
      createdAt: DateTime.now(),
    );

    setUp(() async {
      mockUserRepo = MockUserProfileRepository();
      await mockUserRepo.saveProfile(initialProfile);
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(mockUserRepo),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(initialProfile),
          ),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('populates friend details and allows saving updates', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify initial fields
      expect(find.text('Initial Friend'), findsOneWidget);
      expect(find.text('+919123456789'), findsOneWidget);
      expect(find.text('initial@upi'), findsOneWidget);

      // Edit fields
      await tester.enterText(find.widgetWithText(TextFormField, "Friend's Full Name"), 'Sarah Partner');
      await tester.enterText(find.widgetWithText(TextFormField, "Friend's WhatsApp Number"), '+919876543210');
      await tester.enterText(find.widgetWithText(TextFormField, "Friend's UPI VPA (for accountability stake)"), 'sarah@okaxis');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Accountability Friend'));
      await tester.pumpAndSettle();

      // Verify success banner
      expect(find.text('Friend details saved successfully!'), findsOneWidget);

      // Verify saved in repository
      final updated = await mockUserRepo.fetchProfile('user_123');
      expect(updated?.accountabilityFriend?.name, 'Sarah Partner');
      expect(updated?.accountabilityFriend?.phoneE164, '+919876543210');
      expect(updated?.accountabilityFriend?.upiVpa, 'sarah@okaxis');
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final UserProfile _profile;
  _FakeAuthNotifier(this._profile);

  @override
  AuthState build() {
    return AuthenticatedState(_profile);
  }
}
