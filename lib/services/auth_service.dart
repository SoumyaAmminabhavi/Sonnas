import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'constants.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static final Map<String, _AttemptTracker> _staffCodeAttempts = {};

  static bool isStaffCodeLockedOut(String phone) {
    final normalizedPhone = _normalizePhone(phone);
    final tracker = _staffCodeAttempts[normalizedPhone];
    if (tracker == null) return false;
    if (tracker.lockoutUntil != null && DateTime.now().isBefore(tracker.lockoutUntil!)) {
      return true;
    }
    if (tracker.lockoutUntil != null && DateTime.now().isAfter(tracker.lockoutUntil!)) {
      _staffCodeAttempts.remove(normalizedPhone);
      return false;
    }
    return false;
  }

  static int getStaffCodeAttemptsRemaining(String phone) {
    final normalizedPhone = _normalizePhone(phone);
    final tracker = _staffCodeAttempts[normalizedPhone];
    if (tracker == null) return AuthConstants.maxStaffCodeAttempts;
    if (tracker.lockoutUntil != null && DateTime.now().isBefore(tracker.lockoutUntil!)) {
      return 0;
    }
    return (AuthConstants.maxStaffCodeAttempts - tracker.count).clamp(0, AuthConstants.maxStaffCodeAttempts);
  }

  static Duration? getStaffCodeLockoutRemaining(String phone) {
    final normalizedPhone = _normalizePhone(phone);
    final tracker = _staffCodeAttempts[normalizedPhone];
    if (tracker == null || tracker.lockoutUntil == null) return null;
    final remaining = tracker.lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  static void _recordStaffCodeFailure(String phone) {
    final normalizedPhone = _normalizePhone(phone);
    final tracker = _staffCodeAttempts[normalizedPhone] ?? _AttemptTracker();
    tracker.count++;
    if (tracker.count >= AuthConstants.maxStaffCodeAttempts) {
      tracker.lockoutUntil = DateTime.now().add(AuthConstants.staffCodeLockoutDuration);
    }
    _staffCodeAttempts[normalizedPhone] = tracker;
  }

  static void resetStaffCodeAttempts(String phone) {
    final normalizedPhone = _normalizePhone(phone);
    _staffCodeAttempts.remove(normalizedPhone);
  }

  static String _normalizePhone(String phone) {
    return phone.length > AuthConstants.phoneDigits
        ? phone.substring(phone.length - AuthConstants.phoneDigits)
        : phone;
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

    if (isStaffCodeLockedOut(normalizedPhone)) {
      debugPrint('⚠️ Staff code verification locked out for $normalizedPhone');
      return null;
    }

    final res = await _client
        .from('Staff')
        .select()
        .eq('phone', normalizedPhone)
        .eq('joiningCode', code)
        .eq('isActivated', false)
        .maybeSingle();

    if (res == null) {
      _recordStaffCodeFailure(normalizedPhone);
    } else {
      resetStaffCodeAttempts(normalizedPhone);
    }

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

class _AttemptTracker {
  int count = 0;
  DateTime? lockoutUntil;
}
