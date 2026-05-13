import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';

class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  State<CustomerOrderHistoryScreen> createState() => _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends State<CustomerOrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final phone = user.userMetadata?['phone']?.toString() ?? user.phone ?? '';
      final response = await supabase
          .from('WhatsAppOrder')
          .select('*, items:WhatsAppOrderItem(*)')
          .eq('phone', phone)
          .order('createdAt', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching order history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty 
                  ? Center(child: Text("No orders yet", style: GoogleFonts.plusJakartaSans(color: berryText.withValues(alpha: 0.5))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(context, _orders[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    const primary = Color(0xFFC2185B);
    const berryText = Color(0xFF4A152C);

    final status = (order['status'] ?? 'PENDING').toString().toUpperCase();
    Color statusColor = Colors.orange;
    if (status == 'DELIVERED') statusColor = Colors.green;
    if (status == 'SHIPPED') statusColor = Colors.blue;

    final List items = order['items'] as List? ?? [];
    final itemsText = items.map((i) => i['cakeName']).join(", ");
    
    String formattedDate = "No Date";
    try {
      final date = DateTime.parse(order['createdAt']);
      formattedDate = "${date.day} ${_getMonth(date.month)} ${date.year}";
    } catch (_) {}

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
                    Text("#${order['orderNumber']?.toString().split('-').last ?? 'ORD'}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: berryText)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formattedDate, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        itemsText.isEmpty ? "Exquisite Creation" : itemsText,
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
                    Text("₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: berryText)),
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
                    onPressed: () => _showOrderDetails(context, order),
                    child: Text("VIEW DETAILS", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: berryText.withValues(alpha: 0.5))),
                  ),
                ),
                Container(width: 1, height: 20, color: primary.withValues(alpha: 0.1)),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final cart = context.read<CartProvider>();
                      for (var item in items) {
                        cart.addItem(
                          "reorder_${item['cakeName']}", 
                          item['cakeName'] ?? "Exquisite Creation", 
                          double.tryParse(item['price'].toString()) ?? 0.0, 
                          '',
                          quantity: int.tryParse(item['quantity'].toString()) ?? 1,
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${items.length} items added to bag'),
                          backgroundColor: primary,
                          behavior: SnackBarBehavior.floating,
                        ),
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

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    const berryText = Color(0xFF4A152C);
    const primary = Color(0xFFC2185B);
    final List items = order['items'] as List? ?? [];
    
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
            _detailRow("Order ID", "#${order['orderNumber']?.toString().split('-').last ?? 'ORD'}"),
            _detailRow("Status", order['status'] ?? 'PENDING'),
            _detailRow("Items", items.map((i) => "${i['cakeName']} (x${i['quantity']})").join(", ")),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 18)),
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
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}
