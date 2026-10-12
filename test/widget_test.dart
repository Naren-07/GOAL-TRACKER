import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/core/routing/app_router.dart';
import 'package:growthstreak/core/theme/app_theme.dart';
import 'package:growthstreak/features/auth/data/mock_auth_repository.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/home/presentation/home_screen.dart';
import 'package:growthstreak/features/onboarding/data/mock_user_profile_repository.dart';
import 'package:growthstreak/features/steps/data/mock_step_sensor_repository.dart';
import 'package:growthstreak/features/steps/presentation/step_tracker_notifier.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  testWidgets(
      'Full End-to-End Flow: Auth -> Onboarding -> Home -> Step Sensor Tracking & Auto-Completion',
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
    final mockStepSensor =
        MockStepSensorRepository(initialPermissionGranted: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          userProfileRepositoryProvider.overrideWithValue(mockProfiles),
          taskRepositoryProvider.overrideWithValue(mockTasks),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogs),
          stepSensorRepositoryProvider.overrideWithValue(mockStepSensor),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            // Eagerly watch step tracker
            ref.watch(stepTrackerNotifierProvider);
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
    expect(find.text('Hardware Step Counter'), findsOneWidget);
    expect(find.text('0 / 8,000 steps'), findsOneWidget);

    // 5. Create a Daily Steps task (weight 2)
    final todayWeekday = DateTime.now().weekday;
    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);

    await container.read(todayTasksNotifierProvider.notifier).createTask(
          title: 'Daily Steps',
          category: 'Health',
          weight: 2,
          type: 'steps_auto',
          repeatDays: [todayWeekday],
        );
    await tester.pumpAndSettle();

    expect(find.text('Daily Steps'), findsOneWidget);
    expect(find.text('0/2 wt'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 6. Simulate hardware step sensor events
    // Event 1 establishes baseline
    mockStepSensor.emitSteps(1000);
    await tester.pump(const Duration(milliseconds: 20));

    // Event 2 emits 9000 steps (9000 - 1000 = 8000 steps taken today -> goal reached!)
    mockStepSensor.emitSteps(9000);
    await tester.pumpAndSettle();

    // 7. Verify step counter updated to 8,000 / 8,000 steps
    expect(find.text('8,000 / 8,000 steps'), findsOneWidget);
    expect(find.text('Goal Met!'), findsOneWidget);

    // 8. Verify the Daily Steps task automatically completed and hero ring updated to 100%!
    expect(find.text('2/2 wt'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Streak Secured!'), findsOneWidget);

    // 9. Sign Out
    await tester.scrollUntilVisible(
        find.byKey(const Key('sign_out_button')), 200);
    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
