import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';
import 'menu_details_page.dart';

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
  Set<String> _selectedCategories = {'All'};
  final List<String> _categories = [
    'All',
    'Chocolate Cakes',
    'Vanilla Cakes',
    'Tea Cakes',
    'Seasonal Cakes',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          backgroundColor: cs.surface,
          floatingActionButton: FloatingActionButton(
            backgroundColor: cs.primary,
            elevation: 6,
            shape: const CircleBorder(),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMenuPage(
                    onTabChanged: widget.onTabChanged,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getMenuStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService.fetchMenu(), // To get CakeOptions
                builder: (context, menuSnapshot) {
                  final List<Map<String, dynamic>> rawCakes = menuSnapshot.data ?? snapshot.data ?? [];
              final List<_MenuItem> allItems = rawCakes.map((data) {
                final options = data['CakeOption'] as List? ?? [];
                final basePrice = options.isNotEmpty 
                    ? SupabaseService.formatPrice(options[0]['price']) 
                    : "N/A";
                final baseServes = options.isNotEmpty ? "Serves ${options[0]['serves']}" : "";

                return _MenuItem(
                  id: data['id'],
                  name: data['name'] ?? 'Untitled Cake',
                  category: data['category'] ?? 'General',
                  price: basePrice,
                  description: data['description'] ?? '',
                  serves: baseServes,
                  weight: "Standard",
                  imageUrl: SupabaseService.getPublicUrl(data['image']),
                );
              }).toList();

              // Filtering logic
              final List<_MenuItem> items = allItems.where((item) {
                if (_selectedCategories.contains('All')) return true;
                
                return _selectedCategories.any((filter) {
                  final cat = item.category.toLowerCase();
                  final f = filter.toLowerCase();
                  
                  if (f.contains('chocolate')) return cat.contains('chocolate');
                  if (f.contains('vanilla')) return cat.contains('vanilla');
                  if (f.contains('tea')) return cat.contains('tea');
                  if (f.contains('seasonal')) return cat.contains('seasonal');
                  
                  return cat.contains(f);
                });
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
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Atelier Collection",
                            style: GoogleFonts.notoSerif(
                              color: cs.secondary,
                              fontSize: isDesktop ? 32 : 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${items.length} items cataloged",
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Category Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categories.map((category) {
                                final isSelected = _selectedCategories.contains(category);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(
                                      category.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        letterSpacing: 1.0,
                                        color: isSelected ? Colors.white : cs.secondary,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      setState(() {
                                        if (category == 'All') {
                                          _selectedCategories = {'All'};
                                        } else {
                                          _selectedCategories.remove('All');
                                          if (val) {
                                            _selectedCategories.add(category);
                                          } else {
                                            _selectedCategories.remove(category);
                                          }
                                          if (_selectedCategories.isEmpty) {
                                            _selectedCategories = {'All'};
                                          }
                                        }
                                      });
                                    },
                                    selectedColor: cs.primary,
                                    backgroundColor: cs.surfaceContainer,
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: isSelected ? cs.primary : cs.secondary.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: cs.secondary.withValues(alpha: 0.05)),
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
            );
          },
        ),
      );
    },
  );
}
}

class _MenuItem {
  final String id;
  final String name;
  final String category;
  final String price;
  final String description;
  final String serves;
  final String weight;
  final String imageUrl;

  _MenuItem({
    required this.id,
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuDetailsPage(cakeId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: cs.secondary.withValues(alpha: 0.03),
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
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surface,
                    child: Icon(Icons.cake, color: cs.primary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          item.price,
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: cs.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 10, color: cs.secondary.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(
                          item.serves,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: cs.secondary.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.primary.withValues(alpha: 0.05),
        child: Icon(Icons.cake_outlined,
            size: 24, color: cs.primary.withValues(alpha: 0.2)),
      );
}

class AddMenuPage extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  const AddMenuPage({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: cs.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isDesktop ? "Sonna's Patisserie & Cafe" : "New Menu Item",
              style: GoogleFonts.notoSerif(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
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
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add New Cake",
                  style: GoogleFonts.notoSerif(
                    color: cs.secondary,
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
          color: cs.secondary.withValues(alpha: 0.3),
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
                        backgroundColor: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: GoogleFonts.notoSerif(
        color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(color: cs.secondary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.3),
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: cs.primary.withValues(alpha: 0.6))
                : null,
            filled: true,
            fillColor: cs.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.secondary.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.secondary.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}
