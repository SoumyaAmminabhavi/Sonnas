import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    return _client.from('Cake').stream(primaryKey: ['id']);
  }

  /// Fetch all menu items with fallback
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      // 1. Try Primary (Friend's) project
      final res = await SupabaseService.client.from('Cake').select('*, CakeOption(*)').order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Friend\'s Menu Fetch Failed: $e. Falling back to Private DB.');
      try {
        // 2. Fallback to Private (My) project
        final res = await SupabaseService.myClient.from('Cake').select('*, CakeOption(*)').order('name');
        return List<Map<String, dynamic>>.from(res);
      } catch (e2) {
        debugPrint('❌ All Menu Fetch attempts failed: $e2');
        return []; // Return empty list instead of crashing
      }
    }
  }

  /// Upsert a cake item and return its ID
  static Future<String> upsertCake(Map<String, dynamic> cake) async {
    final res = await _client.from('Cake').upsert(cake).select().single();
    return res['id'].toString();
  }

  /// Upsert cake options (pricing, weight, serves)
  static Future<void> upsertCakeOption(Map<String, dynamic> option) async {
    await _client.from('CakeOption').upsert(option);
  }
}
