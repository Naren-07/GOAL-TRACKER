import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/mock_auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/onboarding/domain/user_profile_repository.dart';
import 'features/onboarding/data/firestore_user_profile_repository.dart';
import 'features/onboarding/data/mock_user_profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthRepository authRepository;
  late final UserProfileRepository userProfileRepository;

  try {
    await Firebase.initializeApp();
    authRepository = FirebaseAuthRepository();
    userProfileRepository = FirestoreUserProfileRepository();
  } catch (e) {
    debugPrint('Firebase not initialized or credentials missing ($e). Using local dev mock fallback.');
    authRepository = MockAuthRepository();
    userProfileRepository = MockUserProfileRepository();
  }

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      ],
      child: const GrowthStreakApp(),
    ),
  );
}

class GrowthStreakApp extends ConsumerWidget {
  const GrowthStreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GrowthStreak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
