import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String title;
  final String price;
  final String imageUrl;

  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = "600g";
  bool addBirthdayPlaque = false;
  bool addArtisanCandles = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color onSurfaceColor = Color(0xFF2B1606);
    const Color secondaryColor = Color(0xFF701235);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: surfaceColor.withOpacity(0.9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.title,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(primaryColor, secondaryColor, onSurfaceColor),
                const SizedBox(height: 16),
                _buildDescription(secondaryColor),
                const SizedBox(height: 16),
                _buildAttributes(primaryColor, onSurfaceColor),
                const SizedBox(height: 20),
                _buildSizeSelector(primaryColor, secondaryColor, onSurfaceColor),
                const SizedBox(height: 20),
                _buildEnhancements(primaryColor, secondaryColor, onSurfaceColor),
                const SizedBox(height: 24),
                _buildAddToCartButton(context, primaryColor, primaryContainerColor),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color secondaryColor, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "SIGNATURE COLLECTION",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: primaryColor.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Row(
              children: List.generate(5, (index) => Icon(Icons.star, size: 14, color: primaryColor)),
            ),
            const SizedBox(width: 8),
            Text(
              "(124 Reviews)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: secondaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Color secondaryColor) {
    return Text(
      "A masterpiece of pure indulgence. Crafted with 70% dark Valrhona chocolate, this five-layer creation features a velvet sponge infused with Madagascar vanilla and a silky Ganache Monteé that melts on the tongue.",
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.4,
        color: secondaryColor.withOpacity(0.8),
      ),
    );
  }

  Widget _buildAttributes(Color primaryColor, Color onSurfaceColor) {
    return Row(
      children: [
        Expanded(
          child: _buildAttrCard("TEXTURE", "Velvet & Silk", primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAttrCard("NOTES", "Roasted Cocoa, Berry", primaryColor),
        ),
      ],
    );
  }

  Widget _buildAttrCard(String label, String value, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(Color primaryColor, Color secondaryColor, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT SIZE",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: secondaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSizeOption("600g", "4-6 servings", primaryColor, onSurfaceColor),
            const SizedBox(width: 16),
            _buildSizeOption("1kg", "8-12 servings", primaryColor, onSurfaceColor),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeOption(String size, String servings, Color primaryColor, Color onSurfaceColor) {
    bool isSelected = selectedSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSize = size),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                size,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                servings,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancements(Color primaryColor, Color secondaryColor, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ENHANCE THE MOMENT",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: secondaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        _buildEnhancementTile(
          "Gold Letter Birthday Plaque",
          "+₹8",
          addBirthdayPlaque,
          (val) => setState(() => addBirthdayPlaque = val!),
          primaryColor,
        ),
        const SizedBox(height: 12),
        _buildEnhancementTile(
          "Artisan Candle Set",
          "+₹12",
          addArtisanCandles,
          (val) => setState(() => addArtisanCandles = val!),
          primaryColor,
        ),
      ],
    );
  }

  Widget _buildEnhancementTile(String title, String price, bool value, Function(bool?) onChanged, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        secondary: Text(
          price,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, Color primaryColor, Color primaryContainerColor) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [primaryColor, primaryContainerColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<CartProvider>().addItem(
                  widget.title,
                  double.parse(widget.price.replaceAll('₹', '').replaceAll(' ', '').replaceAll(',', '')),
                  widget.imageUrl,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${widget.title} added to bag"),
                backgroundColor: primaryColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ADD TO CART",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Text(
                  widget.price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCraftsmanship(Color onSurfaceColor, Color secondaryColor, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              "https://lh3.googleusercontent.com/aida-public/AB6AXuAet3XiPvSzvRNEotW2ZhTEfWckIH-8D6plGLfSpC4VKP7iwlZLHWw-qWkiClW-hCZzpCSZ0QuRWX2TqV_kDYjlXiPjZ-91T-1T56GBR0eIfMs_We2j5O7tNWy5bHyBdGibN5XsFRF0EIjK69ZHNBFp6iwGQQdBs3oAWM1yfkFdBmKPPbGRYRCvSiNneKuAGqLN5ZcH7eRVmxMUsUGA-qC7mbcHBt4Tg2XcVsu3wsqnTk-caQymRq3vhadBR608DD7nZH_4jRxcLrOf",
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "The Craftsmanship",
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontStyle: FontStyle.italic,
            color: onSurfaceColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Each cake is baked in small batches in our copper-lined ovens. We prioritize the \"blooming\" of the cocoa to ensure every slice carries the aromatic intensity of our heritage recipes. It's not just a cake; it's a sensory performance.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            height: 1.7,
            color: secondaryColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            "Learn about our sourcing",
            style: GoogleFonts.notoSerif(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
