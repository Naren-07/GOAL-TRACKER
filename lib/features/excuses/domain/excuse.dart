class Excuse {
  final String id;
  final String uid;
  final String taskId;
  final String date; // YYYY-MM-DD
  final String monthKey; // YYYY-MM
  final String category; // 'Illness', 'Travel', 'Exams', 'Emergency', 'Other'
  final String note; // 10 to 300 characters
  final String status; // 'pending', 'accepted', 'declined', 'missed'
  final String tokenNonce;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? friendName;
  final String? friendPhone;

  const Excuse({
    required this.id,
    required this.uid,
    required this.taskId,
    required this.date,
    required this.monthKey,
    required this.category,
    required this.note,
    this.status = 'pending',
    required this.tokenNonce,
    required this.expiresAt,
    required this.createdAt,
    this.friendName,
    this.friendPhone,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isMissed => status == 'missed';

  Excuse copyWith({
    String? id,
    String? uid,
    String? taskId,
    String? date,
    String? monthKey,
    String? category,
    String? note,
    String? status,
    String? tokenNonce,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? friendName,
    String? friendPhone,
  }) {
    return Excuse(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      monthKey: monthKey ?? this.monthKey,
      category: category ?? this.category,
      note: note ?? this.note,
      status: status ?? this.status,
      tokenNonce: tokenNonce ?? this.tokenNonce,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      friendName: friendName ?? this.friendName,
      friendPhone: friendPhone ?? this.friendPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'taskId': taskId,
      'date': date,
      'monthKey': monthKey,
      'category': category,
      'note': note,
      'status': status,
      'tokenNonce': tokenNonce,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'friendName': friendName,
      'friendPhone': friendPhone,
    };
  }

  factory Excuse.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedExpiresAt;
    final rawExpires = map['expiresAt'];
    if (rawExpires is String) {
      parsedExpiresAt = DateTime.tryParse(rawExpires) ?? DateTime.now();
    } else {
      parsedExpiresAt = DateTime.now();
    }

    DateTime parsedCreatedAt;
    final rawCreated = map['createdAt'];
    if (rawCreated is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Excuse(
      id: id,
      uid: map['uid'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      monthKey: map['monthKey'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      note: map['note'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      tokenNonce: map['tokenNonce'] as String? ?? '',
      expiresAt: parsedExpiresAt,
      createdAt: parsedCreatedAt,
      friendName: map['friendName'] as String?,
      friendPhone: map['friendPhone'] as String?,
    );
  }
}
