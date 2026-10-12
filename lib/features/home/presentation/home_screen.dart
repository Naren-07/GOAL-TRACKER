import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../onboarding/domain/user_profile.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import '../../tasks/presentation/widgets/create_task_sheet.dart';
import '../../tasks/presentation/widgets/task_tile.dart';
import '../../steps/presentation/widgets/step_counter_card.dart';
import 'widgets/hero_completion_ring_card.dart';

import '../../profile/presentation/profile_screen.dart';
import '../../proofs/presentation/camera_proof_screen.dart';

class HomeScreen extends ConsumerWidget {
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayState = ref.watch(todayTasksNotifierProvider);
    final friend = profile.accountabilityFriend;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('GrowthStreak', style: AppTypography.headlineMedium),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('profile_icon_button'),
            tooltip: 'Accountability Profile',
            icon: const Icon(Icons.manage_accounts_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('sign_out_icon_button'),
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_task_fab'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
        onPressed: () {
          CreateTaskSheet.show(
            context,
            onSave: ({
              required String title,
              required String category,
              required int weight,
              required List<int> repeatDays,
            }) {
              ref.read(todayTasksNotifierProvider.notifier).createTask(
                    title: title,
                    category: category,
                    weight: weight,
                    repeatDays: repeatDays,
                  );
            },
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: profile.photoUrl != null
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : 'S',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.streakOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.currentStreak}d',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Hero Circular Ring Card
              HeroCompletionRingCard(
                completionPercent: todayState.completionPercent,
                completedWeight: todayState.completedWeight,
                totalWeight: todayState.totalWeight,
                currentStreak: profile.currentStreak,
              ),
              const SizedBox(height: 24),

              // Today's Tasks Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Tasks", style: AppTypography.headlineMedium),
                  TextButton.icon(
                    key: const Key('add_task_header_button'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Task'),
                    onPressed: () {
                      CreateTaskSheet.show(
                        context,
                        onSave: ({
                          required String title,
                          required String category,
                          required int weight,
                          required List<int> repeatDays,
                        }) {
                          ref.read(todayTasksNotifierProvider.notifier).createTask(
                                title: title,
                                category: category,
                                weight: weight,
                                repeatDays: repeatDays,
                              );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tasks List or Empty State
              if (todayState.tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.checklist_rounded,
                            size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No tasks scheduled for today',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add Task" to create your first weighted daily habit.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...todayState.tasks.map((task) {
                  final isDone = todayState.isTaskCompleted(task.id);
                  return TaskTile(
                    key: Key('task_tile_${task.id}'),
                    task: task,
                    isCompleted: isDone,
                    onToggle: (_) {
                      if (task.type == 'gym_photo') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CameraProofScreen(task: task),
                          ),
                        );
                      } else {
                        ref
                            .read(todayTasksNotifierProvider.notifier)
                            .toggleTask(task.id);
                      }
                    },
                    onDelete: () {
                      ref
                          .read(todayTasksNotifierProvider.notifier)
                          .deleteTask(task.id);
                    },
                  );
                }),
              const SizedBox(height: 24),

              // Discipline Metrics Section
              Text('Discipline Metrics', style: AppTypography.headlineMedium),
              const SizedBox(height: 12),

              const StepCounterCard(),
              const SizedBox(height: 12),

              InkWell(
                key: const Key('accountability_friend_card_button'),
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: _buildMetricCard(
                  icon: Icons.handshake_rounded,
                  iconColor: AppColors.infoBlue,
                  title: 'Accountability Friend',
                  value: friend != null && friend.name.isNotEmpty
                      ? friend.name
                      : 'Not configured yet',
                  subtitle: friend != null && friend.upiVpa.isNotEmpty
                      ? 'UPI: ${friend.upiVpa} • WhatsApp: ${friend.phoneE164} (Tap to edit)'
                      : 'Link a friend to enable gym live photo reviews and UPI stakes (Tap to edit).',
                ),
              ),
              const SizedBox(height: 12),

              _buildMetricCard(
                icon: Icons.currency_rupee_rounded,
                iconColor: profile.unresolvedPenaltiesCount > 0
                    ? AppColors.errorRed
                    : AppColors.successGreen,
                title: 'Unpaid Dues Ledger',
                value: '₹${profile.unresolvedPenaltiesCount * 10}',
                subtitle: profile.unresolvedPenaltiesCount == 0
                    ? 'No outstanding penalties. Streaks active!'
                    : '${profile.unresolvedPenaltiesCount} missed task(s) awaiting UPI settlement.',
              ),
              const SizedBox(height: 32),

              OutlinedButton.icon(
                key: const Key('sign_out_button'),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out'),
              ),
              const SizedBox(height: 48), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.headlineMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
