import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class SelfCheckoutScreen extends ConsumerStatefulWidget {
  const SelfCheckoutScreen({super.key});

  @override
  ConsumerState<SelfCheckoutScreen> createState() => _SelfCheckoutScreenState();
}

class _SelfCheckoutScreenState extends ConsumerState<SelfCheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(customerCartProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "In-Store Self Checkout",
          style: GoogleFonts.notoSerif(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("TELL US WHO YOU ARE"),
            const SizedBox(height: 16),
            _buildTextField("Your Name", Icons.person_outline, controller: _nameController),
            const SizedBox(height: 12),
            _buildTextField(
              "Contact Number",
              Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              prefixText: "+91 ",
              prefixStyle: GoogleFonts.plusJakartaSans(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            
            const SizedBox(height: 40),
            _sectionTitle("ORDER SUMMARY"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...cart.itemList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.name} (x${item.quantity})",
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
                        ),
                        Text(
                          "₹${((item.price * item.quantity) / 100).toStringAsFixed(2)}",
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 32),
                  _summaryRow("Subtotal", "₹${(cart.total / 100).toStringAsFixed(2)}"),
                  _summaryRow("In-Store Service", "FREE"),
                  _summaryRow("Tax (5%)", "₹${(((cart.total.round() * 5) + 50) ~/ 100 / 100).toStringAsFixed(2)}"),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grand Total",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "₹${((cart.total.round() + ((cart.total.round() * 5) + 50) ~/ 100) / 100).toStringAsFixed(2)}",
                        style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final phone = _phoneController.text.trim();
                  if (_nameController.text.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please provide your name and contact number")),
                    );
                    return;
                  }
                  
                  if (phone.length != 10 || !RegExp(r'^[6-9]').hasMatch(phone)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a valid 10-digit Indian contact number starting with 6-9")),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => PaymentScreen(
                        customerName: _nameController.text,
                        phone: _phoneController.text,
                        address: "In-Store Pickup / Self Checkout",
                        deliveryDate: DateTime.now().toIso8601String(),
                        deliveryTime: "Immediate",
                        notes: "Self Checkout Transaction",
                        isSelfCheckout: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.onSurfaceVariant,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  "PROCEED TO PAYMENT",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final sectionCs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: sectionCs.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    final fieldCs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
        prefixText: prefixText,
        prefixStyle: prefixStyle,
        prefixIcon: Icon(icon, size: 20, color: fieldCs.onSurfaceVariant),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldCs.onSurfaceVariant.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldCs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
