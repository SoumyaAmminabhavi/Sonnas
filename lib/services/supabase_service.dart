import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' if (dart.library.html) 'platform_file_stub.dart' as io show File;

/// Core Supabase Configuration & Shared Storage Utilities
class SupabaseService {
  static String get _supabaseUrlFromDefine => const String.fromEnvironment('SUPABASE_URL');
  static String get _supabaseAnonKeyFromDefine => const String.fromEnvironment('SUPABASE_ANON_KEY');

  static late final String supabaseUrl;
  static late final String supabaseAnonKey;

  static String? _safeDotenv(String key) {
    try {
      return dotenv.isInitialized ? dotenv.env[key] : null;
    } catch (_) {
      return null;
    }
  }
  
  static Future<void> initialize() async {
    supabaseUrl = (_supabaseUrlFromDefine.isNotEmpty
        ? _supabaseUrlFromDefine
        : (_safeDotenv('SUPABASE_URL') ?? '')).trim();
    supabaseAnonKey = (_supabaseAnonKeyFromDefine.isNotEmpty
        ? _supabaseAnonKeyFromDefine
        : (_safeDotenv('SUPABASE_ANON_KEY') ?? '')).trim();

    if (supabaseUrl.isEmpty) {
      throw StateError('SUPABASE_URL is not set. Provide via --dart-define=SUPABASE_URL=... or .env file.');
    }
    if (supabaseAnonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY is not set. Provide via --dart-define=SUPABASE_ANON_KEY=... or .env file.');
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Fetching Orders
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

  static String getPublicUrl(String? path, {required String bucket, int? width, int? height}) {
    // 1. Path guards first
    if (path == null || path.isEmpty || path == 'cake_placeholder.png') return '';
    if (path.startsWith('whatsapp://') || path.startsWith('file://')) return '';
    if (path.startsWith('data:')) return path;

    // Convert any png/jpg/jpeg extension (with or without query parameters) to webp,
    // unless the file is a newly uploaded image (starts with 'cmp57z')
    String cleanPath = path;
    final lastSegment = path.split('/').last;
    if (!lastSegment.startsWith('cmp57z')) {
      cleanPath = path.replaceAll(RegExp(r'\.(png|jpg|jpeg)(\?.*)?$', caseSensitive: false), '.webp');
    }

    // 2. Validation
    if (width != null || height != null) {
      throw UnsupportedError('Image resize parameters (width/height) are no longer supported on Supabase Free Tier. Remove them from the call.');
    }
    
    if (cleanPath.startsWith('http')) return cleanPath;
    
    // 3. Sanitize path: strip leading bucket names or extra slashes if present
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
  /// Accepts [Uint8List] or [dart:io File] (cross-platform compatible).
  static Future<String?> uploadImage({
    required String bucket,
    required String path,
    required dynamic file,
  }) async {
    // 1. Runtime type check
    if (file is Uint8List) {
      // Proceed to upload
    } else if (!kIsWeb && file is io.File) {
      // Proceed to upload (File will be converted to bytes by the storage client or we can read it)
    } else {
      throw ArgumentError('Unsupported file type: ${file.runtimeType}. Expected Uint8List or dart:io File.');
    }

    // Use the unified primary client for all storage buckets
    final storageClient = client.storage;

    try {
      if (file is Uint8List) {
        await storageClient.from(bucket).uploadBinary(path, file, fileOptions: const FileOptions(upsert: true));
      } else {
        // Must be io.File on non-web platform
        await storageClient.from(bucket).upload(path, file as io.File, fileOptions: const FileOptions(upsert: true));
      }
      return path;
    } catch (e) {
      debugPrint('❌ Storage Upload Error: $e');
      return null;
    }
  }
}

