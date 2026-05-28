import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _staffSessionKey = 'staff_session';
  static const _storage = FlutterSecureStorage();

  /// Save sanitized staff data to encrypted local storage
  static Future<void> saveStaffSession(Map<String, dynamic> staffData) async {
    // Only persist non-sensitive fields required for session restoration
    final sessionPayload = <String, dynamic>{
      'id': staffData['id'],
      'name': staffData['name'],
      'role': staffData['role'],
      'sub_role': staffData['sub_role'],
      'biometricEnabled': staffData['biometricEnabled'] ?? false,
    };
    await _storage.write(key: _staffSessionKey, value: jsonEncode(sessionPayload));
  }

  /// Retrieve staff data from encrypted local storage with safety checks
  static Future<Map<String, dynamic>?> getStaffSession() async {
    try {
      final sessionStr = await _storage.read(key: _staffSessionKey);
      if (sessionStr == null) return null;
      
      final decoded = jsonDecode(sessionStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      // If data is corrupted, clear it to prevent repeated crashes
      await clearSession();
    }
    return null;
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    await _storage.delete(key: _staffSessionKey);
  }

  /// Update biometric status in the active session
  static Future<void> updateBiometricStatus(bool enabled) async {
    final session = await getStaffSession();
    if (session != null) {
      session['biometricEnabled'] = enabled;
      await _storage.write(key: _staffSessionKey, value: jsonEncode(session));
    }
  }
}
