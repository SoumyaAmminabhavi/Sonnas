import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../../services/supabase_service.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const MenuScreen({super.key, this.initialSearchQuery});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _isLoading = true;
  bool _isGridView = true;

  String _selectedCategory = "All";
  List<String> categories = ["All"];

  late RealtimeChannel _menuChannel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _fetchCakes();
    _subscribeToMenuChanges();
  }

  void _subscribeToMenuChanges() {
    _menuChannel = Supabase.instance.client
        .channel('public:Cake')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Cake',
          callback: (payload) {
            debugPrint('Menu change detected: ${payload.toString()}');
            _fetchCakes(showLoader: false);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    Supabase.instance.client.removeChannel(_menuChannel);
    super.dispose();
  }

  Future<void> _fetchCakes({bool showLoader = true}) async {
    try {
      if (showLoader) setState(() => _isLoading = true);
      
      // Fetch Categories and Menu Items
      final cats = await SupabaseService.fetchCategories();
      final data = await SupabaseService.fetchMenu();
      
      if (mounted) {
        setState(() {
          // Update Categories
          categories = ["All", ...cats.where((c) => c != "All")];
          
          if (widget.initialSearchQuery != null) {
            final queryLower = widget.initialSearchQuery!.trim().toLowerCase();
            final matchedCat = categories.firstWhere(
              (c) => c.toLowerCase() == queryLower,
              orElse: () => '',
            );
            
            if (matchedCat.isNotEmpty) {
              _selectedCategory = matchedCat;
              _searchController.clear();
            } else {
              _selectedCategory = "All";
              _searchController.text = widget.initialSearchQuery!;
            }
          }

          menuItems = data.map((cake) {
            final options = cake['options'] as List?;
            double numericPrice = 0.0;
            String priceDisplay = "₹ 0.00";
            
            if (options != null && options.isNotEmpty) {
              final rawPrice = options[0]['price']?.toString() ?? "0";
              numericPrice = (double.tryParse(rawPrice) ?? 0.0) / 100.0;
              priceDisplay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(numericPrice);
            }

            final String imageName = (cake['image'] as String?) ?? '';
            String imageUrl = SupabaseService.getPublicUrl(imageName, bucket: 'cakes');

            // If we still don't have a valid URL or it's empty, use a unique Unsplash fallback
            if (imageUrl.isEmpty || imageUrl.contains('null')) {
              final String name = (cake['name'] as String?)?.toLowerCase() ?? '';
              final String id = cake['id']?.toString() ?? '1';
              // Use a unique seed for each cake so fallbacks are different
              imageUrl = 'https://picsum.photos/seed/${id + name}/600/600';
            }



            // Extract category name from relation
            final catObj = cake['category'];
            final String catName = (catObj is Map) ? (catObj['name'] ?? 'General') : 'General';

            return {
              'id': cake['id'],
              'title': (cake['name'] as String?) ?? 'Unnamed',
              'price': priceDisplay,
              'numericPrice': numericPrice,
              'image': imageUrl,
              'description': (cake['description'] as String?) ?? '',
              'category': catName,
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
          categories = ["All", "Cakes", "Pastries", "Savories"];
          
          if (widget.initialSearchQuery != null) {
            final queryLower = widget.initialSearchQuery!.trim().toLowerCase();
            final matchedCat = categories.firstWhere(
              (c) => c.toLowerCase() == queryLower,
              orElse: () => '',
            );
            
            if (matchedCat.isNotEmpty) {
              _selectedCategory = matchedCat;
              _searchController.clear();
            } else {
              _selectedCategory = "All";
              _searchController.text = widget.initialSearchQuery!;
            }
          }

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
      final query = _searchController.text.trim().toLowerCase();
      List<Map<String, dynamic>> temp = [];

      if (_selectedCategory == "All") {
        temp = List.from(menuItems);
      } else {
        temp = menuItems.where((item) {
          final category = (item['category'] as String?) ?? 'Cakes';
          return category.toLowerCase().contains(_selectedCategory.toLowerCase());
        }).toList();
      }

      if (query.isNotEmpty) {
        temp = temp.where((item) {
          final name = (item['title'] as String?)?.toLowerCase() ?? '';
          final description = (item['description'] as String?)?.toLowerCase() ?? '';
          final category = (item['category'] as String?)?.toLowerCase() ?? '';
          return name.contains(query) || description.contains(query) || category.contains(query);
        }).toList();
      }

      filteredItems = temp;
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) => _filterByCategory(),
                      decoration: InputDecoration(
                        hintText: "Search delicacies...",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: secondaryColor.withValues(alpha: 0.4),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: primaryColor),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterByCategory();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
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
                              side: BorderSide(color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.1)),
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
                          color: secondaryColor.withValues(alpha: 0.6),
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
                  child: Image.network(
                  item['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  cacheHeight: 120,
                  errorBuilder: (_, _, _) {
                    final id = item['id']?.toString() ?? item['title'].toString();
                    return Image.network(
                      'https://picsum.photos/seed/$id/120/120',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                ),
                title: Text(item['title'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                subtitle: Text(item['price'], style: GoogleFonts.notoSerif(color: primary, fontWeight: FontWeight.bold)),
                trailing: Consumer<FavoritesProvider>(
                  builder: (context, favorites, _) {
                    final isFav = favorites.isFavorite(item['id']?.toString(), item['title']);
                    return IconButton(
                      onPressed: () => favorites.toggleFavorite(item),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? primary : Colors.grey.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    );
                  },
                ),
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
          cakeId: item['id']?.toString(),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'],
                    fit: BoxFit.cover,
                    cacheWidth: 400,
                    errorBuilder: (_, _, _) {
                      final id = item['id']?.toString() ?? item['title'].toString();
                      return Image.network(
                        'https://picsum.photos/seed/$id/600/600',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              ),
            ),
            Consumer<FavoritesProvider>(
              builder: (context, favorites, _) {
                final isFav = favorites.isFavorite(item['id']?.toString(), item['title']);
                return IconButton(
                  onPressed: () => favorites.toggleFavorite(item),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? primary : Colors.grey.withValues(alpha: 0.3),
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
