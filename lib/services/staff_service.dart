import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StaffService {
  static SupabaseClient get _client => SupabaseService.myClient;

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
    await _client.storage.from('staff_photos').uploadBinary(
      fileName, 
      Uint8List.fromList(bytes),
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    return fileName;
  }
}
