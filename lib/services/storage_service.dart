import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyTotalStudyTime = 'total_study_time';
  static const String _keyTotalCredits = 'total_credits';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLastStudyDate = 'last_study_date';
  static const String _keyTodayStudyTime = 'today_study_time';
  static const String _keyDailyGoal = 'daily_goal'; // in minutes
  static const String _keyHistory = 'study_history'; // JSON of daily data
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkAndUpdateStreak();
  }
  
  // Getters
  int getTotalStudyTime() => _prefs.getInt(_keyTotalStudyTime) ?? 0;
  int getTotalCredits() => _prefs.getInt(_keyTotalCredits) ?? 0;
  int getCurrentStreak() => _prefs.getInt(_keyCurrentStreak) ?? 0;
  int getDailyGoal() => _prefs.getInt(_keyDailyGoal) ?? 30; // Default: 30 min
  
  int getTodayStudyTime() {
    _checkAndResetToday();
    return _prefs.getInt(_keyTodayStudyTime) ?? 0;
  }
  
  // History: Map<date_string, seconds_studied>
  Map<String, int> getHistory() {
    final jsonString = _prefs.getString(_keyHistory);
    if (jsonString == null) return {};
    
    try {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }
  
  List<Map<String, dynamic>> getLast7Days() {
    final history = getHistory();
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      final seconds = history[dateKey] ?? 0;
      
      result.add({
        'date': date,
        'dateKey': dateKey,
        'seconds': seconds,
        'minutes': seconds ~/ 60,
      });
    }
    
    return result;
  }
  
  // Setters
  Future<void> setDailyGoal(int minutes) async {
    await _prefs.setInt(_keyDailyGoal, minutes);
  }
  
  Future<void> addStudyTime(int seconds, {String? categoryId}) async {
    final total = getTotalStudyTime() + seconds;
    final today = getTodayStudyTime() + seconds;
    final credits = getTotalCredits() + seconds; // 1:1 ratio
    
    await _prefs.setInt(_keyTotalStudyTime, total);
    await _prefs.setInt(_keyTodayStudyTime, today);
    await _prefs.setInt(_keyTotalCredits, credits);
    await _prefs.setString(_keyLastStudyDate, DateTime.now().toIso8601String());
    
    // Update history
    await _updateHistory(today);
    
    // Update category stats if provided
    if (categoryId != null) {
      await _updateCategoryStats(categoryId, seconds);
    }
    
    _checkAndUpdateStreak();
  }
  
  Future<void> _updateCategoryStats(String categoryId, int seconds) async {
    final key = 'category_$categoryId';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + seconds);
  }
  
  Map<String, int> getCategoryStats() {
    final allKeys = _prefs.getKeys();
    final categoryKeys = allKeys.where((k) => k.startsWith('category_'));
    
    final Map<String, int> stats = {};
    for (final key in categoryKeys) {
      final categoryId = key.replaceFirst('category_', '');
      stats[categoryId] = _prefs.getInt(key) ?? 0;
    }
    
    return stats;
  }
  
  Future<void> _updateHistory(int todaySeconds) async {
    final history = getHistory();
    final dateKey = _dateKey(DateTime.now());
    history[dateKey] = todaySeconds;
    
    // Keep only last 30 days to save space
    if (history.length > 30) {
      final sortedKeys = history.keys.toList()..sort();
      while (history.length > 30) {
        history.remove(sortedKeys.first);
        sortedKeys.removeAt(0);
      }
    }
    
    await _prefs.setString(_keyHistory, json.encode(history));
  }
  
  Future<void> spendCredits(int seconds) async {
    final current = getTotalCredits();
    final newCredits = (current - seconds).clamp(0, double.infinity).toInt();
    await _prefs.setInt(_keyTotalCredits, newCredits);
  }
  
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  void _checkAndResetToday() {
    final lastDate = _prefs.getString(_keyLastStudyDate);
    if (lastDate != null) {
      final last = DateTime.parse(lastDate);
      final now = DateTime.now();
      
      if (last.year != now.year || 
          last.month != now.month || 
          last.day != now.day) {
        _prefs.setInt(_keyTodayStudyTime, 0);
      }
    }
  }
  
  void _checkAndUpdateStreak() {
    final lastDate = _prefs.getString(_keyLastStudyDate);
    if (lastDate == null) return;
    
    final last = DateTime.parse(lastDate);
    final now = DateTime.now();
    final difference = now.difference(last).inDays;
    
    if (difference == 0) {
      // Same day, maintain streak
      return;
    } else if (difference == 1) {
      // Consecutive day, increment streak
      final streak = getCurrentStreak() + 1;
      _prefs.setInt(_keyCurrentStreak, streak);
    } else if (difference > 1) {
      // Streak broken
      _prefs.setInt(_keyCurrentStreak, 1);
    }
  }
  
  Future<void> reset() async {
    await _prefs.clear();
  }
}

// Global instance
final storageService = StorageService();
