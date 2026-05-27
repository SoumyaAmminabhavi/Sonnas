import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../../services/haptic_service.dart';
import 'checkout_screen.dart';
import 'self_checkout_screen.dart';
import 'auth_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color onSurfaceColor = Color(0xFF701235);
    const Color secondaryColor = Color(0xFF701235);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        slivers: [


          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YOUR SELECTION",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color(0xFF867277),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Shopping Bag",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          if (cart.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: secondaryColor.withValues(alpha: 0.1)),
                    const SizedBox(height: 24),
                    Text(
                      "Your bag is empty",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: secondaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "BROWSE COLLECTIONS",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = cart.items[index];
                  return _buildCartItem(context, item, cart);
                },
                childCount: cart.items.length,
              ),
            ),

          if (cart.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    "Continue browsing the daily collections",
                    style: GoogleFonts.notoSerif(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: primaryContainerColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

          if (cart.items.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFulfillmentSection(context, cart),
            ),


          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color onSurfaceColor = Color(0xFF701235);
    const Color outlineVariantColor = Color(0xFFD8C1C6);

    String imageUrl = item.imageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: outlineVariantColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(item.price / 100),
                  style: GoogleFonts.notoSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyIcon(Icons.remove, () => cart.decrementItem(item.id)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "${item.quantity}",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ),
              _buildQtyIcon(Icons.add, () => cart.addItem(item.id, item.name, item.price, item.imageUrl)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildQtyIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD8C1C6).withValues(alpha: 0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: const Color(0xFF701235)),
      ),
    );
  }

  Widget _buildFulfillmentSection(BuildContext context, CartProvider cart) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    // Source delivery fee from a central service/config in production
    const double delivery = 15000.0; // 150.00 Rupees in paise
    final double tax = cart.total * 0.05;
    final double total = cart.total + delivery + tax;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(context, "Subtotal", currencyFormatter.format(cart.total / 100)),
          _buildSummaryRow(context, "Delivery", currencyFormatter.format(delivery / 100)),
          _buildSummaryRow(context, "Tax (5%)", currencyFormatter.format(tax / 100)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total", style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(currencyFormatter.format(total / 100), style: GoogleFonts.notoSerif(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              HapticService.selection();
              final currentUser = Supabase.instance.client.auth.currentUser;
              if (currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthScreen(
                      isOwner: false,
                      onSuccess: () {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white),
                                const SizedBox(width: 12),
                                Text(
                                  "Welcome back! Restoring your cart...",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerCheckoutScreen()),
                        );
                      },
                    ),
                  ),
                );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerCheckoutScreen()));
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, primaryContainerColor]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text("PROCEED TO CHECKOUT", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticService.selection();
              final currentUser = Supabase.instance.client.auth.currentUser;
              if (currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthScreen(
                      isOwner: false,
                      onSuccess: () {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white),
                                const SizedBox(width: 12),
                                Text(
                                  "Welcome back! Restoring your cart...",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SelfCheckoutScreen()),
                        );
                      },
                    ),
                  ),
                );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfCheckoutScreen()));
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text("IN-STORE SELF CHECKOUT", style: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
