import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/menu_service.dart';
import '../services/cart_provider.dart';
import '../services/supabase_service.dart';
import 'checkout_page.dart';
import 'product_detail_page.dart';

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
      backgroundColor: const Color(0xFFFCF9F7), // Soft cream boutique background
      body: CustomScrollView(
        slivers: [
          _buildAppBar(cs, cart.itemCount),
          _buildCategoryFilter(cs),
          _buildProductGrid(cs),
        ],
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
              const SnackBar(content: Text("Search feature coming soon! 🔍")),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        final categories = {'ALL', ...snapshot.data?.map((e) => e['category']?.toString().toUpperCase() ?? 'OTHER') ?? {}};
        
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
      },
    );
  }

  Widget _buildProductGrid(ColorScheme cs) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        final allItems = snapshot.data ?? [];
        final filteredItems = _selectedCategory == 'ALL' 
            ? allItems 
            : allItems.where((i) => i['category']?.toString().toUpperCase() == _selectedCategory).toList();

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
                return _ProductCard(item: item, cs: cs);
              },
              childCount: filteredItems.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartFab(ColorScheme cs, CartState cart) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerCheckoutPage()),
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

  const _ProductCard({required this.item, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = SupabaseService.getPublicUrl(item['image'] ?? '');
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CustomerProductDetailPage(product: item)),
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
                        tag: 'product_${item['id']}',
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(
                            color: cs.primary.withValues(alpha: 0.05),
                            child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
                          ),
                        ),
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
                          "₹${item['price']}",
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
                    item['name'] ?? 'Unknown Item',
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
                    item['description'] ?? 'No description available',
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
                            content: Text("Added ${item['name']} to cart! 🍰"),
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
}
