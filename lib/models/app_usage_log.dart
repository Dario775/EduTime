class AppUsageLog {
  final String childId;
  final String packageName;
  final String appName;
  final DateTime timestamp;
  final int durationSeconds;
  final bool wasAllowed; // Si era una app permitida en ese momento

  AppUsageLog({
    required this.childId,
    required this.packageName,
    required this.appName,
    required this.timestamp,
    required this.durationSeconds,
    required this.wasAllowed,
  });

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'packageName': packageName,
      'appName': appName,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'wasAllowed': wasAllowed,
    };
  }

  factory AppUsageLog.fromMap(Map<String, dynamic> map) {
    return AppUsageLog(
      childId: map['childId'] as String,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      durationSeconds: map['durationSeconds'] as int,
      wasAllowed: map['wasAllowed'] as bool,
    );
  }
}
