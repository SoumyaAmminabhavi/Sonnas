import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class InventoryService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Real-time stream for all inventory items
  static Stream<List<Map<String, dynamic>>> getInventoryStream() {
    return _client.from('InventoryItem').stream(primaryKey: ['id']).order('name');
  }

  /// One-time fetch for inventory items (useful for dialogs to avoid nested stream subscriptions)
  static Future<List<Map<String, dynamic>>> fetchInventory() async {
    final res = await _client.from('InventoryItem').select().order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  /// Add a new inventory item
  static Future<void> addInventoryItem(Map<String, dynamic> item) async {
    await _client.from('InventoryItem').insert(item);
  }

  /// Delete an inventory item
  static Future<void> deleteInventoryItem(String id) async {
    await _client.from('InventoryItem').delete().eq('id', id);
  }

  /// Update inventory stock level (Increment or absolute)
  static Future<void> updateInventoryStock(String id, double value, {bool isIncrement = true}) async {
    if (isIncrement) {
      await _client.rpc<void>('increment_inventory', params: {'item_id': id, 'amount': value});
    } else {
      if (value < 0) throw Exception("Stock level cannot be negative");
      await _client.from('InventoryItem').update({'currentStock': value}).eq('id', id);
    }
  }

  /// Record consumption (decrements stock)
  static Future<void> recordConsumption(String id, double quantity) async {
    if (quantity <= 0) throw Exception("Consumption quantity must be positive");
    // We reuse updateInventoryStock with a negative value
    await updateInventoryStock(id, -quantity, isIncrement: true);
  }

  static Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await _client.from('InventoryItem').update(data).eq('id', id);
  }
}
