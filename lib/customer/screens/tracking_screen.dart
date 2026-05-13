import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_screen.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String? orderId;
  final bool isSelfCheckout;

  const CustomerTrackingScreen({
    super.key,
    this.orderId,
    this.isSelfCheckout = false,
  });

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  static const Color primary = Color(0xFFFF4D8D);
  static const Color background = Color(0xFFFFF0F6);
  static const Color onSurface = Color(0xFF701235);
  static const Color secondary = Color(0xFF701235);
  static const Color surfaceContainerLow = Color(0xFFFFF1E9);

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
      String? targetOrderId = widget.orderId;
      
      if (targetOrderId == null) {
        final currentUser = supabase.auth.currentUser;
        if (currentUser == null) {
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        }

        final userPhone = currentUser.userMetadata?['phone']?.toString() ?? '';
        final recentOrder = await supabase
            .from('WhatsAppOrder')
            .select('id')
            .eq('phone', userPhone) // Filter by user's phone
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

        if (!mounted) return;
        setState(() {
          orderData = orderResponse;
          orderItems = itemsResponse;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching order: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Order", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel your delicious selection? This action cannot be undone.", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("KEEP IT", style: TextStyle(color: secondary.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("YES, CANCEL"),
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
            .eq('id', orderData!['id']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Order cancellation request sent"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrderData(); // Refresh state
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
                "How was your experience?",
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your feedback helps our artisans perfect their craft",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: secondary.withValues(alpha: 0.5),
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
                  hintText: "Share your thoughts on the taste and presentation...",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: surfaceContainerLow.withValues(alpha: 0.3),
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
                        'orderId': orderData?['id'],
                        'message': commentController.text,
                        'userId': currentUser?.id,
                        'userPhone': currentUser?.userMetadata?['phone']?.toString() ?? currentUser?.phone,
                        'createdAt': DateTime.now().toUtc().toIso8601String(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thank you for your lovely review! 💖"),
                            backgroundColor: primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Feedback Error: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to submit review. Please try again.")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: Text(
                    "SUBMIT REVIEW",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
    // Determine if it's a self-checkout based on widget flag or address content
    final bool effectiveSelfCheckout = widget.isSelfCheckout || 
        (orderData?['address']?.toString().toLowerCase().contains('self checkout') ?? false) ||
        (orderData?['address']?.toString().toLowerCase().contains('pickup') ?? false);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: secondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Track Your Order",
          style: GoogleFonts.notoSerif(
            color: secondary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : orderData == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _buildStatusTracker(effectiveSelfCheckout),
                      const SizedBox(height: 40),
                      _buildOrderSummary(effectiveSelfCheckout),
                      const SizedBox(height: 40),
                      _buildHelpCard(),
                      const SizedBox(height: 24),
                      if (orderData?['status'] == 'PENDING' || orderData?['status'] == 'CONFIRMED')
                        _buildCancelButton(),
                      if (orderData?['status'] == 'DELIVERED' || orderData?['status'] == 'COMPLETED')
                        _buildReviewButton(),
                      if (orderData?['status'] == 'CANCELLED')
                        _buildCancelledBadge(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: secondary.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            "No active orders found",
            style: GoogleFonts.plusJakartaSans(fontSize: 16, color: secondary.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(bool isSelfCheckout) {
    final status = orderData?['status'] ?? 'PENDING';
    
    // Stages for Self Checkout
    final List<Map<String, dynamic>> selfCheckoutStages = [
      {'title': 'Confirmed', 'icon': Icons.check_circle_outline, 'match': ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED']},
      {'title': 'Preparing', 'icon': Icons.restaurant, 'match': ['PREPARING', 'READY', 'COMPLETED']},
      {'title': 'Ready', 'icon': Icons.shopping_bag_outlined, 'match': ['READY', 'COMPLETED']},
      {'title': 'Completed', 'icon': Icons.celebration_outlined, 'match': ['COMPLETED']},
    ];

    // Stages for Delivery
    final List<Map<String, dynamic>> deliveryStages = [
      {'title': 'Confirmed', 'icon': Icons.check_circle_outline, 'match': ['PENDING', 'CONFIRMED', 'PREPARING', 'SHIPPED', 'DELIVERED']},
      {'title': 'Preparing', 'icon': Icons.restaurant, 'match': ['PREPARING', 'SHIPPED', 'DELIVERED']},
      {'title': 'On the Way', 'icon': Icons.local_shipping_outlined, 'match': ['SHIPPED', 'DELIVERED']},
      {'title': 'Delivered', 'icon': Icons.home_outlined, 'match': ['DELIVERED']},
    ];

    final stages = isSelfCheckout ? selfCheckoutStages : deliveryStages;
    
    // Find current index based on status
    int currentIndex = -1;
    if (status != 'CANCELLED') {
      for (int i = stages.length - 1; i >= 0; i--) {
        if ((stages[i]['match'] as List).contains(status)) {
          currentIndex = i;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: secondary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final isCompleted = index <= currentIndex;
              final isActive = index == currentIndex;
              final isLast = index == stages.length - 1;
              
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCompleted ? primary : surfaceContainerLow,
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ] : null,
                          ),
                          child: Icon(
                            stages[index]['icon'] as IconData,
                            color: isCompleted ? Colors.white : secondary.withValues(alpha: 0.3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stages[index]['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                            color: isCompleted ? secondary : secondary.withValues(alpha: 0.3),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: index < currentIndex ? primary : surfaceContainerLow,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Text(
            _getStatusMessage(status, isSelfCheckout),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status, bool isSelfCheckout) {
    if (isSelfCheckout) {
      switch (status) {
        case 'PREPARING': return "Our artisans are crafting your selection";
        case 'READY': return "Your order is ready for pickup!";
        case 'COMPLETED': return "Order enjoyed! Hope to see you soon.";
        default: return "Order confirmed and in queue";
      }
    } else {
      switch (status) {
        case 'PREPARING': return "Our artisans are crafting your selection";
        case 'SHIPPED': return "Your delicate selection is en route";
        case 'DELIVERED': return "Hand-delivered with love";
        case 'CANCELLED': return "Order has been cancelled. We're sorry for the inconvenience.";
        default: return "Order confirmed and being processed";
      }
    }
  }

  Widget _buildOrderSummary(bool isSelfCheckout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ORDER SUMMARY",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: secondary.withValues(alpha: 0.4),
                ),
              ),
              Text(
                "#${orderData?['orderNumber']?.split('-').last ?? '...'}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...orderItems.map((item) => _buildCompactItemCard(item)),
          const Divider(height: 40, thickness: 0.5),
          
          if (!isSelfCheckout) ...[
            Text(
              "DELIVERY ADDRESS",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: secondary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceContainerLow.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, color: primary, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      orderData?['address'] ?? "No address provided",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: onSurface,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 48, thickness: 0.5),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount Paid",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondary.withValues(alpha: 0.6),
                ),
              ),
              Text(
                "₹${orderData?['totalPrice'] ?? '0'}",
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItemCard(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cake_outlined, color: primary, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['cakeName'] ?? "Exquisite Creation",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                Text(
                  "Quantity: ${item['quantity']}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: secondary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${item['price']}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_outlined, color: primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Need assistance with your order?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
            child: Text(
              "Help",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _cancelOrder,
      style: TextButton.styleFrom(
        foregroundColor: Colors.red.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cancel_outlined, size: 16),
          const SizedBox(width: 8),
          Text(
            "CANCEL ORDER",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: _showReviewDialog,
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text("RATE & REVIEW"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCancelledBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
          const SizedBox(width: 8),
          Text(
            "ORDER CANCELLED",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.red.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}


