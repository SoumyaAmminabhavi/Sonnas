import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    return _client
        .from('Cake')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((list) => list.where((item) => item['deletedAt'] == null).toList());
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

  /// Fetch all categories that have at least one active product
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      // We only want categories that have active cakes.
      // This automatically "deletes" empty categories from the UI.
      final res = await _client
          .from('Category')
          .select('*, Cake!inner(id)')
          .isFilter('Cake.deletedAt', null)
          .order('sortOrder');
          
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      // If the join fails or returns nothing, we return an empty list
      debugPrint('ℹ️ Category fetch filtered (might be empty): $e');
      return [];
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
      await _client.from('CakeOption').upsert(option);
    } catch (e) {
      debugPrint('⚠️ Upsert CakeOption Failed: $e');
      rethrow;
    }
  }

  /// Permanently delete a product and clean up its category if empty
  static Future<void> deleteCake(String id) async {
    try {
      // 1. Get the categoryId before we delete the cake
      final cakeRes = await _client
          .from('Cake')
          .select('categoryId')
          .eq('id', id)
          .maybeSingle();
      
      final String? categoryId = cakeRes?['categoryId'];

      // 2. Perform HARD DELETE (this will also delete CakeOptions due to Cascade)
      await _client.from('Cake').delete().eq('id', id);

      // 3. Smart Category Cleanup
      if (categoryId != null) {
        // Check if any other cakes (active or archived) still use this category
        final remainingCakes = await _client
            .from('Cake')
            .select('id')
            .eq('categoryId', categoryId)
            .limit(1);

        if (remainingCakes.isEmpty) {
          // No more products in this category at all. Delete it too.
          debugPrint('🧹 Cleaning up empty category: $categoryId');
          await _client.from('Category').delete().eq('id', categoryId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Hard Delete Failed: $e');
      rethrow;
    }
  }
}
