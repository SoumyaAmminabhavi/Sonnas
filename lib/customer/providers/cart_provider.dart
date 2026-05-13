import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, required this.imageUrl, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  double get total {
    return _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String id, String name, double price, String imageUrl, {int quantity = 1}) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity += quantity;
    } else {
      _items[id] = CartItem(id: id, name: name, price: price, imageUrl: imageUrl, quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void decrementItem(String id) {
    if (_items.containsKey(id)) {
      if (_items[id]!.quantity > 1) {
        _items[id]!.quantity--;
      } else {
        _items.remove(id);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
