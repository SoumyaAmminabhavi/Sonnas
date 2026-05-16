import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MenuService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time menu updates
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
      debugPrint('⚠️ Joined menu fetch failed: $e');

      final cakes = List<Map<String, dynamic>>.from(
        await _client.from('Cake').select('*').order('name'),
      );
      final cakeIds = cakes.map((c) => c['id']).whereType<String>().toList();
      final categories = List<Map<String, dynamic>>.from(
        await _client.from('Category').select('*'),
      );
      final options = cakeIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client.from('CakeOption').select('*').inFilter('cakeId', cakeIds),
            );

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
      final data = Map<String, dynamic>.from(category);
      data['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      final res = await _client.from('Category').upsert(data).select().single();
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
      data['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      
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
      final cakeIdRaw = option['cakeId'];
      final sizeRaw = option['size'];
      if (cakeIdRaw == null || sizeRaw == null) {
        throw ArgumentError('cakeId and size are required for CakeOption');
      }
      final String cakeId = cakeIdRaw.toString();
      final String size = sizeRaw.toString();

      // Safety check: Check for existing option with same size to avoid constraint violations
      final existing = await _client
          .from('CakeOption')
          .select('id')
          .eq('cakeId', cakeId)
          .eq('size', size)
          .maybeSingle();
      
      final data = Map<String, dynamic>.from(option);
      final callerProvidedId = option.containsKey('id') ? option['id']?.toString() : null;

      if (existing != null) {
        if (callerProvidedId == null) {
          // Create path: a row already exists for this (cakeId, size) — treat as conflict
          throw StateError('CakeOption for cakeId=$cakeId size=$size already exists (id=${existing['id']}). Provide the existing id to update it.');
        } else if (existing['id'].toString() != callerProvidedId) {
          // Update path: caller's id doesn't match the found row — refuse to retarget
          throw StateError('CakeOption id mismatch: caller provided $callerProvidedId but existing row for cakeId=$cakeId size=$size has id=${existing['id']}.');
        }
        // Update path: ids match — allow the upsert to proceed normally
      }
      data['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      await _client.from('CakeOption').upsert(data);
    } catch (e) {
      debugPrint('⚠️ Upsert CakeOption Failed: $e');
      rethrow;
    }
  }

  /// Permanently delete a product and its options
  static Future<void> deleteCake(String id) async {
    try {
      await _client.from('Cake').delete().eq('id', id);
    } catch (e) {
      debugPrint('⚠️ Delete Failed: $e');
      rethrow;
    }
  }
}
