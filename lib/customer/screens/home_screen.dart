import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';
import 'contact_screen.dart';
import 'product_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onViewMenu;
  const HomeScreen({super.key, required this.onViewMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> featuredCakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedCakes();
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
            String price = "₹ 0.00";
            if (options != null && options.isNotEmpty) {
              final numericPrice = (double.tryParse(options[0]['price']?.toString() ?? "0") ?? 0.0) / 100.0;
              price = "₹ ${numericPrice.toStringAsFixed(2)}";
            }
            return {
              'title': (cake['name'] as String?) ?? 'Unnamed',
              'price': price,
              'image': (cake['image'] as String?) ?? '',
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
              'title': "Classic Chocolate",
              'price': "₹ 650",
              'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000&auto=format&fit=crop',
            },
            {
              'title': "Strawberry Bliss",
              'price': "₹ 720",
              'image': 'https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=1000&auto=format&fit=crop',
            },
            {
              'title': "Red Velvet",
              'price': "₹ 680",
              'image': 'https://images.unsplash.com/photo-1616541823729-00fe0aacd32c?q=80&w=1000&auto=format&fit=crop',
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
            MaterialPageRoute(builder: (context) => CustomerTrackingScreen()),
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
                          Colors.black.withOpacity(0.2),
                          background.withOpacity(1.0),
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
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              title: cake['title']!,
                              price: cake['price']!,
                              imageUrl: cake['image']!,
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
                                color: primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  cake['image']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: primaryColor.withOpacity(0.1),
                                    child: const Icon(Icons.cake, color: primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cake['title']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF4D8D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cake['price']!,
                              style: GoogleFonts.notoSerif(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
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
                      onPressed: widget.onViewMenu,
                      isGradient: true,
                    ),
                    const SizedBox(height: 16),
                    _buildMainButton(
                      "CONTACT SONNA'S PATISSERIE",
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen()));
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
        border: isGradient ? null : Border.all(color: primaryColor.withOpacity(0.2)),
        color: isGradient ? null : Colors.white.withOpacity(0.8),
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
        onTap: widget.onViewMenu,
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
                    color: primaryColor.withOpacity(0.1),
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
                color: primaryColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
