import 'dart:math';
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
    payload['id'] ??= _generateUUID();
    await _client.from('Expense').insert(payload);
  }

  static Future<void> deleteExpense(String id) async {
    final res = await _client.from('Expense').delete().eq('id', id).select('id').maybeSingle();
    if (res == null) {
      debugPrint('⚠️ Delete Expense: no record found for id=$id');
    }
  }

  static String _generateUUID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // set version to 4
    values[8] = (values[8] & 0x3f) | 0x80; // set variant to RFC 4122
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
