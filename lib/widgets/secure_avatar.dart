import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class SecureAvatar extends StatelessWidget {
  final String? path;
  final String bucket;
  final String name;
  final double radius;
  final TextStyle? textStyle;

  const SecureAvatar({
    super.key,
    required this.path,
    required this.bucket,
    required this.name,
    this.radius = 24,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (path == null || path!.isEmpty || path!.toLowerCase() == "null") {
      return _buildPlaceholder(cs);
    }

    return FutureBuilder<String?>(
      future: SupabaseService.getSignedUrl(bucket, path!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: cs.primary.withValues(alpha: 0.05),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final url = snapshot.data;
        if (url == null) return _buildPlaceholder(cs);

        return CircleAvatar(
          radius: radius,
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(cs),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: textStyle ?? GoogleFonts.notoSerif(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }
}
