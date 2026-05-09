import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_service.dart';

/// Cached provider for items within a specific order.
/// Prevents redundant network calls when the dashboard re-renders.
final orderItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  return await OrderService.fetchOrderItems(orderId);
});
