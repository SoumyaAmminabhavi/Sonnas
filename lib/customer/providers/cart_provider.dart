import 'package:flutter/material.dart';

import 'package:flutter_riverpod/legacy.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/haptic_service.dart';

class CartItem {
  final String id;
  final String? cakeId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    this.cakeId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cakeId': cakeId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    cakeId: json['cakeId'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    imageUrl: json['imageUrl'] ?? '',
    quantity: json['quantity'] ?? 1,
  );
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  static const String _cartKey = 'persistent_cart_items';

  List<CartItem> get items => _items.values.toList();

  double get total {
    return _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  CartProvider() {
    _loadCartFromStorage();
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> decodedList = jsonDecode(cartJson);
        _items.clear();
        for (var itemMap in decodedList) {
          final item = CartItem.fromJson(itemMap);
          _items[item.id] = item;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading persistent cart: $e");
    }
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = _items.values.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(cartList));
    } catch (e) {
      debugPrint("Error saving cart: $e");
    }
  }

  void addItem(String id, String name, double price, String imageUrl, {int quantity = 1, String? cakeId}) {
    if (quantity <= 0) throw ArgumentError("Quantity must be greater than zero");
    if (_items.containsKey(id)) {
      _items[id]!.quantity += quantity;
    } else {
      _items[id] = CartItem(
        id: id,
        cakeId: cakeId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
      );
    }
    HapticService.light();
    _saveCartToStorage();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    HapticService.selection();
    _saveCartToStorage();
    notifyListeners();
  }

  void decrementItem(String id) {
    if (_items.containsKey(id)) {
      if (_items[id]!.quantity > 1) {
        _items[id]!.quantity--;
      } else {
        _items.remove(id);
      }
      HapticService.selection();
      _saveCartToStorage();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCartToStorage();
    notifyListeners();
  }
}

final cartProvider = ChangeNotifierProvider<CartProvider>((ref) => CartProvider());
