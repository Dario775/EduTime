import 'package:isar/isar.dart';

part 'subject_schema.g.dart';

/// Subject Isar Schema
/// 
/// Stores study subjects/topics locally.
@collection
class SubjectSchema {
  Id id = Isar.autoIncrement;
  
  /// Firebase document ID (for sync)
  @Index()
  String? firestoreId;
  
  /// User ID
  @Index()
  late String odexUserId;
  
  /// Subject name
  late String name;
  
  /// Subject color (hex string)
  late String color;
  
  /// Subject icon name
  late String icon;
  
  /// Custom time ratio for this subject
  double? customRatio;
  
  /// Total study time in seconds
  late int totalStudyTime;
  
  /// Total sessions count
  late int sessionCount;
  
  /// Is this subject archived?
  late bool isArchived;
  
  /// Display order
  late int order;
  
  /// Creation timestamp (milliseconds since epoch)
  late int createdAt;
  
  /// Last update timestamp (milliseconds since epoch)
  late int updatedAt;
  
  /// Sync status with Firestore
  @enumerated
  late SubjectSyncStatus syncStatus;
  
  /// Last sync timestamp
  int? lastSyncAt;
  
  /// Create a new subject
  static SubjectSchema create({
    required String odexUserId,
    required String name,
    required String color,
    required String icon,
    int order = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SubjectSchema()
      ..odexUserId = odexUserId
      ..name = name
      ..color = color
      ..icon = icon
      ..totalStudyTime = 0
      ..sessionCount = 0
      ..isArchived = false
      ..order = order
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SubjectSyncStatus.pendingUpload;
  }
  
  /// Get formatted total study time
  String get formattedTotalTime {
    final hours = totalStudyTime ~/ 3600;
    final minutes = (totalStudyTime % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    }
    return '0m';
  }
  
  /// Get average session duration
  int get averageSessionDuration {
    if (sessionCount == 0) return 0;
    return totalStudyTime ~/ sessionCount;
  }
  
  /// Add study time from a session
  void addSessionTime(int seconds) {
    totalStudyTime += seconds;
    sessionCount++;
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    syncStatus = SubjectSyncStatus.pendingUpload;
  }
}

/// Subject sync status enum
enum SubjectSyncStatus {
  synced,
  pendingUpload,
  pendingDownload,
  conflict,
  error,
}

/// Default subject colors
class SubjectColors {
  static const String red = '#EF4444';
  static const String orange = '#F97316';
  static const String amber = '#F59E0B';
  static const String yellow = '#EAB308';
  static const String lime = '#84CC16';
  static const String green = '#22C55E';
  static const String emerald = '#10B981';
  static const String teal = '#14B8A6';
  static const String cyan = '#06B6D4';
  static const String sky = '#0EA5E9';
  static const String blue = '#3B82F6';
  static const String indigo = '#6366F1';
  static const String violet = '#8B5CF6';
  static const String purple = '#A855F7';
  static const String fuchsia = '#D946EF';
  static const String pink = '#EC4899';
  static const String rose = '#F43F5E';
  
  static const List<String> all = [
    red, orange, amber, yellow, lime, green, emerald, teal,
    cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose,
  ];
}

/// Default subject icons
class SubjectIcons {
  static const String math = 'calculate';
  static const String science = 'science';
  static const String history = 'history_edu';
  static const String language = 'translate';
  static const String literature = 'menu_book';
  static const String art = 'palette';
  static const String music = 'music_note';
  static const String sports = 'sports_soccer';
  static const String technology = 'computer';
  static const String geography = 'public';
  static const String biology = 'biotech';
  static const String chemistry = 'science';
  static const String physics = 'bolt';
  static const String economics = 'trending_up';
  static const String philosophy = 'psychology';
  static const String general = 'school';
  
  static const List<String> all = [
    math, science, history, language, literature, art, music,
    sports, technology, geography, biology, chemistry, physics,
    economics, philosophy, general,
  ];
}
