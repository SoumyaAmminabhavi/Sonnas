import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class KitchenPage extends StatelessWidget {
  final ColorScheme cs;
  const KitchenPage({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getRecentOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];
        // Only show orders that need kitchen work
        final kitchenOrders = allOrders.where((o) => 
          o['status'] == 'PENDING' || o['status'] == 'ACCEPTED'
        ).toList();

        if (kitchenOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bakery_dining_outlined, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "Kitchen is all clear!",
                  style: GoogleFonts.notoSerif(
                    fontSize: 20, 
                    fontWeight: FontWeight.w600,
                    color: cs.secondary.withValues(alpha: 0.3)
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                // Refined extent for the new ticket design
                mainAxisExtent: 300, 
              ),
              itemCount: kitchenOrders.length,
              itemBuilder: (context, index) {
                final order = kitchenOrders[index];
                return KitchenOrderCard(order: order, cs: cs);
              },
            );
          },
        );
      },
    );
  }
}

class KitchenOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ColorScheme cs;

  const KitchenOrderCard({super.key, required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    final bool isAccepted = order['status'] == 'ACCEPTED';
    final createdAt = DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();
    final elapsed = DateTime.now().difference(createdAt);
    final String timeLabel = elapsed.inMinutes < 60 
        ? "${elapsed.inMinutes}m ago" 
        : "${elapsed.inHours}h ago";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional Ticket Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.03),
                border: Border(bottom: BorderSide(color: cs.secondary.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "REF #${order['orderNumber'] ?? 'N/A'}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order['customerName']?.toUpperCase() ?? 'GUEST',
                        style: GoogleFonts.notoSerif(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAccepted ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAccepted ? "PRODUCTION" : "QUEUED",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isAccepted ? Colors.blue.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Items List
            Expanded(
              child: Builder(
                builder: (context) {
                  final items = (order['items'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text("No items", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.4))),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${item['quantity']}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['cakeName'] ?? 'Cake Item',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.secondary.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: cs.secondary.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: cs.secondary.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final String nextStatus = isAccepted ? 'READY' : 'ACCEPTED';
                      await SupabaseService.updateOrderStatus(order['id'], nextStatus);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isAccepted ? Colors.green.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
                      foregroundColor: isAccepted ? Colors.green.shade700 : cs.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      isAccepted ? "MARK READY" : "START PREP",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
