import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    return _client.from('Cake').stream(primaryKey: ['id']);
  }

  /// Fetch all menu items
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      final res = await _client.from('Cake').select('*, CakeOption(*)').order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      rethrow;
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
