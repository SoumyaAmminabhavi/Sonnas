import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_provider.dart';
import '../widgets/wasm_image.dart';
import '../services/supabase_service.dart';
import '../services/constants.dart';

class CustomerProductDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final String? heroTag;

  const CustomerProductDetailPage({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  ConsumerState<CustomerProductDetailPage> createState() => _CustomerProductDetailPageState();
}

class _CustomerProductDetailPageState extends ConsumerState<CustomerProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final product = widget.product;

    // Validate product image URL before calling getPublicUrl
    final String? imageUrl;
    final rawImage = product['image']?.toString().trim();
    if (rawImage == null || rawImage.isEmpty) {
      imageUrl = null;
    } else if (rawImage.startsWith('data:') ||
        rawImage.startsWith('http://') ||
        rawImage.startsWith('https://')) {
      // Enforce HTTPS to prevent mixed-content warnings
      imageUrl = rawImage.startsWith('http://') ? rawImage.replaceFirst('http://', 'https://') : rawImage;
    } else {
      imageUrl = SupabaseService.getPublicUrl(rawImage, bucket: 'cakes');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(imageUrl, cs),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(product, cs),
                  const SizedBox(height: 24),
                  _buildDescription(product, cs),
                  const SizedBox(height: 32),
                  _buildQuantitySelector(cs),
                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(product, cs),
    );
  }

  Widget _buildSliverAppBar(String? imageUrl, ColorScheme cs) {
    return SliverAppBar(
      expandedHeight: 400,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
          child: Icon(Icons.arrow_back, color: cs.secondary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: widget.heroTag ?? 'product_${widget.product['id'] ?? widget.product.hashCode}',
          child: _buildImageWidget(imageUrl),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Placeholder for null or empty imageUrl
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.cake, size: 100, color: Colors.grey),
        ),
      );
    } else if (imageUrl.startsWith('data:')) {
      // Handle data URI with Image.memory
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, size: 50, color: Colors.grey),
            ),
          ),
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.error, size: 50, color: Colors.grey),
          ),
        );
      }
    } else {
      // Use SafeWasmImage for network URLs
      return SafeWasmImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildHeader(Map<String, dynamic> product, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (product['name'] as String?) ?? 'Unknown Masterpiece',
                style: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.bold, color: cs.secondary),
              ),
            ),
            Text(
              _priceDisplay(product['price']),
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(99)),
          child: Text(
            _getCategoryName(product),
            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Map<String, dynamic> product, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("THE CREATION", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: cs.secondary.withValues(alpha: 0.4))),
        const SizedBox(height: 12),
        Text(
          (product['description'] as String?) ?? 'A unique selection curated by Chef Sonna, using the finest ingredients and artisan techniques.',
          style: GoogleFonts.notoSerif(fontSize: 15, height: 1.6, color: cs.secondary.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ColorScheme cs) {
    return Row(
      children: [
        Text("QUANTITY", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: cs.secondary.withValues(alpha: 0.4))),
        const Spacer(),
        Container(
          decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              IconButton(onPressed: () => setState(() => _quantity = (_quantity > 1) ? _quantity - 1 : 1), icon: const Icon(Icons.remove)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("$_quantity", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> product, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(product, quantity: _quantity);
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text("Added to cart!"), behavior: SnackBarBehavior.floating),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("ADD TO SELECTION", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  static String _priceDisplay(dynamic price) {
    final double normalized = PriceConstants.normalizePrice(price);
    return "${PriceConstants.currencySymbol}${normalized.toStringAsFixed(normalized.truncateToDouble() == normalized ? 0 : 2)}";
  }

  static String _getCategoryName(Map<String, dynamic> product) {
    final cat = product['Category'];
    if (cat is Map) return (cat['name'] ?? 'BOUTIQUE').toString().toUpperCase();
    return (cat ?? 'BOUTIQUE').toString().toUpperCase();
  }
}
