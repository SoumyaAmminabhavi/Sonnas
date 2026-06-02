class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double currentStock;
  final double minStock;
  final String unit;
  final DateTime? lastRestocked;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.unit,
    this.lastRestocked,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Item',
      category: map['category']?.toString() ?? 'General',
      currentStock: double.tryParse(map['currentStock']?.toString() ?? '0') ?? 0.0,
      minStock: double.tryParse(map['minStock']?.toString() ?? '0') ?? 0.0,
      unit: map['unit']?.toString() ?? 'units',
      lastRestocked: DateTime.tryParse(map['lastRestocked']?.toString() ?? ''),
    );
  }

  bool get isLowStock => currentStock <= minStock;
}
