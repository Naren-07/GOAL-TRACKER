import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoadingState;
    final errorMessage = authState is AuthErrorState ? authState.message : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Logo Badge
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Title & Subtitle
                Text(
                  'GrowthStreak',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily weighted goals, peer verification, and real stakes for college students.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Feature Highlights
                _buildFeatureCard(
                  icon: Icons.fitness_center_rounded,
                  title: 'Gym & Step Tracking',
                  description: 'Live photo verification and built-in pedometer auto-sync.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Peer Accountability',
                  description: 'Your friend verifies workouts via lightweight WhatsApp web link.',
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Zero-Custody Stakes',
                  description: 'Missed workouts pay ₹10 directly to your friend via UPI deeplink.',
                ),
                const SizedBox(height: 36),

                // Error Banner
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.errorRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Google Sign In Button
                ElevatedButton(
                  key: const Key('google_sign_in_button'),
                  onPressed: isLoading
                      ? null
                      : () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // Terms Note
                Text(
                  'By signing in, you agree to student accountability terms and daily streak rules.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
