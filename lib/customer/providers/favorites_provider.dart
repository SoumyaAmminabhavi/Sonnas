import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/haptic_service.dart';

class CustomerFavoritesState {
  final List<Map<String, dynamic>> items;

  const CustomerFavoritesState({this.items = const []});

  bool isFavorite(String? id, String title) {
    return items.any((f) => (f['id']?.toString() ?? f['title']) == (id ?? title));
  }

  CustomerFavoritesState copyWith({List<Map<String, dynamic>>? items}) {
    return CustomerFavoritesState(items: items ?? this.items);
  }
}

class CustomerFavoritesNotifier extends Notifier<CustomerFavoritesState> {
  final String _storageKey = 'sonnas_favorites';

  @override
  CustomerFavoritesState build() {
    _loadFavorites();
    return const CustomerFavoritesState();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_storageKey);
      if (favoritesJson != null) {
        final loaded = List<Map<String, dynamic>>.from(json.decode(favoritesJson) as List<dynamic>);
        state = CustomerFavoritesState(items: loaded);
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final String itemId = item['id']?.toString() ?? item['title']?.toString() ?? '';
    final index = state.items.indexWhere((f) => (f['id']?.toString() ?? f['title']) == itemId);

    final updated = List<Map<String, dynamic>>.from(state.items);
    if (index >= 0) {
      updated.removeAt(index);
      HapticService.selection();
    } else {
      updated.add({
        'id': item['id'],
        'title': item['title'],
        'price': item['price'],
        'image': item['image'],
      });
      HapticService.light();
    }

    state = CustomerFavoritesState(items: updated);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(state.items));
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }
}

final customerFavoritesProvider = NotifierProvider<CustomerFavoritesNotifier, CustomerFavoritesState>(CustomerFavoritesNotifier.new);
