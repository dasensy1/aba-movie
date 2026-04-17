class SavedAccount {
  final int userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime loggedOutAt;

  const SavedAccount({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.loggedOutAt,
  });

  factory SavedAccount.fromMap(Map<String, dynamic> map) {
    return SavedAccount(
      userId: map['user_id'] as int,
      email: (map['email'] ?? '') as String,
      displayName: map['display_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      loggedOutAt: DateTime.tryParse((map['logged_out_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
