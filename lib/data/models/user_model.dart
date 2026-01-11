import '../../../domain/entities/user.dart';

/// User data model for API/Database operations
/// 
/// Extends the domain User entity with serialization capabilities.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
    required super.settings,
    required super.stats,
  });

  /// Create UserModel from JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoURL'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      settings: UserSettingsModel.fromJson(
        json['settings'] as Map<String, dynamic>? ?? {},
      ),
      stats: UserStatsModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'settings': (settings as UserSettingsModel).toJson(),
      'stats': (stats as UserStatsModel).toJson(),
    };
  }

  /// Create UserModel from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      settings: UserSettingsModel.fromEntity(user.settings),
      stats: UserStatsModel.fromEntity(user.stats),
    );
  }

  /// Convert to domain entity
  User toEntity() => this;

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}

/// UserSettings model with serialization
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.theme,
    super.notifications,
    super.language,
    super.defaultStudyDuration,
    super.defaultBreakDuration,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      theme: json['theme'] as String? ?? 'system',
      notifications: json['notifications'] as bool? ?? true,
      language: json['language'] as String? ?? 'es',
      defaultStudyDuration: json['defaultStudyDuration'] as int? ?? 25,
      defaultBreakDuration: json['defaultBreakDuration'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications': notifications,
      'language': language,
      'defaultStudyDuration': defaultStudyDuration,
      'defaultBreakDuration': defaultBreakDuration,
    };
  }

  factory UserSettingsModel.fromEntity(UserSettings settings) {
    return UserSettingsModel(
      theme: settings.theme,
      notifications: settings.notifications,
      language: settings.language,
      defaultStudyDuration: settings.defaultStudyDuration,
      defaultBreakDuration: settings.defaultBreakDuration,
    );
  }
}

/// UserStats model with serialization
class UserStatsModel extends UserStats {
  const UserStatsModel({
    super.totalStudyTime,
    super.totalSessions,
    super.currentStreak,
    super.longestStreak,
    super.lastStudyDate,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalStudyTime: json['totalStudyTime'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.tryParse(json['lastStudyDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudyTime': totalStudyTime,
      'totalSessions': totalSessions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
    };
  }

  factory UserStatsModel.fromEntity(UserStats stats) {
    return UserStatsModel(
      totalStudyTime: stats.totalStudyTime,
      totalSessions: stats.totalSessions,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      lastStudyDate: stats.lastStudyDate,
    );
  }
}
