import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? targetOrderId;
  bool _isOrderTrackingEnabled = true;
  Stream<List<Map<String, dynamic>>>? _orderStream;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOrderTrackingEnabled = prefs.getBool('notif_order_tracking') ?? true;

      final supabase = Supabase.instance.client;
      String? id = widget.orderId;
      
      if (id == null) {
        final currentUser = supabase.auth.currentUser;
        final isGuestLoggedIn = prefs.getBool('is_guest_logged_in') ?? false;
        
        if (currentUser == null && !isGuestLoggedIn) {
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        }

        String? userEmail = currentUser?.email?.trim();
        String? userPhone;

        if (currentUser != null && currentUser.userMetadata != null) {
          final meta = currentUser.userMetadata!;
          if (meta['phone'] != null) {
            userPhone = meta['phone'].toString().replaceAll(RegExp(r'\D'), '');
          }
        }

        if ((userPhone == null || userPhone.isEmpty) && currentUser != null && currentUser.phone != null) {
          userPhone = currentUser.phone!.replaceAll(RegExp(r'\D'), '');
        }

        // Check SharedPreferences for guest details
        if (userPhone == null || userPhone.isEmpty) {
          userPhone = (prefs.getString('guest_phone') ?? prefs.getString('saved_phone'))
              ?.replaceAll(RegExp(r'\D'), '');
        }

        if (userPhone != null && userPhone.isNotEmpty) {
          userPhone = userPhone.length > 10
              ? userPhone.substring(userPhone.length - 10)
              : userPhone;
        }

        var query = supabase
            .from('Order')
            .select('id');

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
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        }

        query = query.or(filters.join(','));

        final recentOrder = await query
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle();
        id = recentOrder?['id'] as String?;
      }

      if (id != null) {
        // Fetch items once (items rarely change)
        final itemsResponse = await supabase
            .from('OrderItem')
            .select('*')
            .eq('orderId', id);

        if (!mounted) return;
        setState(() {
          targetOrderId = id;
          orderItems = itemsResponse;
          _orderStream = supabase
              .from('Order')
              .stream(primaryKey: ['id'])
              .eq('id', id!);
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error initializing tracking: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (targetOrderId == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: _buildAppBar(context),
        body: _buildEmptyState(),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: background,
            appBar: _buildAppBar(context),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: background,
            appBar: _buildAppBar(context),
            body: _buildEmptyState(),
          );
        }

        if (data.isNotEmpty) {
          orderData = data.first;
        }

        // Determine if it's a self-checkout based on widget flag or address content
        final bool effectiveSelfCheckout = widget.isSelfCheckout || 
            (orderData?['address']?.toString().toLowerCase().contains('self checkout') ?? false) ||
            (orderData?['address']?.toString().toLowerCase().contains('pickup') ?? false);

        return Scaffold(
          backgroundColor: background,
          appBar: _buildAppBar(context),
          body: orderData == null && snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(color: primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      if (_isOrderTrackingEnabled) ...[
                        _buildStatusTracker(effectiveSelfCheckout),
                        const SizedBox(height: 40),
                      ],
                      _buildOrderSummary(effectiveSelfCheckout),
                      const SizedBox(height: 40),
                      _buildHelpCard(),
                      const SizedBox(height: 24),
                      if (orderData?['status'] == 'PENDING' || orderData?['status'] == 'CONFIRMED')
                        _buildCancelButton(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
    final String status = (orderData?['status'] as String?) ?? 'PENDING';
    
    // Unified Status Stages
    final List<Map<String, dynamic>> stages = [
      {'title': 'Confirmed', 'icon': Icons.check_circle_outline, 'match': ['PENDING', 'CONFIRMED', 'OUT_FOR_DELIVERY', 'DELIVERED']},
      {'title': 'Preparing', 'icon': Icons.restaurant, 'match': ['CONFIRMED', 'OUT_FOR_DELIVERY', 'DELIVERED']},
      {'title': 'On the Way', 'icon': Icons.local_shipping_outlined, 'match': ['OUT_FOR_DELIVERY', 'DELIVERED']},
      {'title': 'Delivered', 'icon': Icons.home_outlined, 'match': ['DELIVERED', 'COMPLETED']},
    ];

    if (isSelfCheckout) {
      stages[2] = {'title': 'Ready', 'icon': Icons.shopping_bag_outlined, 'match': ['OUT_FOR_DELIVERY', 'DELIVERED']};
    }
    
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
              final isLast = index == stages.length - 1;
              
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted ? primary : surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            stages[index]['icon'] as IconData,
                            color: isCompleted ? Colors.white : secondary.withValues(alpha: 0.3),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stages[index]['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                            color: isCompleted ? secondary : secondary.withValues(alpha: 0.3),
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
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status, bool isSelfCheckout) {
    switch (status) {
      case 'OUT_FOR_DELIVERY': return isSelfCheckout ? "Your order is ready for pickup!" : "Your delicate selection is en route";
      case 'DELIVERED': return isSelfCheckout ? "Order picked up! Enjoy your treat." : "Hand-delivered with love";
      case 'CANCELLED': return "Order has been cancelled.";
      case 'CONFIRMED': return "We are preparing your order";
      default: return "Order confirmed and in queue";
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
          Text(
            "ORDER SUMMARY",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: secondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          ...orderItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${item['cakeName']} x${item['quantity']}",
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: onSurface),
                  ),
                ),
                Text(
                  "₹${((item['price'] ?? 0) / 100).toStringAsFixed(2)}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: secondary),
                ),
              ],
            ),
          )),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Paid", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text(
                "₹${((orderData?['totalPrice'] ?? 0) / 100).toStringAsFixed(2)}",
                style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: secondary.withValues(alpha: 0.05))),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_outlined, color: primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text("Need help with your order?", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: secondary.withValues(alpha: 0.7)))),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
            child: Text("Support", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (targetOrderId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Order", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to cancel this order? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("NO", style: TextStyle(color: secondary.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES, CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        }).eq('id', targetOrderId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully"), backgroundColor: Colors.red),
          );
          // Go back or refresh
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _cancelOrder,
      style: TextButton.styleFrom(foregroundColor: Colors.red.withValues(alpha: 0.6)),
      child: const Text("CANCEL ORDER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
