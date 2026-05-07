import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../widgets/owner_sidebar.dart';
import '../widgets/skeleton.dart';

class InventoryAnalyticsPage extends StatefulWidget {
  const InventoryAnalyticsPage({super.key});

  @override
  State<InventoryAnalyticsPage> createState() => _InventoryAnalyticsPageState();
}

class _InventoryAnalyticsPageState extends State<InventoryAnalyticsPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Ingredients', 'Packaging', 'Equipment', 'Other'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width > 1100;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isDesktop
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: cs.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          isDesktop ? "Sonna's Patisserie & Cafe" : "Stock Intelligence",
          style: GoogleFonts.notoSerif(
            color: cs.primary,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [],
      ),
      body: Row(
        children: [
          if (isDesktop)
            OwnerSidebar(
              currentIndex: 4,
              onTap: (index) {
                Navigator.pop(context, index);
              },
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.getInventoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeleton(cs);
                }

                final allItems = snapshot.data ?? [];
                final filteredItems = _selectedCategory == 'All'
                    ? allItems
                    : allItems.where((i) => i['category'] == _selectedCategory).toList();

                final lowStockItems = allItems.where((i) {
                  final current = (i['currentStock'] as num?)?.toDouble() ?? 0.0;
                  final min = (i['minStock'] as num?)?.toDouble() ?? 0.0;
                  return current <= min;
                }).toList();

                return CustomScrollView(
                  slivers: [
                    _buildSliverHeader(cs, isDesktop),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKPIs(cs, allItems.length, lowStockItems.length),
                            const SizedBox(height: 32),
                            if (lowStockItems.isNotEmpty) ...[
                              _buildAlertSection(cs, lowStockItems),
                              const SizedBox(height: 32),
                            ],
                            _buildCategoryFilter(cs),
                            const SizedBox(height: 24),
                            if (filteredItems.isEmpty)
                              _buildEmptyState(cs)
                            else
                              _buildInventoryGrid(cs, filteredItems),
                            const SizedBox(height: 64),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context, cs),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          "ADD ITEM",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat),
              onSelected: (val) => setState(() => _selectedCategory = cat),
              backgroundColor: cs.surfaceContainer,
              selectedColor: cs.primary.withValues(alpha: 0.1),
              checkmarkColor: cs.primary,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? cs.primary : cs.secondary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              side: BorderSide(color: isSelected ? cs.primary : cs.secondary.withValues(alpha: 0.1)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: cs.secondary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              "No items in this category",
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                color: cs.secondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryCard(ColorScheme cs, Map<String, dynamic> item) {
    final current = (item['currentStock'] as num?)?.toDouble() ?? 0.0;
    final min = (item['minStock'] as num?)?.toDouble() ?? 0.0;
    
    // Status Logic
    Color statusColor = cs.primary;
    if (current == 0) {
      statusColor = Colors.red;
    } else if (current <= min) {
      statusColor = Colors.orange;
    }

    final progress = current > 0 ? (current / (max(current, min * 2))).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['name']?.toUpperCase() ?? 'ITEM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: cs.secondary.withValues(alpha: 0.4), size: 18),
                onSelected: (val) async {
                  if (val == 'delete') {
                    await SupabaseService.deleteInventoryItem(item['id']);
                  } else if (val == 'edit') {
                    _showEditStockDialog(context, cs, item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Adjust Stock")),
                  const PopupMenuItem(value: 'delete', child: Text("Delete Item", style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                current.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item['unit'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: cs.secondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.secondary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStockDialog(BuildContext context, ColorScheme cs, Map<String, dynamic> item) {
    final controller = TextEditingController(text: item['currentStock'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Adjust Stock: ${item['name']}", style: GoogleFonts.notoSerif()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Current quantity (${item['unit']})",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newVal = double.tryParse(controller.text) ?? 0.0;
              await SupabaseService.updateInventoryStock(item['id'], newVal);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  // Helper for max
  double max(double a, double b) => a > b ? a : b;

  void _showAddItemSheet(BuildContext context, ColorScheme cs) {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final currentController = TextEditingController();
    final minController = TextEditingController();
    String selectedCategory = _categories[1]; // Default to Ingredients

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "New Inventory Item",
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSheetInput(cs, "ITEM NAME", "e.g. Belgian Chocolate", nameController),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CATEGORY",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: _categories.skip(1).map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setSheetState(() => selectedCategory = val!),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cs.surfaceContainer.withValues(alpha: 0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSheetInput(cs, "UNIT", "e.g. KG, LTR, BOX", unitController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSheetInput(cs, "MIN STOCK", "Alert below", minController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetInput(cs, "INITIAL STOCK", "Current quantity", currentController, isNumber: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    
                    await SupabaseService.addInventoryItem({
                      'name': nameController.text,
                      'category': selectedCategory,
                      'unit': unitController.text,
                      'currentStock': double.tryParse(currentController.text) ?? 0.0,
                      'minStock': double.tryParse(minController.text) ?? 0.0,
                      'lastRestocked': DateTime.now().toIso8601String(),
                    });
                    
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("SAVE ITEM"),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetInput(ColorScheme cs, String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: cs.secondary.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cs.surfaceContainer.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.secondary.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.secondary.withValues(alpha: 0.1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ColorScheme cs) {
    return SkeletonWrapper(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Skeleton(height: 40, width: 250),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
            ],
          ),
          const SizedBox(height: 32),
          const Skeleton(height: 24, width: 200),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(6, (index) => Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(ColorScheme cs, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stock Intelligence",
              style: GoogleFonts.notoSerif(
                fontSize: isDesktop ? 48 : 36,
                color: cs.secondary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Performance Overview",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: cs.secondary.withValues(alpha: 0.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIs(ColorScheme cs, int total, int low) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 450;
      if (isMobile) {
        return Column(
          children: [
            _kpiCard(cs, "TOTAL ITEMS", total.toString(), Icons.inventory_2_outlined, cs.primary),
            const SizedBox(height: 16),
            _kpiCard(cs, "LOW STOCK", low.toString(), Icons.warning_amber_rounded, low > 0 ? Colors.orange : cs.secondary.withValues(alpha: 0.4)),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _kpiCard(cs, "TOTAL ITEMS", total.toString(), Icons.inventory_2_outlined, cs.primary)),
          const SizedBox(width: 16),
          Expanded(child: _kpiCard(cs, "LOW STOCK", low.toString(), Icons.warning_amber_rounded, low > 0 ? Colors.orange : cs.secondary.withValues(alpha: 0.4))),
        ],
      );
    });
  }

  Widget _kpiCard(ColorScheme cs, String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cs.secondary.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              Icon(icon, color: accent, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.notoSerif(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection(ColorScheme cs, List<Map<String, dynamic>> lowStockItems) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                "Restock Required",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lowStockItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['name'] ?? 'Unknown',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "${item['currentStock']} ${item['unit']} left",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(ColorScheme cs, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current Stock Levels",
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.secondary,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 140,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _inventoryCard(cs, item);
            },
          );
        }),
      ],
    );
  }
}
