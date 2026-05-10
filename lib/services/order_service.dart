import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint("Launching maps for: $url");
  }

  /// Format price with currency symbol
  static String formatPrice(dynamic price) {
    if (price == null) return "₹0.00";
    try {
      // Strip any existing currency symbols, commas, or suffixes like /-
      String clean = price.toString()
          .replaceAll('₹', '')
          .replaceAll('INR', '')
          .replaceAll('/-', '')
          .replaceAll(',', '')
          .trim();
          
      if (clean.isEmpty) return "₹0.00";
      
      final double p = double.parse(clean);
      return "₹${p.toStringAsFixed(2)}";
    } catch (e) {
      return "₹$price";
    }
  }

  /// Real-time stream for a single order
  /// Real-time stream for a single order
  static Stream<Map<String, dynamic>?> getSingleOrderStream(String id) async* {
    String actualId = id;
    
    // If it looks like an order number (starts with SN-), resolve the real ID first
    if (id.startsWith('SN-')) {
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
    final res = await _client.from('WhatsAppOrder').select().order('createdAt', ascending: false);
    return List<Map<String, dynamic>>.from(res);
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
        final amount = double.tryParse(order['totalPrice']?.toString() ?? '0') ?? 0.0;

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
  static Future<void> launchWhatsApp(String phone, String message) async {
    // Note: Use url_launcher in actual implementation
    final query = Uri.encodeComponent(message);
    final url = Uri.parse("whatsapp://send?phone=$phone&text=$query");
    debugPrint("Launching WhatsApp: $url");
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
