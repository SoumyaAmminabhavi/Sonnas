import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static SharedPreferences? _cachedPrefs;

  static Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    final success = await prefs.setString(_themeKey, mode.name);
    if (!success) {
      throw StateError(
        'Theme persistence failed: could not save mode "${mode.name}" to key "$_themeKey".',
      );
    }
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await _prefs;
    final modeName = prefs.getString(_themeKey);
    if (modeName == null) return ThemeMode.light;
    
    return ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.light,
    );
  }
}
