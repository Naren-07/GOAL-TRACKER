import '../../excuses/domain/excuse.dart';
import '../../proofs/domain/proof.dart';
import 'day_log.dart';
import 'habit_task.dart';

class FinalizationResult {
  final DayLog finalDayLog;
  final Map<String, String> updatedProofStatuses;
  final Map<String, String> updatedExcuseStatuses;
  final int penaltiesOwed;

  const FinalizationResult({
    required this.finalDayLog,
    required this.updatedProofStatuses,
    required this.updatedExcuseStatuses,
    required this.penaltiesOwed,
  });
}

class DayFinalizerService {
  /// Resolves day log outcomes past the 10:00 AM grace cutoff using Asymmetric Resolution
  FinalizationResult resolvePastGraceDeadline({
    required String date,
    required List<HabitTask> scheduledTasks,
    required DayLog dayLog,
    required List<Proof> proofs,
    required List<Excuse> excuses,
  }) {
    final updatedOutcomes = Map<String, TaskOutcome>.from(dayLog.taskOutcomes);
    final updatedProofStatuses = <String, String>{};
    final updatedExcuseStatuses = <String, String>{};
    int penaltiesOwed = 0;

    for (final task in scheduledTasks) {
      final currentOutcome =
          updatedOutcomes[task.id] ?? const TaskOutcome(status: 'pending');

      // 1. If already completed, nothing to change
      if (currentOutcome.isCompleted) {
        continue;
      }

      // 2. If already excused by friend, streak is preserved and no penalty
      if (currentOutcome.isExcused) {
        continue;
      }

      // 3. Find matching proofs or excuses for this task
      final matchingProof = proofs.cast<Proof?>().firstWhere(
            (p) => p?.taskId == task.id,
            orElse: () => null,
          );
      final matchingExcuse = excuses.cast<Excuse?>().firstWhere(
            (e) => e?.taskId == task.id,
            orElse: () => null,
          );

      // Asymmetric Resolution Rules:
      if (matchingProof != null && matchingProof.isPending) {
        // Unreviewed photo proof auto-approves past 10 AM grace without penalty
        updatedProofStatuses[matchingProof.id] = 'auto_approved';
        updatedOutcomes[task.id] = TaskOutcome(
          status: 'completed',
          proofId: matchingProof.id,
        );
      } else if (matchingExcuse != null && matchingExcuse.isPending) {
        // Pending excuse unreviewed by 10 AM finalizes as missed with ₹10 penalty
        updatedExcuseStatuses[matchingExcuse.id] = 'missed';
        updatedOutcomes[task.id] = TaskOutcome(
          status: 'missed',
          excuseId: matchingExcuse.id,
        );
        penaltiesOwed += 10;
      } else if (matchingExcuse != null && matchingExcuse.isDeclined) {
        // Declined excuse finalizes as missed with ₹10 penalty
        updatedOutcomes[task.id] = TaskOutcome(
          status: 'missed',
          excuseId: matchingExcuse.id,
        );
        penaltiesOwed += 10;
      } else {
        // Neither photo nor accepted excuse was submitted -> marked missed with ₹10 penalty
        updatedOutcomes[task.id] = const TaskOutcome(
          status: 'missed',
        );
        penaltiesOwed += 10;
      }
    }

    // Recalculate weights
    var totalWeight = 0;
    var completedWeight = 0;
    for (final task in scheduledTasks) {
      final outcome = updatedOutcomes[task.id]!;
      if (!outcome.isExcused) {
        totalWeight += task.weight;
      }
      if (outcome.isCompleted) {
        completedWeight += task.weight;
      }
    }

    final percent = totalWeight == 0
        ? 0
        : ((completedWeight / totalWeight) * 100).round().clamp(0, 100);

    final finalDayLog = dayLog.copyWith(
      taskOutcomes: updatedOutcomes,
      totalWeight: totalWeight,
      completedWeight: completedWeight,
      completionPercent: percent,
    );

    return FinalizationResult(
      finalDayLog: finalDayLog,
      updatedProofStatuses: updatedProofStatuses,
      updatedExcuseStatuses: updatedExcuseStatuses,
      penaltiesOwed: penaltiesOwed,
    );
  }
}
