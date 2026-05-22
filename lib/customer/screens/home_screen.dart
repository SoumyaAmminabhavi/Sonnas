import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';
import 'contact_screen.dart';
import 'product_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  final void Function(String?) onViewMenu;
  const HomeScreen({super.key, required this.onViewMenu});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> featuredCakes = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;
  Timer? _promoTimer;

  final List<Map<String, dynamic>> _promoOffers = [
    {
      'title': "TODAY'S PICK",
      'subtitle': "White Chocolate Raspberry Gateau",
      'discount': "15% OFF today only! Use code SONNA15",
      'bgGradient': [const Color(0xFFFF4D8D), const Color(0xFFFFB6D3)],
      'icon': Icons.star_rounded,
      'code': "SONNA15",
    },
    {
      'title': "WEEKEND SPECIAL",
      'subtitle': "Signature French Macarons Box",
      'discount': "Buy 1 Get 1 Free on all boxes!",
      'bgGradient': [const Color(0xFF701235), const Color(0xFFC2185B)],
      'icon': Icons.card_giftcard_rounded,
      'code': "MACARONBOGO",
    },
    {
      'title': "CUSTOM CREATIONS",
      'subtitle': "Premium Birthday & Anniversary Cakes",
      'discount': "Book 3 days ahead for free delivery!",
      'bgGradient': [const Color(0xFFE26D5C), const Color(0xFFF0A202)],
      'icon': Icons.palette_rounded,
      'code': "FREEDELIVERY",
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchFeaturedCakes();
    _startPromoTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _promoController.dispose();
    _promoTimer?.cancel();
    super.dispose();
  }

  void _startPromoTimer() {
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promoController.hasClients) {
        setState(() {
          _currentPromoPage = (_currentPromoPage + 1) % _promoOffers.length;
        });
        _promoController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchFeaturedCakes() async {
    try {
      final supabase = Supabase.instance.client;
      // Fetch from 'Cake' and 'CakeOption' for the home screen
      final data = await supabase
          .from('Cake')
          .select('*, options:CakeOption(*)')
          .limit(5);
      
      if (mounted) {
        setState(() {
          featuredCakes = List<Map<String, dynamic>>.from(data).map((cake) {
            final options = cake['options'] as List?;
            debugPrint("DEBUG: Cake ${cake['name']} has ${options?.length ?? 0} options");
            
            String price = "₹ 0.00";
            if (options != null && options.isNotEmpty) {
              final rawPrice = options[0]['price']?.toString() ?? "0";
              final numericPrice = (double.tryParse(rawPrice) ?? 0.0) / 100.0;
              price = "₹ ${numericPrice.toStringAsFixed(2)}";
            }

            // Robust image URL generation
            final String imageName = (cake['image'] as String?) ?? '';
            String imageUrl = '';

            if (imageName.startsWith('http')) {
              imageUrl = imageName;
            } else if (imageName.isNotEmpty) {
              final cleanPath = imageName
                  .replaceFirst('cakes/', '')
                  .replaceFirst('/cakes/', '')
                  .replaceAll('.pngpng', '.png');
              
              imageUrl = supabase.storage.from('cakes').getPublicUrl(cleanPath);
            }

            // Fallback for missing or broken images
            if (imageUrl.isEmpty || imageUrl.contains('null')) {
              final String name = (cake['name'] as String?)?.toLowerCase() ?? '';
              final String id = cake['id']?.toString() ?? '1';
              imageUrl = 'https://picsum.photos/seed/${id + name}/600/600';
            }

            return {
              'id': cake['id']?.toString() ?? '',
              'title': (cake['name'] as String?) ?? 'Unnamed',
              'price': price,
              'image': imageUrl,
              'rawOptions': options ?? [],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching featured cakes: $e");
      if (mounted) {
        setState(() {
          featuredCakes = [
            {
              'id': '1',
              'title': "Classic Chocolate",
              'price': "₹ 650",
              'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000&auto=format&fit=crop',
              'rawOptions': <dynamic>[],
            },
            {
              'id': '2',
              'title': "Strawberry Bliss",
              'price': "₹ 720",
              'image': 'https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=1000&auto=format&fit=crop',
              'rawOptions': <dynamic>[],
            },
            {
              'id': '3',
              'title': "Red Velvet",
              'price': "₹ 680",
              'image': 'https://images.unsplash.com/photo-1616541823729-00fe0aacd32c?q=80&w=1000&auto=format&fit=crop',
              'rawOptions': <dynamic>[],
            },
          ];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Using local cache (Backend restricted)"), backgroundColor: Color(0xFFFF4D8D)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);


    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const CustomerTrackingScreen()),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.delivery_dining, color: Colors.white),
        label: Text(
          "TRACKING",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            SizedBox(
              height: 500,
              width: double.infinity,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/storefront.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                          height: 500,
                        ),
                      ),
                      Expanded(
                        child: Image.asset(
                          'assets/patisserie_bg.png',
                          fit: BoxFit.cover,
                          height: 500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          background.withValues(alpha: 1.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Sonna's Patisserie",
                          style: GoogleFonts.notoSerif(
                            fontSize: 40,
                            color: const Color(0xFFFF4D8D),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSearchBar(primaryColor),
            const SizedBox(height: 32),
            _buildPromoCarousel(primaryColor),
            const SizedBox(height: 32),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "OUR CATEGORIES",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildCategoryItem("Cakes", Icons.cake_outlined),
                  _buildCategoryItem("Pastries", Icons.bakery_dining_outlined),
                  _buildCategoryItem("Savories", Icons.breakfast_dining_outlined),
                  _buildCategoryItem("Macarons", Icons.cookie_outlined),
                  _buildCategoryItem("Custom", Icons.edit_note_outlined),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Slides Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "SIGNATURE SLIDES",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              )
            else if (featuredCakes.isEmpty)
              const SizedBox(
                height: 240,
                child: Center(child: Text("Our signature items will be back shortly.")),
              )
            else
              SizedBox(
                height: 240,
                child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: featuredCakes.length,
                itemBuilder: (context, index) {
                  final cake = featuredCakes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => ProductDetailScreen(
                              cakeId: cake['id'] as String,
                              title: cake['title'] as String,
                              price: cake['price'] as String,
                              imageUrl: cake['image'] as String,
                              rawOptions: cake['rawOptions'] as List<dynamic>,
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 180,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  cake['image']?.toString() ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    child: const Icon(Icons.cake, color: primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cake['title']?.toString() ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFFF4D8D),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        cake['price']?.toString() ?? '',
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final favorites = ref.watch(customerFavoritesProvider);
                                    final isFav = favorites.isFavorite(null, cake['title']?.toString() ?? '');
                                    return IconButton(
                                      onPressed: () => ref.read(customerFavoritesProvider.notifier).toggleFavorite(cake),
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? primaryColor : Colors.grey.withValues(alpha: 0.4),
                                        size: 18,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 64),

            // Action Section
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _buildMainButton(
                      "EXPLORE FULL MENU",
                      onPressed: () => widget.onViewMenu(null),
                      isGradient: true,
                    ),
                    const SizedBox(height: 16),
                    _buildMainButton(
                      "CONTACT SONNA'S PATISSERIE",
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute<void>(builder: (context) => const ContactScreen()));
                      },
                      isGradient: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, {required VoidCallback onPressed, bool isGradient = false}) {
    const Color primaryColor = Color(0xFFFF4D8D);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isGradient
            ? const LinearGradient(
                colors: [Color(0xFFFF4D8D), Color(0xFFFFB6D3)],
              )
            : null,
        border: isGradient ? null : Border.all(color: primaryColor.withValues(alpha: 0.2)),
        color: isGradient ? null : Colors.white.withValues(alpha: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: isGradient ? Colors.white : primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon) {
    const Color primaryColor = Color(0xFFFF4D8D);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () => widget.onViewMenu(name),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF701235),
        ),
        decoration: InputDecoration(
          hintText: "Search for chocolates, custom cakes...",
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF701235).withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_forward_rounded, color: primaryColor),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                widget.onViewMenu(_searchController.text.trim());
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onViewMenu(value.trim());
          }
        },
      ),
    );
  }

  Widget _buildPromoCarousel(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "DAILY SPECIALS",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _promoController,
            onPageChanged: (index) {
              setState(() {
                _currentPromoPage = index;
              });
            },
            itemCount: _promoOffers.length,
            itemBuilder: (context, index) {
              final promo = _promoOffers[index];
              final List<Color> gradientColors = promo['bgGradient'] as List<Color>;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Icon(
                          promo['icon'] as IconData,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                promo['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promo['subtitle'] as String,
                              style: GoogleFonts.notoSerif(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promo['discount'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoOffers.length, (index) {
            final isCurrent = _currentPromoPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isCurrent ? 18 : 6,
              decoration: BoxDecoration(
                color: isCurrent ? primaryColor : primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
