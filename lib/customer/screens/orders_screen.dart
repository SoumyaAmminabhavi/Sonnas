import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
      // Fetch orders with their items
      final data = await supabase
          .from('WhatsAppOrder')
          .select('*, items:WhatsAppOrderItem(*)')
          .order('createdAt', ascending: false);
      
      if (mounted) {
        setState(() {
          orders = List<Map<String, dynamic>>.from(data).map((order) {
            final items = order['items'] as List?;
            String firstItemTitle = "Custom Order";
            String imageUrl = "";
            
            if (items != null && items.isNotEmpty) {
              firstItemTitle = items[0]['cakeName'];
              // If there's no image in the order, we might need a placeholder or first item image
              // Since items don't have images in the schema, we'll use order's customImageUrl or a placeholder
              imageUrl = order['customImageUrl'] ?? "https://images.unsplash.com/photo-1578985545062-69928b1d9587";
            }

            return {
              "id": order['orderNumber'] ?? order['id'],
              "uuid": order['id'],
              "date": _formatDate(order['createdAt']),
              "title": firstItemTitle,
              "price": "₹${order['totalPrice'] ?? '0'}",
              "status": order['status'],
              "imageUrl": imageUrl,
              "isActive": (order['status'] == 'PENDING' || order['status'] == 'PREPARING').toString()
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
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _cancelOrder(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Order", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES, CANCEL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('WhatsAppOrder')
            .update({'status': 'CANCELLED'})
            .eq('id', uuid);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cancellation request sent"), backgroundColor: Colors.red),
          );
          _fetchOrders(); // Refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  void _showReviewDialog() {
    double rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
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
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: primary,
                      size: 40,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1.0),
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
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Thank you for your feedback! 💖"), backgroundColor: primary),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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

  @override
  Widget build(BuildContext context) {

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
              const Expanded(child: Center(child: CircularProgressIndicator(color: primary)))
            else if (orders.isEmpty)
              const Expanded(child: Center(child: Text("You haven't placed any orders yet.")))
            else ...[
              // Active Order Banner (Compact)
              if (orders.any((o) => o['isActive'] == 'true'))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerTrackingScreen()),
                      );
                    },
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
                          const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
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
                                  orders.firstWhere((o) => o['isActive'] == 'true')['title'],
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildCompactOrderCard(context, orders[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(BuildContext context, Map<String, dynamic> order) {
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
              order['imageUrl']!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
                      order['date']!.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order['status']!.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order['title']!,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['price']!,
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
                    if (order['status'] == 'PENDING' || order['status'] == 'CONFIRMED')
                      TextButton(
                        onPressed: () => _cancelOrder(order['uuid']),
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
                    if (order['status'] == 'DELIVERED' || order['status'] == 'COMPLETED')
                      TextButton(
                        onPressed: _showReviewDialog,
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
                    TextButton(
                      onPressed: () {
                        if (order['isActive'] == "true") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CustomerTrackingScreen()),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: order['isActive'] == "true" 
                        ? Text(
                            "TRACK",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: primary,
                            ),
                          )
                        : const SizedBox.shrink(),
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

