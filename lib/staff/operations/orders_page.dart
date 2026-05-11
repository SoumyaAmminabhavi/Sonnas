import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/glass_order_sheet.dart';

class StaffOrdersPage extends StatelessWidget {
  const StaffOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "ORDER MANAGEMENT",
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
        stream: OrderService.getKitchenOrdersStream(), // Reuse the active orders stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allOrders = snapshot.data ?? [];

          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    "NO ORDERS FOUND",
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

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: allOrders.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: StaffOrderCard(orderMap: allOrders[index], cs: cs),
              );
            },
          );
        },
      ),
    );
  }
}

class StaffOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderMap;
  final ColorScheme cs;

  const StaffOrderCard({super.key, required this.orderMap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final order = WhatsAppOrder.fromMap(orderMap);
    
    return InkWell(
      onTap: () => GlassOrderSheet.show(context, order),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: cs.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.secondary,
                    ),
                  ),
                  Text(
                    "#${order.orderNumber} • ${order.items.length} items",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.formattedPrice,
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: order.status, cs: cs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final ColorScheme cs;

  const _StatusBadge({required this.status, required this.cs});

  @override
  Widget build(BuildContext context) {
    Color color = cs.primary;
    if (status == OrderStatus.ready) color = Colors.green.shade700;
    if (status == OrderStatus.completed) color = cs.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
