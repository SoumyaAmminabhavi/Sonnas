import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
  /// Real-time menu updates with joined data
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    // We stream the raw Cake table to detect changes, then fetch the full joined data
    return _client
        .from('Cake')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchMenu(includeArchived: false));
  }

  /// Fetch all menu items with full category and option data
  static Future<List<Map<String, dynamic>>> fetchMenu({bool includeArchived = false}) async {
    try {
      // Fetch active cakes with their categories and options
      // Note: Join syntax '*, Category(*), CakeOption(*)'
      var query = _client
          .from('Cake')
          .select('*, Category(*), CakeOption(*)');
      
      if (!includeArchived) {
        query = query.isFilter('deletedAt', null);
      }
      
      final res = await query.order('name');
      
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Menu Fetch Failed: $e');
      rethrow;
    }
  }

  /// Fetch all categories
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final res = await _client
          .from('Category')
          .select('*')
          .order('sortOrder');
          
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Category fetch failed: $e');
      rethrow;
    }
  }

  /// Create or update a category
  static Future<String> upsertCategory(Map<String, dynamic> category) async {
    try {
      final res = await _client.from('Category').upsert(category).select().single();
      return res['id'].toString();
    } catch (e) {
      debugPrint('⚠️ Upsert Category Failed: $e');
      rethrow;
    }
  }

  /// Create or update a menu item (Cake)
  static Future<String> upsertCake(Map<String, dynamic> cake) async {
    try {
      // Remove the legacy 'category' string field if it exists in the payload
      final data = Map<String, dynamic>.from(cake);
      data.remove('category');
      
      final res = await _client.from('Cake').upsert(data).select().single();
      return res['id'].toString();
    } catch (e) {
      debugPrint('⚠️ Upsert Cake Failed: $e');
      rethrow;
    }
  }

  /// Create or update a cake option
  static Future<void> upsertCakeOption(Map<String, dynamic> option) async {
    try {
      final String cakeId = option['cakeId'].toString();
      final String size = option['size'].toString();

      // Safety check: Check for existing option with same size to avoid constraint violations
      final existing = await _client
          .from('CakeOption')
          .select('id')
          .eq('cakeId', cakeId)
          .eq('size', size)
          .maybeSingle();
      
      final data = Map<String, dynamic>.from(option);
      if (existing != null) {
        data['id'] = existing['id']; // Force update existing row
      }

      await _client.from('CakeOption').upsert(data);
    } catch (e) {
      debugPrint('⚠️ Upsert CakeOption Failed: $e');
      rethrow;
    }
  }

  /// Permanently delete a product and clean up its category if empty
  static Future<void> deleteCake(String id) async {
    try {
      // 1. Perform HARD DELETE (this will also delete CakeOptions due to Cascade)
      await _client.from('Cake').delete().eq('id', id);

      // 3. Keep empty categories; they are now user-managed records.
    } catch (e) {
      debugPrint('⚠️ Hard Delete Failed: $e');
      rethrow;
    }
  }
}
