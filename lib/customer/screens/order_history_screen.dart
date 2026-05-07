import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerOrderHistoryScreen extends StatelessWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF0F5);
    const berryText = Color(0xFF4A152C);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Your Orders",
                style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: berryText),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildOrderCard(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, int index) {
    const primary = Color(0xFFC2185B);
    const berryText = Color(0xFF4A152C);

    final statuses = ["Processing", "Ready", "Delivered"];
    final statusColors = [const Color(0xFFC2185B), Colors.orange, Colors.green];
    final status = statuses[index % 3];
    final statusColor = statusColors[index % 3];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("#SN-2024-0$index", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: berryText)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("24 Oct 2024, 04:30 PM", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Belgian Chocolate, Wildberry Sensation",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: berryText.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text("₹520.00", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: berryText)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.02), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showOrderDetails(context, index),
                    child: Text("VIEW DETAILS", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: berryText.withValues(alpha: 0.5))),
                  ),
                ),
                Container(width: 1, height: 20, color: primary.withValues(alpha: 0.1)),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order items added to bag"), backgroundColor: primary, behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Text("REORDER", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, int index) {
    const berryText = Color(0xFF4A152C);
    const primary = Color(0xFFC2185B);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Details", style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: berryText)),
            const SizedBox(height: 24),
            _detailRow("Order ID", "#SN-2024-0$index"),
            _detailRow("Date", "24 Oct 2024"),
            _detailRow("Items", "Belgian Chocolate, Wildberry Sensation"),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₹520.00", style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
