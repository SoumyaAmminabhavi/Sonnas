import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shimmer/shimmer.dart';
import 'dart:io' show File;
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/menu_service.dart';
import '../widgets/owner_sidebar.dart';
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
                  builder: (_) =>
                      AddMenuPage(onTabChanged: widget.onTabChanged),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: MenuService.getMenuStream(),
            builder: (context, snapshot) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: MenuService.fetchMenu(),
                builder: (context, menuSnapshot) {
                  if (!menuSnapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                    final cs2 = Theme.of(context).colorScheme;
                    return Shimmer.fromColors(
                      baseColor: cs2.surfaceContainer,
                      highlightColor: cs2.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: crossAxisCount * 2,
                          itemBuilder: (_, __) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (menuSnapshot.hasError || snapshot.hasError) {
                    final error = (menuSnapshot.error ?? snapshot.error).toString();
                    return _MenuErrorView(
                      cs: cs,
                      error: error,
                      onRetry: () {
                        setState(() {});
                      },
                    );
                  }

                  final List<Map<String, dynamic>> rawCakes = menuSnapshot.data ?? snapshot.data ?? [];
              final List<_MenuItem> allItems = rawCakes.map((data) {
                final options = data['CakeOption'] as List? ?? [];
                final basePrice = options.isNotEmpty
                    ? OrderService.formatPrice(options[0]['price'])
                    : (data['price'] != null
                          ? OrderService.formatPrice(data['price'])
                          : "Price on Request");
                final baseServes = options.isNotEmpty
                    ? "Serves ${options[0]['serves']}"
                    : "";

                return _MenuItem(
                  id: data['id'],
                  name: data['name'] ?? 'Untitled Cake',
                  category: data['category'] ?? 'General',
                  price: basePrice,
                  description: data['description'] ?? '',
                  serves: baseServes,
                  weight: "Standard",
                  imageUrl: SupabaseService.getPublicUrl(data['image'], width: 250, height: 250),
                );
              }).toList();

              // Dynamic Categories
              final Set<String> uniqueCategories = {'All'};
              for (var item in allItems) {
                if (item.category.isNotEmpty) {
                  uniqueCategories.add(item.category);
                }
              }
              final List<String> categories = uniqueCategories.toList()
                ..sort((a, b) {
                  if (a == 'All') return -1;
                  if (b == 'All') return 1;
                  return a.compareTo(b);
                });

              // Filtering logic
              final List<_MenuItem> items = allItems.where((item) {
                if (_selectedCategories.contains('All')) return true;
                return _selectedCategories.contains(item.category);
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 48 : 24,
                        20,
                        isDesktop ? 48 : 24,
                        0,
                      ),
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
                              children: categories.map((category) {
                                final isSelected = _selectedCategories.contains(
                                  category,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(
                                      category.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        letterSpacing: 1.0,
                                        color: isSelected
                                            ? Colors.white
                                            : cs.secondary,
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
                                            _selectedCategories.remove(
                                              category,
                                            );
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
                                        color: isSelected
                                            ? cs.primary
                                            : cs.secondary.withValues(
                                                alpha: 0.1,
                                              ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
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
                      isDesktop ? 48 : 16,
                      16,
                      isDesktop ? 48 : 16,
                      100,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return _MenuItemCard(
                          item: item,
                          onTabChanged: widget.onTabChanged,
                        );
                      }, childCount: items.length),
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

class _MenuErrorView extends StatelessWidget {
  final ColorScheme cs;
  final String error;
  final VoidCallback onRetry;

  const _MenuErrorView({
    required this.cs,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: cs.primary.withValues(alpha: 0.1), size: 64),
            const SizedBox(height: 24),
            Text(
              "Collection Unavailable",
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "We're having trouble reaching the atelier's menu. Let's try refreshing the collection.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: cs.secondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "REFRESH MENU",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final _MenuItem item;
  final ValueChanged<int>? onTabChanged;
  const _MenuItemCard({required this.item, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MenuDetailsPage(cakeId: item.id, onTabChanged: onTabChanged),
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
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: double.infinity,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: cs.surface,
                    child: Icon(
                      Icons.cake,
                      color: cs.primary.withValues(alpha: 0.2),
                    ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        Icon(
                          Icons.people_outline,
                          size: 10,
                          color: cs.secondary.withValues(alpha: 0.3),
                        ),
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
}

class AddMenuPage extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  final Map<String, dynamic>? cakeData;
  const AddMenuPage({super.key, this.onTabChanged, this.cakeData});

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
              isDesktop
                  ? "Sonna's Patisserie & Cafe"
                  : (cakeData != null ? "Edit Item" : "New Menu Item"),
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
                    if (!context.mounted) return;
                    // Use popUntil to return to the OwnerDashboard specifically
                    Navigator.of(context).popUntil((route) => route.settings.name == 'OwnerDashboard' || route.isFirst);
                    onTabChanged?.call(index);
                  },
                ),
              Expanded(
                child: _AddMenuContent(
                  isDesktop: isDesktop,
                  initialData: cakeData,
                ),
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
  final Map<String, dynamic>? initialData;
  const _AddMenuContent({required this.isDesktop, this.initialData});

  @override
  State<_AddMenuContent> createState() => _AddMenuContentState();
}

class _AddMenuContentState extends State<_AddMenuContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedCategory;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _servesController;

  final _picker = ImagePicker();
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final options = data?['CakeOption'] as List? ?? [];
    final firstOption = options.isNotEmpty ? options[0] as Map<String, dynamic> : null;

    final priceValue = firstOption?['price'];
    double displayPrice = 0;
    if (priceValue is num) {
      displayPrice = priceValue.toDouble() / 100.0;
    } else if (priceValue != null) {
      displayPrice = (double.tryParse(priceValue.toString()) ?? 0) / 100.0;
    }

    _nameController = TextEditingController(text: data?['name']?.toString());
    _selectedCategory = data?['category']?.toString();
    _priceController = TextEditingController(
      text: displayPrice > 0 ? displayPrice.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: data?['description']?.toString());
    _weightController = TextEditingController(text: firstOption?['weight']?.toString() ?? '');
    _servesController = TextEditingController(text: firstOption?['serves']?.toString() ?? '');
    _existingImageUrl = data?['image'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _servesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String? imagePath = _existingImageUrl;

      // 1. Upload new image if selected
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final extension = _selectedImage!.path.split('.').last;
        final fileName = 'cake_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        final uploadedPath = await SupabaseService.uploadImage(
          bucket: 'staff-images', // Using the existing bucket for now
          path: fileName,
          file: bytes,
        );
        
        if (uploadedPath != null) {
          imagePath = fileName;
        }
      }

      // 2. Save cake details
      final cakeId = await MenuService.upsertCake({
        if (widget.initialData != null) 'id': widget.initialData!['id'],
        'name': _nameController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'image': imagePath,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 3. Save cake options
      await MenuService.upsertCakeOption({
        'cakeId': cakeId,
        'price': (double.tryParse(_priceController.text.replaceAll('/-', '')) ?? 0) * 100,
        'weight': _weightController.text,
        'serves': _servesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Catalog updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = widget.isDesktop
            ? (constraints.maxWidth > 850 ? (constraints.maxWidth - 850) / 2 : 48.0)
            : 16.0;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
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
                  widget.initialData != null ? "Edit Creation" : "Add New Cake",
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
        Container(height: 1, color: cs.secondary.withValues(alpha: 0.3)),
        const SizedBox(height: 48),

        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader("Creation Image"),
                  const SizedBox(height: 16),
                  _buildImagePicker(cs),
                  const SizedBox(height: 32),
                  const _SectionHeader("Pâtisserie Details"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown(cs)),
                        const SizedBox(width: 24),
                        const Spacer(),
                      ],
                    )
                  else
                    _buildCategoryDropdown(cs),
                  const SizedBox(height: 24),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: "Item Name",
                            hint: "e.g. SONNA'S CLASSIC CHOCOLATE",
                            icon: Icons.cake,
                            controller: _nameController,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Price",
                            hint: "e.g. 675/-",
                            icon: Icons.currency_rupee,
                            controller: _priceController,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _InputField(
                      label: "Item Name",
                      hint: "e.g. SONNA'S CLASSIC CHOCOLATE",
                      icon: Icons.cake,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: "Price",
                      hint: "e.g. 675/-",
                      icon: Icons.currency_rupee,
                      controller: _priceController,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _InputField(
                    label: "Item Description",
                    hint: "e.g. Chocolate Whipped Ganache",
                    icon: Icons.description,
                    maxLines: 3,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 48),

                  const _SectionHeader("Portions & Servings"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: "Weight",
                            hint: "e.g. 600 grams",
                            icon: Icons.scale,
                            controller: _weightController,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Serves",
                            hint: "e.g. Serves 4-6",
                            icon: Icons.people,
                            controller: _servesController,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _InputField(
                      label: "Weight",
                      hint: "e.g. 600 grams",
                      icon: Icons.scale,
                      controller: _weightController,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: "Serves",
                      hint: "e.g. Serves 4-6",
                      icon: Icons.people,
                      controller: _servesController,
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Text(
                              widget.initialData != null
                                  ? "SAVE CHANGES"
                                  : "CATALOG CREATION",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ],
    );
   },
  );
 }

  Widget _buildCategoryDropdown(ColorScheme cs) {
    final categories = [
      'Chocolate Cakes',
      'Fruit & Floral Cakes',
      'Artisan Pastries',
      'Cheesecakes',
      'Cookies & Macarons',
      'Savory Delights',
      'Seasonal Cakes',
      'Slices',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CATEGORY",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          hint: Text(
            "Select Collection",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.category,
              color: cs.primary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: cs.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.secondary.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.secondary.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: cs.secondary, size: 20),
          dropdownColor: cs.surface,
          items: categories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                c,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ],
    );
  }

  Widget _buildImagePicker(ColorScheme cs) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: widget.isDesktop ? 600 : double.infinity,
          height: widget.isDesktop ? 450 : 300,
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: cs.secondary.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _selectedImage != null
                ? kIsWeb
                    ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                    ? Image.network(
                        SupabaseService.getPublicUrl(_existingImageUrl),
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: cs.primary.withValues(alpha: 0.4),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "TAP TO SELECT IMAGE",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

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
  final TextEditingController? controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.controller,
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
          controller: controller,
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
              borderSide: BorderSide(
                color: cs.secondary.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.secondary.withValues(alpha: 0.1),
              ),
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
