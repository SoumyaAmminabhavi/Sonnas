import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class FinanceService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final res = await _client.from('Expense').select().order('date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> addExpense(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    await _client.from('Expense').insert(payload);
  }

  static Future<void> deleteExpense(String id) async {
    final res = await _client.from('Expense').delete().eq('id', id).select('id').maybeSingle();
    if (res == null) {
      debugPrint('⚠️ Delete Expense: no record found for id=$id');
    }
  }
}
