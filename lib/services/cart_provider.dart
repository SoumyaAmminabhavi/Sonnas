import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class CartItem {
  final Map<String, dynamic> product; // Raw menu item
  int quantity;
  final String? selectedOptions;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedOptions,
  });

  double get totalPrice => (double.tryParse(product['price']?.toString() ?? '0') ?? 0) * quantity;
}

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  CartState({this.items = const [], this.isLoading = false});

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items, bool? isLoading}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState();

  void addItem(Map<String, dynamic> product, {int quantity = 1, String? options}) {
    final existingIndex = state.items.indexWhere((item) => 
      item.product['id'] == product['id'] && item.selectedOptions == options
    );

    if (existingIndex != null && existingIndex != -1) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex].quantity += quantity;
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity, selectedOptions: options)]);
    }
  }

  void removeItem(int index) {
    final updatedItems = List<CartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(int index, int delta) {
    final updatedItems = List<CartItem>.from(state.items);
    final newQty = updatedItems[index].quantity + delta;
    if (newQty > 0) {
      updatedItems[index].quantity = newQty;
      state = state.copyWith(items: updatedItems);
    } else {
      removeItem(index);
    }
  }

  void clear() {
    state = CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
