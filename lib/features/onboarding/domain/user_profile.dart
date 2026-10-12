class AccountabilityFriend {
  final String name;
  final String phoneE164;
  final String upiVpa;
  final bool firstProofViewed;

  const AccountabilityFriend({
    required this.name,
    required this.phoneE164,
    required this.upiVpa,
    this.firstProofViewed = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phoneE164': phoneE164,
        'upiVpa': upiVpa,
        'firstProofViewed': firstProofViewed,
      };

  factory AccountabilityFriend.fromMap(Map<String, dynamic> map) {
    return AccountabilityFriend(
      name: map['name'] as String? ?? '',
      phoneE164: map['phoneE164'] as String? ?? '',
      upiVpa: map['upiVpa'] as String? ?? '',
      firstProofViewed: map['firstProofViewed'] as bool? ?? false,
    );
  }

  AccountabilityFriend copyWith({
    String? name,
    String? phoneE164,
    String? upiVpa,
    bool? firstProofViewed,
  }) {
    return AccountabilityFriend(
      name: name ?? this.name,
      phoneE164: phoneE164 ?? this.phoneE164,
      upiVpa: upiVpa ?? this.upiVpa,
      firstProofViewed: firstProofViewed ?? this.firstProofViewed,
    );
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? whatsappPhone;
  final AccountabilityFriend? accountabilityFriend;
  final int stepGoal;
  final int currentStreak;
  final int bestStreak;
  final int unresolvedPenaltiesCount;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.whatsappPhone,
    this.accountabilityFriend,
    this.stepGoal = 8000,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.unresolvedPenaltiesCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'whatsappPhone': whatsappPhone,
        'accountabilityFriend': accountabilityFriend?.toMap(),
        'stepGoal': stepGoal,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'unresolvedPenaltiesCount': unresolvedPenaltiesCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt != null && rawCreatedAt.toString().contains('Timestamp')) {
      parsedCreatedAt = DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      whatsappPhone: map['whatsappPhone'] as String?,
      accountabilityFriend: map['accountabilityFriend'] != null
          ? AccountabilityFriend.fromMap(
              Map<String, dynamic>.from(map['accountabilityFriend'] as Map),
            )
          : null,
      stepGoal: (map['stepGoal'] as num?)?.toInt() ?? 8000,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      unresolvedPenaltiesCount:
          (map['unresolvedPenaltiesCount'] as num?)?.toInt() ?? 0,
      createdAt: parsedCreatedAt,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? whatsappPhone,
    AccountabilityFriend? accountabilityFriend,
    int? stepGoal,
    int? currentStreak,
    int? bestStreak,
    int? unresolvedPenaltiesCount,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      accountabilityFriend: accountabilityFriend ?? this.accountabilityFriend,
      stepGoal: stepGoal ?? this.stepGoal,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      unresolvedPenaltiesCount:
          unresolvedPenaltiesCount ?? this.unresolvedPenaltiesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
