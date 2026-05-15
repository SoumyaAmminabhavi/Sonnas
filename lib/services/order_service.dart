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
  static Stream<Map<String, dynamic>?> getSingleOrderStream(String id) {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Real-time stream for recent orders
  static Stream<List<Map<String, dynamic>>> getRecentOrdersStream() {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .limit(50);
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
        // Map source enum to UI 'orderType' for backward compatibility
        o['orderType'] = o['source']?.toString() ?? 'APP';
        return o;
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
    // Note: status should be one of OrderStatus Enum (e.g. 'CONFIRMED', 'DELIVERED')
    await _client.from('Order').update({'status': status}).eq('id', orderId);
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
  static Stream<List<Map<String, dynamic>>> getKitchenOrdersStream() {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: true);
  }

  /// Submit a new order from the public customer platform (Unified)
  static Future<void> submitPublicOrder(Map<String, dynamic> data) async {
    final orderData = Map<String, dynamic>.from(data);
    final items = orderData.remove('items') as List<dynamic>;
    
    // Set unified source
    orderData['source'] = 'APP';
    
    final response = await _client
        .from('Order')
        .insert(orderData)
        .select()
        .single();
    
    final orderId = response['id'];
    
    // Insert order items
    final orderItems = items.map((item) => {
      'orderId': orderId,
      'cakeId': item['cakeId'], // Linked if available
      'cakeName': item['cakeName'],
      'quantity': item['quantity'],
      'price': item['price'],
      'size': item['size'] ?? 'Standard',
    }).toList();

 
    try {
      await _client.from('OrderItem').insert(orderItems);
    } catch (e) {
      // Cleanup: delete the orphaned order record if items failed to save
      debugPrint('❌ OrderItems failed to save, rolling back Order $orderId: $e');
      await _client.from('Order').delete().eq('id', orderId);
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
