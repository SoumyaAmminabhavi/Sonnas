import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static final _supabase = Supabase.instance.client;

  /// Returns a real-time stream of all customer feedback, newest first.
  static Stream<List<Map<String, dynamic>>> getFeedbackStream() {
    return _supabase
        .from('Feedback')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }
}
