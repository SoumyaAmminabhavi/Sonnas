import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _staffSessionKey = 'staff_session';
  static const _storage = FlutterSecureStorage();

  /// Save staff data to encrypted local storage
  static Future<void> saveStaffSession(Map<String, dynamic> staffData) async {
    await _storage.write(key: _staffSessionKey, value: jsonEncode(staffData));
  }

  /// Retrieve staff data from encrypted local storage
  static Future<Map<String, dynamic>?> getStaffSession() async {
    final sessionStr = await _storage.read(key: _staffSessionKey);
    if (sessionStr != null) {
      return jsonDecode(sessionStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    await _storage.delete(key: _staffSessionKey);
  }
}
