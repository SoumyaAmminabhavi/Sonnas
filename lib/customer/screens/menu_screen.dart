import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _isLoading = true;
  bool _isGridView = true;

  String _selectedCategory = "All";
  List<String> categories = ["All", "General", "Cakes", "Pastries", "Savories", "Macarons"];

  @override
  void initState() {
    super.initState();
    _fetchCakes();
  }

  Future<void> _fetchCakes() async {
    try {
      setState(() => _isLoading = true);
      
      // Using the centralized service we just updated
      final data = await SupabaseService.fetchMenu();
      
      if (mounted) {
        setState(() {
          menuItems = data.map((cake) {
            final options = cake['options'] as List?;
            double numericPrice = 0.0;
            String priceDisplay = "₹ 0.00";
            
            if (options != null && options.isNotEmpty) {
              // Prisma stores price as Int (likely paise/cents), so we divide by 100
              final rawPrice = options[0]['price']?.toString() ?? "0";
              numericPrice = (double.tryParse(rawPrice) ?? 0.0) / 100.0;
              priceDisplay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(numericPrice);
            }

            return {
              'id': cake['id'],
              'title': (cake['name'] as String?) ?? 'Unnamed',
              'price': priceDisplay,
              'numericPrice': numericPrice,
              'image': (cake['image'] as String?) ?? 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=400&auto=format&fit=crop',
              'description': (cake['description'] as String?) ?? '',
              'category': (cake['category'] as String?) ?? 'General',
              'options': options ?? const [],
            };
          }).toList();
          
          filteredItems = List.from(menuItems);
          _filterByCategory();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching cakes: $e");
      if (mounted) {
        setState(() {
          // Fallback to sample data for visual feedback
          menuItems = [
            {
              'title': "Classic Chocolate",
              'price': "₹ 650",
              'numericPrice': 650.0,
              'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000&auto=format&fit=crop',
              'description': 'Rich Belgian chocolate ganache.',
              'category': 'Cakes',
              'options': [],
            },
            {
              'title': "Strawberry Bliss",
              'price': "₹ 720",
              'numericPrice': 720.0,
              'image': 'https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=1000&auto=format&fit=crop',
              'description': 'Fresh strawberries with cream.',
              'category': 'Cakes',
              'options': [],
            },
            {
              'title': "Butter Croissant",
              'price': "₹ 150",
              'numericPrice': 150.0,
              'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=1000&auto=format&fit=crop',
              'description': 'Flaky, buttery French pastry.',
              'category': 'Pastries',
              'options': [],
            },
            {
              'title': "Cheese Quiche",
              'price': "₹ 220",
              'numericPrice': 220.0,
              'image': 'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?q=80&w=1000&auto=format&fit=crop',
              'description': 'Savory tart with aged cheddar.',
              'category': 'Savories',
              'options': [],
            },
          ];
          filteredItems = List.from(menuItems);
          _filterByCategory();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backend Restricted: Please check Supabase RLS Policies"),
            backgroundColor: Color(0xFF701235),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _sortItems(String criteria) {
    setState(() {
      if (criteria == "Price: Low to High") {
        filteredItems.sort((a, b) => a['numericPrice'].compareTo(b['numericPrice']));
      } else if (criteria == "Price: High to Low") {
        filteredItems.sort((a, b) => b['numericPrice'].compareTo(a['numericPrice']));
      } else if (criteria == "Name: A-Z") {
        filteredItems.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
      } else {
        _filterByCategory(); // Apply category filter again to reset sorting to category default
      }
    });
  }

  void _filterByCategory() {
    setState(() {
      if (_selectedCategory == "All") {
        filteredItems = List.from(menuItems);
      } else {
        filteredItems = menuItems.where((item) {
          final category = (item['category'] as String?) ?? 'Cakes';
          return category.toLowerCase().contains(_selectedCategory.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color secondaryColor = Color(0xFF701235);
    const Color onSurface = Color(0xFF701235);

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OUR MENU",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(cat.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _filterByCategory();
                                });
                              }
                            },
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : onSurface,
                            ),
                            selectedColor: primaryColor,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? primaryColor : primaryColor.withOpacity(0.1)),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${filteredItems.length} items",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: secondaryColor.withOpacity(0.6),
                        ),
                      ),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            onSelected: _sortItems,
                            offset: const Offset(0, 30),
                            child: Row(
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
                              ],
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: "Popularity", child: Text("Popularity")),
                              const PopupMenuItem(value: "Price: Low to High", child: Text("Price: Low to High")),
                              const PopupMenuItem(value: "Price: High to Low", child: Text("Price: High to Low")),
                              const PopupMenuItem(value: "Name: A-Z", child: Text("Name: A-Z")),
                            ],
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => setState(() => _isGridView = true),
                            icon: Icon(Icons.grid_view_rounded, 
                              size: 20, 
                              color: _isGridView ? onSurface : Colors.grey.shade400
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => setState(() => _isGridView = false),
                            icon: Icon(Icons.list_rounded, 
                              size: 24, 
                              color: !_isGridView ? onSurface : Colors.grey.shade400
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            )
          else if (filteredItems.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text("No delicacies found.")),
            )
          else
            _isGridView ? _buildGrid(primaryColor, secondaryColor, onSurface) : _buildList(primaryColor, secondaryColor, onSurface),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildGrid(Color primary, Color secondary, Color onSurface) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(context, filteredItems[index], primary, secondary, onSurface),
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildList(Color primary, Color secondary, Color onSurface) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filteredItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () => _openDetail(item),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 120, cacheHeight: 120),
                ),
                title: Text(item['title'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                subtitle: Text(item['price'], style: GoogleFonts.notoSerif(color: primary, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          title: item['title'],
          price: item['price'],
          imageUrl: item['image'],
          rawOptions: item['options'] ?? [],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> item, Color primary, Color secondary, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _openDetail(item),
            child: Hero(
              tag: 'menu_item_${item['id'] ?? item['title']}',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['image'], fit: BoxFit.cover, cacheWidth: 400),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['title'],
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item['price'],
          style: GoogleFonts.notoSerif(fontSize: 11, fontWeight: FontWeight.w900, color: primary),
        ),
      ],
    );
  }
}
