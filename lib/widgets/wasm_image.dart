import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SafeWasmImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? cacheWidth;

  const SafeWasmImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    if (kIsWeb) {
      // Use standard Image.network to bypass legacy JS cache manager and leverage browser native caching
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildShimmer(context);
        },
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
    }

    // Use CachedNetworkImage for Mobile platforms (Android/iOS)
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth?.toInt(),
      placeholder: (context, url) => _buildShimmer(context),
      errorWidget: (context, url, error) => _buildError(context),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainer,
      highlightColor: cs.surface,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: cs.surfaceContainer,
      child: Icon(Icons.image, color: cs.primary.withValues(alpha: 0.2)),
    );
  }

  Widget _buildError(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: cs.surfaceContainer,
      child: Icon(Icons.broken_image_outlined, color: cs.primary.withValues(alpha: 0.2)),
    );
  }
}
