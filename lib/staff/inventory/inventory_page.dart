import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventory_service.dart';

class StaffInventoryPage extends StatefulWidget {
  final ColorScheme cs;
  final bool isDesktop;

  const StaffInventoryPage({super.key, required this.cs, required this.isDesktop});

  @override
  State<StaffInventoryPage> createState() => _StaffInventoryPageState();
}

class _StaffInventoryPageState extends State<StaffInventoryPage> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: InventoryService.getInventoryStream(),
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
                Icon(Icons.inventory_2_outlined, size: 64, color: widget.cs.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  "No inventory items found",
                  style: GoogleFonts.plusJakartaSans(color: widget.cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isDesktop ? 48 : 24,
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.cs.primary,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "INVENTORY OVERVIEW",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: widget.isDesktop ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: widget.cs.secondary,
                      ),
                    ),
                  ],
                ),
                if (widget.isDesktop)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showAddStockDialog(context, isConsumption: true, fallbackItems: items),
                        icon: const Icon(Icons.remove_shopping_cart_rounded),
                        label: const Text("Usage Entry"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.cs.error,
                          side: BorderSide(color: widget.cs.error.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddStockDialog(context, fallbackItems: items),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text("Purchase Entry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.cs.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: widget.cs.secondary.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              children: [
                _buildQuickStat(
                  context,
                  "Total Items", 
                  items.length.toString(), 
                  Icons.category_outlined,
                  widget.cs.surfaceContainer,
                ),
                const SizedBox(width: 16),
                _buildQuickStat(
                  context,
                  "Low Stock", 
                  items.where((i) => ((i['currentStock'] as num?) ?? 0) <= ((i['minStock'] as num?) ?? 0)).length.toString(), 
                  Icons.warning_amber_rounded,
                  widget.cs.primary.withValues(alpha: 0.05),
                  iconColor: widget.cs.error,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inventory List
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.isDesktop ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _InventoryCard(
                  item: item, 
                  cs: widget.cs,
                  onAddStock: (item) => _showAddStockDialog(context, preselectedItem: item, fallbackItems: items),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon, Color bgColor, {Color? iconColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.cs.primary.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? widget.cs.primary, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.notoSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.cs.secondary,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: widget.cs.secondary.withValues(alpha: 0.5),
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

  void _showAddStockDialog(BuildContext context, {Map<String, dynamic>? preselectedItem, bool isConsumption = false, List<Map<String, dynamic>> fallbackItems = const []}) async {
    final TextEditingController quantityController = TextEditingController();
    Map<String, dynamic>? selectedItem = preselectedItem;
    bool isSubmitting = false;
    bool isManualSelection = false;
    Future<List<Map<String, dynamic>>> dialogInventoryFuture = fallbackItems.isNotEmpty
        ? Future.value(fallbackItems)
        : InventoryService.fetchInventory();

    try {
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isConsumption ? "Record Usage" : (preselectedItem != null ? "Update Stock" : "Purchase Entry"),
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, color: isConsumption ? widget.cs.error : widget.cs.secondary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preselectedItem == null)
                StatefulBuilder(
                  builder: (context, setFieldState) {
                    if (isManualSelection) {
                      return DropdownButtonFormField<String>(
                        initialValue: selectedItem?['id'] as String?,
                        decoration: InputDecoration(
                          labelText: "Select Ingredient (Manual)",
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                        ),
                        items: fallbackItems.map((item) => DropdownMenuItem(
                          value: item['id'] as String,
                          child: Text((item['name'] as String?) ?? ''),
                        )).toList(),
                        onChanged: (val) {
                          final newItem = fallbackItems.firstWhere((i) => i['id'] == val);
                          setDialogState(() => selectedItem = newItem);
                          setFieldState(() {});
                        },
                      );
                    }

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: dialogInventoryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              Text("Failed to load ingredients", style: TextStyle(color: widget.cs.error, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      final fresh = InventoryService.fetchInventory();
                                      setDialogState(() {
                                        dialogInventoryFuture = fresh;
                                      });
                                      setFieldState(() {});
                                    },
                                    icon: const Icon(Icons.refresh, size: 14),
                                    label: const Text("Retry", style: TextStyle(fontSize: 12)),
                                  ),
                                  if (fallbackItems.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        setFieldState(() {
                                          isManualSelection = true;
                                        });
                                      },
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text("Select manually", style: TextStyle(fontSize: 12)),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final items = snapshot.data!;
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: selectedItem?['id'] as String?,
                          decoration: InputDecoration(
                            labelText: "Select Ingredient",
                            labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                          ),
                          items: items.map((item) => DropdownMenuItem(
                            value: item['id'] as String,
                            child: Text((item['name'] as String?) ?? ''),
                          )).toList(),
                          onChanged: (val) {
                            final newItem = items.firstWhere((i) => i['id'] == val);
                            setDialogState(() => selectedItem = newItem);
                          },
                        );
                      }
                    );
                  }
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: widget.cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        "${preselectedItem['name']}",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isConsumption ? "Quantity Used" : (preselectedItem != null ? "Quantity to Add" : "Purchase Quantity"),
                  suffixText: (selectedItem?['unit'] as String?) ?? '',
                  helperText: isConsumption ? "This will be deducted from current stock" : "This will be added to current stock",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.plusJakartaSans(color: widget.cs.secondary.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (selectedItem == null || quantityController.text.isEmpty) return;
                
                final qty = double.tryParse(quantityController.text);
                if (qty == null || qty <= 0) return;

                setDialogState(() => isSubmitting = true);
                
                try {
                  if (isConsumption) {
                    await InventoryService.recordConsumption(selectedItem!['id'] as String, qty);
                  } else {
                    await InventoryService.updateInventoryStock(selectedItem!['id'] as String, qty);
                  }
                  
                  if (context.mounted) {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(isConsumption 
                          ? "Recorded consumption of $qty ${selectedItem!['unit']} ${selectedItem!['name']}"
                          : "Stock updated for ${selectedItem!['name']}!"),
                        backgroundColor: isConsumption ? widget.cs.error : Colors.green.shade700,
                      ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: isConsumption ? widget.cs.error : widget.cs.primary, 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isConsumption ? "Record Usage" : "Update Stock"),
            ),
          ],
        ),
      ),
      );
    } finally {
      quantityController.dispose();
    }
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final void Function(Map<String, dynamic>) onAddStock;

  const _InventoryCard({
    required this.item, 
    required this.cs,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final double stock = ((item['currentStock'] as num?) ?? 0).toDouble();
    final double minStock = ((item['minStock'] as num?) ?? 0).toDouble();
    final bool isLow = stock <= minStock;
    final String unit = (item['unit'] as String?) ?? 'units';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
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
            (item['name'] as String?) ?? 'Unknown Item',
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
