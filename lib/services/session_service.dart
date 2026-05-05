import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _staffSessionKey = 'staff_session';

  /// Save staff data to local storage
  static Future<void> saveStaffSession(Map<String, dynamic> staffData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffSessionKey, jsonEncode(staffData));
  }

  /// Retrieve staff data from local storage
  static Future<Map<String, dynamic>?> getStaffSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString(_staffSessionKey);
    if (sessionStr != null) {
      return jsonDecode(sessionStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_staffSessionKey);
  }
}
