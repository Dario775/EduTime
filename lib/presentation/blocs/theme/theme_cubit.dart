import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Cubit for managing app theme (light/dark/system)
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'THEME_MODE';
  final SharedPreferences sharedPreferences;

  ThemeCubit({required this.sharedPreferences}) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeString = sharedPreferences.getString(_themeKey);
    switch (themeString) {
      case 'light':
        emit(ThemeMode.light);
      case 'dark':
        emit(ThemeMode.dark);
      default:
        emit(ThemeMode.system);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final themeString = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await sharedPreferences.setString(_themeKey, themeString);
    emit(mode);
  }

  Future<void> toggleTheme() async {
    final newMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setTheme(newMode);
  }
}
