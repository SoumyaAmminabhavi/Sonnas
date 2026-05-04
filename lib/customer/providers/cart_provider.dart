import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({required this.name, required this.price, required this.imageUrl, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String name, double price, String imageUrl) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(name: name, price: price, imageUrl: imageUrl));
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.removeWhere((item) => item.name == name);
    notifyListeners();
  }

  void decrementItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
