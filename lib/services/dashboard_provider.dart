import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_service.dart';
import 'order_service.dart';

/// Cached provider for the bakery menu.
/// Solves the "Infinite Query Loop" by caching the menu data.
final menuProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await MenuService.fetchMenu();
});

/// Real-time stream of all orders.
final ordersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return OrderService.getAllOrdersStream();
});

/// Real-time stream of recent orders (with items).
final recentOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return OrderService.getRecentOrdersStream();
});

/// Reactive dashboard stats computed locally from the orders stream.
/// This avoids redundant "stats" network calls.
final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  
  return ordersAsync.when(
    data: (orders) {
      double totalRevenue = 0;
      final Set<String> customers = {};
      
      for (var order in orders) {
        final price = (double.tryParse(order['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0) / 100.0;
        if ((order['paymentStatus'] ?? 'PENDING') == 'PAID') {
          totalRevenue += price;
        }
        if (order['phone'] != null) customers.add(order['phone']);
      }
      
      final paidOrders = orders.where((o) => (o['paymentStatus'] ?? 'PENDING') == 'PAID').toList();
      
      return {
        'totalOrders': orders.length,
        'totalRevenue': totalRevenue,
        'activeCustomers': customers.length,
        'avgOrderValue': paidOrders.isEmpty ? 0 : totalRevenue / paidOrders.length,
      };
    },
    loading: () => {
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'activeCustomers': 0,
      'avgOrderValue': 0,
      'isLoading': true,
    },
    error: (_, __) => {
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'activeCustomers': 0,
      'avgOrderValue': 0,
      'error': true,
    },
  );
});
