enum UserRole {
  parent,
  child,
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? linkedParentId;
  final List<String>? linkedChildrenIds;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.linkedParentId,
    this.linkedChildrenIds,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String,
      name: map['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
      ),
      linkedParentId: map['linkedParentId'] as String?,
      linkedChildrenIds: map['linkedChildrenIds'] != null
          ? List<String>.from(map['linkedChildrenIds'] as List)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'linkedParentId': linkedParentId,
      'linkedChildrenIds': linkedChildrenIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
