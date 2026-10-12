import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/core/routing/app_router.dart';
import 'package:growthstreak/core/theme/app_theme.dart';
import 'package:growthstreak/features/auth/data/mock_auth_repository.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';

void main() {
  testWidgets('Full Spike Flow: Sign In -> Onboarding -> Home -> Sign Out',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    final mockProfiles = MockUserProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          userProfileRepositoryProvider.overrideWithValue(mockProfiles),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify on Sign In Screen
    expect(find.text('GrowthStreak'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);

    // 2. Tap Google Sign In
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // 3. User has no profile yet -> lands on Onboarding Screen
    expect(find.text('Profile Setup'), findsOneWidget);
    expect(find.text('1. Student Information'), findsOneWidget);
    expect(find.text('2. Daily Step Goal'), findsOneWidget);
    expect(find.byKey(const Key('complete_onboarding_button')), findsOneWidget);

    // 4. Submit Onboarding Form
    await tester.tap(find.byKey(const Key('complete_onboarding_button')));
    await tester.pumpAndSettle();

    // 5. Lands on Home Screen
    expect(find.text('Alex Rivers'), findsOneWidget);
    expect(find.text('0d'), findsOneWidget);
    expect(find.text('Daily Step Goal'), findsOneWidget);
    expect(find.text('8,000 steps'), findsOneWidget);
    expect(find.byKey(const Key('sign_out_button')), findsOneWidget);

    // 6. Tap Sign Out
    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    // 7. Returns to Sign In Screen
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
