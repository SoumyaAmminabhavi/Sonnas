import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class StaffInventoryPage extends StatelessWidget {
  final ColorScheme cs;
  final bool isDesktop;

  const StaffInventoryPage({super.key, required this.cs, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getInventoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: cs.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  "No inventory items found",
                  style: GoogleFonts.plusJakartaSans(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 24,
            vertical: 32,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RAW MATERIALS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Inventory",
                      style: GoogleFonts.notoSerif(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monitor and manage raw materials",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: () => _showAddStockDialog(context),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text("Purchase Entry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                _buildQuickStat(
                  "Total Items", 
                  items.length.toString(), 
                  Icons.category_outlined,
                  cs.surfaceContainerLow,
                ),
                const SizedBox(width: 16),
                _buildQuickStat(
                  "Low Stock", 
                  items.where((i) => (i['currentStock'] ?? 0) <= (i['minStock'] ?? 0)).length.toString(), 
                  Icons.warning_amber_rounded,
                  const Color(0xFFFFF4E5),
                  iconColor: const Color(0xFFB45309),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Inventory List
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _InventoryCard(
                  item: item, 
                  cs: cs,
                  onAddStock: (item) => _showAddStockDialog(context, preselectedItem: item),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color bgColor, {Color? iconColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? cs.primary, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.notoSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, {Map<String, dynamic>? preselectedItem}) {
    final TextEditingController quantityController = TextEditingController();
    Map<String, dynamic>? selectedItem = preselectedItem;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            preselectedItem != null ? "Update Stock" : "Purchase Entry",
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preselectedItem == null)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getInventoryStream(),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(labelText: "Select Ingredient"),
                      items: items.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item['name'] ?? ''),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedItem = val),
                    );
                  }
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Ingredient: ${preselectedItem['name']}",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: preselectedItem != null ? "Quantity to Add" : "Purchase Quantity",
                  suffixText: selectedItem?['unit'] ?? '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (selectedItem == null || quantityController.text.isEmpty) return;
                
                final qty = double.tryParse(quantityController.text);
                if (qty == null || qty <= 0) return;

                setDialogState(() => isSubmitting = true);
                
                try {
                  final double currentStock = (selectedItem!['currentStock'] ?? 0).toDouble();
                  await SupabaseService.updateInventoryStock(selectedItem!['id'], currentStock + qty);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Stock updated for ${selectedItem!['name']}! 📦")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to update stock."), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (context.mounted) setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final Function(Map<String, dynamic>) onAddStock;

  const _InventoryCard({
    required this.item, 
    required this.cs,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final double stock = (item['currentStock'] ?? 0).toDouble();
    final double minStock = (item['minStock'] ?? 0).toDouble();
    final bool isLow = stock <= minStock;
    final String unit = item['unit'] ?? 'units';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isLow ? Colors.amber : cs.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: isLow ? Colors.amber.shade800 : cs.primary,
                  size: 20,
                ),
              ),
              Text(
                item['category']?.toString().toUpperCase() ?? 'GENERAL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: cs.secondary.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item['name'] ?? 'Unknown Item',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURRENT STOCK",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        stock.toStringAsFixed(1),
                        style: GoogleFonts.notoSerif(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isLow ? Colors.amber.shade900 : cs.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => onAddStock(item),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: cs.primary,
                tooltip: "Quick Add Stock",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
