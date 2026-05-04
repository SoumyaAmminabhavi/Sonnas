import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? customerName;
  final String? phone;
  final String? address;
  final String? deliveryDate;
  final String? deliveryTime;
  final String? notes;

  const PaymentScreen({
    super.key,
    this.customerName,
    this.phone,
    this.address,
    this.deliveryDate,
    this.deliveryTime,
    this.notes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'UPI Scanner';
  bool _showSuccess = false;
  bool _isLoading = false;
  String? _placedOrderId;

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";
      _placedOrderId = orderId;
      final String orderNumber = "SN-${DateTime.now().millisecondsSinceEpoch}";
      final String customerPhone = widget.phone ?? '0000000000';
      
      // 1. Ensure Conversation exists for THIS phone number to satisfy Foreign Key constraint
      final existingConv = await supabase
          .from('WhatsAppConversation')
          .select('id')
          .eq('phone', customerPhone)
          .maybeSingle();
      
      final String conversationId = existingConv?['id'] ?? "CONV-${DateTime.now().millisecondsSinceEpoch}";
      
      await supabase.from('WhatsAppConversation').upsert({
        'id': conversationId,
        'phone': customerPhone,
        'name': widget.customerName ?? 'Guest Customer',
        'state': 'IDLE',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      // 2. Insert Order
      await supabase.from('WhatsAppOrder').insert({
        'id': orderId,
        'orderNumber': orderNumber,
        'phone': customerPhone,
        'customerName': widget.customerName ?? 'Guest Customer',
        'address': widget.address,
        'deliveryDate': widget.deliveryDate,
        'deliveryTime': widget.deliveryTime,
        'notes': widget.notes,
        'totalPrice': (cart.total + 150 + (cart.total * 0.05)).toString(),
        'status': 'PENDING',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'customImageUrl': cart.items.isNotEmpty ? cart.items.first.imageUrl : null,
      });
      
      // 3. Insert Items
      final List<Map<String, dynamic>> itemsToInsert = cart.items.asMap().entries.map((entry) => {
        'id': "ITEM-${orderId}-${entry.key}",
        'orderId': orderId,
        'cakeName': entry.value.name,
        'size': 'Standard', // Default size from schema requirement
        'price': entry.value.price.toString(),
        'quantity': entry.value.quantity,
      }).toList();
      
      await supabase.from('WhatsAppOrderItem').insert(itemsToInsert);
      
      // 3. Clear Cart
      cart.clear();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      debugPrint("Error placing order: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: const Color(0xFFFF4D8D),
            duration: const Duration(seconds: 5),
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
    const Color onSurfaceColor = Color(0xFF2B1606);
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
                color: primaryContainerColor.withOpacity(0.05),
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
                backgroundColor: surfaceColor.withOpacity(0.8),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
                ),
                title: Text(
                  "Sonna’s Patisserie",
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
                          color: primaryColor.withOpacity(0.7),
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
                            TextSpan(
                              text: "Savoury Experience",
                              style: const TextStyle(
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
                          color: secondaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
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
                                border: Border.all(color: outlineVariantColor.withOpacity(0.1)),
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
                                      color: secondaryColor.withOpacity(0.6),
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
                                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: secondaryColor.withOpacity(0.3)),
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
                          color: secondaryColor.withOpacity(0.08),
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
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: secondaryColor.withOpacity(0.7)),
                                ),
                              ),
                              Text(
                                "₹${(item.price * item.quantity).toInt()}",
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: onSurfaceColor),
                              ),
                            ],
                          ),
                        )).toList(),
                        
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
                                  "₹${(cart.total + 150 + (cart.total * 0.05)).toInt()}",
                                  style: GoogleFonts.notoSerif(fontSize: 40, fontWeight: FontWeight.w400, color: onSurfaceColor),
                                ),
                              ],
                            ),
                            Text(
                              "Incl. all taxes",
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontStyle: FontStyle.italic, color: secondaryColor.withOpacity(0.4)),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Confirm Button
                        InkWell(
                          onTap: _isLoading ? null : () => _placeOrder(cart),
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
                                    color: primaryColor.withOpacity(0.2),
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
                                color: const Color(0xFF867277).withOpacity(0.4),
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
    const Color onSurfaceColor = Color(0xFF2B1606);
    const Color secondaryColor = Color(0xFF701235);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? primaryColor.withOpacity(0.2) : const Color(0xFFD8C1C6).withOpacity(0.1)),
        boxShadow: [
          if (isSelected)
            BoxShadow(color: secondaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                    color: const Color(0xFFFFB6D3).withOpacity(0.2),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: secondaryColor.withOpacity(0.6)),
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
          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF701235).withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color secondaryColor = Color(0xFF701235);
    const Color surfaceColor = Color(0xFFFFF0F6);

    return Material(
      color: surfaceColor.withOpacity(0.6),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(color: secondaryColor.withOpacity(0.1), blurRadius: 80, offset: const Offset(0, 40)),
              ],
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB6D3).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: primaryColor, size: 64),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [primaryColor, Color(0xFFFFB6D3)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  "Payment Successful",
                  style: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 16),
                Text(
                  "Your order is being prepared with love. Our artisans are currently crafting your selection for the perfect sensory delight.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: secondaryColor.withOpacity(0.7), height: 1.6),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CustomerTrackingScreen(orderId: _placedOrderId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: secondaryColor,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFD8C1C6)),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("TRACK YOUR ORDER", style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Back to Sonna's Patisserie",
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: primaryColor, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
