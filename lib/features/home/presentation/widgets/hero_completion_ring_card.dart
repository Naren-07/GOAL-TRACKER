import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HeroCompletionRingCard extends StatelessWidget {
  final int completionPercent;
  final int completedWeight;
  final int totalWeight;
  final int currentStreak;

  const HeroCompletionRingCard({
    super.key,
    required this.completionPercent,
    required this.completedWeight,
    required this.totalWeight,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isStreakSafe = completionPercent >= 70;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isStreakSafe
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: isStreakSafe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isStreakSafe
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Hero Ring
          SizedBox(
            width: 104,
            height: 104,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.0,
                end: completionPercent / 100.0,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(104, 104),
                      painter: _HeroRingPainter(
                        progress: value,
                        isSafe: isStreakSafe,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(value * 100).round()}%',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isStreakSafe
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$completedWeight/$totalWeight wt',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),

          // Details & Streak Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.streakOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.streakOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentStreak day streak',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.streakOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isStreakSafe
                      ? 'Streak Secured!'
                      : (totalWeight == 0
                          ? 'No tasks scheduled'
                          : '${70 - completionPercent}% to hold streak'),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isStreakSafe ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalWeight == 0
                      ? 'Add daily tasks below to begin tracking.'
                      : (isStreakSafe
                          ? 'Great discipline! Complete all tasks for 100% score.'
                          : 'Daily cutoff requires ≥70% weighted completion to keep streak.'),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRingPainter extends CustomPainter {
  final double progress;
  final bool isSafe;

  const _HeroRingPainter({required this.progress, required this.isSafe});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track background
    final backgroundPaint = Paint()
      ..color = AppColors.surfaceMuted
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      final progressPaint = Paint()
        ..color = isSafe ? AppColors.primary : AppColors.primaryLight
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isSafe != isSafe;
  }
}
