import 'package:intl/intl.dart';

enum OrderStatus {
  pending,
  confirmed,
  accepted,
  preparing,
  ready,
  delivered,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get name => toString().split('.').last.toUpperCase();
  
  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return OrderStatus.pending;
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'ACCEPTED': return OrderStatus.accepted;
      case 'PREPARING': return OrderStatus.preparing;
      case 'READY': return OrderStatus.ready;
      case 'DELIVERED': return OrderStatus.delivered;
      case 'COMPLETED': return OrderStatus.completed;
      case 'CANCELLED': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String id;
  final String cakeName;
  final int quantity;
  final double price;
  final String? options;

  OrderItem({
    required this.id,
    required this.cakeName,
    required this.quantity,
    required this.price,
    this.options,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      cakeName: map['cakeName']?.toString() ?? 'Unknown Cake',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      price: (double.tryParse(map['price']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0) / 100.0,
      options: map['options']?.toString(),
    );
  }
}

class WhatsAppOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String phone;
  final OrderStatus status;
  final String paymentStatus;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? notes;
  final String? customImageUrl;

  WhatsAppOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
    this.notes,
    this.customImageUrl,
  });

  factory WhatsAppOrder.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems = map['items'] as List<dynamic>? ?? [];
    return WhatsAppOrder(
      id: map['id']?.toString() ?? '',
      orderNumber: map['orderNumber']?.toString() ?? '---',
      customerName: map['customerName']?.toString() ?? 'Guest',
      phone: map['phone']?.toString() ?? '',
      status: OrderStatusExtension.fromString(map['status']?.toString() ?? 'PENDING'),
      paymentStatus: map['paymentStatus']?.toString() ?? 'PENDING',
      totalPrice: (double.tryParse(map['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0.0) / 100.0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: rawItems.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      notes: map['notes']?.toString(),
      customImageUrl: map['customImageUrl']?.toString(),
    );
  }

  String get formattedPrice {
    final fmt = NumberFormat('#,##,###.##');
    return "₹${fmt.format(totalPrice)}";
  }
  
  bool get isKitchenActionable => status == OrderStatus.pending || status == OrderStatus.confirmed || status == OrderStatus.accepted || status == OrderStatus.preparing;
}
