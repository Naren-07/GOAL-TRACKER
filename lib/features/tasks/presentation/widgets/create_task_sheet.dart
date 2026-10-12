import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class CreateTaskSheet extends StatefulWidget {
  final Function({
    required String title,
    required String category,
    required int weight,
    required List<int> repeatDays,
  }) onSave;

  const CreateTaskSheet({super.key, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String title,
      required String category,
      required int weight,
      required List<int> repeatDays,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskSheet(onSave: onSave),
    );
  }

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String _category = 'Health';
  int _weight = 1;
  String _schedule = 'daily'; // 'daily' or 'weekdays'

  final _categories = ['Health', 'Academics', 'Technical Skills', 'Custom'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final repeatDays = _schedule == 'daily'
          ? const [1, 2, 3, 4, 5, 6, 7]
          : const [1, 2, 3, 4, 5];

      widget.onSave(
        title: _titleController.text.trim(),
        category: _category,
        weight: _weight,
        repeatDays: repeatDays,
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text('Create Daily Task', style: AppTypography.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Define a recurring habit with category and weight.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                key: const Key('task_title_input'),
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. DSA Practice, 5km Run, Study Math',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              Text('Category', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceMuted,
                    labelStyle: AppTypography.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Weight (1 - 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Task Weight', style: AppTypography.labelLarge),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_weight wt',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Higher weight tasks carry more value towards your daily 70% threshold.',
                style: AppTypography.bodySmall,
              ),
              Slider(
                value: _weight.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.borderLight,
                onChanged: (val) => setState(() => _weight = val.round()),
              ),
              const SizedBox(height: 12),

              // Schedule
              Text('Repeat Schedule', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Every Day')),
                      selected: _schedule == 'daily',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceMuted,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: _schedule == 'daily'
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _schedule = 'daily'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Weekdays (Mon-Fri)')),
                      selected: _schedule == 'weekdays',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceMuted,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: _schedule == 'weekdays'
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _schedule = 'weekdays'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                key: const Key('save_task_button'),
                onPressed: _submit,
                child: const Text('Save Daily Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
