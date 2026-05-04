import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCakes();
  }

  Future<void> _fetchCakes() async {
    try {
      final supabase = Supabase.instance.client;
      // Fetch cakes with their options (joining CakeOption)
      final data = await supabase
          .from('Cake')
          .select('*, options:CakeOption(*)');
      
      if (mounted) {
        setState(() {
          menuItems = List<Map<String, dynamic>>.from(data).map((cake) {
            // Find the lowest price from options or default
            final options = cake['options'] as List?;
            String price = "₹ 0.00";
            if (options != null && options.isNotEmpty) {
              price = "₹ ${options[0]['price']}";
            }
            return {
              'title': cake['name'],
              'price': price,
              'image': cake['image'],
              'description': cake['description'],
              'options': options,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching featured cakes: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Menu Fetch Error"), backgroundColor: Color(0xFFFF4D8D)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color secondaryColor = Color(0xFF701235);
    const Color onSurface = Color(0xFF2B1606);

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          // Header / Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SUMMER MENU",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${menuItems.length} items",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: secondaryColor.withOpacity(0.6),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Sort",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                          const SizedBox(width: 16),
                          const Icon(Icons.grid_view_rounded, size: 20, color: onSurface),
                          const SizedBox(width: 8),
                          const Icon(Icons.list_rounded, size: 20, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading State
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            ),

          // Empty State
          if (!_isLoading && menuItems.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text("No delicacies found today.")),
            ),

          // Product Grid
          if (!_isLoading && menuItems.isNotEmpty)
            SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = menuItems[index];
                  return _buildProductCard(context, item, primaryColor, secondaryColor, onSurface);
                },
                childCount: menuItems.length,
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> item, Color primary, Color secondary, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Container
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    title: item['title'],
                    price: item['price'],
                    imageUrl: item['image'],
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Hero(
                  tag: item['title'],
                  child: Container(
                    padding: const EdgeInsets.all(4), // Reduced padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE7E7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item['image'],
                        fit: BoxFit.contain, // Ensure full product is visible
                      ),
                    ),
                  ),
                ),
                // Quick Add Button (Ultra Compact)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Material(
                    color: Colors.white.withOpacity(0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        final priceValue = double.parse(item['price'].replaceAll('₹', '').replaceAll(' ', '').replaceAll(',', ''));
                        context.read<CartProvider>().addItem(item['title'], priceValue, item['image']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${item['title']} added"),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: primary,
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.add, size: 12, color: primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Text Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: onSurface,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item['price'],
              style: GoogleFonts.notoSerif(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
