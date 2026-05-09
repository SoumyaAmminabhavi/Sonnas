import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/glass_order_sheet.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "PRODUCTION QUEUE",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 2,
            color: cs.secondary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: OrderService.getKitchenOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allOrders = snapshot.data ?? [];
          final activeOrders = allOrders.where((o) {
            final s = o['status']?.toString().toUpperCase() ?? 'PENDING';
            return s == 'PENDING' || s == 'ACCEPTED';
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
              maxCrossAxisExtent: 400,
              mainAxisExtent: 300,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              return KitchenOrderCard(orderMap: activeOrders[index], cs: cs);
            },
          );
        },
      ),
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
    final bool isAccepted = order.status == OrderStatus.accepted;
    final elapsed = DateTime.now().difference(order.createdAt);
    final String timeLabel = elapsed.inMinutes < 60 
        ? "${elapsed.inMinutes}m" 
        : "${elapsed.inHours}h";
    
    return InkWell(
      onTap: () => GlassOrderSheet.show(context, order),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.03),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAccepted ? Colors.blue.withValues(alpha: 0.03) : cs.primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.orderNumber}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isAccepted ? Colors.blue : cs.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: cs.secondary.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ...order.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${item.quantity}x ${item.cakeName}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.secondary.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (order.items.length > 3)
                    Text(
                      "+ ${order.items.length - 3} more items",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: cs.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nextStatus = isAccepted ? 'READY' : 'ACCEPTED';
                    await OrderService.updateOrderStatus(order.id, nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepted ? Colors.green.shade700 : cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isAccepted ? "MARK AS READY" : "START PRODUCTION",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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
}
