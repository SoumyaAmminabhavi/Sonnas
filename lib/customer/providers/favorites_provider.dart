import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/haptic_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];
  final String _storageKey = 'sonnas_favorites';

  List<Map<String, dynamic>> get favorites => _favorites;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_storageKey);
      if (favoritesJson != null) {
        _favorites = List<Map<String, dynamic>>.from(json.decode(favoritesJson) as List<dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final String itemId = (item['id'] as String?) ?? (item['title'] as String?) ?? '';
    final int index = _favorites.indexWhere((f) => (f['id']?.toString() ?? f['title']) == itemId);

    if (index >= 0) {
      _favorites.removeAt(index);
      HapticService.selection();
    } else {
      _favorites.add({
        'id': item['id'],
        'title': item['title'],
        'price': item['price'],
        'image': item['image'],
      });
      HapticService.light();
    }

    notifyListeners();
    _saveToDisk();
  }

  bool isFavorite(String? id, String title) {
    return _favorites.any((f) => (f['id']?.toString() ?? f['title']) == (id ?? title));
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(_favorites));
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }
}
