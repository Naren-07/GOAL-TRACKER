import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/auth/presentation/auth_controller.dart';
import 'package:growthstreak/features/auth/presentation/auth_state.dart';
import 'package:growthstreak/features/excuses/data/mock_excuse_repository.dart';
import 'package:growthstreak/features/excuses/presentation/excuse_providers.dart';
import 'package:growthstreak/features/excuses/presentation/submit_excuse_sheet.dart';
import 'package:growthstreak/features/onboarding/domain/user_profile.dart';
import 'package:growthstreak/features/tasks/data/mock_day_log_repository.dart';
import 'package:growthstreak/features/tasks/data/mock_task_repository.dart';
import 'package:growthstreak/features/tasks/domain/habit_task.dart';
import 'package:growthstreak/features/tasks/presentation/today_tasks_notifier.dart';

void main() {
  group('SubmitExcuseSheet Widget Flow', () {
    late MockExcuseRepository mockExcuseRepo;
    late MockDayLogRepository mockDayLogRepo;
    late MockTaskRepository mockTaskRepo;

    final testTask = HabitTask(
      id: 'gym_task_1',
      title: 'Morning Gym Session',
      category: 'Health',
      type: 'gym_photo',
      weight: 3,
      createdAt: DateTime.now(),
    );

    final testProfile = UserProfile(
      uid: 'user_123',
      name: 'Naren Student',
      email: 'naren@example.com',
      accountabilityFriend: const AccountabilityFriend(
        name: 'Friend Bob',
        phoneE164: '+919876543210',
        upiVpa: 'bob@upi',
      ),
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockExcuseRepo = MockExcuseRepository();
      mockDayLogRepo = MockDayLogRepository();
      mockTaskRepo = MockTaskRepository();
    });

    tearDown(() {
      mockExcuseRepo.dispose();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          excuseRepositoryProvider.overrideWithValue(mockExcuseRepo),
          dayLogRepositoryProvider.overrideWithValue(mockDayLogRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(testProfile),
          ),
          currentUserIdProvider.overrideWithValue(testProfile.uid),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () => SubmitExcuseSheet.show(ctx, testTask),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('enters valid excuse, submits and sees confirmation with WhatsApp share', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Verify title and usage count
      expect(find.text('Submit Missed-Day Excuse'), findsOneWidget);
      expect(find.textContaining('Used this month'), findsOneWidget);

      // Verify button initially disabled (length < 10)
      final submitButton = find.byKey(const Key('submit_excuse_button'));
      final elevatedButtonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(elevatedButtonWidget.onPressed, isNull);

      // Enter valid reason note
      await tester.enterText(
        find.byKey(const Key('excuse_note_input')),
        'Suffering from acute migraine and need to rest today.',
      );
      await tester.pumpAndSettle();

      // Button is now enabled!
      final enabledButtonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(enabledButtonWidget.onPressed, isNotNull);

      // Tap Submit
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify confirmation screen & WhatsApp share button
      expect(find.text('Excuse Note Submitted!'), findsOneWidget);
      expect(find.byKey(const Key('send_excuse_whatsapp_button')), findsOneWidget);

      // Verify excuse in repository
      final excuses = await mockExcuseRepo.watchExcusesForDate('user_123', TodayTasksNotifier.todayDateString()).first;
      expect(excuses.length, 1);
      expect(excuses.first.status, 'pending');
      expect(excuses.first.note, contains('acute migraine'));
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
