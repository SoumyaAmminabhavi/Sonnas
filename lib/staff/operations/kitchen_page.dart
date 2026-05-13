import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/dashboard_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderService.getKitchenOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((o) {
          final s = o['status']?.toString().toUpperCase() ?? 'PENDING';
          return s == 'PENDING' || s == 'CONFIRMED' || s == 'ACCEPTED' || s == 'PREPARING';
        }).toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "NO ACTIVE ORDERS",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.3),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            mainAxisExtent: 320,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            return KitchenOrderCard(orderMap: activeOrders[index], cs: cs);
          },
        );
      },
    );
  }
}

class KitchenOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderMap;
  final ColorScheme cs;

  const KitchenOrderCard({super.key, required this.orderMap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final order = WhatsAppOrder.fromMap(orderMap);
    final String status = order.status.name.toUpperCase();
    
    // Status Logic
    bool isPreparing = status == 'PREPARING';
    
    final elapsed = DateTime.now().difference(order.createdAt);
    final String timeLabel = elapsed.inMinutes < 60 
        ? "${elapsed.inMinutes}m" 
        : "${elapsed.inHours}h";
    
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isPreparing ? cs.primary.withValues(alpha: 0.2) : cs.secondary.withValues(alpha: 0.08),
            width: isPreparing ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPreparing ? cs.primary.withValues(alpha: 0.08) : cs.primary.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isPreparing ? cs.primary.withValues(alpha: 0.05) : cs.primary.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${order.orderNumber}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: cs.secondary.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
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
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: cs.secondary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final itemsAsync = ref.watch(orderItemsProvider(order.id));
                      return itemsAsync.when(
                        data: (items) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...items.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.cake_outlined, size: 14, color: cs.primary.withValues(alpha: 0.4)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${item['quantity'] ?? 1}x ${item['cakeName'] ?? 'Unknown'}",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.secondary.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (items.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 24),
                                child: Text(
                                  "+ ${items.length - 3} more creations",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: cs.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (_, __) => Text("No items found", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.3))),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    String nextStatus = 'CONFIRMED';
                    if (status == 'PENDING') {
                      nextStatus = 'CONFIRMED';
                    } else if (status == 'CONFIRMED' || status == 'ACCEPTED') {
                      nextStatus = 'PREPARING';
                    } else if (status == 'PREPARING') {
                      nextStatus = 'READY';
                    }
                    
                    await OrderService.updateOrderStatus(order.id, nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPreparing ? Colors.teal : cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: cs.primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    _getButtonLabel(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED':
      case 'ACCEPTED': return Colors.blue;
      case 'PREPARING': return Colors.teal;
      case 'READY': return Colors.green;
      default: return cs.secondary;
    }
  }

  String _getButtonLabel(String status) {
    switch (status) {
      case 'PENDING': return "CONFIRM ORDER";
      case 'CONFIRMED':
      case 'ACCEPTED': return "START PREPARATION";
      case 'PREPARING': return "MARK AS READY";
      default: return "VIEW DETAILS";
    }
  }
}
