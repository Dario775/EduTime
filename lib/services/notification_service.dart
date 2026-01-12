import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    await _notifications.initialize(initSettings);
    
    // Request permission (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  bool areNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? false; // Disabled by default
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }
  
  Future<void> scheduleDailyReminder() async {
    // Simplified - just a placeholder for now
    // Full implementation would require timezone package
  }
  
  Future<void> showGoalCompleted() async {
    await _notifications.show(
      1,
      '🎉 ¡Meta Cumplida!',
      '¡Excelente trabajo! Alcanzaste tu meta de estudio de hoy',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Logros',
          channelDescription: 'Notificaciones de logros y metas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
  
  Future<void> showStreakMilestone(int days) async {
    await _notifications.show(
      2,
      '🔥 ¡Racha de $days días!',
      'Mantén el impulso. ¡Vas muy bien!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Logros',
          channelDescription: 'Notificaciones de logros y metas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
  
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

// Global instance
final notificationService = NotificationService();
