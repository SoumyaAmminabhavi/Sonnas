import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get _myClient => SupabaseService.myClient; // Private instance

  static Future<Map<String, dynamic>?> loginStaff(String phone, String password) async {
    // Normalize phone to last 10 digits
    final normalizedPhone = phone.length > 10 ? phone.substring(phone.length - 10) : phone;

    // 1. Fetch staff member by phone (must be activated)
    final staff = await _myClient
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
      // In case the stored password is not a valid hash (e.g. legacy plain text)
      if (storedHash == password) {
        return staff;
      }
    }
    
    return null;
  }

  static Future<Map<String, dynamic>?> verifyStaffCode(String phone, String code) async {
    // Normalize phone to last 10 digits
    final normalizedPhone = phone.length > 10 ? phone.substring(phone.length - 10) : phone;

    final res = await _myClient
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
      await _myClient.from('Staff').update({
        'password': hashedSub,
        'isActivated': true,
      }).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cache the hash to avoid redundant network calls and improve login speed
  static String? _cachedOwnerPinHash;

  /// Fetch the owner PIN hash early to make login instant
  static Future<void> prewarmOwnerAuth() async {
    try {
      final res = await _myClient
          .from('WhatsAppSetting')
          .select('value')
          .eq('key', 'owner_pin_hash')
          .maybeSingle();
      if (res != null) {
        _cachedOwnerPinHash = res['value']?.toString();
      }
    } catch (_) {
      // Fail silently, verifyOwnerPin will retry if needed
    }
  }

  static Future<bool> verifyOwnerPin(String pin) async {
    try {
      String? hash = _cachedOwnerPinHash;
      
      // If not cached, fetch it now (fallback)
      if (hash == null) {
        final res = await _myClient
            .from('WhatsAppSetting')
            .select('value')
            .eq('key', 'owner_pin_hash')
            .maybeSingle();
        
        if (res == null) return false;
        hash = res['value']?.toString();
        _cachedOwnerPinHash = hash; // Cache it for next time
      }
      
      if (hash == null) return false;

      // Verify the hashed PIN using bcrypt
      return DBCrypt().checkpw(pin, hash);
    } catch (e) {
      // Silently fail in production or use a logger
      return false;
    }
  }
}
