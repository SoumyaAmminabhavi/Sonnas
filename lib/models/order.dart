import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/constants.dart';

enum OrderStatus {
  pending,
  confirmed,
  outForDelivery,
  delivered,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  /// Uppercased enum identifier (e.g. 'OUTFORDELIVERY'). Used for internal labels and DB fallback.
  String get internalLabel => toString().split('.').last.toUpperCase();

  String get humanReadable {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.completed: return 'Completed';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
  
  static OrderStatus fromString(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING': return OrderStatus.pending;
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'OUT_FOR_DELIVERY':
      case 'OUTFORDELIVERY': return OrderStatus.outForDelivery;
      case 'DELIVERED': return OrderStatus.delivered;
      case 'COMPLETED': return OrderStatus.completed;
      case 'CANCELLED': return OrderStatus.cancelled;
      // Legacy mappings (deprecated)
      case 'ACCEPTED': return OrderStatus.confirmed;
      case 'PREPARING': return OrderStatus.confirmed;
      case 'READY': return OrderStatus.outForDelivery;
      default:
        debugPrint('⚠️ Unknown OrderStatus: $status — defaulting to pending');
        return OrderStatus.pending;
    }
  }

  /// Canonical DB value — always use this for persistence.
  String get dbValue {
    switch (this) {
      case OrderStatus.outForDelivery: return 'OUT_FOR_DELIVERY';
      default: return internalLabel;
    }
  }

  /// Whether the order should be visible in the kitchen management view.
  bool get isKitchenActionable {
    // Only CONFIRMED orders are actively being prepared in the kitchen.
    // PENDING may need confirmation first, and OUT_FOR_DELIVERY is already done.
    return this == OrderStatus.confirmed;
  }

  /// Whether the order status can still be changed or cancelled.
  bool get canCancel {
    return this == OrderStatus.pending || this == OrderStatus.confirmed;
  }

  /// Whether the order has reached a terminal state.
  bool get isFinalized {
    return this == OrderStatus.completed || 
           this == OrderStatus.cancelled;
  }
}

class OrderItem {
  final String id;
  final String? cakeId;
  final String cakeName;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    this.cakeId,
    required this.cakeName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      cakeId: map['cakeId']?.toString(),
      cakeName: map['cakeName']?.toString() ?? 'Unknown Cake',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      price: PriceConstants.normalizePrice(map['price']),
    );
  }
}

class SonnaOrder {
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
  final String? conversationImageUrl;
  final String source;
  final bool isCustom;

  SonnaOrder({
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
    this.conversationImageUrl,
    required this.source,
    required this.isCustom,
  });

  factory SonnaOrder.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems = map['items'] as List<dynamic>? ?? map['OrderItem'] as List<dynamic>? ?? [];
    
    // Fix: prefer customerPhone, fallback to phone or WhatsAppConversation.phone
    final customerPhone = (map['customerPhone'] ?? map['phone'] ?? map['WhatsAppConversation']?['phone'])?.toString().trim() ?? '';
    
    return SonnaOrder(
      id: map['id']?.toString() ?? '',
      orderNumber: map['orderNumber']?.toString() ?? '---',
      customerName: map['customerName']?.toString() ?? 'Guest',
      phone: customerPhone,
      status: OrderStatusExtension.fromString(map['status']?.toString() ?? 'PENDING'),
      paymentStatus: map['paymentStatus']?.toString() ?? 'PENDING',
      totalPrice: PriceConstants.normalizePrice(map['totalPrice']),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: rawItems.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      notes: map['notes']?.toString(),
      customImageUrl: map['customImageUrl']?.toString(),
      conversationImageUrl: map['WhatsAppConversation'] != null ? map['WhatsAppConversation']['customImageUrl']?.toString() : null,
      source: map['source']?.toString() ?? 'APP',
      isCustom: map['isCustom'] == true,
    );
  }

  String get formattedPrice {
    final fmt = NumberFormat('#,##,###.##');
    return "${PriceConstants.currencySymbol}${fmt.format(totalPrice)}";
  }
  
}
