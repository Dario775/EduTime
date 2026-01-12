import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/app_usage_log.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AppMonitoringService {
  static const String _keyUsageLogs = 'app_usage_logs';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Request permission to access usage stats
  Future<bool> requestUsagePermission() async {
    try {
      await UsageStats.grantUsagePermission();
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      print('Error requesting usage permission: $e');
      return false;
    }
  }

  // Check if we have permission
  Future<bool> hasUsagePermission() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get app usage for today
  Future<List<UsageInfo>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final stats = await UsageStats.queryUsageStats(
        startOfDay,
        now,
      );
      return stats ?? [];
    } catch (e) {
      print('Error getting usage stats: $e');
      return [];
    }
  }

  // Check if child is using prohibited apps
  Future<void> checkCurrentUsage() async {
    final user = authService.currentUser;
    if (user == null || user.role != UserRole.child) return;

    // Get current task
    final tasks = await taskService.getTasksForChild(user.uid);
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).toList();
    
    if (pendingTasks.isEmpty) return; // No active tasks

    final currentTask = pendingTasks.first;
    final allowedApps = currentTask.allowedApps.toSet();

    // Get recent usage (last 2 minutes)
    final now = DateTime.now();
    final twoMinAgo = now.subtract(const Duration(minutes: 2));
    
    final usage = await UsageStats.queryUsageStats(twoMinAgo, now);
    if (usage == null || usage.isEmpty) return;

    // Find most recent app
    usage.sort((a, b) => (b.lastTimeUsed ?? 0).compareTo(a.lastTimeUsed ?? 0));
    final currentApp = usage.first;

    // Check if it's allowed
    if (!allowedApps.contains(currentApp.packageName)) {
      // Log violation
      await _logUsage(
        childId: user.uid,
        packageName: currentApp.packageName ?? 'unknown',
        appName: currentApp.appName ?? 'Unknown',
        durationSeconds: ((currentApp.totalTimeInForeground ?? 0) / 1000).round(),
        wasAllowed: false,
      );

      // Notify parent
      await _notifyParent(user.name, currentApp.appName ?? 'Unknown');
    }
  }

  // Log app usage
  Future<void> _logUsage({
    required String childId,
    required String packageName,
    required String appName,
    required int durationSeconds,
    required bool wasAllowed,
  }) async {
    final logs = await _getAllLogs();
    
    final log = AppUsageLog(
      childId: childId,
      packageName: packageName,
      appName: appName,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      wasAllowed: wasAllowed,
    );

    logs.add(log);
    await _saveLogs(logs);
  }

  // Get all usage logs
  Future<List<AppUsageLog>> _getAllLogs() async {
    final logsJson = _prefs.getString(_keyUsageLogs);
    if (logsJson == null) return [];

    try {
      final List<dynamic> list = json.decode(logsJson) as List<dynamic>;
      return list.map((map) => AppUsageLog.fromMap(map as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting logs: $e');
      return [];
    }
  }

  // Save logs
  Future<void> _saveLogs(List<AppUsageLog> logs) async {
    final list = logs.map((log) => log.toMap()).toList();
    await _prefs.setString(_keyUsageLogs, json.encode(list));
  }

  // Get logs for a specific child
  Future<List<AppUsageLog>> getLogsForChild(String childId, {DateTime? since}) async {
    final allLogs = await _getAllLogs();
    var childLogs = allLogs.where((log) => log.childId == childId).toList();

    if (since != null) {
      childLogs = childLogs.where((log) => log.timestamp.isAfter(since)).toList();
    }

    childLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return childLogs;
  }

  // Get violations count (unauthorized apps used)
  Future<int> getViolationsCount(String childId, {DateTime? since}) async {
    final logs = await getLogsForChild(childId, since: since);
    return logs.where((log) => !log.wasAllowed).length;
  }

  // Notify parent about violation
  Future<void> _notifyParent(String childName, String appName) async {
    await notificationService.showNotification(
      title: '⚠️ Alerta de App',
      body: '$childName está usando "$appName" (no permitida)',
      payload: 'violation',
    );
  }

  // Get summary stats for child
  Future<Map<String, dynamic>> getChildStats(String childId, {DateTime? since}) async {
    final logs = await getLogsForChild(childId, since: since);
    
    final violations = logs.where((log) => !log.wasAllowed).length;
    final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationSeconds) ~/ 60;
    
    // App distribution
    final appUsage = <String, int>{};
    for (final log in logs) {
      appUsage[log.appName] = (appUsage[log.appName] ?? 0) + log.durationSeconds;
    }

    return {
      'totalLogs': logs.length,
      'violations': violations,
      'totalMinutes': totalMinutes,
      'complianceRate': logs.isEmpty ? 100.0 : ((logs.length - violations) / logs.length) * 100,
      'topApps': appUsage,
    };
  }
}

final appMonitoringService = AppMonitoringService();
