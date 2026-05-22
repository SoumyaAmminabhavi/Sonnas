import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'order_success_screen.dart';
import '../../owner/owner_dashboard.dart' deferred as owner_dashboard;
import '../main.dart';
import '../providers/cart_provider.dart';
import 'tracking_screen.dart';


class PaymentScreen extends StatefulWidget {
  final String? customerName;
  final String? phone;
  final String? address;
  final String? deliveryDate;
  final String? deliveryTime;
  final String? notes;
  final bool isSelfCheckout;

  const PaymentScreen({
    super.key,
    this.customerName,
    this.phone,
    this.address,
    this.deliveryDate,
    this.deliveryTime,
    this.notes,
    this.isSelfCheckout = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Razorpay';
  final bool _showSuccess = false;
  bool _isLoading = false;
  String? _placedOrderId;
  double? _placedOrderTotal;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Razorpay Payment Success: ${response.paymentId}");
    final cart = context.read<CartProvider>();
    _placeOrder(cart, paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Razorpay Payment Error: ${response.code} - ${response.message}");
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
  }

  void _startRazorpayPayment(CartProvider cart) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Online payments via Razorpay are only supported on Android & iOS mobile devices."),
          backgroundColor: Color(0xFFFF4D8D),
        ),
      );
      return;
    }

    final double totalWithExtras = _calculateTotal(cart.total);
    final int amountInPaise = totalWithExtras.round();
    
    final options = {
      'key': dotenv.get('RAZORPAY_KEY_ID', fallback: 'rzp_test_SlapcQRITI3KNO'),
      'amount': amountInPaise,
      'name': "Sonna's Patisserie",
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': widget.phone ?? '',
        'email': '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      setState(() => _isLoading = true);
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal(double cartTotal) {
    final int subtotalCents = cartTotal.round();
    final int packagingCents = widget.isSelfCheckout ? 0 : 15000;
    final int taxCents = ((subtotalCents * 5) + 50) ~/ 100;
    return (subtotalCents + packagingCents + taxCents).toDouble();
  }

  Future<void> _placeOrder(CartProvider cart, {String? paymentId}) async {
    if (cart.items.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";
      _placedOrderId = orderId;
      _placedOrderTotal = _calculateTotal(cart.total);
      final String orderNumber = "SN-${DateTime.now().millisecondsSinceEpoch}";
      final String? customerPhone = widget.phone?.replaceAll(RegExp(r'\D'), '');
      if (customerPhone == null || customerPhone.isEmpty) {
        throw Exception("A valid contact number is required to place an order.");
      }
      
      // 1. (Optional) Try to ensure Conversation exists, but don't let it block the order
      String? conversationId;
      try {
        final existingConv = await supabase
            .from('WhatsAppConversation')
            .select('id')
            .eq('phone', customerPhone)
            .maybeSingle();
        
        conversationId = existingConv?['id'] ?? "CONV-${DateTime.now().millisecondsSinceEpoch}";
        
        await supabase.from('WhatsAppConversation').upsert({
          'id': conversationId,
          'phone': customerPhone,
          'name': widget.customerName ?? 'Guest Customer',
          'state': 'IDLE',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint("Note: Skipping conversation log due to permissions, but proceeding with order. Error: $e");
      }

      // 2. Insert Order (The primary goal)
      final double totalWithExtras = _calculateTotal(cart.total);
      final int totalInPaise = totalWithExtras.round();

      await supabase.from('Order').insert({
        'id': orderId,
        'orderNumber': orderNumber,
        'customerPhone': customerPhone,
        'customerName': widget.customerName ?? 'Guest Customer',
        'address': widget.address ?? 'No Address',
        'deliveryDate': widget.deliveryDate,
        'deliverySlot': widget.deliveryTime,
        'notes': widget.notes,
        'totalPrice': totalInPaise,
        'status': paymentId != null ? 'CONFIRMED' : 'PENDING',
        'paymentStatus': paymentId != null ? 'PAID' : 'PENDING',
        'paymentId': paymentId,
        'source': 'APP',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isCustom': cart.items.any((item) => item.imageUrl.contains('custom')),
        'customImageUrl': cart.items.isNotEmpty ? cart.items.first.imageUrl : null,
      });

      // Update user metadata with phone if logged in
      try {
        if (supabase.auth.currentUser != null && customerPhone.isNotEmpty) {
          await supabase.auth.updateUser(UserAttributes(data: {'phone': customerPhone}));
        }
      } catch (e) {
        debugPrint("Note: Could not update user metadata: $e");
      }

      try {
        // 3. Insert Items
        final List<Map<String, dynamic>> itemsToInsert = cart.items.asMap().entries.map((entry) => {
          'id': "ITEM-$orderId-${entry.key}",
          'orderId': orderId,
          'cakeId': entry.value.cakeId ?? entry.value.id,
          'cakeName': entry.value.name,
          'size': 'Standard',
          'price': entry.value.price.round(),
          'quantity': entry.value.quantity,
        }).toList();
        
        await supabase.from('OrderItem').insert(itemsToInsert);
      } catch (e) {
        // Rollback Order if Items fail
        debugPrint("Items insertion failed, rolling back order $orderId: $e");
        await supabase.from('Order').delete().eq('id', orderId);
        rethrow;
      }
      
      // 4. Clear Cart
      cart.clear();
      
      if (mounted) {
        setState(() => _isLoading = false);
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderNumber: orderNumber,
              totalAmount: totalWithExtras / 100,
            ),
          ),
        ));
      }
    } catch (e) {
      debugPrint("CRITICAL ERROR placing order: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        final String errorMessage = paymentId != null 
            ? "Payment was successful, but we encountered an error recording your order. Please contact us with Payment ID: $paymentId"
            : "Payment failed. Please try again later.";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFFF4D8D),
            duration: const Duration(seconds: 10),
            action: paymentId != null ? SnackBarAction(
              label: "COPY ID",
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: paymentId));
              },
            ) : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color onSurfaceColor = Color(0xFF701235);
    const Color secondaryColor = Color(0xFF701235);
    const Color outlineVariantColor = Color(0xFFD8C1C6);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: primaryContainerColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              // Top Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: surfaceColor.withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
                ),
                title: Text(
                  "Sonnaâ€™s Patisserie",
                  style: GoogleFonts.notoSerif(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.account_circle_outlined, color: primaryColor),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CHECKOUT JOURNEY",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.notoSerif(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                            color: onSurfaceColor,
                            height: 1.1,
                          ),
                          children: [
                            const TextSpan(text: "Complete Your\n"),
                            const TextSpan(
                              text: "Savoury Experience",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Payment Methods
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CHOOSE PAYMENT METHOD",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: secondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildPaymentMethod(
                        id: 'Razorpay',
                        icon: Icons.security,
                        title: 'Pay Online (Razorpay)',
                        subtitle: 'Cards, UPI, Netbanking, Wallets',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Icon(Icons.wallet, size: 16, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                "Secure SSL Payments",
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      _buildPaymentMethod(
                        id: 'UPI Scanner',
                        icon: Icons.qr_code_scanner,
                        title: 'UPI Scanner',
                        subtitle: 'Scan and pay instantly at the counter',
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: outlineVariantColor.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Image.network(
                                    "https://lh3.googleusercontent.com/aida-public/AB6AXuCE0VkjT0DzbaGmhQllA7poRoma8CX_y5_fOZaNBnH7LUp4pYx0Yra0gZ_zghUWvjFyRqmMsJDK-Qu3nUWm3b3EkpZDVrwRkQwZvxnljK2Y5Jv1Vy5ofM3k1A1ty0hQaadVHhsz97Ef0LBYtgoBqHDHCmXJocOWpQ1oNcFQ5qygyeMWq2bj-y7kG9r5dzvuglhjONwbpp1QqsNkY2IFfV-CcWXWQWCWjD97yMb_NHk715YrKAgkv9XT2ehk8eTf_qlei13Tq5YDtlhV",
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Scan the display QR at the Sonna's Patisserie counter to pay instantly.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: secondaryColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      _buildPaymentMethod(
                        id: 'UPI ID',
                        icon: Icons.smartphone,
                        title: 'UPI ID / App',
                        subtitle: 'Pay via GPay, PhonePe, or Paytm',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Enter UPI ID (e.g. user@bank)",
                                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: secondaryColor.withValues(alpha: 0.3)),
                                        filled: true,
                                        fillColor: const Color(0xFFFFF1E9),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "VERIFY",
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAppLogo("GPay"),
                                  const SizedBox(width: 16),
                                  _buildAppLogo("PhPe"),
                                  const SizedBox(width: 16),
                                  _buildAppLogo("Paytm"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      _buildPaymentMethod(
                        id: 'Cash',
                        icon: Icons.payments_outlined,
                        title: 'Cash on Collection',
                        subtitle: 'Pay by cash or card at our boutique',
                      ),
                    ],
                  ),
                ),
              ),

              // Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryColor.withValues(alpha: 0.08),
                          blurRadius: 80,
                          offset: const Offset(0, 40),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Summary",
                          style: GoogleFonts.notoSerif(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item.name} (x${item.quantity})",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: secondaryColor.withValues(alpha: 0.7)),
                                ),
                              ),
                              Text(
                                "â‚¹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2).format((item.price * item.quantity) / 100)}",
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: onSurfaceColor),
                              ),
                            ],
                          ),
                        )),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(color: Color(0xFFD8C1C6), thickness: 0.5),
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL AMOUNT",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹', decimalDigits: 2).format(_calculateTotal(cart.total) / 100),
                                  style: GoogleFonts.notoSerif(fontSize: 40, fontWeight: FontWeight.w400, color: onSurfaceColor),
                                ),
                              ],
                            ),
                            Text(
                              "Incl. all taxes",
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontStyle: FontStyle.italic, color: secondaryColor.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Confirm Button
                        InkWell(
                          onTap: _isLoading ? null : () {
                            if (_selectedMethod == 'Razorpay') {
                              _startRazorpayPayment(cart);
                            } else {
                              _placeOrder(cart);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading 
                                  ? [Colors.grey, Colors.grey] 
                                  : [primaryColor, primaryContainerColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                if (!_isLoading)
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "CONFIRM PAYMENT",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 14, color: Color(0xFF867277)),
                            const SizedBox(width: 8),
                            Text(
                              "SECURE SSL ENCRYPTED CHECKOUT",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: const Color(0xFF867277).withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Success State Overlay
          if (_showSuccess)
            _buildSuccessOverlay(context),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    final bool isSelected = _selectedMethod == id;
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color onSurfaceColor = Color(0xFF701235);
    const Color secondaryColor = Color(0xFF701235);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? primaryColor.withValues(alpha: 0.2) : const Color(0xFFD8C1C6).withValues(alpha: 0.1)),
        boxShadow: [
          if (isSelected)
            BoxShadow(color: secondaryColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = id),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6D3).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: onSurfaceColor),
                      ),
                      if (!isSelected)
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: secondaryColor.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? primaryColor : const Color(0xFFD8C1C6), width: 2),
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                  child: isSelected ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white)) : null,
                ),
              ],
            ),
            if (isSelected && child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF701235).withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color secondaryColor = Color(0xFF701235);
    const Color surfaceColor = Color(0xFFFFF0F6);

    return Material(
      color: surfaceColor.withValues(alpha: 0.95),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Aesthetic Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Heading
              Text(
                "Order Placed Successfully ðŸŽ‰",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your boutique selection is being prepared\nby our expert artisans.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: secondaryColor.withValues(alpha: 0.6),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Info Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow("Order ID", "#${_placedOrderId?.split('-').last ?? '...'}"),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildInfoRow("Total Paid", NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹', decimalDigits: 2).format((_placedOrderTotal ?? 0) / 100)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildInfoRow("Est. Preparation", "15 - 20 Mins"),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Primary Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerTrackingScreen(
                          orderId: _placedOrderId,
                          isSelfCheckout: widget.isSelfCheckout,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    "TRACK ORDER",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary Action
              TextButton(
                onPressed: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  final role = user?.userMetadata?['role']?.toString();
                  
                  if (role == 'owner' || role == 'admin') {
                    owner_dashboard.loadLibrary().then((_) {
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => owner_dashboard.OwnerDashboard()),
                          (route) => false,
                        );
                      }
                    });
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  "Back to Home",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: secondaryColor.withValues(alpha: 0.5),
                    letterSpacing: 1.0,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF701235).withValues(alpha: 0.4),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF701235),
          ),
        ),
      ],
    );
  }
}

