import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'constants.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static String _normalizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length > AuthConstants.phoneDigits
        ? digitsOnly.substring(digitsOnly.length - AuthConstants.phoneDigits)
        : digitsOnly;
  }

  static Future<Map<String, dynamic>?> loginStaff(String phone, String password) async {
    final normalizedPhone = _normalizePhone(phone);

    final staff = await _client
        .from('Staff')
        .select()
        .eq('phone', normalizedPhone)
        .eq('isActivated', true)
        .maybeSingle();

    if (staff == null) return null;

    final storedHash = staff['password'] as String?;
    if (storedHash == null) return null;

    try {
      final isCorrect = DBCrypt().checkpw(password, storedHash);
      if (isCorrect) {
        return staff;
      }
    } catch (e) {
      debugPrint('❌ Password check failed (possibly invalid hash): $e');
    }
    
    return null;
  }

  static Future<Map<String, dynamic>?> verifyStaffCode(String phone, String code) async {
    final normalizedPhone = _normalizePhone(phone);
    try {
      final res = await _client.rpc('verify_staff_code', params: {
        'phone_param': normalizedPhone,
        'code_param': code,
      });
      
      final map = Map<String, dynamic>.from(res);
      final success = map['success'] as bool? ?? false;
      if (!success) {
        final msg = map['message'] as String? ?? 'Verification failed';
        throw Exception(msg);
      }
      
      final staff = await _client
          .from('Staff')
          .select()
          .eq('phone', normalizedPhone)
          .maybeSingle();
      return staff;
    } catch (e) {
      debugPrint('❌ Staff verification RPC failed: $e');
      rethrow;
    }
  }

  static Future<bool> registerStaff(String id, String password) async {
    try {
      final hashedSub = DBCrypt().hashpw(password, DBCrypt().gensalt());
      final res = await _client.rpc('self_update_staff', params: {
        'staff_id': id,
        'update_data': {
          'password': hashedSub,
          'isActivated': true,
        },
      });
      return res as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Register staff RPC failed: $e');
      return false;
    }
  }

  @Deprecated('Use server-side RPC validation instead')
  static Future<void> prewarmOwnerAuth() async {
    // No-op (Server-side RPC validation renders client-side caching obsolete)
  }

  static Future<bool> verifyOwnerPin(String pin) async {
    try {
      final res = await _client.rpc('verify_owner_pin', params: {
        'pin': pin,
      });
      return res as bool? ?? false;
    } catch (e) {
      debugPrint('⚠️ PIN Verification RPC Error: $e');
      return false;
    }
  }
}
