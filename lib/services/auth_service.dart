import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client; // Use unified client

  static Future<Map<String, dynamic>?> loginStaff(String phone, String password) async {
    // Normalize phone to last 10 digits
    final normalizedPhone = phone.length > 10 ? phone.substring(phone.length - 10) : phone;

    // 1. Fetch staff member by phone (must be activated)
    final staff = await _client
        .from('Staff')
        .select()
        .eq('phone', normalizedPhone)
        .eq('isActivated', true)
        .maybeSingle();

    if (staff == null) return null;

    // 2. Verify password hash using dbcrypt
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
    // Normalize phone to last 10 digits
    final normalizedPhone = phone.length > 10 ? phone.substring(phone.length - 10) : phone;

    final res = await _client
        .from('Staff')
        .select()
        .eq('phone', normalizedPhone)
        .eq('joiningCode', code)
        .eq('isActivated', false)
        .maybeSingle();
    return res;
  }

  static Future<bool> registerStaff(String id, String password) async {
    try {
      final hashedSub = DBCrypt().hashpw(password, DBCrypt().gensalt());
      final res = await _client.from('Staff').update({
        'password': hashedSub,
        'isActivated': true,
      }).eq('id', id).select('id').maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  // Cache the hash to avoid redundant network calls and improve login speed
  static String? _cachedOwnerPinHash;

  /// Fetch the owner PIN hash early to make login instant
  static Future<void> prewarmOwnerAuth() async {
    try {
      final res = await _client
          .from('SystemSetting')
          .select('value')
          .eq('key', 'owner_pin_hash')
          .maybeSingle();
      if (res != null) {
        _cachedOwnerPinHash = res['value']?.toString();
      }
    } catch (e) {
      debugPrint('⚠️ Prewarm Auth Failed: $e');
    }
  }

  static Future<bool> verifyOwnerPin(String pin) async {
    try {
      String? hash = _cachedOwnerPinHash;
      
      // If not cached, fetch it now (fallback)
      if (hash == null) {
        final res = await _client
            .from('SystemSetting')
            .select('value')
            .eq('key', 'owner_pin_hash')
            .maybeSingle();
        
        if (res == null) {
           debugPrint('❌ Owner PIN hash not found in DB');
           return false;
        }
        hash = res['value']?.toString();
        _cachedOwnerPinHash = hash; 
      }
      
      if (hash == null) return false;
      bool isCorrect = DBCrypt().checkpw(pin, hash);

      // Defensive retry: if it fails, the PIN might have changed. Refresh cache and try once more.
      if (!isCorrect) {
        final res = await _client
            .from('SystemSetting')
            .select('value')
            .eq('key', 'owner_pin_hash')
            .maybeSingle();
        
        if (res != null) {
          final freshHash = res['value']?.toString();
          if (freshHash != null && freshHash != hash) {
            _cachedOwnerPinHash = freshHash;
            isCorrect = DBCrypt().checkpw(pin, freshHash);
          }
        }
      }

      return isCorrect;
    } catch (e) {
      debugPrint('⚠️ PIN Verification Error: $e');
      return false;
    }
  }
}
