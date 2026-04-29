import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (!path.contains('/') || path.startsWith('whatsapp://') || path.startsWith('file://')) return '';
    
    return client.storage.from('cakes').getPublicUrl(path);
  }

  // Format price consistently (ensures one ₹ symbol)
  static String formatPrice(dynamic price) {
    if (price == null) return "₹0";
    String p = price.toString();
    if (p.startsWith('₹')) return p;
    return "₹$p";
  }

  // Real-time stream for WhatsApp Orders (Matching Prisma 'WhatsAppOrder')
  static Stream<List<Map<String, dynamic>>> getOrdersStream() {
    return client
        .from('WhatsAppOrder')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false);
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
}
