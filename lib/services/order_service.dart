import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';

import 'package:url_launcher/url_launcher.dart';

class OrderService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time stream for ALL orders (used for analytics)
  static Stream<List<Map<String, dynamic>>> getAllOrdersStream() {
    return _client.from('WhatsAppOrder').stream(primaryKey: ['id']);
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
      // Handle numeric types directly
      double p;
      if (price is num) {
        p = price.toDouble() / 100.0;
      } else {
        // Strip any existing currency symbols, commas, or suffixes like /-
        String clean = price.toString()
            .replaceAll('₹', '')
            .replaceAll('INR', '')
            .replaceAll('/-', '')
            .replaceAll(',', '')
            .trim();
            
        if (clean.isEmpty) return "₹0";
        p = double.parse(clean) / 100.0;
      }
      
      // If it's a whole number, don't show .00
      if (p == p.toInt().toDouble()) {
        return "₹${p.toInt()}";
      }
      return "₹${p.toStringAsFixed(2)}";
    } catch (e) {
      return "₹$price";
    }
  }

  /// Real-time stream for a single order
  /// Real-time stream for a single order
  static Stream<Map<String, dynamic>?> getSingleOrderStream(String id) async* {
    String actualId = id;
    
    // If it looks like an order number (contains SNAP or SN- or SPC- or SN-), resolve the real ID first
    if (id.contains('-') && !id.startsWith('c')) { // CUIDs often start with 'c'
      final res = await _client
          .from('WhatsAppOrder')
          .select('id')
          .eq('orderNumber', id)
          .maybeSingle();
      if (res != null) {
        actualId = res['id'];
      }
    }

    yield* _client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .eq('id', actualId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Real-time stream for recent orders
  static Stream<List<Map<String, dynamic>>> getRecentOrdersStream() {
    return _client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .limit(50);
  }

  /// Bulk fetch items for multiple orders
  static Future<List<Map<String, dynamic>>> fetchBulkOrderItems(List<String> orderIds) async {
    final res = await _client.from('WhatsAppOrderItem').select().inFilter('orderId', orderIds);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      // 1. Try Primary (Friend's) project
      final res = await SupabaseService.client.from('WhatsAppOrder').select().order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('⚠️ Friend\'s Orders Fetch Failed: $e. Falling back to Private DB.');
      try {
        // 2. Fallback to Private (My) project
        final res = await SupabaseService.myClient.from('WhatsAppOrder').select().order('createdAt', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (e2) {
        debugPrint('❌ All Order Fetch attempts failed: $e2');
        return [];
      }
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    final res = await _client.from('WhatsAppOrderItem').select().eq('orderId', orderId);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Stats stream for dashboard charts (Transformed into `Map<int, double>`)
  static Stream<Map<int, double>> getSalesChartStream({required String range, int? targetMonth, int? targetYear}) {
    return _client.from('WhatsAppOrder').stream(primaryKey: ['id']).map((orders) {
      final Map<int, double> chartData = {};
      
      for (final order in orders) {
        final dateStr = order['createdAt']?.toString();
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final amount = (double.tryParse(order['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0) / 100.0;

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
    await _client.from('WhatsAppOrder').update({'status': status}).eq('id', orderId);
  }

  static Future<void> updatePaymentStatus(String orderId, String status) async {
    await _client.from('WhatsAppOrder').update({'paymentStatus': status}).eq('id', orderId);
  }

  /// Format phone number for display
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return "Contact hidden";
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) return "+91$clean";
    if (clean.startsWith('91') && clean.length == 12) return "+$clean";
    return phone;
  }

  /// Real-time stream for kitchen (PENDING or ACCEPTED)
  static Stream<List<Map<String, dynamic>>> getKitchenOrdersStream() {
    return _client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: true);
  }

  /// Submit a new order from the public customer platform
  static Future<void> submitPublicOrder(Map<String, dynamic> data) async {
    final orderData = Map<String, dynamic>.from(data);
    final items = orderData.remove('items') as List<dynamic>;
    
    final response = await _client
        .from('WhatsAppOrder')
        .insert(orderData)
        .select()
        .single();
    
    final orderId = response['id'];
    
    // Insert order items
    final orderItems = items.map((item) => {
      'orderId': orderId,
      'cakeName': item['cakeName'],
      'quantity': item['quantity'],
      'price': item['price'],
    }).toList();
    
    await _client.from('WhatsAppOrderItem').insert(orderItems);
  }

  /// Launch WhatsApp with a message
  static Future<void> launchWhatsApp(String? phone, String message) async {
    if (phone == null || phone.isEmpty) return;
    
    // Clean phone number: keep only digits
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Ensure international format (add 91 if it's a 10-digit number)
    if (cleanPhone.length == 10) {
      cleanPhone = "91$cleanPhone";
    }

    final query = Uri.encodeComponent(message);
    final url = Uri.parse("https://wa.me/$cleanPhone?text=$query");
    
    debugPrint("NEW WhatsApp Launcher: $url");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp: $url");
    }
  }
  /// Robust date parsing for various formats (ISO, DD/MM/YYYY, etc.)
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Try DD/MM/YYYY
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
      return null;
    }
  }
}
