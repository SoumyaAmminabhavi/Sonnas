import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FinanceService {
  static SupabaseClient get _myClient => SupabaseService.myClient;

  /// Fetch business expenses from the private owner DB
  static Future<List<Map<String, dynamic>>> fetchExpenses() async {
    try {
      final res = await _myClient.from('Expense').select().order('date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addExpense(Map<String, dynamic> data) async {
    await _myClient.from('Expense').insert(data);
  }

  static Future<void> deleteExpense(String id) async {
    await _myClient.from('Expense').delete().eq('id', id);
  }
}
