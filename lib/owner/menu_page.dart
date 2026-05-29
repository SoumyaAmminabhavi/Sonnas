import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/menu_service.dart';
import '../services/dashboard_provider.dart';
import '../services/constants.dart';
import '../services/image_conversion.dart';
import '../widgets/owner_sidebar.dart';
import 'menu_details_page.dart';


// ─────────────────────────────────────────────
//  MenuPage — the landing page (shows all items)
// ─────────────────────────────────────────────
class MenuPage extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTabChanged;
  const MenuPage({super.key, this.onTabChanged});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  Set<String> _selectedCategories = {'All'};
  bool _isUpdatingCategories = false;

  void _showManageCategoriesSheet(
    BuildContext context,
    List<Map<String, dynamic>> initialCategories,
    List<_MenuItem> allItems,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, ref, child) {
                final catsAsync = ref.watch(categoriesProvider);
                final categories = catsAsync.value ?? initialCategories;
                final theme = Theme.of(context);
                final cs = theme.colorScheme;

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "MANAGE COLLECTIONS",
                              style: GoogleFonts.plusJakartaSans(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Organize your menu structure",
                              style: GoogleFonts.notoSerif(
                                color: cs.secondary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                          itemCount: categories.length,
                          separatorBuilder: (_, index) => Divider(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final catId = cat['id']?.toString() ?? '';
                            final catName = cat['name']?.toString() ?? 'Unnamed';
                            
                            final productCount = allItems.where((item) => item.category == catName).length;
                            final canDelete = productCount == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        catName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: cs.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$productCount products in this collection",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: cs.secondary.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              "Delete Category?",
                                              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
                                            ),
                                            content: Text(
                                              "Are you sure you want to delete '$catName'? This cannot be undone.",
                                              style: GoogleFonts.plusJakartaSans(),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("CANCEL"),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text("DELETE"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true && context.mounted) {
                                          try {
                                            await MenuService.deleteCategory(catId);
                                            ref.invalidate(categoriesProvider);
                                            ref.invalidate(menuProvider);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Category '$catName' deleted successfully"),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: cs.primary,
                                                ),
                                              );
                                            }
                                          } catch (e, st) {
                                            debugPrint('Category delete error: $e\n$st');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("An error occurred, please try again"),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    )
                                  else
                                    IconButton(
                                      icon: Icon(Icons.remove, color: cs.outlineVariant),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text("Cannot delete a category with active products"),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: cs.secondary,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "CLOSE",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: cs.surface,
        body: _buildProductsView(context),
        floatingActionButton: FloatingActionButton(
          backgroundColor: cs.primary,
          elevation: 6,
          shape: const CircleBorder(),
          onPressed: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    AddMenuPage(onTabChanged: widget.onTabChanged),
              ),
            );
            if (!context.mounted) return;
            ref.invalidate(menuProvider);
            ref.invalidate(categoriesProvider);
            setState(() => _selectedCategories = {'All'});
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
  }

  Widget _buildProductsView(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        final isMobile = constraints.maxWidth < 600;

        return ref.watch(menuProvider).when(
          loading: () {
            final cs2 = Theme.of(context).colorScheme;
            return Shimmer.fromColors(
              baseColor: cs2.surfaceContainer,
              highlightColor: cs2.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: crossAxisCount * 2,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            );
          },
          error: (error, _) => _MenuErrorView(
            cs: cs,
            error: error.toString(),
            onRetry: () => ref.invalidate(menuProvider),
          ),
          data: (rawCakes) {
            final catsAsync = ref.watch(categoriesProvider);
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

              final String imageField = data['image']?.toString() ?? '';
              final String version = data['updatedAt']?.toString() ?? '1';
              final String imageUrl = imageField.isEmpty
                  ? ''
                  : RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(imageField)
                      ? '$imageField?v=$version'
                      : '${SupabaseService.getPublicUrl(imageField, bucket: 'cakes')}?v=$version';

              return _MenuItem(
                id: (data['id'] as String?) ?? '',
                name: (data['name'] as String?) ?? 'Untitled Cake',
                category: (data['Category']?['name'] as String?) ?? (data['category'] as String?) ?? 'General',
                price: basePrice,
                description: (data['description'] as String?) ?? '',
                serves: baseServes,
                weight: "Standard",
                imageUrl: imageUrl,
              );
            }).toList();

            final Set<String> uniqueCategories = {'All'};
            final Set<String> activeCategoryNames = allItems.map((i) => i.category).toSet();
            final dbCategories = catsAsync.value ?? [];
            for (var c in dbCategories) {
              final catName = c['name']?.toString() ?? '';
              if (activeCategoryNames.contains(catName)) {
                uniqueCategories.add(catName);
              }
            }
            uniqueCategories.addAll(activeCategoryNames);

            final List<String> categories = uniqueCategories.toList()
              ..sort((a, b) {
                if (a == 'All') return -1;
                if (b == 'All') return 1;
                return a.compareTo(b);
              });

            // Move validation out of build using a post-frame callback
            if (!_isUpdatingCategories && mounted && !_selectedCategories.contains('All')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isUpdatingCategories || !mounted) return;
                final validSelection = _selectedCategories.where((cat) => uniqueCategories.contains(cat)).toSet();
                Set<String> newValue;
                if (validSelection.isEmpty) {
                  newValue = {'All'};
                } else if (validSelection.length != _selectedCategories.length) {
                  newValue = validSelection;
                } else {
                  return; // No change needed
                }
                
                if (newValue.length != _selectedCategories.length || !newValue.every(_selectedCategories.contains)) {
                  _isUpdatingCategories = true;
                  setState(() => _selectedCategories = newValue);
                  _isUpdatingCategories = false;
                }
              });
            }

            final List<_MenuItem> items = allItems.where((item) {
              if (_selectedCategories.contains('All')) return true;
              return _selectedCategories.contains(item.category);
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
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
                                    fontSize: 24,
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
                              ],
                            ),
                             if (isMobile)
                              IconButton.outlined(
                                onPressed: () => _showManageCategoriesSheet(context, dbCategories, allItems),
                                icon: Icon(Icons.category_outlined, color: cs.primary, size: 16),
                                style: IconButton.styleFrom(
                                  side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () => _showManageCategoriesSheet(context, dbCategories, allItems),
                                icon: Icon(Icons.category_outlined, size: 16, color: cs.primary),
                                label: Text(
                                  "MANAGE CATEGORIES",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((category) {
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                MenuDetailsPage(cakeId: item.id, onTabChanged: onTabChanged),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
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
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 110,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: cs.surface,
                    child: Center(
                      child: Shimmer.fromColors(
                        baseColor: cs.surfaceContainer,
                        highlightColor: cs.surface,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
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
                  ? "Sonnas"
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
class _AddMenuContent extends ConsumerStatefulWidget {
  final bool isDesktop;
  final Map<String, dynamic>? initialData;
  const _AddMenuContent({required this.isDesktop, this.initialData});

  @override
  ConsumerState<_AddMenuContent> createState() => _AddMenuContentState();
}

class _AddMenuContentState extends ConsumerState<_AddMenuContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _servesController;
  late TextEditingController _newCategoryController;
  bool _showNewCategoryField = false;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _categoriesLoaded = false;

  final _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final options = data?['CakeOption'] as List? ?? [];
    final firstOption = options.isNotEmpty ? options[0] as Map<String, dynamic> : null;

    final priceValue = firstOption?['price'];
    final double displayPrice = priceValue != null
        ? PriceConstants.normalizePrice(priceValue)
        : 0.0;

    _nameController = TextEditingController(text: data?['name']?.toString());
    _selectedCategoryId = data?['categoryId']?.toString();
    // Fallback for old data: if categoryId is null but category string exists
    if (_selectedCategoryId == null && data?['category'] != null) {
      _selectedCategoryId = data?['category']?.toString();
    }

    _priceController = TextEditingController(
      text: displayPrice > 0 ? displayPrice.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '') : '',
    );
    _descriptionController = TextEditingController(text: data?['description']?.toString());
    _weightController = TextEditingController(text: (firstOption?['size'] ?? firstOption?['weight'])?.toString() ?? '');
    _servesController = TextEditingController(text: firstOption?['serves']?.toString() ?? '');
    _newCategoryController = TextEditingController();
    _existingImageUrl = data?['image'] as String?;

    _loadCategories();
  }

  String _sanitizePrice(String value) {
    return value
        .replaceAll('/-', '')
        .replaceAll(PriceConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
  }

  Future<void> _loadCategories() async {
    if (mounted) setState(() => _isLoadingCategories = true);
    try {
      final cats = await MenuService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Load Categories Failed: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _categoriesLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _servesController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (!mounted) return;
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  String _generateCmpId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final randomPart = List.generate(
      19,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    // This creates exactly 25 chars: cmp57z + 19 random chars
    return 'cmp57z$randomPart';
  }

  Future<void> _saveItem() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final String cakeName = _nameController.text.trim();
      String slug = cakeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
      
      // Make slug unique for new items to avoid accidental overwrites
      if (widget.initialData == null) {
        slug = '$slug-${DateTime.now().millisecondsSinceEpoch}';
      }

      if (slug.isEmpty || slug == '-') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid name.'), backgroundColor: Colors.red));
        setState(() => _isUploading = false);
        return;
      }

      // Final ID: If editing, use existing. If adding, ALWAYS generate new to prevent overwrites.
      final String finalCakeId = widget.initialData?['id']?.toString() ?? _generateCmpId();

      String? imagePath = _existingImageUrl;

      // 2. Upload new image if selected
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final convertedBytes = await convertToWebP(bytes, _selectedImage!.name);
        final isWebp = convertedBytes != bytes;
        final fileName = '$finalCakeId.${isWebp ? 'webp' : _selectedImage!.name.split('.').last.toLowerCase()}';

        final uploadedPath = await SupabaseService.uploadImage(
          bucket: 'cakes', path: fileName, file: convertedBytes,
        );
        if (uploadedPath == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Please try again.'), backgroundColor: Colors.red),
          );
          setState(() => _isUploading = false);
          return;
        }

        imagePath = uploadedPath;
      }

      // 3. Resolve Categories (Foreign Key Guard)
      String? categoryId;

      if (_showNewCategoryField) {
        final trimmedCat = _newCategoryController.text.trim();
        if (trimmedCat.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a category name')));
          setState(() => _isUploading = false);
          return;
        }
        
        final existingCats = await MenuService.fetchCategories();
        final matchCat = existingCats.firstWhere(
          (c) => c['name'].toString().toLowerCase() == trimmedCat.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (matchCat.isNotEmpty) {
          categoryId = matchCat['id'].toString();
        } else {
          final catSlug = trimmedCat.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
          if (catSlug.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category name must contain at least one letter or number')));
            setState(() => _isUploading = false);
            return;
          }
          final nextSortOrder = existingCats.isEmpty ? 0 : (existingCats.map((c) => int.tryParse(c['sortOrder']?.toString() ?? '0') ?? 0).reduce((a, b) => a > b ? a : b) + 1);
          
          categoryId = await MenuService.upsertCategory({
            'id': _generateCmpId(),
            'name': trimmedCat,
            'slug': catSlug,
            'sortOrder': nextSortOrder,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          await _loadCategories();
        }
      } else {
        // FK Guard: Ensure category selection is valid
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
          setState(() => _isUploading = false);
          return;
        }
        
        final existingCat = _categories.firstWhere(
          (c) => c['id']?.toString() == _selectedCategoryId,
          orElse: () => <String, dynamic>{},
        );

        if (existingCat.isNotEmpty) {
          categoryId = existingCat['id'].toString();
        } else {
          // Check if it's a legacy string name that matches a category
          final matchByName = _categories.firstWhere(
            (c) => c['name']?.toString() == _selectedCategoryId,
            orElse: () => <String, dynamic>{},
          );
          
          if (matchByName.isNotEmpty) {
            categoryId = matchByName['id'].toString();
          } else {
            // Revert: Labels are not IDs. If it's a fallback string (e.g. "Slices"), 
            // set to null to avoid FK violations.
            categoryId = null;
          }
        }
        
        // Final guard: Fallback names like "Slices" are not real categories yet
        if (categoryId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected category is a placeholder. Please select or create a real category.'))
          );
          setState(() => _isUploading = false);
          return;
        }
      }

      // 4. Capture original cake data for rollback (if editing)
      final isNewCake = widget.initialData == null;
      Map<String, dynamic>? originalCakePayload;
      if (!isNewCake && widget.initialData != null) {
        originalCakePayload = {
          'id': widget.initialData!['id'],
          'name': widget.initialData!['name'],
          'slug': widget.initialData!['slug'],
          'categoryId': widget.initialData!['categoryId'],
          'description': widget.initialData!['description'],
          'image': widget.initialData!['image'],
          'isAvailable': widget.initialData!['isAvailable'],
          'sortOrder': widget.initialData!['sortOrder'],
          'updatedAt': widget.initialData!['updatedAt'],
        };
      }

      // 5. Perform Upsert
      final savePayload = {
        'id': finalCakeId,
        'name': cakeName,
        'slug': slug,
        'categoryId': categoryId,
        'description': _descriptionController.text,
        'image': imagePath ?? '',
        'isAvailable': widget.initialData?['isAvailable'] ?? true,
        'sortOrder': widget.initialData?['sortOrder'] ?? 0,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final cakeId = await MenuService.upsertCake(savePayload);

      // 6. Save Options (Hardened against duplication)
      final List<dynamic> existingOptions = [
        ...(widget.initialData?['CakeOption'] as List? ?? []),
      ];

      final currentSize = _weightController.text.trim();

      // Robust ID reuse: Try to find an exact size match first
      Map<String, dynamic>? matchedOption;
      for (var opt in existingOptions) {
        if (opt['size']?.toString().trim() == currentSize) {
          matchedOption = Map<String, dynamic>.from(opt as Map<dynamic, dynamic>);
          break;
        }
      }

      // If no exact size match but editing, reuse the first option's ID to avoid orphan rows
      if (matchedOption == null && existingOptions.isNotEmpty && widget.initialData != null) {
        matchedOption = Map<String, dynamic>.from(existingOptions.first as Map<dynamic, dynamic>);
        matchedOption['cakeId'] = cakeId;
        matchedOption['size'] = currentSize;
      }

      final normalizedPrice = _sanitizePrice(_priceController.text);

      try {
        await MenuService.upsertCakeOption({
          'id': matchedOption?['id'] ?? _generateCmpId(),
          'cakeId': cakeId,
          'price': ((double.tryParse(normalizedPrice) ?? 0) * PriceConstants.minorUnitsPerMajor).toInt(),
          'size': currentSize,
          'serves': _servesController.text.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (optError) {
        // Compensation: Cleanup if option save fails
        debugPrint('⚠️ Option save failed, cleaning up cake: $optError');
        try {
          if (isNewCake) {
            await MenuService.deleteCake(cakeId);
          } else if (originalCakePayload != null) {
            // Restore original cake state for existing cakes
            await MenuService.upsertCake(originalCakePayload);
          }
          if (imagePath != null && imagePath.isNotEmpty && isNewCake) {
             // In a real app, delete the uploaded image from Supabase storage here
          }
        } catch (cleanupError) {
          debugPrint('❌ Cleanup failed: $cleanupError');
        }
        rethrow;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Catalog updated successfully"), behavior: SnackBarBehavior.floating));
      ref.invalidate(menuProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Save item failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Failed to save item. Please try again."), backgroundColor: Theme.of(context).colorScheme.error, behavior: SnackBarBehavior.floating),
      );
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCategoryDropdown(cs)),
                        const SizedBox(width: 24),
                        if (_showNewCategoryField)
                          Expanded(
                            child: _InputField(
                              label: "New Category Name",
                              hint: "e.g. Special Editions",
                              icon: Icons.add_circle_outline,
                              controller: _newCategoryController,
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    )
                  else ...[
                    _buildCategoryDropdown(cs),
                    if (_showNewCategoryField) ...[
                      const SizedBox(height: 24),
                      _InputField(
                        label: "New Category Name",
                        hint: "e.g. Special Editions",
                        icon: Icons.add_circle_outline,
                        controller: _newCategoryController,
                      ),
                    ],
                  ],
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
                            validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Price",
                            hint: "e.g. 675/-",
                            icon: Icons.currency_rupee,
                            controller: _priceController,
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Required";
                              final clean = _sanitizePrice(v);
                              final p = double.tryParse(clean);
                              if (p == null) return "Invalid price";
                              if (p < 0) return "Must be non-negative";
                              return null;
                            },
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
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: "Price",
                      hint: "e.g. 675/-",
                      icon: Icons.currency_rupee,
                      controller: _priceController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        final clean = _sanitizePrice(v);
                        final p = double.tryParse(clean);
                        if (p == null) return "Invalid price";
                        if (p < 0) return "Must be non-negative";
                        return null;
                      },
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
                      onPressed: _isUploading ? null : _saveItem,
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
                  const SizedBox(height: 16),
                  if (widget.initialData != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : () async {
                          if (_isUploading) return;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Item?"),
                              content: const Text("This will permanently delete this item. This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            setState(() => _isUploading = true);
                            try {
                              await MenuService.deleteCake(widget.initialData!['id'] as String);
                              ref.invalidate(menuProvider);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                             } catch (e) {
                               debugPrint("Menu item delete failed: $e");
                               if (!context.mounted) return;
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
                            } finally {
                              if (mounted) setState(() => _isUploading = false);
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text("DELETE CREATION", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
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
    // Standard fallback categories if table is empty
    final List<String> fallbackNames = [
      'Chocolate Cakes',
      'Fruit & Floral Cakes',
      'Artisan Pastries',
      'Cheesecakes',
      'Cookies & Macarons',
      'Savory Delights',
      'Seasonal Cakes',
      'Mini Cheesecakes',
      'Slices',
    ];

    final List<DropdownMenuItem<String>> items = [];
    
    // 1. Add categories from DB
    for (var cat in _categories) {
      items.add(DropdownMenuItem(
        value: cat['id'] as String?,
        child: Text((cat['name'] as String?) ?? 'Untitled'),
      ));
    }

    // 2. Add fallback categories if DB is empty or current selection is old string
    if (_categoriesLoaded && !_isLoadingCategories && _categories.isEmpty) {
      for (var name in fallbackNames) {
        items.add(DropdownMenuItem(value: name, child: Text(name)));
      }
    }

    // 3. Ensure current selection is visible (even if it's an old string)
    if (_selectedCategoryId != null && !items.any((item) => item.value == _selectedCategoryId)) {
      items.add(DropdownMenuItem(value: _selectedCategoryId, child: Text(_selectedCategoryId!)));
    }

    items.add(const DropdownMenuItem(value: 'Add New...', child: Text('Add New...')));

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
           initialValue: _selectedCategoryId,
           hint: Text(
             _isLoadingCategories ? "Loading collections..." : "Select Collection",
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
          items: items,
          onChanged: (val) {
            setState(() {
              if (val == 'Add New...') {
                _showNewCategoryField = true;
                _selectedCategoryId = null;
              } else {
                _showNewCategoryField = false;
                _selectedCategoryId = val;
              }
            });
          },
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
            child: _selectedImageBytes != null
                ? Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(cs),
                  )
                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                    ? Image.network(
                        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(_existingImageUrl!)
                            ? _existingImageUrl!
                            : SupabaseService.getPublicUrl(_existingImageUrl, bucket: 'cakes'),
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

  Widget _buildImagePlaceholder(ColorScheme cs) {
    return Container(
      color: cs.primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: cs.primary.withValues(alpha: 0.2), size: 40),
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
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.controller,
    this.validator,
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
          validator: validator,
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
