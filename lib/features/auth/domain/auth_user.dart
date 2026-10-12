class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      uid.hashCode ^ email.hashCode ^ (displayName?.hashCode ?? 0) ^ (photoUrl?.hashCode ?? 0);

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, displayName: $displayName, photoUrl: $photoUrl)';
}
