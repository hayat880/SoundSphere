/// Model: the local account stored on this device (no server involved).
class UserProfile {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  UserProfile copyWith({String? name}) => UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
      );

  factory UserProfile.fromMap(Map<String, Object?> m) => UserProfile(
        id: m['id'] as int,
        name: m['name'] as String,
        email: m['email'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}
