import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class SelfCheckoutScreen extends StatefulWidget {
  const SelfCheckoutScreen({super.key});

  @override
  State<SelfCheckoutScreen> createState() => _SelfCheckoutScreenState();
}

class _SelfCheckoutScreenState extends State<SelfCheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final meta = user.userMetadata!;
        if (meta['full_name'] != null) {
          _nameController.text = meta['full_name'];
        }
        if (meta['phone'] != null) {
          _phoneController.text = meta['phone'];
        }
      }
    } catch (e) {
      debugPrint("Error checking Supabase auth in self checkout: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_nameController.text.isEmpty) {
        final savedName = prefs.getString('guest_name');
        if (savedName != null && mounted) {
          setState(() {
            _nameController.text = savedName;
          });
        }
      }
      if (_phoneController.text.isEmpty) {
        final savedPhone = prefs.getString('guest_phone') ?? prefs.getString('saved_phone');
        if (savedPhone != null && mounted) {
          setState(() {
            _phoneController.text = savedPhone;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading guest details in self checkout: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF4D8D);
    const background = Color(0xFFFFF0F6);
    const berryText = Color(0xFF701235);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: berryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "In-Store Self Checkout",
          style: GoogleFonts.notoSerif(color: primary, fontStyle: FontStyle.italic),
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
              prefixStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF701235), fontWeight: FontWeight.w600, fontSize: 14),
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
                    color: berryText.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.name} (x${item.quantity})",
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: berryText.withValues(alpha: 0.7)),
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
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grand Total",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "₹${(cart.total / 100).toStringAsFixed(2)}",
                        style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: primary,
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
                  
                  final int subtotalCents = cart.total.round();
                  final int grandTotalCents = subtotalCents;
                  
                  // Save guest details to SharedPreferences for future pre-filling
                  final trimmedName = _nameController.text.trim();
                  final trimmedPhone = phone;
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('guest_name', trimmedName);
                    prefs.setString('guest_phone', trimmedPhone);
                  }).catchError((e) {
                    debugPrint("Error saving guest details to SharedPreferences: $e");
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        customerName: _nameController.text,
                        phone: _phoneController.text,
                        address: "In-Store Pickup / Self Checkout",
                        deliveryDate: DateTime.now().toIso8601String(),
                        deliveryTime: "Immediate",
                        notes: "Self Checkout Transaction",
                        isSelfCheckout: true,
                        totalAmount: grandTotalCents.toDouble(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
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
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: const Color(0xFF701235).withValues(alpha: 0.5),
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
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFFF4D8D)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFFF4D8D).withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4D8D)),
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
