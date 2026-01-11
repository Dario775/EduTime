import 'package:isar/isar.dart';

part 'study_session_schema.g.dart';

/// Study Session Isar Schema
/// 
/// Records individual study periods locally.
/// Syncs with Firestore for cross-device access.
@collection
class StudySessionSchema {
  Id id = Isar.autoIncrement;
  
  /// Firebase document ID (for sync)
  @Index()
  String? firestoreId;
  
  /// User ID
  @Index()
  late String odexUserId;
  
  /// Subject being studied
  @Index()
  String? subjectId;
  
  /// Subject name (denormalized for quick access)
  String? subjectName;
  
  /// Session type
  @enumerated
  late SessionType type;
  
  /// Session status
  @enumerated
  late SessionStatus status;
  
  /// Planned duration in seconds
  late int plannedDuration;
  
  /// Actual duration in seconds
  late int actualDuration;
  
  /// Time earned in seconds (after ratio applied)
  late int earnedTime;
  
  /// Start timestamp (milliseconds since epoch)
  @Index()
  late int startedAt;
  
  /// End timestamp (milliseconds since epoch, null if active)
  int? endedAt;
  
  /// Pause periods (JSON encoded array)
  late String pausePeriodsJson;
  
  /// Total pause time in seconds
  late int totalPauseTime;
  
  /// Notes about the session
  String? notes;
  
  /// Rating (1-5)
  int? rating;
  
  /// Was the goal met?
  late bool goalMet;
  
  /// Creation timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Last update timestamp (milliseconds since epoch)
  late int updatedAt;
  
  /// Sync status with Firestore
  @enumerated
  late SessionSyncStatus syncStatus;
  
  /// Last sync timestamp
  int? lastSyncAt;
  
  /// Create a new study session
  static StudySessionSchema create({
    required String odexUserId,
    required SessionType type,
    required int plannedDuration,
    String? subjectId,
    String? subjectName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return StudySessionSchema()
      ..odexUserId = odexUserId
      ..subjectId = subjectId
      ..subjectName = subjectName
      ..type = type
      ..status = SessionStatus.active
      ..plannedDuration = plannedDuration
      ..actualDuration = 0
      ..earnedTime = 0
      ..startedAt = now
      ..pausePeriodsJson = '[]'
      ..totalPauseTime = 0
      ..goalMet = false
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SessionSyncStatus.pendingUpload;
  }
  
  /// Check if session is currently active
  bool get isActive => status == SessionStatus.active;
  
  /// Check if session is paused
  bool get isPaused => status == SessionStatus.paused;
  
  /// Check if session is completed
  bool get isCompleted => status == SessionStatus.completed;
  
  /// Get effective duration (actual - pauses)
  int get effectiveDuration => actualDuration - totalPauseTime;
  
  /// Get formatted duration string
  String get formattedDuration {
    final duration = effectiveDuration;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
  
  /// Get progress percentage (0.0 - 1.0)
  double get progress {
    if (plannedDuration == 0) return 0.0;
    return (effectiveDuration / plannedDuration).clamp(0.0, 1.0);
  }
  
  /// Get formatted start time
  DateTime get startDateTime => 
      DateTime.fromMillisecondsSinceEpoch(startedAt);
  
  /// Get formatted end time
  DateTime? get endDateTime => 
      endedAt != null ? DateTime.fromMillisecondsSinceEpoch(endedAt!) : null;
}

/// Session type enum
enum SessionType {
  pomodoro,
  free,
  timed,
}

/// Session status enum
enum SessionStatus {
  active,
  completed,
  paused,
  cancelled,
}

/// Session sync status enum
enum SessionSyncStatus {
  synced,
  pendingUpload,
  pendingDownload,
  conflict,
  error,
}
