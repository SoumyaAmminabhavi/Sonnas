import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'constants.dart';

class StaffService {
  static SupabaseClient get _client => SupabaseService.client;

  static Stream<List<Map<String, dynamic>>> getStaffStream() {
    return _client.from('Staff').stream(primaryKey: ['id']).order('name');
  }

  static Future<String> addStaff(Map<String, dynamic> data) async {
    final mutableData = Map<String, dynamic>.from(data);
    // Ensure a joining code exists before the first attempt
    mutableData['joiningCode'] ??= _generateJoiningCode();
    int attempts = 0;
    while (attempts < AuthConstants.maxJoiningCodeRetries) {
      final code = mutableData['joiningCode'] as String;
      try {
        await _client.from('Staff').insert(mutableData);
        return code; // Success
      } on PostgrestException catch (e) {
        // Check if the error is a unique constraint violation on joiningCode
        if (e.code == '23505' && e.message.toLowerCase().contains('joiningcode')) {
          attempts++;
          if (attempts >= AuthConstants.maxJoiningCodeRetries) {
            throw StateError('Failed to insert staff after ${AuthConstants.maxJoiningCodeRetries} attempts due to duplicate joining codes');
          }
          // Generate a new joining code and retry
          mutableData['joiningCode'] = _generateJoiningCode();
        } else {
          rethrow; // Different error, propagate it
        }
      } catch (e) {
        // Fallback for non-PostgrestException errors
        final errorStr = e.toString();
        if ((errorStr.contains('23505') || errorStr.toLowerCase().contains('unique constraint')) &&
            errorStr.toLowerCase().contains('joiningcode')) {
          attempts++;
          if (attempts >= AuthConstants.maxJoiningCodeRetries) {
            throw StateError('Failed to insert staff after ${AuthConstants.maxJoiningCodeRetries} attempts due to duplicate joining codes');
          }
          mutableData['joiningCode'] = _generateJoiningCode();
        } else {
          rethrow;
        }
      }
    }
    throw StateError('Unexpected: loop exited without return');
  }

  static String _generateJoiningCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  static Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    await _client.from('Staff').update(data).eq('id', id);
  }

  static Future<void> deleteStaff(String id) async {
    await _client.from('Staff').delete().eq('id', id);
  }

  static Future<bool> updateBiometricStatus(String id, bool enabled) async {
    try {
      final res = await _client.rpc<bool>('self_update_staff', params: {
        'staff_id': id,
        'update_data': {
          'biometricEnabled': enabled,
        },
      });
      return res;
    } catch (e) {
      debugPrint('❌ Update biometric status RPC failed: $e');
      rethrow;
    }
  }

  static Future<String> uploadStaffImage(String fileName, List<int> bytes) async {
    final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (uint8Bytes.length > AuthConstants.maxImageSizeBytes) {
      throw ArgumentError('Image size exceeds ${AuthConstants.maxImageSizeBytes ~/ (1024 * 1024)}MB limit');
    }
    await _client.storage.from('staff_photos').uploadBinary(
      fileName, 
      uint8Bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    return fileName;
  }

  static Future<bool> isJoiningCodeTaken(String code) async {
    final res = await _client
        .from('Staff')
        .select('id')
        .eq('joiningCode', code)
        .maybeSingle();
    return res != null;
  }
}
