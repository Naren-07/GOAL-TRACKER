import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../proofs/domain/whatsapp_share_service.dart';
import '../../tasks/domain/habit_task.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import 'excuse_notifier.dart';

class SubmitExcuseSheet extends ConsumerStatefulWidget {
  final HabitTask task;

  const SubmitExcuseSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, HabitTask task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SubmitExcuseSheet(task: task),
    );
  }

  @override
  ConsumerState<SubmitExcuseSheet> createState() => _SubmitExcuseSheetState();
}

class _SubmitExcuseSheetState extends ConsumerState<SubmitExcuseSheet> {
  final _controller = TextEditingController();
  String _selectedCategory = 'Illness';
  final List<String> _categories = ['Illness', 'Travel', 'Exams', 'Emergency', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthenticatedState) {
        final now = DateTime.now();
        final monthKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
        ref.read(excuseNotifierProvider.notifier).checkMonthlyUsage(auth.profile.uid, monthKey);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(excuseNotifierProvider);
    final auth = ref.watch(authNotifierProvider);
    final profile = auth is AuthenticatedState ? auth.profile : null;
    final friend = profile?.accountabilityFriend;
    final emerald = Theme.of(context).colorScheme.primary;
    final textLength = _controller.text.trim().length;
    final isLengthValid = textLength >= 10 && textLength <= 300;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: state.isSubmitted && state.submittedExcuse != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                const SizedBox(height: 14),
                Text(
                  'Excuse Note Submitted!',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${friend?.name ?? "Accountability Friend"}. If accepted, your daily weight is adjusted and streak is preserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('send_excuse_whatsapp_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Send via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final excuse = state.submittedExcuse!;
                    final service = WhatsAppShareService();
                    await service.launchWhatsApp(
                      phone: friend?.phoneE164 ?? '',
                      friendName: friend?.name ?? 'Friend',
                      studentName: profile?.name ?? 'Student',
                      streak: profile?.currentStreak ?? 0,
                      date: excuse.date,
                      proofId: excuse.id,
                      tokenNonce: excuse.tokenNonce,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Submit Missed-Day Excuse',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.monthlyUsedCount} / 3 Used this month',
                        style: TextStyle(
                          color: emerald,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cannot attend gym? Submit an excuse before 11:59 PM. Max 3 accepted excuses per calendar month.',
                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Category Chips
                Wrap(
                  spacing: 8,
                  children: _categories.map((c) {
                    final selected = _selectedCategory == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      selectedColor: emerald.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _selectedCategory = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Note TextField
                TextField(
                  key: const Key('excuse_note_input'),
                  controller: _controller,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter reason (10 to 300 characters)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: '$textLength / 300 characters (minimum 10)',
                    helperStyle: TextStyle(
                      color: isLengthValid ? Colors.grey.shade600 : Colors.red.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (state.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('submit_excuse_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (!isLengthValid || state.isLoading)
                        ? null
                        : () async {
                            final uid = profile?.uid ?? 'guest';
                            final today = TodayTasksNotifier.todayDateString();
                            await ref.read(excuseNotifierProvider.notifier).submitExcuse(
                                  uid: uid,
                                  taskId: widget.task.id,
                                  date: today,
                                  category: _selectedCategory,
                                  note: _controller.text,
                                  friend: friend,
                                );
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Excuse Note', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}
