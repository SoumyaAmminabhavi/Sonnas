import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class KitchenPage extends StatelessWidget {
  final ColorScheme cs;
  const KitchenPage({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getOrdersStream(),
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

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: kitchenOrders.length,
          itemBuilder: (context, index) {
            final order = kitchenOrders[index];
            return KitchenOrderCard(order: order, cs: cs);
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
      margin: const EdgeInsets.only(bottom: 20),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ORDER #${order['orderNumber'] ?? 'N/A'}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['customerName'] ?? 'Guest Customer',
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAccepted ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isAccepted ? "IN PRODUCTION" : "PENDING",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAccepted ? Colors.blue.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Items List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: SupabaseService.fetchOrderItems(order['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              final items = snapshot.data ?? [];
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${item['quantity']}x",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['cakeName'] ?? 'Cake Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const Divider(height: 1),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: cs.secondary.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  timeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: cs.secondary.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final String nextStatus = isAccepted ? 'READY' : 'ACCEPTED';
                    await SupabaseService.updateOrderStatus(order['id'], nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepted ? Colors.green : cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(isAccepted ? "MARK AS READY" : "START PREP"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
