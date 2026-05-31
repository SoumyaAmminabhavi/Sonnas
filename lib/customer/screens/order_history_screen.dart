import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cart_provider.dart';

class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  State<CustomerOrderHistoryScreen> createState() =>
      _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState
    extends State<CustomerOrderHistoryScreen> {
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

      String? userEmail = user?.email?.trim();
      String? userPhone;

      if (user != null && user.userMetadata != null) {
        final meta = user.userMetadata!;
        if (meta['phone'] != null) {
          userPhone = meta['phone'].toString().replaceAll(RegExp(r'\D'), '');
        }
      }

      if ((userPhone == null || userPhone.isEmpty) && user != null && user.phone != null) {
        userPhone = user.phone!.replaceAll(RegExp(r'\D'), '');
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        if (userPhone == null || userPhone.isEmpty) {
          userPhone = (prefs.getString('guest_phone') ?? prefs.getString('saved_phone'))
              ?.replaceAll(RegExp(r'\D'), '');
        }
      } catch (e) {
        debugPrint("Error loading SharedPreferences in order history screen: $e");
      }

      if (userPhone != null && userPhone.isNotEmpty) {
        userPhone = userPhone.length > 10
            ? userPhone.substring(userPhone.length - 10)
            : userPhone;
      }

      var query = supabase
          .from('Order')
          .select('*, items:OrderItem(*)');

      List<String> filters = [];
      if (userEmail != null && userEmail.isNotEmpty) {
        filters.add('customerEmail.eq.$userEmail');
      }
      if (userPhone != null && userPhone.isNotEmpty) {
        filters.add('customerPhone.eq.$userPhone');
        filters.add('customerPhone.eq.91$userPhone');
        filters.add('customerPhone.eq.+91$userPhone');
        filters.add('whatsappPhone.eq.$userPhone');
        filters.add('whatsappPhone.eq.91$userPhone');
        filters.add('whatsappPhone.eq.+91$userPhone');
      }

      if (filters.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      query = query.or(filters.join(','));

      final response = await query.order('createdAt', ascending: false);

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
                style:
                    GoogleFonts.dmSerifDisplay(fontSize: 32, color: berryText),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? Center(
                          child: Text("No orders yet",
                              style: GoogleFonts.plusJakartaSans(
                                  color: berryText.withValues(alpha: 0.5))))
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) =>
                              _buildOrderCard(context, _orders[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, Map<String, dynamic> order) {
    const primary = Color(0xFFC2185B);
    const berryText = Color(0xFF4A152C);

    final status = (order['status'] ?? 'PENDING').toString().toUpperCase();

    // Map the new OrderStatus enum values to colors
    Color statusColor;
    switch (status) {
      case 'CONFIRMED':
        statusColor = Colors.blue;
        break;
      case 'OUT_FOR_DELIVERY':
        statusColor = Colors.indigo;
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      default: // PENDING
        statusColor = Colors.orange;
    }

    final List items = order['items'] as List? ?? [];
    final itemsText = items.map((i) => i['cakeName']).join(", ");

    String formattedDate = "No Date";
    try {
      final date = DateTime.parse(order['createdAt']);
      formattedDate =
          "${date.day} ${_getMonth(date.month)} ${date.year}";
    } catch (_) {}

    final source = order['source']?.toString() ?? 'APP';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
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
                    Text(
                      "#${order['orderNumber']?.toString().split('-').last ?? 'ORD'}",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: berryText),
                    ),
                    Row(
                      children: [
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: source == 'WHATSAPP'
                                ? Colors.green.shade50
                                : primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            source == 'WHATSAPP' ? '💬 WA' : '📲 APP',
                            style: TextStyle(
                                color: source == 'WHATSAPP'
                                    ? Colors.green.shade700
                                    : primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formattedDate,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        itemsText.isEmpty ? "Exquisite Creation" : itemsText,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: berryText.withValues(alpha: 0.7)),
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
                    Text("Total Amount",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      "₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: berryText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.02),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showOrderDetails(context, order),
                    child: Text(
                      "VIEW DETAILS",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: berryText.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    height: 20,
                    color: primary.withValues(alpha: 0.1)),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final cart = context.read<CartProvider>();
                      for (var item in items) {
                        cart.addItem(
                          "reorder_${item['cakeName']}_${DateTime.now().millisecondsSinceEpoch}",
                          item['cakeName'] ?? "Exquisite Creation",
                          (double.tryParse(item['price'].toString()) ?? 0.0) /
                              100.0,
                          '',
                          quantity: int.tryParse(
                                  item['quantity'].toString()) ??
                              1,
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${items.length} items added to bag'),
                          backgroundColor: primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      "REORDER",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(
      BuildContext context, Map<String, dynamic> order) {
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
            Text("Order Details",
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24, color: berryText)),
            const SizedBox(height: 24),
            _detailRow("Order ID",
                "#${order['orderNumber']?.toString().split('-').last ?? 'ORD'}"),
            _detailRow("Status", order['status'] ?? 'PENDING'),
            _detailRow("Source", order['source'] ?? 'APP'),
            _detailRow(
                "Items",
                items
                    .map((i) =>
                        "${i['cakeName']} (${i['size']}) x${i['quantity']}")
                    .join(", ")),
            if (order['deliveryDate'] != null)
              _detailRow("Delivery Date",
                  order['deliveryDate'].toString().split('T')[0]),
            if (order['deliverySlot'] != null)
              _detailRow("Delivery Slot", order['deliverySlot']),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (order['status'] == 'PENDING' || order['status'] == 'CONFIRMED')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmCancellation(context, order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("CANCEL ORDER"),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmCancellation(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: Text(order['paymentId'] != null 
          ? "Your payment of ₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)} will be refunded within 3-5 business days."
          : "Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("NO")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder(order);
            }, 
            child: const Text("YES, CANCEL", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    try {
      final supabase = Supabase.instance.client;
      
      final updates = {
        'status': 'CANCELLED',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (order['paymentId'] != null) {
        updates['paymentStatus'] = 'REFUNDED';
      }

      await supabase
          .from('Order')
          .update(updates)
          .eq('id', order['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order cancelled successfully"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Close the details sheet
        unawaited(_fetchOrders()); // Refresh the list
      }
    } catch (e) {
      debugPrint("Error cancelling order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel order. Please contact support.")),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
}

