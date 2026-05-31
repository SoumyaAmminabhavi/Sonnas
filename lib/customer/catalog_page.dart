import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/menu_service.dart';
import '../services/cart_provider.dart';
import '../services/supabase_service.dart';
import '../services/constants.dart';
import 'checkout_page.dart';
import 'product_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerCatalogPage extends ConsumerStatefulWidget {
  const CustomerCatalogPage({super.key});

  @override
  ConsumerState<CustomerCatalogPage> createState() => _CustomerCatalogPageState();
}

class _CustomerCatalogPageState extends ConsumerState<CustomerCatalogPage> {
  String _selectedCategory = 'ALL';
  late Future<List<Map<String, dynamic>>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = MenuService.fetchMenu();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 16),
                  Text("Failed to load menu", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: cs.error)),
                  const SizedBox(height: 8),
                  Text("Please check your connection and try again.", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.5))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _menuFuture = MenuService.fetchMenu()),
                    child: const Text("RETRY"),
                  ),
                ],
              ),
            );
          }
          final menuData = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildAppBar(cs, cart.itemCount),
              _buildCategoryFilter(cs, menuData),
              _buildProductGrid(cs, menuData),
            ],
          );
        },
      ),
      floatingActionButton: cart.items.isNotEmpty
          ? _buildCartFab(cs, cart)
          : null,
    );
  }

  Widget _buildAppBar(ColorScheme cs, int cartCount) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          "Our Selection",
          style: GoogleFonts.notoSerif(
            color: cs.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Search feature coming soon!")),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs, List<Map<String, dynamic>> menuData) {
    final categories = {'ALL', ...menuData.map((e) {
      final cat = e['Category'];
      if (cat is Map) return (cat['name'] ?? 'OTHER').toString().toUpperCase();
      return (cat ?? 'OTHER').toString().toUpperCase();
    })};
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedCategory = cat),
                backgroundColor: Colors.white,
                selectedColor: cs.primary,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : cs.secondary.withValues(alpha: 0.6),
                  letterSpacing: 1.0,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                side: BorderSide(color: isSelected ? Colors.transparent : cs.secondary.withValues(alpha: 0.1)),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid(ColorScheme cs, List<Map<String, dynamic>> menuData) {
    final allItems = menuData;
    final filteredItems = _selectedCategory == 'ALL' 
        ? allItems 
        : allItems.where((i) {
            final cat = i['Category'];
            String catName;
            if (cat is Map) {
              catName = (cat['name'] ?? 'OTHER').toString().toUpperCase();
            } else {
              catName = (cat ?? 'OTHER').toString().toUpperCase();
            }
            return catName == _selectedCategory;
          }).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          mainAxisExtent: 280,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filteredItems[index];
            return _ProductCard(item: item, cs: cs, index: index);
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildCartFab(ColorScheme cs, CartState cart) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (context) => const CustomerCheckoutPage()),
      ),
      backgroundColor: cs.primary,
      label: Text(
        "VIEW CART (${cart.itemCount})",
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      icon: const Icon(Icons.shopping_bag_outlined),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final int index;

  const _ProductCard({
    required this.item,
    required this.cs,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = item['image']?.toString() ?? '';
    String imageUrl;
    if (imagePath.isEmpty) {
      imageUrl = '';
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('data:')) {
      // Enforce HTTPS to prevent mixed-content warnings
      imageUrl = imagePath.startsWith('http://') ? imagePath.replaceFirst('http://', 'https://') : imagePath;
    } else {
      imageUrl = SupabaseService.getPublicUrl(imagePath, bucket: 'cakes');
    }

    final heroTag = 'product_${item['id'] ?? index}';

    return InkWell(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (context) => CustomerProductDetailPage(product: item, heroTag: heroTag)),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: heroTag,
                        child: imageUrl.isNotEmpty
                            ? (imageUrl.startsWith('data:')
                                ? _buildDataImage(imageUrl, cs)
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: cs.primary.withValues(alpha: 0.05),
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) => _placeholder(cs),
                                  ))
                            : _placeholder(cs),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${PriceConstants.currencySymbol}${PriceConstants.normalizePrice(item['price']).toStringAsFixed(PriceConstants.normalizePrice(item['price']).truncateToDouble() == PriceConstants.normalizePrice(item['price']) ? 0 : 2)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['name'] as String?) ?? 'Unknown Item',
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item['description'] as String?) ?? 'No description available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Added ${item['name']} to cart!"),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        foregroundColor: cs.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        "ADD TO CART",
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDataImage(String dataUrl, ColorScheme cs) {
    try {
      final uriData = UriData.parse(dataUrl);
      return Image.memory(
        uriData.contentAsBytes(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(cs),
      );
    } catch (e) {
      return _placeholder(cs);
    }
  }

  static Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.primary.withValues(alpha: 0.05),
      child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
    );
  }
}
