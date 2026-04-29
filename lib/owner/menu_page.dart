import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';

// Brand Colors - Sweet Pink Bakery Theme
const Color _primaryColor = Color(0xFFFF4D8D);
const Color _secondaryColor = Color(0xFF701235);
const Color _bgColor = Color(0xFFFFF0F6);

// ─────────────────────────────────────────────
//  MenuPage — the landing page (shows all items)
// ─────────────────────────────────────────────
class MenuPage extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  const MenuPage({super.key, this.onTabChanged});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Dummy menu items – replace with real data source later
  final List<_MenuItem> _items = [
    _MenuItem(
      name: "Sonna's Classic Chocolate",
      category: "Chocolate Based",
      price: "₹675",
      description: "Chocolate Whipped Ganache",
      serves: "Serves 4–6",
      weight: "600 grams",
      imageUrl:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuByamhClb3gDhF3nngRFpLvkbtTTHarLWuqt4-agAtERKXjlvCqO0UX3yoFz8JcqTxXexzX6nYk_VgLcK0PhyPJcetaMu0wIt5XswIYgIbUVmdoLWucs7HsL6WEwnGYbjBT8Dju38uIOlCwkRSaksxz6v2pSSi1xjhD_tiuMHQWhwmm3o8mBSZGVB41NEqCjepzdUc_TgIx4FsF49JV6XFveVlL76uJKML55RWk6tpcySzc2TFE1MfrNg1sUXJ6BKv69tr904uK6oSO",
    ),
    _MenuItem(
      name: "Rose Petal Macarons",
      category: "French Collection",
      price: "₹480",
      description: "Delicate almond shell with rose cream",
      serves: "Box of 12",
      weight: "300 grams",
      imageUrl:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCM8kvDF0eQhzkrDce4yaFTqilGBWhOLlO7wx60ONJurXiVrOtd_OxtCoHsnovhs-8sOoq92Ge3JOQgpTx1oNV_v1IzLMg43-0LwUsR9OzGAfZccvybEMZ22DzEIM-srgN-y7WK9b4AR1SDByB7KIYM2HGlZM-MoZp92RfDAUA8G4G0UdbTulmCbP2ZjUea_9_CaMYy7htLKkWx57MRNRlbGuIw8KS6KwLl8N_IJE6tln_1kG0Yew4Fdjq7GVdOV1cKn4T_Ya6-u7-M",
    ),
    _MenuItem(
      name: "Wild Strawberry Tart",
      category: "Seasonal Specials",
      price: "₹550",
      description: "Fresh strawberries on vanilla custard",
      serves: "Serves 2–4",
      weight: "400 grams",
      imageUrl:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuBgLiZjc9axvI-eFs8vO1zzxXSfph_zKSHA9tUul1gcWpf1QEOdqEipFJuCWmE0P8H9Mq_9T6s6P2dAUoW4WGiI94z-4QrxdHl7AYmzfzGCy5GOgFQAo4TmUwJnSFPSTtkV8bBW20fV0MurGRSB4jnPK111Qxuv2yiTQ2CIfFHGRGyXA1CZbUmlIs-v6A3RHMYNqdsl0PoOJJxyZ_lFRObqOKAnKPqc_4mCp1DvHn01byvns9Mc3JHBquVh_j04E5LWBNRgrLU-tRzQ",
    ),
    _MenuItem(
      name: "Valrhona Signature Noir",
      category: "Chocolate Based",
      price: "₹920",
      description: "Single-origin 72% dark chocolate mousse",
      serves: "Serves 6–8",
      weight: "800 grams",
      imageUrl:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuBcgLx1wB_YtTPx7L-WwIzghvzvQLj43G009Tgdx1uD4KLxn2vWlH6YUZ1Q-lGTQDvpN7xaz-2nVbwjmzbWH5ylkGSkDiW8LNpmC5ljF6E-YfV1jzZ722iWXWt54gfNS20E0rusxK9a6S6r-7-OF0xFjPztm4XQ1cgCxkjCtUyNihoSVuaq8U0Mod44tySWkS4pqXYdjaaQfrsGu29MLQQJ8kscebLKA_DsNJP8ivJhk-YGokXGBIpPivIso3tcIiM_1tlyEnfpI0Od",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final crossAxisCount = constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;

        return Scaffold(
          backgroundColor: _bgColor,
          floatingActionButton: FloatingActionButton(
            backgroundColor: _primaryColor,
            elevation: 6,
            shape: const CircleBorder(),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMenuPage(
                    onTabChanged: widget.onTabChanged,
                  ),
                ),
              );
              if (result is _MenuItem) {
                setState(() => _items.add(result));
              }
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: SupabaseService.fetchMenu(),
            builder: (context, snapshot) {
              if (snapshot.hasData) debugPrint('DEBUG: Cakes Count: ${snapshot.data?.length}');
              if (snapshot.hasError) debugPrint('DEBUG: Menu Error: ${snapshot.error}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final List<Map<String, dynamic>> rawCakes = snapshot.data ?? [];
              final List<_MenuItem> items = rawCakes.map((data) {
                // Handle nested options for price/size
                final options = data['CakeOption'] as List? ?? [];
                final basePrice = options.isNotEmpty ? "₹${options[0]['price']}" : "N/A";
                final baseServes = options.isNotEmpty ? "Serves ${options[0]['serves']}" : "";

                return _MenuItem(
                  name: data['name'] ?? 'Untitled Cake',
                  category: data['category'] ?? 'General',
                  price: basePrice,
                  description: data['description'] ?? '',
                  serves: baseServes,
                  weight: "Standard",
                  imageUrl: SupabaseService.getPublicUrl(data['image']),
                );
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          isDesktop ? 48 : 24, 20, isDesktop ? 48 : 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OUR MENU",
                            style: GoogleFonts.plusJakartaSans(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Atelier Collection",
                            style: GoogleFonts.notoSerif(
                              color: _secondaryColor,
                              fontSize: isDesktop ? 32 : 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${items.length} items cataloged",
                            style: GoogleFonts.plusJakartaSans(
                              color: _secondaryColor.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: _secondaryColor.withValues(alpha: 0.05)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 48 : 16, 16, isDesktop ? 48 : 16, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          debugPrint('DEBUG: Menu Item Image URL: ${item.imageUrl}');
                          return _MenuItemCard(item: item);
                        },
                        childCount: items.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 130, 
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String name;
  final String category;
  final String price;
  final String description;
  final String serves;
  final String weight;
  final String imageUrl;

  _MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.serves,
    required this.weight,
    this.imageUrl = "",
  });
}

class _MenuItemCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _secondaryColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 110,
              height: double.infinity,
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: _secondaryColor.withValues(alpha: 0.05),
                          child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      },
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        item.price,
                        style: GoogleFonts.notoSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: _secondaryColor.withValues(alpha: 0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.people_outline, 
                           size: 12, 
                           color: _secondaryColor.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Text(
                        item.serves,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: _secondaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _primaryColor.withValues(alpha: 0.05),
        child: Icon(Icons.cake_outlined,
            size: 24, color: _primaryColor.withValues(alpha: 0.2)),
      );
}

// ─────────────────────────────────────────────
//  AddMenuPage — opened when "+" is tapped
// ─────────────────────────────────────────────
class AddMenuPage extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  const AddMenuPage({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isDesktop ? "Sonna's Patisserie & Cafe" : "New Menu Item",
              style: GoogleFonts.notoSerif(
                color: isDesktop
                    ? const Color.fromARGB(255, 146, 6, 53)
                    : _primaryColor,
                fontStyle: isDesktop ? FontStyle.italic : FontStyle.normal,
                fontWeight: isDesktop ? FontWeight.w600 : FontWeight.bold,
                fontSize: isDesktop ? 20 : 18,
                letterSpacing: isDesktop ? -0.5 : 0,
              ),
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: 3,
                  onTap: (index) {
                    Navigator.pop(context);
                    onTabChanged?.call(index);
                  },
                ),
              Expanded(
                child: _AddMenuContent(isDesktop: isDesktop),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Add Menu Form (was the old MenuPage content)
// ─────────────────────────────────────────────
class _AddMenuContent extends StatefulWidget {
  final bool isDesktop;
  const _AddMenuContent({required this.isDesktop});

  @override
  State<_AddMenuContent> createState() => _AddMenuContentState();
}

class _AddMenuContentState extends State<_AddMenuContent> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 48.0 : 16.0,
        vertical: 24.0,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MENU ITEM",
                  style: GoogleFonts.plusJakartaSans(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add New Cake",
                  style: GoogleFonts.notoSerif(
                    color: _secondaryColor,
                    fontSize: widget.isDesktop ? 48 : 32,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: _secondaryColor.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 48),

        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader("Pâtisserie Details"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Category",
                            hint: "e.g. Chocolate Based",
                            icon: Icons.category,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Category Subtitle",
                            hint: "e.g. Indulgent artisan chocolate",
                            icon: Icons.subtitles,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Category",
                      hint: "e.g. Chocolate Based",
                      icon: Icons.category,
                    ),
                    SizedBox(height: 16),
                    _InputField(
                      label: "Category Subtitle",
                      hint: "e.g. Indulgent artisan chocolate",
                      icon: Icons.subtitles,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _InputField(
                    label: "Item Name",
                    hint: "e.g. SONNA'S CLASSIC CHOCOLATE",
                    icon: Icons.cake,
                  ),
                  const SizedBox(height: 24),
                  if (isTwoCol)
                    Row(
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Item Flavors",
                            hint: "e.g. Chocolate cake",
                            icon: Icons.auto_awesome,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Price",
                            hint: "e.g. 675/-",
                            icon: Icons.currency_rupee,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Item Flavors",
                      hint: "e.g. Chocolate cake",
                      icon: Icons.auto_awesome,
                    ),
                    SizedBox(height: 24),
                    _InputField(
                      label: "Price",
                      hint: "e.g. 675/-",
                      icon: Icons.currency_rupee,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _InputField(
                    label: "Item Description",
                    hint: "e.g. Chocolate Whipped Ganache",
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 48),

                  const _SectionHeader("Portions & Servings"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Weight",
                            hint: "e.g. 600 grams",
                            icon: Icons.scale,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Serves",
                            hint: "e.g. Serves 4-6",
                            icon: Icons.people,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Weight",
                      hint: "e.g. 600 grams",
                      icon: Icons.scale,
                    ),
                    SizedBox(height: 16),
                    _InputField(
                      label: "Serves",
                      hint: "e.g. Serves 4-6",
                      icon: Icons.people,
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Product added successfully!")),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "ADD PRODUCT TO MENU",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.notoSerif(
        color: _primaryColor,
        fontSize: 20,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(color: _secondaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: _secondaryColor.withValues(alpha: 0.3),
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: _primaryColor.withValues(alpha: 0.6))
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _secondaryColor.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _secondaryColor.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
