import 'package:isar/isar.dart';

part 'family_config_schema.g.dart';

/// Family Config Isar Schema
/// 
/// Stores family-wide settings and configuration locally.
/// Only syncs for family members.
@collection
class FamilyConfigSchema {
  Id id = Isar.autoIncrement;
  
  /// Unique family ID (Firestore document ID)
  @Index(unique: true)
  late String familyId;
  
  /// Family display name
  late String name;
  
  /// Family owner UID (primary parent)
  late String ownerUid;
  
  /// List of parent UIDs (JSON encoded)
  late String parentUidsJson;
  
  /// List of child UIDs (JSON encoded)
  late String childUidsJson;
  
  /// PIN hash for parental controls (bcrypt)
  String? pinHash;
  
  // ============ Time Ratio Settings ============
  
  /// Default study to leisure ratio (e.g., 1.0 = 1:1)
  late double globalRatio;
  
  /// Subject-specific ratios (JSON encoded map)
  late String subjectRatiosJson;
  
  /// Bonus multiplier for streaks
  late double streakBonusMultiplier;
  
  /// Minimum streak days to apply bonus
  late int streakBonusThreshold;
  
  /// Weekend ratio modifier
  late double weekendModifier;
  
  // ============ Screen Time Limits ============
  
  /// Daily leisure time limit in seconds (0 = unlimited)
  late int dailyLeisureLimit;
  
  /// Required study time before leisure in seconds
  late int studyBeforeLeisure;
  
  /// Bedtime start (HH:mm format)
  String? bedtimeStart;
  
  /// Bedtime end (HH:mm format)
  String? bedtimeEnd;
  
  /// Days bedtime is enforced (JSON encoded array of ints)
  late String bedtimeDaysJson;
  
  /// Break reminder interval in minutes
  late int breakReminderInterval;
  
  // ============ Family Settings ============
  
  /// Allow children to modify their own goals
  late bool allowChildGoalModification;
  
  /// Require approval for leisure time spending
  late bool requireSpendingApproval;
  
  /// Send parent notifications for milestones
  late bool notifyOnMilestones;
  
  /// Send daily summary notifications
  late bool dailySummaryEnabled;
  
  /// Daily summary time (HH:mm format)
  late String dailySummaryTime;
  
  // ============ Invite Settings ============
  
  /// Family invite code (for joining)
  String? inviteCode;
  
  /// Invite code expiration (milliseconds since epoch)
  int? inviteCodeExpiresAt;
  
  // ============ Timestamps ============
  
  /// Family creation timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Last update timestamp (milliseconds since epoch)
  late int updatedAt;
  
  /// Sync status with Firestore
  @enumerated
  late FamilySyncStatus syncStatus;
  
  /// Last sync timestamp
  int? lastSyncAt;
  
  /// Create default family configuration
  static FamilyConfigSchema createDefault({
    required String familyId,
    required String name,
    required String ownerUid,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return FamilyConfigSchema()
      ..familyId = familyId
      ..name = name
      ..ownerUid = ownerUid
      ..parentUidsJson = '["$ownerUid"]'
      ..childUidsJson = '[]'
      ..globalRatio = 1.0
      ..subjectRatiosJson = '{}'
      ..streakBonusMultiplier = 1.1
      ..streakBonusThreshold = 3
      ..weekendModifier = 1.0
      ..dailyLeisureLimit = 7200 // 2 hours
      ..studyBeforeLeisure = 1800 // 30 minutes
      ..bedtimeStart = '21:00'
      ..bedtimeEnd = '07:00'
      ..bedtimeDaysJson = '[0,1,2,3,4]' // Sunday-Thursday
      ..breakReminderInterval = 25 // Pomodoro default
      ..allowChildGoalModification = true
      ..requireSpendingApproval = false
      ..notifyOnMilestones = true
      ..dailySummaryEnabled = true
      ..dailySummaryTime = '20:00'
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = FamilySyncStatus.synced;
  }
  
  /// Check if user is family owner
  bool isOwner(String uid) => ownerUid == uid;
  
  /// Check if user is a parent in this family
  bool isParent(String uid) {
    return parentUidsJson.contains('"$uid"');
  }
  
  /// Check if invite code is valid
  bool get hasValidInviteCode {
    if (inviteCode == null || inviteCodeExpiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < inviteCodeExpiresAt!;
  }
  
  /// Get formatted daily leisure limit
  String get formattedDailyLeisureLimit {
    if (dailyLeisureLimit == 0) return 'Sin límite';
    final hours = dailyLeisureLimit ~/ 3600;
    final minutes = (dailyLeisureLimit % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }
}

/// Family sync status enum
enum FamilySyncStatus {
  synced,
  pendingUpload,
  pendingDownload,
  conflict,
  error,
}
