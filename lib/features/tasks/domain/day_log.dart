class TaskOutcome {
  final String status; // "pending" | "completed" | "excused" | "missed"
  final String? proofId;
  final String? excuseId;
  final String? penaltyId;

  const TaskOutcome({
    this.status = 'pending',
    this.proofId,
    this.excuseId,
    this.penaltyId,
  });

  bool get isCompleted => status == 'completed';
  bool get isExcused => status == 'excused';
  bool get isMissed => status == 'missed';
  bool get isPending => status == 'pending';

  Map<String, dynamic> toMap() => {
        'status': status,
        if (proofId != null) 'proofId': proofId,
        if (excuseId != null) 'excuseId': excuseId,
        if (penaltyId != null) 'penaltyId': penaltyId,
      };

  factory TaskOutcome.fromMap(Map<String, dynamic> map) {
    return TaskOutcome(
      status: map['status'] as String? ?? 'pending',
      proofId: map['proofId'] as String?,
      excuseId: map['excuseId'] as String?,
      penaltyId: map['penaltyId'] as String?,
    );
  }

  TaskOutcome copyWith({
    String? status,
    String? proofId,
    String? excuseId,
    String? penaltyId,
  }) {
    return TaskOutcome(
      status: status ?? this.status,
      proofId: proofId ?? this.proofId,
      excuseId: excuseId ?? this.excuseId,
      penaltyId: penaltyId ?? this.penaltyId,
    );
  }
}

class DayLog {
  final String date; // YYYY-MM-DD
  final int totalWeight;
  final int completedWeight;
  final int completionPercent; // 0 to 100
  final Map<String, TaskOutcome> taskOutcomes;
  final bool finalized;
  final DateTime? finalizedAt;

  const DayLog({
    required this.date,
    this.totalWeight = 0,
    this.completedWeight = 0,
    this.completionPercent = 0,
    this.taskOutcomes = const {},
    this.finalized = false,
    this.finalizedAt,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'totalWeight': totalWeight,
        'completedWeight': completedWeight,
        'completionPercent': completionPercent,
        'taskOutcomes': taskOutcomes.map((k, v) => MapEntry(k, v.toMap())),
        'finalized': finalized,
        if (finalizedAt != null) 'finalizedAt': finalizedAt!.toIso8601String(),
      };

  factory DayLog.fromMap(Map<String, dynamic> map, String date) {
    final rawOutcomes = map['taskOutcomes'];
    final outcomes = <String, TaskOutcome>{};
    if (rawOutcomes is Map) {
      rawOutcomes.forEach((key, val) {
        if (val is Map) {
          outcomes[key.toString()] = TaskOutcome.fromMap(
            Map<String, dynamic>.from(val),
          );
        }
      });
    }

    DateTime? parsedFinalizedAt;
    final rawFinalizedAt = map['finalizedAt'];
    if (rawFinalizedAt is String) {
      parsedFinalizedAt = DateTime.tryParse(rawFinalizedAt);
    }

    return DayLog(
      date: date,
      totalWeight: (map['totalWeight'] as num?)?.toInt() ?? 0,
      completedWeight: (map['completedWeight'] as num?)?.toInt() ?? 0,
      completionPercent: (map['completionPercent'] as num?)?.toInt() ?? 0,
      taskOutcomes: outcomes,
      finalized: map['finalized'] as bool? ?? false,
      finalizedAt: parsedFinalizedAt,
    );
  }

  DayLog copyWith({
    String? date,
    int? totalWeight,
    int? completedWeight,
    int? completionPercent,
    Map<String, TaskOutcome>? taskOutcomes,
    bool? finalized,
    DateTime? finalizedAt,
  }) {
    return DayLog(
      date: date ?? this.date,
      totalWeight: totalWeight ?? this.totalWeight,
      completedWeight: completedWeight ?? this.completedWeight,
      completionPercent: completionPercent ?? this.completionPercent,
      taskOutcomes: taskOutcomes ?? this.taskOutcomes,
      finalized: finalized ?? this.finalized,
      finalizedAt: finalizedAt ?? this.finalizedAt,
    );
  }
}
