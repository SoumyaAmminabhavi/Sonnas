import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FinanceService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetch business expenses from the unified DB
  static Future<List<Map<String, dynamic>>> fetchExpenses() async {
    try {
      final res = await _client.from('Expense').select().order('date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> addExpense(Map<String, dynamic> data) async {
    await _client.from('Expense').insert(data);
  }

  static Future<void> deleteExpense(String id) async {
    await _client.from('Expense').delete().eq('id', id);
  }
}
