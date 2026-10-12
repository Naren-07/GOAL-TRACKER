class HabitTask {
  final String id;
  final String title;
  final String category; // "Health", "Academics", "Technical Skills", "Custom"
  final String type; // "standard", "gym_photo", "steps_auto"
  final int weight; // 1 to 10, default 1
  final int penaltyAmount; // default 10
  final List<int> repeatDays; // 1=Monday ... 7=Sunday
  final String? reminderTime; // e.g. "18:00"
  final bool active;
  final DateTime createdAt;

  const HabitTask({
    required this.id,
    required this.title,
    required this.category,
    this.type = 'standard',
    this.weight = 1,
    this.penaltyAmount = 10,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime,
    this.active = true,
    required this.createdAt,
  });

  bool isScheduledForWeekday(int weekday) {
    return repeatDays.contains(weekday);
  }

  HabitTask copyWith({
    String? id,
    String? title,
    String? category,
    String? type,
    int? weight,
    int? penaltyAmount,
    List<int>? repeatDays,
    String? reminderTime,
    bool? active,
    DateTime? createdAt,
  }) {
    return HabitTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderTime: reminderTime ?? this.reminderTime,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type,
      'weight': weight,
      'penaltyAmount': penaltyAmount,
      'repeatDays': repeatDays,
      'reminderTime': reminderTime,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitTask.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final rawRepeat = map['repeatDays'];
    List<int> parsedRepeat = const [1, 2, 3, 4, 5, 6, 7];
    if (rawRepeat is List) {
      parsedRepeat = rawRepeat.map((e) => (e as num).toInt()).toList();
    }

    return HabitTask(
      id: id,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Custom',
      type: map['type'] as String? ?? 'standard',
      weight: (map['weight'] as num?)?.toInt() ?? 1,
      penaltyAmount: (map['penaltyAmount'] as num?)?.toInt() ?? 10,
      repeatDays: parsedRepeat,
      reminderTime: map['reminderTime'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
