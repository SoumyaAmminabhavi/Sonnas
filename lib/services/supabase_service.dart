import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Core Supabase Configuration & Shared Storage Utilities
class SupabaseService {
  static final String supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  static final String supabaseAnonKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
  
  static Future<void> initialize() async {
    // Initialize Primary Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Unified helper to get public URL for a file in Supabase storage
  /// Note: Resize parameters (width/height) are not supported on Supabase Free Tier.
  static String getPublicUrl(String? path, {String bucket = 'cakes', int? width, int? height}) {
    // 1. Path guards first
    if (path == null || path.isEmpty || path == 'cake_placeholder.png') return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('whatsapp://') || path.startsWith('file://')) return '';

    // 2. Validation
    if (width != null || height != null) {
      throw ArgumentError('Resize parameters (width/height) are not supported on Supabase Free Tier. Use CSS for scaling.');
    }
    
    // 3. Sanitize path: strip leading bucket names or extra slashes if present
    String cleanPath = path;
    if (cleanPath.startsWith('/$bucket/')) {
      cleanPath = cleanPath.replaceFirst('/$bucket/', '');
    } else if (cleanPath.startsWith('$bucket/')) {
      cleanPath = cleanPath.replaceFirst('$bucket/', '');
    }
    
    // Remove leading slash if it remains
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Use the unified primary client for all storage buckets
    final storageClient = client.storage;
    
    // Use direct public URL (Transformation is a paid feature)
    return storageClient.from(bucket).getPublicUrl(cleanPath);
  }

  /// Helper to get a signed URL for private storage items
  static Future<String?> getSignedUrl(String bucket, String path) async {
    // Return public URL as fallback/prototype behavior or implement createSignedUrl
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload an image to Supabase storage. 
  /// Accepts [Uint8List] (cross-platform compatible).
  static Future<String?> uploadImage({
    required String bucket,
    required String path,
    required dynamic file,
  }) async {
    // 1. Runtime type check
    if (file is! Uint8List) {
      throw ArgumentError('uploadImage: file must be Uint8List for cross-platform compatibility.');
    }

    // Use the unified primary client for all storage buckets
    final storageClient = client.storage;

    try {
      await storageClient.from(bucket).uploadBinary(path, file, fileOptions: const FileOptions(upsert: true));
      return path;
    } catch (e) {
      debugPrint('❌ Storage Upload Error: $e');
      return null;
    }
  }
}
