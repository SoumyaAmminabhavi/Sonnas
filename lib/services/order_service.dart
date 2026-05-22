import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class OrderService {
  static SupabaseClient get _client => SupabaseService.client;

  static Stream<T> _debounceStream<T>(Stream<T> source, Duration duration) {
    Timer? debounceTimer;
    StreamSubscription<T>? sub;
    final controller = StreamController<T>.broadcast();

    controller.onListen = () {
      sub = source.listen(
        (data) {
          debounceTimer?.cancel();
          debounceTimer = Timer(duration, () {
            if (!controller.isClosed) controller.add(data);
          });
        },
        onError: (Object e, StackTrace st) {
          debounceTimer?.cancel();
          if (!controller.isClosed) controller.addError(e, st);
        },
        onDone: () {
          debounceTimer?.cancel();
          controller.close();
        },
      );
    };

    controller.onCancel = () {
      debounceTimer?.cancel();
      sub?.cancel();
    };

    return controller.stream;
  }

  static Stream<R> _switchMapAsync<T, R>(Stream<T> source, Future<R> Function(T) mapper) {
    StreamSubscription<T>? sub;
    final controller = StreamController<R>.broadcast();
    int latestRequestId = 0;

    controller.onListen = () {
      sub = source.listen(
        (data) async {
          final requestId = ++latestRequestId;
          try {
            final result = await mapper(data);
            if (requestId == latestRequestId && !controller.isClosed) {
              controller.add(result);
            }
          } catch (e, st) {
            if (requestId == latestRequestId && !controller.isClosed) {
              controller.addError(e, st);
            }
          }
        },
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
        onDone: () {
          controller.close();
        },
      );
    };

    controller.onCancel = () => sub?.cancel();

    return controller.stream;
  }

  /// Real-time stream for orders (limited to recent 90 days to prevent memory bloat)
  static Stream<List<Map<String, dynamic>>> getAllOrdersStream({int limit = OrderConstants.defaultOrderLimit}) {
    final cutoff = DateTime.now().subtract(OrderConstants.orderHistoryWindow).toIso8601String();
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .gte('createdAt', cutoff)
        .order('createdAt', ascending: false)
        .limit(limit);
  }

  /// Launch Google Maps for a delivery address
  static Future<void> launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch maps");
    }
  }

  /// Format price with currency symbol (converts minor units to major)
  static String formatPrice(dynamic price) {
    if (price == null) return "${PriceConstants.currencySymbol}0";
    try {
      final double normalized = PriceConstants.normalizePrice(price);
      if (normalized == normalized.toInt().toDouble()) {
        return "${PriceConstants.currencySymbol}${normalized.toInt()}";
      }
      return "${PriceConstants.currencySymbol}${normalized.toStringAsFixed(2)}";
    } catch (e) {
      return "${PriceConstants.currencySymbol}$price";
    }
  }

  /// Fetch a single order by ID or Order Number.
  static Future<Map<String, dynamic>?> fetchOrderByIdOrNumber(String idOrNumber) async {
    try {
      final cleanInput = idOrNumber.replaceAll(RegExp(r'^(SN-|SPC |SPC-|ORD-|#)'), '');
      if (cleanInput.isEmpty) return null;
      
      final escapedInput = cleanInput.replaceAll('%', '\\%').replaceAll('_', '\\_');
      
      // Try ID, then OrderNumber
      var res = await _client
          .from('Order')
          .select('*, WhatsAppConversation(*)')
          .eq('id', idOrNumber)
          .maybeSingle();

      res ??= await _client
          .from('Order')
          .select('*, WhatsAppConversation(*)')
          .eq('orderNumber', cleanInput)
          .maybeSingle();

      if (res == null) {
        final matches = List<Map<String, dynamic>>.from(await _client
            .from('Order')
            .select('*, WhatsAppConversation(*)')
            .ilike('orderNumber', '%$escapedInput%')
            .limit(2));
        if (matches.length == 1) {
          res = matches.first;
        }
      }
      
      return res;
    } catch (e) {
      debugPrint('⚠️ Fetch Order Failed: $e');
      rethrow;
    }
  }

  static Stream<Map<String, dynamic>?> getSingleOrderStream(String idOrNumber) async* {
    final cleanInput = idOrNumber.replaceAll(RegExp(r'^(SN-|SPC |SPC-|ORD-|#)'), '');
    if (cleanInput.isEmpty) {
      yield null;
      return;
    }
    final escapedInput = cleanInput.replaceAll('%', '\\%').replaceAll('_', '\\_');

    try {
      var resolved = await _client
          .from('Order')
          .select('id')
          .eq('id', idOrNumber)
          .maybeSingle();

      resolved ??= await _client
          .from('Order')
          .select('id')
          .eq('orderNumber', cleanInput)
          .maybeSingle();

      if (resolved == null) {
        final matches = List<Map<String, dynamic>>.from(await _client
            .from('Order')
            .select('id')
            .ilike('orderNumber', '%$escapedInput%')
            .limit(2));
        if (matches.length == 1) {
          resolved = matches.first;
        }
      }

      if (resolved == null) {
        yield null;
        return;
      }

      final resolvedId = resolved['id'].toString();
      yield* _client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('id', resolvedId)
          .map((list) => list.isEmpty ? null : list.first);
    } catch (e) {
      debugPrint('⚠️ Order Stream Init Failed: $e');
      rethrow;
    }
  }

  /// Real-time stream for recent orders with joined data (debounced to prevent query storms)
  static Stream<List<Map<String, dynamic>>> getRecentOrdersStream() {
    final rawStream = _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false);

    return _switchMapAsync(
      _debounceStream(rawStream, OrderConstants.streamDebounce),
      (_) async {
        final res = await _client
            .from('Order')
            .select('*, WhatsAppConversation(*), items:OrderItem(*)')
            .order('createdAt', ascending: false)
            .limit(OrderConstants.recentOrdersLimit);
        return List<Map<String, dynamic>>.from(res);
      },
    );
  }

  /// Bulk fetch items for multiple orders
  static Future<List<Map<String, dynamic>>> fetchBulkOrderItems(List<String> orderIds) async {
    if (orderIds.isEmpty) return [];
    final res = await _client.from('OrderItem').select().inFilter('orderId', orderIds);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch all orders (Unified)
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final res = await _client.from('Order').select().order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(res).map((o) {
        return {
          ...o,
          'orderType': o['source']?.toString() ?? 'APP',
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Order Fetch failed: $e');
      rethrow;
    }
  }

  /// Fetch items for any order (Unified)
  static Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    try {
      final res = await _client.from('OrderItem').select().eq('orderId', orderId);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Fetch Order Items failed: $e');
      rethrow;
    }
  }

  /// Stats stream for dashboard charts
  static Stream<Map<int, double>> getSalesChartStream({required String range, int? targetMonth, int? targetYear}) {
    return _client.from('Order').stream(primaryKey: ['id']).eq('paymentStatus', 'PAID').map((orders) {
      final Map<int, double> chartData = {};
      
      final now = DateTime.now();
      DateTime windowStart;
      DateTime windowEnd;
      
      if (range == 'today') {
        windowStart = DateTime(now.year, now.month, now.day);
        windowEnd = windowStart.add(const Duration(days: 1));
      } else if (range == 'weekly') {
        windowStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        windowEnd = windowStart.add(const Duration(days: 7));
      } else if (range == 'monthly') {
        final year = targetYear ?? now.year;
        final month = targetMonth ?? now.month;
        windowStart = DateTime(year, month, 1);
        windowEnd = DateTime(year, month + 1, 1);
      } else {
        final year = targetYear ?? now.year;
        if (targetMonth != null) {
          windowStart = DateTime(year, targetMonth, 1);
          windowEnd = DateTime(year, targetMonth + 1, 1);
        } else {
          windowStart = DateTime(year, 1, 1);
          windowEnd = DateTime(year + 1, 1, 1);
        }
      }
      
      for (final order in orders) {
        final dateStr = order['createdAt']?.toString();
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        if (date.isBefore(windowStart) || date.isAtSameMomentAs(windowEnd) || date.isAfter(windowEnd)) continue;

        // Apply Month/Year filters if provided
        if (targetMonth != null && date.month != targetMonth) continue;
        if (targetYear != null && date.year != targetYear) continue;
        
        // Only count PAID orders in revenue
        if ((order['paymentStatus']?.toString().toUpperCase()) != 'PAID') continue;

        final amount = PriceConstants.normalizePrice(order['totalPrice']);

        int key;
        if (range == 'today') {
          key = date.hour;
        } else if (range == 'weekly') {
          key = date.weekday;
        } else if (range == 'monthly') {
          key = date.day;
        } else {
          key = date.month;
        }

        chartData[key] = (chartData[key] ?? 0) + amount;
      }
      return chartData;
    });
  }

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedStatus = status.toUpperCase();
    final Map<String, dynamic> payload = {
      'status': normalizedStatus,
    };
    
    if (normalizedStatus == 'CONFIRMED') payload['confirmedAt'] = now;
    if (normalizedStatus == 'DELIVERED') payload['deliveredAt'] = now;
    if (normalizedStatus == 'COMPLETED') payload['completedAt'] = now;
    if (normalizedStatus == 'CANCELLED') payload['cancelledAt'] = now;
    
    try {
      await _client.from('Order').update(payload).eq('id', orderId);
    } catch (e) {
      debugPrint('❌ Order Status Update Failed: $e');
      rethrow;
    }
  }

  /// Update payment status
  static Future<void> updatePaymentStatus(String orderId, String status) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedStatus = status.toUpperCase();
    final Map<String, dynamic> payload = {
      'paymentStatus': normalizedStatus,
    };
    
    if (normalizedStatus == 'PAID') {
      payload['paidAt'] = now;
    } else {
      payload['paidAt'] = null;
    }
    
    try {
      await _client.from('Order').update(payload).eq('id', orderId);
    } catch (e) {
      debugPrint('❌ Payment Status Update Failed: $e');
      rethrow;
    }
  }

  /// Format phone number for display
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return "Contact hidden";
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) return "+91$clean";
    if (clean.startsWith('91') && clean.length == 12) return "+$clean";
    return phone;
  }

  /// Real-time stream for kitchen with joined data (debounced to prevent query storms)
  static Stream<List<Map<String, dynamic>>> getKitchenOrdersStream() {
    final rawStream = _client
        .from('Order')
        .stream(primaryKey: ['id']);

    return _switchMapAsync(
      _debounceStream(rawStream, OrderConstants.streamDebounce),
      (_) async {
        final res = await _client
            .from('Order')
            .select('*, WhatsAppConversation(*), items:OrderItem(*)')
            .inFilter('status', ['PENDING', 'CONFIRMED', 'OUT_FOR_DELIVERY'])
            .order('createdAt', ascending: true);
        return List<Map<String, dynamic>>.from(res);
      },
    );
  }

  /// Submit a public order atomically via RPC.
  static Future<void> submitPublicOrder(Map<String, dynamic> data) async {
    final orderData = Map<String, dynamic>.from(data);
    
    orderData['source'] = OrderConstants.defaultSource;
    
    try {
      final rawItems = orderData.remove('items');
      if (rawItems is! List) {
        throw ArgumentError('items must be a List');
      }
      if (rawItems.isEmpty) {
        throw ArgumentError('items must not be empty');
      }
      final items = rawItems.map((e) {
        if (e is! Map) throw ArgumentError('Each item must be a Map');
        return Map<String, dynamic>.from(e);
      }).toList();
      
      await _client.rpc<void>(
        'create_order_with_items',
        params: {
          'p_order_data': orderData,
          'p_items_data': items,
        },
      );
    } catch (e) {
      debugPrint('❌ Submit Order failed: $e');
      rethrow;
    }
  }

  /// Launch WhatsApp with a message
  static Future<void> launchWhatsApp(String? phone, String message) async {
    if (phone == null || phone.isEmpty) return;
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = "91$cleanPhone";

    final query = Uri.encodeComponent(message);
    final url = Uri.parse("https://wa.me/$cleanPhone?text=$query");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  /// Robust date parsing
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
      return null;
    }
  }
}
