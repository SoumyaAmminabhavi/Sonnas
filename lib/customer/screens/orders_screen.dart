import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

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
  static const Color onSurface = Color(0xFF2B1606);
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
                      color: primary.withOpacity(0.6),
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
                                    color: Colors.white.withOpacity(0.8),
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
            color: secondary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: secondary.withOpacity(0.05)),
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
                        color: secondary.withOpacity(0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
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
                    color: secondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

