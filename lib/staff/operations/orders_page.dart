import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class OrdersPage extends StatelessWidget {
  final ColorScheme cs;
  const OrdersPage({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];
        // Show orders that are READY for pickup/delivery
        final readyOrders = allOrders.where((o) => o['status'] == 'READY').toList();

        if (readyOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "No orders ready for pickup",
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
          itemCount: readyOrders.length,
          itemBuilder: (context, index) {
            final order = readyOrders[index];
            return ReadyOrderCard(order: order, cs: cs);
          },
        );
      },
    );
  }
}

class ReadyOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ColorScheme cs;

  const ReadyOrderCard({super.key, required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
            title: Text(
              order['customerName'] ?? 'Guest Customer',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            subtitle: Text(
              "ORDER #${order['orderNumber'] ?? 'N/A'}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: cs.secondary.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
            trailing: Text(
              SupabaseService.formatPrice(order['totalPrice']),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: cs.secondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SupabaseService.launchWhatsApp(order['phone'], "Hi ${order['customerName']}, your order from Sonna's is ready! 🎂"),
                    icon: const Icon(Icons.message_rounded, size: 18),
                    label: const Text("NOTIFY"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await SupabaseService.updateOrderStatus(order['id'], 'DELIVERED');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("DELIVERED"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
