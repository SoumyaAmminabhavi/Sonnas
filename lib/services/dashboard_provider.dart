import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_service.dart';
import 'order_service.dart';
import 'constants.dart';
import 'feedback_service.dart';

/// Cached provider for the bakery menu.
final menuProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  return await MenuService.fetchMenu();
});

/// Provider for all categories (including those without cakes).
final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return await MenuService.fetchCategories();
    });

/// Provider for specific order items, cached by orderId.
final orderItemsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, orderId) async {
      return await OrderService.fetchOrderItems(orderId);
    });

/// Real-time stream of all orders (limited to recent 90 days).
final ordersStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return OrderService.getAllOrdersStream();
    });

/// Real-time stream of recent orders (with items).
final recentOrdersProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return OrderService.getRecentOrdersStream();
    });

/// Reactive dashboard stats computed locally from the orders stream.
final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);

  return ordersAsync.when(
    data: (orders) {
      double totalRevenue = 0;
      final Set<String> customers = {};
      int paidOrderCount = 0;

      for (var order in orders) {
        final price = PriceConstants.normalizePrice(order['totalPrice']);

        final pStatus =
            (order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
        if (pStatus == 'PAID') {
          totalRevenue += price;
          paidOrderCount++;
        }

        final rawPhone = order['customerPhone'] ?? order['phone'];
        if (rawPhone != null) {
          final digitsOnly = rawPhone.toString().replaceAll(RegExp(r'\D'), '');
          final phone =
              digitsOnly.length > 10
                  ? digitsOnly.substring(digitsOnly.length - 10)
                  : digitsOnly;
          if (phone.isNotEmpty) {
            customers.add(phone);
          }
        }
      }

      return <String, dynamic>{
        'totalOrders': orders.length,
        'totalRevenue': totalRevenue,
        'activeCustomers': customers.length,
        'avgOrderValue':
            paidOrderCount == 0 ? 0.0 : totalRevenue / paidOrderCount,
      };
    },
    loading:
        () => <String, dynamic>{
          'totalOrders': 0,
          'totalRevenue': 0.0,
          'activeCustomers': 0,
          'avgOrderValue': 0.0,
          'isLoading': true,
        },
    error:
        (error, _) => <String, dynamic>{
          'totalOrders': 0,
          'totalRevenue': 0.0,
          'activeCustomers': 0,
          'avgOrderValue': 0.0,
          'error': true,
        },
  );
});

class SalesChartParam {
  final String range;
  final int? targetMonth;
  final int? targetYear;

  const SalesChartParam({
    required this.range,
    this.targetMonth,
    this.targetYear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesChartParam &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          targetMonth == other.targetMonth &&
          targetYear == other.targetYear;

  @override
  int get hashCode =>
      range.hashCode ^ targetMonth.hashCode ^ targetYear.hashCode;
}

final salesChartProvider = StreamProvider.autoDispose
    .family<Map<int, SalesChartDataPoint>, SalesChartParam>((ref, param) {
      return OrderService.getSalesChartStream(
        range: param.range,
        targetMonth: param.targetMonth,
        targetYear: param.targetYear,
      );
    });

/// Cached provider for fetching and refreshing a single order by ID or number
final orderNotifierProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, arg) async {
      final cleanId = arg.replaceAll(RegExp(r'[#]'), '');
      return await OrderService.fetchOrderByIdOrNumber(cleanId);
    });

/// Real-time stream of customer feedback/reviews.
final feedbackStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return FeedbackService.getFeedbackStream();
    });
