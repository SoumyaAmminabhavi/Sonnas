import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
enum SalesRange { today, weekly, monthly, yearly }

class SupabaseService {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Helper to get public URL for images in the 'cakes' bucket
  static String getPublicUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // Already a full web link — use directly
    if (path.startsWith('https://') || path.startsWith('http://')) return path;
    // Local device paths (e.g. whatsapp://) can't be loaded — skip them
    if (path.startsWith('whatsapp://') || path.startsWith('file://')) return '';
    
    return client.storage.from('cakes').getPublicUrl(path);
  }

  // Format price consistently (ensures one ₹ symbol for numbers)
  static String formatPrice(dynamic price) {
    if (price == null) return "₹0";
    String p = price.toString();
    if (p.startsWith('₹')) return p;
    
    // Check if it's a numeric value (ignore currency symbol for things like 'Pending Quote')
    final isNumeric = double.tryParse(p.replaceAll(',', '')) != null;
    if (!isNumeric) return p;
    
    return "₹$p";
  }

  // Format phone for display (adds + if missing)
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'Contact hidden';
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 10 && !phone.startsWith('+')) {
      // Assuming India (91) if it starts with 91 or is 10 digits
      if (clean.startsWith('91')) return '+$clean';
      if (clean.length == 10) return '+91$clean';
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }

  // Launch WhatsApp Chat
  static Future<void> launchWhatsApp(String? phone, String message) async {
    if (phone == null || phone.isEmpty) return;
    
    // Clean phone number (remove non-digits except +)
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Ensure it has a country code (prefix 91 if missing and 10 digits)
    if (cleanPhone.length == 10) cleanPhone = "91$cleanPhone";
    
    final Uri url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp for $cleanPhone');
    }
  }

  // Launch Google Maps
  static Future<void> launchMaps(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedQuery");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Maps for $query');
    }
  }

  // Real-time stream for WhatsApp Orders (Matching Prisma 'WhatsAppOrder')
  static Stream<List<Map<String, dynamic>>> getOrdersStream() {
    return client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false);
  }



  // Real-time stream for Sales Performance
  static Stream<Map<int, double>> getSalesStream({
    SalesRange range = SalesRange.weekly,
    int? targetMonth,
    int? targetYear,
  }) {
    return getOrdersStream().map((orders) {
      final Map<int, double> salesData = {};
      final now = DateTime.now();
      final year = targetYear ?? now.year;
      final month = targetMonth ?? now.month;

      // Initialize keys based on range
      if (range == SalesRange.today) {
        for (int i = 0; i < 24; i++) {
          salesData[i] = 0.0;
        }
      } else if (range == SalesRange.weekly) {
        for (int i = 0; i < 7; i++) {
          salesData[i] = 0.0;
        }
      } else if (range == SalesRange.monthly) {
        // Find days in month
        final lastDay = DateTime(year, month + 1, 0).day;
        for (int i = 1; i <= lastDay; i++) {
          salesData[i] = 0.0;
        }
      } else if (range == SalesRange.yearly) {
        for (int i = 1; i <= 12; i++) {
          salesData[i] = 0.0;
        }
      }

      for (var order in orders) {
        final createdAtStr = order['createdAt'];
        if (createdAtStr == null) continue;
        
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null) continue;
        
        final price = double.tryParse(order['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0;

        if (range == SalesRange.today) {
          if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day) {
            final hour = createdAt.hour;
            salesData[hour] = (salesData[hour] ?? 0) + price;
          }
        } else if (range == SalesRange.weekly) {
          final diff = now.difference(createdAt).inDays;
          if (diff >= 0 && diff < 7) {
            final weekday = (createdAt.weekday - 1);
            salesData[weekday] = (salesData[weekday] ?? 0) + price;
          }
        } else if (range == SalesRange.monthly) {
          if (createdAt.year == year && createdAt.month == month) {
            final day = createdAt.day;
            salesData[day] = (salesData[day] ?? 0) + price;
          }
        } else if (range == SalesRange.yearly) {
          if (createdAt.year == year) {
            final m = createdAt.month;
            salesData[m] = (salesData[m] ?? 0) + price;
          }
        }
      }
      return salesData;
    });
  }

  // Real-time Dashboard Stats
  static Stream<Map<String, dynamic>> getDashboardStatsStream() {
    return getOrdersStream().map((orders) {
      double totalRevenue = 0;
      final Set<String> customers = {};
      
      for (var order in orders) {
        final price = double.tryParse(order['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0;
        totalRevenue += price;
        if (order['phone'] != null) customers.add(order['phone']);
      }
      
      return {
        'totalOrders': orders.length,
        'totalRevenue': totalRevenue,
        'activeCustomers': customers.length,
      };
    });
  }

  // Fetching WhatsApp Orders (Matching Prisma 'WhatsAppOrder')
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final data = await client
          .from('WhatsAppOrder')
          .select()
          .order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Real-time stream for Menu Cakes
  static Stream<List<Map<String, dynamic>>> getMenuStream() {
    return client
        .from('Cake')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => Map<String, dynamic>.from(item)).toList());
  }

  // Real-time stream for a single order by number
  static Stream<Map<String, dynamic>?> getSingleOrderStream(String orderNumber) {
    return client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .eq('orderNumber', orderNumber)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Real-time stream for a single cake by id
  static Stream<Map<String, dynamic>?> getSingleCakeStream(String id) {
    return client
        .from('Cake')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Fetching Menu Cakes (Matching Prisma 'Cake' and 'CakeOption')
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      // Fetch cakes with their related options
      final data = await client
          .from('Cake')
          .select('*, CakeOption(*)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      return [];
    }
  }

  // Fetching Conversations for CRM purposes
  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    try {
      final data = await client
          .from('WhatsAppConversation')
          .select()
          .order('lastMessageAt', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  // Update Order Status
  static Future<void> updateOrderStatus(String id, String status) async {
    try {
      await client
          .from('WhatsAppOrder')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  // Update Payment Status
  static Future<void> updatePaymentStatus(String id, String status) async {
    try {
      // Try updating 'paymentStatus' column first
      await client
          .from('WhatsAppOrder')
          .update({'paymentStatus': status})
          .eq('id', id);
    } catch (e) {
      // Fallback: Use 'status' if 'paymentStatus' doesn't exist
      await updateOrderStatus(id, status);
    }
  }

  // Fetch items for a specific order
  static Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    try {
      final data = await client
          .from('WhatsAppOrderItem')
          .select()
          .eq('orderId', orderId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching order items: $e');
      return [];
    }
  }
}
