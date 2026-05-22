import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    id: json['id'] as String,
    cakeId: json['cakeId'] as String?,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    imageUrl: (json['imageUrl'] as String?) ?? '',
    quantity: (json['quantity'] as int?) ?? 1,
  );
}

class CustomerCartState {
  final Map<String, CartItem> items;

  const CustomerCartState({this.items = const {}});

  List<CartItem> get itemList => items.values.toList();

  double get total {
    return items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  CustomerCartState copyWith({Map<String, CartItem>? items}) {
    return CustomerCartState(items: items ?? this.items);
  }
}

class CustomerCartNotifier extends Notifier<CustomerCartState> {
  static const String _cartKey = 'persistent_cart_items';

  @override
  CustomerCartState build() {
    _loadCartFromStorage();
    return const CustomerCartState();
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> decodedList = jsonDecode(cartJson) as List<dynamic>;
        final loaded = <String, CartItem>{};
        for (var itemMap in decodedList) {
          final item = CartItem.fromJson(itemMap as Map<String, dynamic>);
          loaded[item.id] = item;
        }
        state = CustomerCartState(items: loaded);
      }
    } catch (e) {
      debugPrint("Error loading persistent cart: $e");
    }
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = state.items.values.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(cartList));
    } catch (e) {
      debugPrint("Error saving cart: $e");
    }
  }

  void addItem(String id, String name, double price, String imageUrl, {int quantity = 1, String? cakeId}) {
    if (quantity <= 0) throw ArgumentError("Quantity must be greater than zero");
    final updated = Map<String, CartItem>.from(state.items);
    if (updated.containsKey(id)) {
      updated[id]!.quantity += quantity;
    } else {
      updated[id] = CartItem(
        id: id,
        cakeId: cakeId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
      );
    }
    HapticService.light();
    state = CustomerCartState(items: updated);
    _saveCartToStorage();
  }

  void removeItem(String id) {
    final updated = Map<String, CartItem>.from(state.items);
    updated.remove(id);
    HapticService.selection();
    state = CustomerCartState(items: updated);
    _saveCartToStorage();
  }

  void decrementItem(String id) {
    final updated = Map<String, CartItem>.from(state.items);
    if (updated.containsKey(id)) {
      if (updated[id]!.quantity > 1) {
        updated[id]!.quantity--;
      } else {
        updated.remove(id);
      }
      HapticService.selection();
      state = CustomerCartState(items: updated);
      _saveCartToStorage();
    }
  }

  void clear() {
    state = const CustomerCartState();
    _saveCartToStorage();
  }
}

final customerCartProvider = NotifierProvider<CustomerCartNotifier, CustomerCartState>(CustomerCartNotifier.new);
