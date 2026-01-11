import 'package:isar/isar.dart';

part 'user_profile_schema.g.dart';

/// User Profile Isar Schema
/// 
/// Stores user profile information locally for offline access.
/// Syncs with Firestore UserProfile collection.
@collection
class UserProfileSchema {
  Id id = Isar.autoIncrement;
  
  /// Firebase Auth UID
  @Index(unique: true)
  late String uid;
  
  /// Display name
  late String displayName;
  
  /// Email address
  late String email;
  
  /// Profile photo URL
  String? photoUrl;
  
  /// User's role in their family
  @enumerated
  late FamilyRole role;
  
  /// Family ID the user belongs to
  String? familyId;
  
  /// FCM token for push notifications
  String? fcmToken;
  
  /// User's timezone
  late String timezone;
  
  /// Preferred language
  late String language;
  
  /// Date of birth (milliseconds since epoch)
  int? dateOfBirth;
  
  /// Account status
  @enumerated
  late AccountStatus status;
  
  /// Account creation timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Last update timestamp (milliseconds since epoch)
  late int updatedAt;
  
  /// Last login timestamp (milliseconds since epoch)
  int? lastLoginAt;
  
  /// Sync status with Firestore
  @enumerated
  late SyncStatus syncStatus;
  
  /// Last sync timestamp
  int? lastSyncAt;
  
  /// Create default user profile
  static UserProfileSchema createDefault({
    required String uid,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return UserProfileSchema()
      ..uid = uid
      ..email = email
      ..displayName = displayName ?? email.split('@').first
      ..role = FamilyRole.child
      ..timezone = 'America/Argentina/Buenos_Aires'
      ..language = 'es'
      ..status = AccountStatus.active
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SyncStatus.synced;
  }
  
  /// Check if user is a parent
  bool get isParent => role == FamilyRole.parent;
  
  /// Check if user is a child
  bool get isChild => role == FamilyRole.child;
  
  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.fromMillisecondsSinceEpoch(dateOfBirth!);
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }
}

/// Family roles enum
enum FamilyRole {
  parent,
  child,
  observer,
}

/// Account status enum
enum AccountStatus {
  active,
  suspended,
  pending,
}

/// Sync status enum (shared across schemas)
enum SyncStatus {
  synced,
  pendingUpload,
  pendingDownload,
  conflict,
  error,
}
