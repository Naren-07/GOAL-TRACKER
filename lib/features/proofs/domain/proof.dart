class Proof {
  final String id;
  final String uid;
  final String taskId;
  final String date; // YYYY-MM-DD
  final String photoUrl;
  final String perceptualHash;
  final String status; // 'pending', 'approved', 'auto_approved', 'rejected'
  final String tokenNonce;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? friendPhone;
  final String? friendName;
  final String? friendVpa;

  const Proof({
    required this.id,
    required this.uid,
    required this.taskId,
    required this.date,
    required this.photoUrl,
    required this.perceptualHash,
    this.status = 'pending',
    required this.tokenNonce,
    required this.expiresAt,
    required this.createdAt,
    this.rejectionReason,
    this.friendPhone,
    this.friendName,
    this.friendVpa,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'auto_approved';
  bool get isRejected => status == 'rejected';

  Proof copyWith({
    String? id,
    String? uid,
    String? taskId,
    String? date,
    String? photoUrl,
    String? perceptualHash,
    String? status,
    String? tokenNonce,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? rejectionReason,
    String? friendPhone,
    String? friendName,
    String? friendVpa,
  }) {
    return Proof(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      photoUrl: photoUrl ?? this.photoUrl,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      status: status ?? this.status,
      tokenNonce: tokenNonce ?? this.tokenNonce,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      friendPhone: friendPhone ?? this.friendPhone,
      friendName: friendName ?? this.friendName,
      friendVpa: friendVpa ?? this.friendVpa,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'taskId': taskId,
      'date': date,
      'photoUrl': photoUrl,
      'perceptualHash': perceptualHash,
      'status': status,
      'tokenNonce': tokenNonce,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'rejectionReason': rejectionReason,
      'friendPhone': friendPhone,
      'friendName': friendName,
      'friendVpa': friendVpa,
    };
  }

  factory Proof.fromMap(Map<String, dynamic> map, String id) {
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

    return Proof(
      id: id,
      uid: map['uid'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      perceptualHash: map['perceptualHash'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      tokenNonce: map['tokenNonce'] as String? ?? '',
      expiresAt: parsedExpiresAt,
      createdAt: parsedCreatedAt,
      rejectionReason: map['rejectionReason'] as String?,
      friendPhone: map['friendPhone'] as String?,
      friendName: map['friendName'] as String?,
      friendVpa: map['friendVpa'] as String?,
    );
  }
}
