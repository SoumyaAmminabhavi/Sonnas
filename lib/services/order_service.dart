import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time stream for ALL orders
  static Stream<List<Map<String, dynamic>>> getAllOrdersStream() {
    return _client.from('Order').stream(primaryKey: ['id']).order('createdAt', ascending: false);
  }

  /// Launch Google Maps for a delivery address
  static Future<void> launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch maps: $url");
    }
  }

  /// Format price with currency symbol (converts minor units to major)
  static String formatPrice(dynamic price) {
    if (price == null) return "₹0";
    try {
      double p;
      if (price is num) {
        p = price.toDouble() / 100.0;
      } else {
        String clean = price.toString()
            .replaceAll('₹', '')
            .replaceAll('INR', '')
            .replaceAll('/-', '')
            .replaceAll(',', '')
            .trim();
            
        if (clean.isEmpty) return "₹0";
        p = double.parse(clean) / 100.0;
      }
      
      if (p == p.toInt().toDouble()) {
        return "₹${p.toInt()}";
      }
      return "₹${p.toStringAsFixed(2)}";
    } catch (e) {
      return "₹$price";
    }
  }

  /// Real-time stream for a single order
  /// Get a single order by ID or Order Number
  /// Fetch a single order by ID or Order Number (Direct Fetch)
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

  /// Real-time stream for recent orders
  /// Real-time stream for recent orders with joined data
  static Stream<List<Map<String, dynamic>>> getRecentOrdersStream() {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
          final res = await _client
              .from('Order')
              .select('*, WhatsAppConversation(*)')
              .order('createdAt', ascending: false)
              .limit(50);
          return List<Map<String, dynamic>>.from(res);
        });
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
    return _client.from('Order').stream(primaryKey: ['id']).map((orders) {
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

        final amount = (double.tryParse(order['totalPrice']?.toString() ?? '0') ?? 0.0) / 100.0;

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
      'updatedAt': now,
    };
    
    // Set specific audit timestamps
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
      'updatedAt': now,
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

  /// Real-time stream for kitchen
  /// Real-time stream for kitchen with joined data
  static Stream<List<Map<String, dynamic>>> getKitchenOrdersStream() {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
          final res = await _client
              .from('Order')
              .select('*, WhatsAppConversation(*)')
              .inFilter('status', ['PENDING', 'CONFIRMED'])
              .order('createdAt', ascending: true);
          return List<Map<String, dynamic>>.from(res);
        });
  }

  /// Submit a public order atomically via RPC.
  static Future<void> submitPublicOrder(Map<String, dynamic> data) async {
    final orderData = Map<String, dynamic>.from(data);
    
    // Set unified source
    orderData['source'] = 'APP';
    
    try {
      final rawItems = orderData.remove('items');
      if (rawItems is! List) {
        throw ArgumentError('items must be a List');
      }
      final items = rawItems.map((e) {
        if (e is! Map) throw ArgumentError('Each item must be a Map');
        return Map<String, dynamic>.from(e);
      }).toList();
      
      await _client.rpc(
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
      debugPrint("Could not launch WhatsApp: $url");
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
