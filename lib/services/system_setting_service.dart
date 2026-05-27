import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemSettingService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetch all settings from SystemSetting table
  static Future<Map<String, String>> fetchAllSettings() async {
    try {
      final data = await _client.from('SystemSetting').select();
      final Map<String, String> settings = {};
      for (var row in data) {
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key != null && value != null) {
          settings[key] = value;
        }
      }
      return settings;
    } catch (e) {
      print("Error fetching settings: $e");
      // Return empty map on error to allow fallback values
      return {};
    }
  }

  /// Update a setting by key
  static Future<void> updateSetting(String key, String value) async {
    await _client.from('SystemSetting').upsert({'key': key, 'value': value});
  }
}
