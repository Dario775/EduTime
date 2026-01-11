import 'package:equatable/equatable.dart';

/// User entity - Core business object
/// 
/// Represents a user in the application domain.
/// This is a pure Dart class with no framework dependencies.
class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSettings settings;
  final UserStats stats;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    required this.stats,
  });

  /// Create a copy with modified properties
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSettings? settings,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        updatedAt,
        settings,
        stats,
      ];
}

/// User settings entity
class UserSettings extends Equatable {
  final String theme;
  final bool notifications;
  final String language;
  final int defaultStudyDuration; // in minutes
  final int defaultBreakDuration; // in minutes

  const UserSettings({
    this.theme = 'system',
    this.notifications = true,
    this.language = 'es',
    this.defaultStudyDuration = 25,
    this.defaultBreakDuration = 5,
  });

  UserSettings copyWith({
    String? theme,
    bool? notifications,
    String? language,
    int? defaultStudyDuration,
    int? defaultBreakDuration,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      defaultStudyDuration: defaultStudyDuration ?? this.defaultStudyDuration,
      defaultBreakDuration: defaultBreakDuration ?? this.defaultBreakDuration,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        notifications,
        language,
        defaultStudyDuration,
        defaultBreakDuration,
      ];
}

/// User statistics entity
class UserStats extends Equatable {
  final int totalStudyTime; // in minutes
  final int totalSessions;
  final int currentStreak; // days
  final int longestStreak; // days
  final DateTime? lastStudyDate;

  const UserStats({
    this.totalStudyTime = 0,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
  });

  UserStats copyWith({
    int? totalStudyTime,
    int? totalSessions,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
  }) {
    return UserStats(
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      totalSessions: totalSessions ?? this.totalSessions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    );
  }

  /// Formatted total study time string
  String get formattedTotalTime {
    final hours = totalStudyTime ~/ 60;
    final minutes = totalStudyTime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        totalStudyTime,
        totalSessions,
        currentStreak,
        longestStreak,
        lastStudyDate,
      ];
}
