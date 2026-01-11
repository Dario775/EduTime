import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderTime = 'reminder_time'; // Hour of day (0-23)
  
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
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }
  
  int getReminderHour() {
    return _prefs.getInt(_keyReminderTime) ?? 20; // Default: 8 PM
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelAll();
    }
  }
  
  Future<void> setReminderTime(int hour) async {
    await _prefs.setInt(_keyReminderTime, hour);
    if (areNotificationsEnabled()) {
      await scheduleDailyReminder();
    }
  }
  
  Future<void> scheduleDailyReminder() async {
    await _notifications.cancel(0); // Cancel existing
    
    if (!areNotificationsEnabled()) return;
    
    final hour = getReminderHour();
    
    await _notifications.zonedSchedule(
      0,
      '📚 ¡Hora de estudiar!',
      '¿Ya cumpliste tu meta de hoy? Cada minuto cuenta',
      _nextInstanceOfTime(hour, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Recordatorio Diario',
          channelDescription: 'Recordatorio para estudiar cada día',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
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

// For timezone support (simplified - will work without actual timezone package)
class tz {
  static final local = _Local();
  static TZDateTime now(_Local location) => TZDateTime.now();
}

class _Local {}

class TZDateTime extends DateTime {
  TZDateTime(dynamic location, int year, [int month = 1, int day = 1, int hour = 0, int minute = 0])
      : super(year, month, day, hour, minute);
  
  static TZDateTime now() => TZDateTime(null, DateTime.now().year, DateTime.now().month, 
      DateTime.now().day, DateTime.now().hour, DateTime.now().minute);
}

enum DateTimeComponents { time }

// Global instance
final notificationService = NotificationService();
