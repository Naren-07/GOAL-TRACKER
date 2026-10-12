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
import 'features/tasks/domain/task_repository.dart';
import 'features/tasks/data/firestore_task_repository.dart';
import 'features/tasks/data/mock_task_repository.dart';
import 'features/tasks/domain/day_log_repository.dart';
import 'features/tasks/data/firestore_day_log_repository.dart';
import 'features/tasks/data/mock_day_log_repository.dart';
import 'features/tasks/presentation/today_tasks_notifier.dart';
import 'features/steps/domain/step_sensor_repository.dart';
import 'features/steps/data/hardware_step_sensor_repository.dart';
import 'features/steps/data/mock_step_sensor_repository.dart';
import 'features/steps/presentation/step_tracker_notifier.dart';

import 'features/proofs/domain/proof_repository.dart';
import 'features/proofs/domain/proof_storage_repository.dart';
import 'features/proofs/data/firestore_proof_repository.dart';
import 'features/proofs/data/firebase_storage_proof_repository.dart';
import 'features/proofs/data/mock_proof_repository.dart';
import 'features/proofs/data/mock_proof_storage_repository.dart';
import 'features/proofs/presentation/proof_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthRepository authRepository;
  late final UserProfileRepository userProfileRepository;
  late final TaskRepository taskRepository;
  late final DayLogRepository dayLogRepository;
  late final StepSensorRepository stepSensorRepository;
  late final ProofRepository proofRepository;
  late final ProofStorageRepository proofStorageRepository;

  try {
    await Firebase.initializeApp();
    authRepository = FirebaseAuthRepository();
    userProfileRepository = FirestoreUserProfileRepository();
    taskRepository = FirestoreTaskRepository();
    dayLogRepository = FirestoreDayLogRepository();
    proofRepository = FirestoreProofRepository();
    proofStorageRepository = FirebaseStorageProofRepository();
  } catch (e) {
    debugPrint(
        'Firebase not initialized or credentials missing ($e). Using local dev mock fallback.');
    authRepository = MockAuthRepository();
    userProfileRepository = MockUserProfileRepository();
    taskRepository = MockTaskRepository();
    dayLogRepository = MockDayLogRepository();
    proofRepository = MockProofRepository();
    proofStorageRepository = MockProofStorageRepository();
  }

  try {
    stepSensorRepository = HardwareStepSensorRepository();
  } catch (e) {
    debugPrint('Hardware pedometer unavailable ($e). Using mock step sensor.');
    stepSensorRepository = MockStepSensorRepository();
  }

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
        taskRepositoryProvider.overrideWithValue(taskRepository),
        dayLogRepositoryProvider.overrideWithValue(dayLogRepository),
        stepSensorRepositoryProvider.overrideWithValue(stepSensorRepository),
        proofRepositoryProvider.overrideWithValue(proofRepository),
        proofStorageRepositoryProvider.overrideWithValue(proofStorageRepository),
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
