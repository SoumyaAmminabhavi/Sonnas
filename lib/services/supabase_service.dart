import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Example: Fetching Orders
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final data = await client
          .from('Order')
          .select()
          .order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Fetching Menu Items (Cakes) as per Prisma Schema
  static Future<List<Map<String, dynamic>>> fetchMenu() async {
    try {
      final data = await client
          .from('Cake')
          .select('*, options:CakeOption(*), category:Category(name)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      return [];
    }
  }

  // Fetching Categories
  static Future<List<String>> fetchCategories() async {
    try {
      final data = await client
          .from('Category')
          .select('name');
      
      final List<String> cats = List<Map<String, dynamic>>.from(data)
          .map((item) => item['name'].toString())
          .toList();
      
      return cats;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
}
