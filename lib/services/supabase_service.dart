import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Core Supabase Configuration & Shared Storage Utilities
class SupabaseService {
  static final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static final String mySupabaseUrl = dotenv.env['MY_SUPABASE_URL'] ?? '';
  static final String mySupabaseAnonKey = dotenv.env['MY_SUPABASE_ANON_KEY'] ?? '';

  static late SupabaseClient _myClient;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    _myClient = SupabaseClient(mySupabaseUrl, mySupabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseClient get myClient => _myClient;

  /// Unified helper to get public URL for a file in Supabase storage
  static String getPublicUrl(String? path, {String bucket = 'staff-images', int? width, int? height}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('whatsapp://') || path.startsWith('file://')) return '';
    
    if (width != null || height != null) {
      return client.storage.from(bucket).getPublicUrl(
        path,
        transform: TransformOptions(
          width: width,
          height: height,
          resize: ResizeMode.cover,
        ),
      );
    }
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Helper to get a signed URL for private storage items
  static Future<String?> getSignedUrl(String bucket, String path) async {
    // Return public URL as fallback/prototype behavior or implement createSignedUrl
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
