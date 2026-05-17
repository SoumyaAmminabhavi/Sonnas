import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_provider.dart';
import '../services/order_service.dart';

class CustomerCheckoutPage extends ConsumerStatefulWidget {
  const CustomerCheckoutPage({super.key});

  @override
  ConsumerState<CustomerCheckoutPage> createState() => _CustomerCheckoutPageState();
}

class _CustomerCheckoutPageState extends ConsumerState<CustomerCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Checkout")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: cs.primary.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              const Text("Your cart is empty"),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back to Selection")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: Text("Finalize Selection", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: cs.secondary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildCartSummary(cs, cart),
            const SizedBox(height: 32),
            _buildCustomerForm(cs),
            const SizedBox(height: 48),
            _buildSubmitButton(cs, cart),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(ColorScheme cs, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR SELECTION", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: cs.primary)),
          const SizedBox(height: 16),
          ...cart.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product['name'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Qty: ${item.quantity}", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.secondary.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  Text(_formatPrice(item.totalPrice), style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(idx, -1),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              Text(_formatPrice(cart.subtotal), style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerForm(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DELIVERY DETAILS", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: cs.primary)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration("Full Name", Icons.person_outline),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Required";
            if (v.trim().length < 2) return "Name is too short";
            if (!RegExp(r"^[\p{L}\p{M}\s.'\-\u2019]+$", unicode: true).hasMatch(v.trim())) return "Name contains invalid characters";
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration("WhatsApp Number", Icons.phone_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Required";
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10) return "Enter a valid 10-digit number";
            if (digits.length > 12) return "Number is too long";
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: _inputDecoration("Delivery Address", Icons.location_on_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Required for delivery";
            if (v.trim().length < 10) return "Address is too short";
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: _inputDecoration("Notes for Chef (Optional)", Icons.edit_note),
          validator: (v) {
            if (v != null && v.length > 500) return "Notes are too long (max 500 characters)";
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs, CartState cart) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitOrder(cart),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("PLACE ORDER", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Future<void> _submitOrder(CartState cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = Random().nextInt(10000).toString().padLeft(4, '0');
      final orderData = {
        'orderNumber': 'SONNA-$timestamp-$randomSuffix',
        'customerName': _nameController.text.trim(),
        'phone': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'totalPrice': cart.subtotal.round(),
        'status': 'PENDING',
        'paymentStatus': 'PENDING',
        'createdAt': DateTime.now().toIso8601String(),
        'items': cart.items.map((i) => {
          'cakeName': i.product['name'],
          'quantity': i.quantity,
          'price': (double.tryParse(i.product['price']?.toString() ?? '0') ?? 0.0).round(),
        }).toList(),
      };

      await OrderService.submitPublicOrder(orderData);
      
      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission failed: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Merci!", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: const Text("Your selection has been received. We will contact you on WhatsApp shortly to confirm your masterpiece."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Checkout
            },
            child: const Text("Return to Boutique"),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double priceInCents) {
    final rupees = priceInCents / 100.0;
    return "₹${rupees.toStringAsFixed(rupees.truncateToDouble() == rupees ? 0 : 2)}";
  }
}
