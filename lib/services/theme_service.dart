import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  /// Save the theme preference to local storage
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// Retrieve the theme preference from local storage
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_themeKey);
    if (modeName == null) return ThemeMode.light;
    
    return ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.light,
    );
  }
}
