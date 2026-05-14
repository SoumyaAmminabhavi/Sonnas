import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    return _client.from('Cake').stream(primaryKey: ['id']).order('name');
  }

  /// Fetch all menu items with full category and option data
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      // Fetch active cakes with their categories and options
      // Note: Join syntax '*, Category(*), CakeOption(*)'
      final res = await _client
          .from('Cake')
          .select('*, Category(*), CakeOption(*)')
          .isFilter('deletedAt', null)
          .order('name');
      
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Menu Fetch Failed: $e');
      rethrow;
    }
  }

  /// Fetch all categories from the official Category table
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final res = await _client.from('Category').select('*').order('sortOrder');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Fetch Categories Failed: $e');
      return [];
    }
  }

  /// Create or update a category
  static Future<String> upsertCategory(Map<String, dynamic> category) async {
    final res = await _client.from('Category').upsert(category).select().single();
    return res['id'].toString();
  }

  /// Create or update a menu item (Cake)
  static Future<String> upsertCake(Map<String, dynamic> cake) async {
    // Remove the legacy 'category' string field if it exists in the payload
    final data = Map<String, dynamic>.from(cake);
    data.remove('category');
    
    final res = await _client.from('Cake').upsert(data).select().single();
    return res['id'].toString();
  }

  /// Create or update a cake option
  static Future<void> upsertCakeOption(Map<String, dynamic> option) async {
    await _client.from('CakeOption').upsert(option);
  }

  /// Soft delete a cake
  static Future<void> deleteCake(String id) async {
    await _client.from('Cake').update({'deletedAt': DateTime.now().toIso8601String()}).eq('id', id);
  }
}
