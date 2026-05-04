import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String? orderId;
  const CustomerTrackingScreen({super.key, this.orderId});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  static const Color primary = Color(0xFFFF4D8D);
  static const Color background = Color(0xFFFFF0F6);
  static const Color onSurface = Color(0xFF2B1606);
  static const Color secondary = Color(0xFF701235);
  static const Color surfaceContainerLow = Color(0xFFFFF1E9);
  static const Color outlineVariant = Color(0xFFD8C1C6);

  Map<String, dynamic>? orderData;
  List<dynamic> orderItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  Future<void> _fetchOrderData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // If no orderId is provided, try to fetch the most recent order
      String? targetOrderId = widget.orderId;
      
      if (targetOrderId == null) {
        final recentOrder = await supabase
            .from('WhatsAppOrder')
            .select('id')
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle();
        targetOrderId = recentOrder?['id'];
      }

      if (targetOrderId != null) {
        final orderResponse = await supabase
            .from('WhatsAppOrder')
            .select('*')
            .eq('id', targetOrderId)
            .single();

        final itemsResponse = await supabase
            .from('WhatsAppOrderItem')
            .select('*')
            .eq('orderId', targetOrderId);

        setState(() {
          orderData = orderResponse;
          orderItems = itemsResponse;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching order: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Track Order",
          style: GoogleFonts.notoSerif(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : orderData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: secondary.withOpacity(0.1)),
                      const SizedBox(height: 24),
                      Text(
                        "No active orders found",
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, color: secondary.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 32),
                      _buildTimeline(),
                      const SizedBox(height: 32),
                      _buildOrderDetails(),
                      const SizedBox(height: 32),
                      _buildHelpSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusHeader() {
    String statusMsg = "Your delicate selection is being processed.";
    
    final status = orderData?['status'] ?? 'PENDING';
    final String deliveryDateStr = orderData?['deliveryDate'] ?? '';
    final String deliveryTime = orderData?['deliveryTime'] ?? 'No Time';
    
    String formattedDate = "Coming Soon";
    if (deliveryDateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(deliveryDateStr);
        formattedDate = DateFormat('MMM dd').format(date);
      } catch (_) {}
    }

    String arrivalText = "$formattedDate, $deliveryTime";

    if (status == 'PREPARING') {
      statusMsg = "Our artisans are crafting your delight.";
    } else if (status == 'SHIPPED') {
      statusMsg = "Your delicate selection is en route.";
    } else if (status == 'DELIVERED') {
      statusMsg = "Hand-delivered with love.";
      arrivalText = "Delivered";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ORDER STATUS: ${status.toUpperCase()}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: secondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            arrivalText,
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusMsg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: secondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = orderData?['status'] ?? 'PENDING';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: secondary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            title: "Order Confirmed",
            time: "Confirmed",
            isCompleted: true,
            isLast: false,
          ),
          _buildTimelineStep(
            title: "In Preparation",
            time: status == 'PREPARING' || status == 'SHIPPED' || status == 'DELIVERED' ? "Active" : "Pending",
            isCompleted: status == 'PREPARING' || status == 'SHIPPED' || status == 'DELIVERED',
            isActive: status == 'PREPARING',
            isLast: false,
          ),
          _buildTimelineStep(
            title: "On the Way",
            time: status == 'SHIPPED' || status == 'DELIVERED' ? "En Route" : "Waiting",
            isCompleted: status == 'SHIPPED' || status == 'DELIVERED',
            isActive: status == 'SHIPPED',
            isLast: false,
          ),
          _buildTimelineStep(
            title: "Delivered",
            time: status == 'DELIVERED' ? "Arrived" : "Est. Arrival",
            isCompleted: status == 'DELIVERED',
            isActive: status == 'DELIVERED',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    bool isCompleted = false,
    bool isActive = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isCompleted || isActive) ? primary : outlineVariant.withOpacity(0.5),
                  border: isActive ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: isActive ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8)] : null,
                ),
                child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? primary : outlineVariant.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.w500,
                      color: (isActive || isCompleted) ? onSurface : secondary.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: secondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: secondary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ORDER SUMMARY",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: secondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ...orderItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cake_outlined, color: primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['cakeName'] ?? "Exquisite Creation",
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Qty: ${item['quantity']} • ₹${item['price']}",
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: secondary.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 32),
          Text(
            "DELIVERY ADDRESS",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: secondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            orderData?['address'] ?? "Collection from Boutique",
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.headset_mic_outlined, size: 18),
        label: const Text("Need help with your order?"),
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}


