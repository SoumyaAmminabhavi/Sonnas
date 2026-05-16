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
      
      final escapedInput = cleanInput.replaceAll('%', '\\%').replaceAll('_', '\\_');
      
      // Try ID, then OrderNumber
      var res = await _client
          .from('Order')
          .select('*, WhatsAppConversation(*)')
          .eq('id', idOrNumber)
          .maybeSingle();

      if (res == null) {
        res = await _client
            .from('Order')
            .select('*, WhatsAppConversation(*)')
            .eq('orderNumber', idOrNumber)
            .maybeSingle();
      }

      if (res == null) {
        res = await _client
            .from('Order')
            .select('*, WhatsAppConversation(*)')
            .ilike('orderNumber', '%$escapedInput%')
            .maybeSingle();
      }
      
      return res;
    } catch (e) {
      debugPrint('⚠️ Fetch Order Failed: $e');
      return null;
    }
  }

  static Stream<Map<String, dynamic>?> getSingleOrderStream(String idOrNumber) {
    final cleanInput = idOrNumber.replaceAll(RegExp(r'^(SN-|SPC |SPC-|ORD-|#)'), '');
    final escapedInput = cleanInput.replaceAll('%', '\\%').replaceAll('_', '\\_');

    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .map((list) {
          try {
            return list.firstWhere(
              (o) {
                final String dbId = o['id'].toString();
                final String dbNum = o['orderNumber']?.toString() ?? '';

                if (dbId == idOrNumber) return true;
                if (dbNum == idOrNumber) return true;

                final cleanDbNum = dbNum.replaceAll(RegExp(r'^(SN-|SPC |SPC-|ORD-|#)'), '');
                if (cleanInput.isNotEmpty && cleanInput == cleanDbNum) return true;

                final dbNumEscaped = dbNum.replaceAll('%', '\\%').replaceAll('_', '\\_');
                return dbNumEscaped.toLowerCase().contains(escapedInput.toLowerCase());
              },
              orElse: () => <String, dynamic>{},
            );
          } catch (_) {
            return null;
          }
        })
        .map((order) => (order == null || order.isEmpty) ? null : order);
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
      
      for (final order in orders) {
        final dateStr = order['createdAt']?.toString();
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

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
    final Map<String, dynamic> payload = {
      'status': status.toUpperCase(),
      'updatedAt': now,
    };
    
    // Set specific audit timestamps
    if (status == 'CONFIRMED') payload['confirmedAt'] = now;
    if (status == 'DELIVERED') payload['deliveredAt'] = now;
    if (status == 'COMPLETED') payload['completedAt'] = now;
    if (status == 'CANCELLED') payload['cancelledAt'] = now;
    
    try {
      await _client.from('Order').update(payload).eq('id', orderId);
    } catch (e) {
      debugPrint('❌ Order Status Update Failed: $e');
      rethrow;
    }
  }

  /// Update payment status
  static Future<void> updatePaymentStatus(String orderId, String status) async {
    // Note: status should be one of PaymentStatus Enum (e.g. 'PAID', 'FAILED')
    await _client.from('Order').update({'paymentStatus': status}).eq('id', orderId);
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

  /// Submit a public order. Both writes should ideally be atomic via a server-side
  /// RPC (e.g. create_order_with_items in Supabase). TODO: migrate to single RPC call.
  static Future<void> submitPublicOrder(Map<String, dynamic> data) async {
    final orderData = Map<String, dynamic>.from(data);
    final items = orderData.remove('items') as List<dynamic>;
    
    // Set unified source
    orderData['source'] = 'APP';
    
    try {
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
