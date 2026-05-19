import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates with joined data
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    final subscriptions = <StreamSubscription>[];
    var refreshRequestId = 0;

    Future<void> refresh() async {
      final requestId = ++refreshRequestId;
      try {
        final data = await fetchMenu();
        if (requestId != refreshRequestId) return;
        if (!controller.isClosed) controller.add(data);
      } catch (e, stackTrace) {
        if (requestId != refreshRequestId) return;
        if (!controller.isClosed) controller.addError(e, stackTrace);
      }
    }

    void handleEvent(_) => refresh();

    controller.onListen = () {
      if (subscriptions.isEmpty) {
        subscriptions.add(_client.from('Cake').stream(primaryKey: ['id']).listen(handleEvent));
        subscriptions.add(_client.from('Category').stream(primaryKey: ['id']).listen(handleEvent));
        subscriptions.add(_client.from('CakeOption').stream(primaryKey: ['id']).listen(handleEvent));
        refresh();
      }
    };

    controller.onCancel = () {
      // Cancel subscriptions to prevent memory leaks, but keep controller open for reuse
      for (final sub in subscriptions) {
        sub.cancel();
      }
      subscriptions.clear();
    };

    return controller.stream;
  }

  /// Fetch all menu items with full category and option data
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      final res = await _client
          .from('Cake')
          .select('*, Category(*), CakeOption(*)')
          .order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Joined menu fetch failed, attempting fallback: $e');
      
      try {
        final cakes = List<Map<String, dynamic>>.from(
          await _client.from('Cake').select('*').order('name'),
        );
        final cakeIds = cakes.map((c) => c['id']?.toString()).where((id) => id != null).toList();
        
        // Parallel fetch for categories and options
        final results = await Future.wait([
          _client.from('Category').select('*'),
          cakeIds.isEmpty 
              ? Future.value([]) 
              : _client.from('CakeOption').select('*').inFilter('cakeId', cakeIds),
        ]);

        final categories = List<Map<String, dynamic>>.from(results[0]);
        final options = List<Map<String, dynamic>>.from(results[1]);

        final categoriesById = {
          for (final c in categories) c['id'].toString(): c,
        };

        return cakes.map((cake) {
          final cakeId = cake['id'].toString();
          final categoryId = cake['categoryId']?.toString();
          return {
            ...cake,
            'Category': categoryId == null ? null : categoriesById[categoryId],
            'CakeOption': options.where((o) => o['cakeId'].toString() == cakeId).toList(),
          };
        }).toList();
      } catch (fallbackError) {
        debugPrint('❌ Fallback menu fetch failed: $fallbackError');
        rethrow;
      }
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
    final data = Map<String, dynamic>.from(category);
    data['updatedAt'] = category['updatedAt'] ?? DateTime.now().toUtc().toIso8601String();
    final res = await _client.from('Category').upsert(data).select().single();
    return res['id'].toString();
  }

  /// Create or update a menu item (Cake)
  static Future<String> upsertCake(Map<String, dynamic> cake) async {
    final data = Map<String, dynamic>.from(cake);
    data.remove('category');
    data['updatedAt'] = cake['updatedAt'] ?? DateTime.now().toUtc().toIso8601String();
    
    final res = await _client.from('Cake').upsert(data).select().single();
    return res['id'].toString();
  }

  /// Create or update a cake option
  static Future<void> upsertCakeOption(Map<String, dynamic> option) async {
    final cakeIdRaw = option['cakeId'];
    final sizeRaw = option['size'];
    if (cakeIdRaw == null || sizeRaw == null) {
      throw ArgumentError('cakeId and size are required for CakeOption');
    }
    final String cakeId = cakeIdRaw.toString();
    final String size = sizeRaw.toString().trim();
    if (size.isEmpty) {
      throw ArgumentError('size must not be empty or whitespace-only');
    }

    final data = Map<String, dynamic>.from(option);
    data['cakeId'] = cakeId;
    data['size'] = size;
    data['updatedAt'] = option['updatedAt'] ?? DateTime.now().toUtc().toIso8601String();

    try {
      await _client.from('CakeOption').upsert(data);
    } catch (dbError) {
      final errStr = dbError.toString();
      if (errStr.contains('23505') || errStr.toLowerCase().contains('unique constraint')) {
         throw StateError('A CakeOption for cakeId=$cakeId and size=$size already exists. Please provide the correct ID to update the existing record.');
      }
      debugPrint('⚠️ Upsert CakeOption Failed: $dbError');
      rethrow;
    }
  }

  /// Permanently delete a product (CakeOption cascade-deletes via DB)
  static Future<void> deleteCake(String id) async {
    try {
      await _client.from('Cake').delete().eq('id', id);
    } catch (e) {
      debugPrint('⚠️ Delete Failed: $e');
      rethrow;
    }
  }

  /// Permanently delete a category
  static Future<void> deleteCategory(String id) async {
    try {
      await _client.from('Category').delete().eq('id', id);
    } catch (e) {
      debugPrint('⚠️ Delete Category Failed: $e');
      rethrow;
    }
  }
}
