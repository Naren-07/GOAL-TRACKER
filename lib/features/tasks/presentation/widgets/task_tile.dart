import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/habit_task.dart';

class TaskTile extends StatelessWidget {
  final HabitTask task;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onSubmitExcuse;

  const TaskTile({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.onToggle,
    this.onDelete,
    this.onSubmitExcuse,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.fitness_center_rounded;
      case 'Academics':
        return Icons.menu_book_rounded;
      case 'Technical Skills':
        return Icons.code_rounded;
      default:
        return Icons.star_outline_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health':
        return AppColors.primary;
      case 'Academics':
        return AppColors.infoBlue;
      case 'Technical Skills':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.warningAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(task.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.borderLight,
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(task.category),
              color: catColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Title & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.titleLarge.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${task.weight} wt',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.category,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (onSubmitExcuse != null && !isCompleted)
            TextButton(
              key: Key('submit_reason_button_${task.id}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onSubmitExcuse,
              child: const Text('Submit Reason', style: TextStyle(fontSize: 12)),
            ),

          // Delete icon button if provided
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.textTertiary),
              onPressed: onDelete,
            ),

          // Instant Checkbox Toggle
          Transform.scale(
            scale: 1.15,
            child: Checkbox(
              key: Key('task_checkbox_${task.id}'),
              value: isCompleted,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (val) {
                if (val != null) onToggle(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
