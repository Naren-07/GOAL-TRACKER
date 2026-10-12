import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../onboarding/domain/user_profile.dart';

class HomeScreen extends ConsumerWidget {
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            key: const Key('sign_out_icon_button'),
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Foundation Spike Success Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Foundation Active',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Emerald theme, Google Auth spike, and Firestore persistence established.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily Targets & Settings Cards
              Text('Discipline Metrics', style: AppTypography.headlineMedium),
              const SizedBox(height: 12),

              // Step Goal Card
              _buildMetricCard(
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.primary,
                title: 'Daily Step Goal',
                value: '${profile.stepGoal.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )} steps',
                subtitle: 'Tracked automatically via on-device pedometer sensor.',
              ),
              const SizedBox(height: 12),

              // Accountability Friend Card
              _buildMetricCard(
                icon: Icons.handshake_rounded,
                iconColor: AppColors.infoBlue,
                title: 'Accountability Friend',
                value: friend != null && friend.name.isNotEmpty
                    ? friend.name
                    : 'Not configured yet',
                subtitle: friend != null && friend.upiVpa.isNotEmpty
                    ? 'UPI: ${friend.upiVpa} • WhatsApp: ${friend.phoneE164}'
                    : 'Link a friend to enable gym live photo reviews and UPI stakes.',
              ),
              const SizedBox(height: 12),

              // Dues & Penalties Card
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

              // Sign Out Outlined Button
              OutlinedButton.icon(
                key: const Key('sign_out_button'),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out'),
              ),
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
