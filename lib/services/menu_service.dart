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
      // 1. Try Primary (Friend's) project with join
      try {
        final res = await SupabaseService.client.from('Cake').select('*, CakeOption(*)').order('name');
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('⚠️ Join fetch failed, trying simple fetch + merge: $e');
        // Fallback to simple select if join fails (relationship name might be different)
        final cakes = await SupabaseService.client.from('Cake').select('*').order('name');
        final List<Map<String, dynamic>> cakesList = List<Map<String, dynamic>>.from(cakes);
        
        if (cakesList.isEmpty) return [];

        // Manual join/merge for CakeOption
        final cakeIds = cakesList.map((c) => c['id'].toString()).toList();
        final options = await SupabaseService.client.from('CakeOption').select('*').inFilter('cakeId', cakeIds);
        final List<Map<String, dynamic>> optionsList = List<Map<String, dynamic>>.from(options);

        // Merge options back into cakes
        for (var cake in cakesList) {
          cake['CakeOption'] = optionsList.where((o) => o['cakeId'] == cake['id']).toList();
        }
        
        return cakesList;
      }
    } catch (e) {
      debugPrint('⚠️ Friend\'s Menu Fetch Failed: $e. Falling back to Private DB.');
      try {
        // 2. Fallback to Private (My) project
        final res = await SupabaseService.myClient.from('Cake').select('*, CakeOption(*)').order('name');
        return List<Map<String, dynamic>>.from(res);
      } catch (e2) {
        debugPrint('❌ All Menu Fetch attempts failed: $e2');
        rethrow; // Rethrow to allow UI to handle error state
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
