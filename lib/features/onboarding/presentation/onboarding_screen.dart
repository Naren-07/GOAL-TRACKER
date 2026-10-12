import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final AuthUser user;

  const OnboardingScreen({super.key, required this.user});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _stepGoalController;
  late final TextEditingController _friendNameController;
  late final TextEditingController _friendPhoneController;
  late final TextEditingController _friendUpiController;

  int _selectedStepGoal = 8000;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _stepGoalController = TextEditingController(text: '8000');
    _friendNameController = TextEditingController();
    _friendPhoneController = TextEditingController();
    _friendUpiController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stepGoalController.dispose();
    _friendNameController.dispose();
    _friendPhoneController.dispose();
    _friendUpiController.dispose();
    super.dispose();
  }

  void _onStepChipSelected(int goal) {
    setState(() {
      _selectedStepGoal = goal;
      _stepGoalController.text = goal.toString();
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final stepGoal = int.tryParse(_stepGoalController.text.trim()) ?? 8000;
      ref.read(authNotifierProvider.notifier).completeOnboarding(
            name: _nameController.text.trim(),
            stepGoal: stepGoal,
            friendName: _friendNameController.text.trim(),
            friendPhone: _friendPhoneController.text.trim(),
            friendUpi: _friendUpiController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoadingState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        actions: [
          TextButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authNotifierProvider.notifier).signOut(),
            child: Text(
              'Sign Out',
              style: AppTypography.labelMedium.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: widget.user.photoUrl != null
                            ? NetworkImage(widget.user.photoUrl!)
                            : null,
                        child: widget.user.photoUrl == null
                            ? const Icon(Icons.person_rounded,
                                color: Colors.white, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to GrowthStreak',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section 1: Student Profile
                Text(
                  '1. Student Information',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('name_input_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Section 2: Daily Step Goal
                Text(
                  '2. Daily Step Goal',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tracked automatically via device hardware sensors (1,000 – 50,000 steps).',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 14),

                // Quick selector chips
                Wrap(
                  spacing: 8,
                  children: [5000, 8000, 10000, 12000].map((goal) {
                    final isSelected = _selectedStepGoal == goal;
                    return ChoiceChip(
                      label: Text(
                        '$goal steps${goal == 8000 ? ' (Default)' : ''}',
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      showCheckmark: false,
                      onSelected: (_) => _onStepChipSelected(goal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('step_goal_input_field'),
                  controller: _stepGoalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Steps per Day *',
                    prefixIcon: Icon(Icons.directions_walk_rounded),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val.trim());
                    if (parsed != null) {
                      setState(() => _selectedStepGoal = parsed);
                    }
                  },
                  validator: (val) {
                    final parsed = int.tryParse(val?.trim() ?? '');
                    if (parsed == null || parsed < 1000 || parsed > 50000) {
                      return 'Step goal must be between 1,000 and 50,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Section 3: Accountability Friend
                Text(
                  '3. Accountability Friend (Optional for now)',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your friend reviews your gym check-ins via WhatsApp web link and receives ₹10 if missed.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('friend_name_input_field'),
                  controller: _friendNameController,
                  decoration: const InputDecoration(
                    labelText: "Friend's Name",
                    hintText: 'e.g. Samir Sharma',
                    prefixIcon: Icon(Icons.handshake_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('friend_phone_input_field'),
                  controller: _friendPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Friend's WhatsApp Number",
                    hintText: '+919876543210',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('friend_upi_input_field'),
                  controller: _friendUpiController,
                  decoration: const InputDecoration(
                    labelText: "Friend's UPI VPA",
                    hintText: 'e.g. samir@okaxis',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                ElevatedButton(
                  key: const Key('complete_onboarding_button'),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Complete Profile & Start Streak',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
