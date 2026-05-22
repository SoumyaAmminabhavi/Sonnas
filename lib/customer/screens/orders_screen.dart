import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;

  static const Color primary = Color(0xFFFF4D8D);
  static const Color background = Color(0xFFFFF0F6);
  static const Color onSurface = Color(0xFF701235);
  static const Color secondary = Color(0xFF701235);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userPhone =
          currentUser.userMetadata?['phone']?.toString() ??
          currentUser.phone ??
          '';

      if (userPhone.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Query the unified Order table using customerPhone
      final data = await supabase
          .from('Order')
          .select('*, items:OrderItem(*)')
          .eq('customerPhone', userPhone)
          .order('createdAt', ascending: false);

      if (mounted) {
        setState(() {
          orders = List<Map<String, dynamic>>.from(data).map((order) {
            final items = order['items'] as List?;
            String firstItemTitle = "Custom Order";
            String imageUrl = "";

            if (items != null && items.isNotEmpty) {
              firstItemTitle = items[0]['cakeName']?.toString() ?? firstItemTitle;
              imageUrl = order['customImageUrl']?.toString() ?? 
                  "https://images.unsplash.com/photo-1578985545062-69928b1d9587";
            }

            final status = order['status']?.toString() ?? 'PENDING';

            return {
              "id": order['orderNumber'] ?? order['id'],
              "uuid": order['id'],
              "date": _formatDate(order['createdAt']?.toString() ?? ''),
              "title": firstItemTitle,
              // totalPrice is stored in paise → convert to rupees
              "price": "₹${((order['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}",
              "status": status,
              "source": order['source']?.toString() ?? 'APP',
              "imageUrl": imageUrl,
              // active = PENDING or CONFIRMED (not yet out for delivery)
              "isActive":
                  (status == 'PENDING' || status == 'CONFIRMED').toString(),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _cancelOrder(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Order",
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("NO")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES, CANCEL",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('Order').update({
          'status': 'CANCELLED',
          'cancelledAt': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', uuid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Cancellation request sent"),
                backgroundColor: Colors.red),
          );
          unawaited(_fetchOrders());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    double rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 32,
            left: 32,
            right: 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Rate Your Experience",
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: primary,
                      size: 40,
                    ),
                    onPressed: () =>
                        setModalState(() => rating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "What did you love about your order?",
                  filled: true,
                  fillColor: background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final supabase = Supabase.instance.client;
                      final currentUser = supabase.auth.currentUser;

                      await supabase.from('Feedback').insert({
                        'rating': rating,
                        'orderId': order['uuid'],
                        'message': commentController.text,
                        'userId': currentUser?.id,
                        'userPhone':
                            currentUser?.userMetadata?['phone']?.toString() ??
                                currentUser?.phone,
                        'createdAt':
                            DateTime.now().toUtc().toIso8601String(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Thank you for your feedback! 💖"),
                              backgroundColor: primary),
                        );
                      }
                    } catch (e) {
                      debugPrint("Feedback Error: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Failed to submit review.")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: const Text("SUBMIT REVIEW"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 80,
                  color: primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Gourmet History",
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Sign in to see your past orders, track active deliveries, and download receipts in high-fidelity PDF formats.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: secondary.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => AuthScreen(
                          isOwner: false,
                          onSuccess: () {
                            Navigator.pop(context);
          unawaited(_fetchOrders());
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 5,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    "SIGN IN OR REGISTER",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return _buildGuestView(context);
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CULINARY JOURNEY",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Orders",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: primary)))
            else if (orders.isEmpty)
              const Expanded(
                  child: Center(
                      child:
                          Text("You haven't placed any orders yet.")))
            else ...[
              // Active Order Banner
              if (orders.any((o) => o['isActive'] == 'true'))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const CustomerTrackingScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primary, Color(0xFFFFB6D3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TRACK ACTIVE ORDER",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  orders.firstWhere(
                                      (o) => o['isActive'] == 'true')['title']?.toString() ?? '',
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildCompactOrderCard(context, orders[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(
      BuildContext context, Map<String, dynamic> order) {
    final String status = order['status']?.toString() ?? 'PENDING';
    final String source = order['source']?.toString() ?? 'APP';

    // Map status → color
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
      default:
        statusColor = primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              order['imageUrl']?.toString() ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                color: primary.withValues(alpha: 0.1),
                child: const Icon(Icons.cake, color: primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['date']?.toString().toUpperCase() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Row(
                      children: [
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: source == 'WHATSAPP'
                                ? Colors.green.shade50
                                : primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            source == 'WHATSAPP' ? '💬 WA' : '📲 APP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: source == 'WHATSAPP'
                                  ? Colors.green.shade700
                                  : primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order['title']?.toString() ?? '',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['price']?.toString() ?? '',
                  style: GoogleFonts.notoSerif(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: secondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel — only for PENDING or CONFIRMED
                    if (status == 'PENDING' || status == 'CONFIRMED')
                      TextButton(
                        onPressed: () => _cancelOrder(order['uuid']?.toString() ?? ''),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(right: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.red.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    // Review — for DELIVERED or COMPLETED
                    if (status == 'DELIVERED' || status == 'COMPLETED')
                      TextButton(
                        onPressed: () => _showReviewDialog(order),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(right: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "REVIEW",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
