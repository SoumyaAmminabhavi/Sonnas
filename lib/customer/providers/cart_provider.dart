import 'package:flutter/material.dart';
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
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  double get total {
    return _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
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
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    HapticService.selection();
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
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
