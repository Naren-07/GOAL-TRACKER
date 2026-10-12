import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../step_tracker_notifier.dart';

class StepCounterCard extends ConsumerWidget {
  const StepCounterCard({super.key});

  void _showPermissionExplanation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_walk_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Step Counter Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GrowthStreak tracks your daily walking steps directly using your phone\'s low-power hardware pedometer sensor.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Zero GPS or location tracking\n• Near-zero battery consumption\n• Automatically completes your daily step task when you hit your target goal',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(stepTrackerNotifierProvider.notifier)
                  .requestPermission();
            },
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(stepTrackerNotifierProvider);
    final progress = stepState.progress;
    final isDone = stepState.isGoalReached;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.successGreen : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.directions_walk_rounded,
                  color: isDone ? AppColors.successGreen : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hardware Step Counter',
                        style: AppTypography.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${stepState.todaySteps.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )} / ${stepState.stepGoal.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )} steps',
                      style: AppTypography.headlineMedium,
                    ),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Goal Met!',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.successGreen : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% of target',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppColors.successGreen : AppColors.textPrimary,
                ),
              ),
              if (!stepState.isPermissionGranted)
                InkWell(
                  key: const Key('request_permission_button'),
                  onTap: () => _showPermissionExplanation(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.warningAmber),
                      const SizedBox(width: 4),
                      Text(
                        'Enable Sensor Access',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warningAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Sensor Active • Auto-Syncing',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
