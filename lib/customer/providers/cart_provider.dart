import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({required this.name, required this.price, required this.imageUrl, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  double get total {
    return _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String name, double price, String imageUrl) {
    if (_items.containsKey(name)) {
      _items[name]!.quantity++;
    } else {
      _items[name] = CartItem(name: name, price: price, imageUrl: imageUrl);
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.remove(name);
    notifyListeners();
  }

  void decrementItem(String name) {
    if (_items.containsKey(name)) {
      if (_items[name]!.quantity > 1) {
        _items[name]!.quantity--;
      } else {
        _items.remove(name);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
