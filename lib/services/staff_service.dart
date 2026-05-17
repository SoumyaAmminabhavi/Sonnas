import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'constants.dart';

class StaffService {
  static SupabaseClient get _client => SupabaseService.client;

  static Stream<List<Map<String, dynamic>>> getStaffStream() {
    return _client.from('Staff').stream(primaryKey: ['id']).order('name');
  }

  static Future<void> addStaff(Map<String, dynamic> data) async {
    await _client.from('Staff').insert(data);
  }

  static Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    await _client.from('Staff').update(data).eq('id', id);
  }

  static Future<void> deleteStaff(String id) async {
    await _client.from('Staff').delete().eq('id', id);
  }

  static Future<bool> updateBiometricStatus(String id, bool enabled) async {
    try {
      await _client.from('Staff').update({'biometricEnabled': enabled}).eq('id', id);
      return true;
    } catch (e) {
      return false;
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
