import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/core/routing/app_router.dart';
import 'package:growthstreak/core/theme/app_theme.dart';
import 'package:growthstreak/features/auth/data/mock_auth_repository.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  testWidgets(
      'Full End-to-End Flow: Sign In -> Onboarding -> Home Hero Ring & Task Toggles',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = MockAuthRepository();
    final mockProfiles = MockUserProfileRepository();
    final mockTasks = MockTaskRepository();
    final mockDayLogs = MockDayLogRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          userProfileRepositoryProvider.overrideWithValue(mockProfiles),
          taskRepositoryProvider.overrideWithValue(mockTasks),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogs),
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
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);

    // 2. Tap Google Sign In
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // 3. User has no profile yet -> lands on Onboarding Screen
    expect(find.text('Profile Setup'), findsOneWidget);
    await tester.tap(find.byKey(const Key('complete_onboarding_button')));
    await tester.pumpAndSettle();

    // 4. Lands on Home Screen
    expect(find.text('Alex Rivers'), findsOneWidget);
    expect(find.text("Today's Tasks"), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0/0 wt'), findsOneWidget);

    // 5. Tap Add Task button
    await tester.tap(find.byKey(const Key('add_task_header_button')));
    await tester.pumpAndSettle();

    // Verify modal bottom sheet opened
    expect(find.text('Create Daily Task'), findsOneWidget);

    // Enter title: "Gym Workout"
    await tester.enterText(
        find.byKey(const Key('task_title_input')), 'Gym Workout');
    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    // 6. Verify task created and displayed in Today's Tasks
    expect(find.text('Gym Workout'), findsOneWidget);
    expect(find.text('0/1 wt'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 7. Toggle Gym Workout checkbox
    final checkboxFinder = find.byType(Checkbox).first;
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // 8. Dynamic Hero Ring updates to 100% (1/1 wt)
    expect(find.text('1/1 wt'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Streak Secured!'), findsOneWidget);

    // 9. Untoggle checkbox
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(find.text('0/1 wt'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 10. Tap Sign Out
    await tester.scrollUntilVisible(
        find.byKey(const Key('sign_out_button')), 200);
    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
