import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../services/haptic_service.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;

  const OrderSuccessScreen({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _triggerSuccessFeedback();
  }

  void _triggerSuccessFeedback() {
    HapticService.success();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color secondaryColor = Color(0xFF701235);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Lottie Success Animation
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_u4j3cx7p.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                "Order Confirmed!",
                style: GoogleFonts.notoSerif(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Thank you for choosing Sonna's Patisserie. Your sweet treats are being prepared with love.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: secondaryColor.withValues(alpha: 0.6),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                    _buildSummaryRow("Order Number", "#${widget.orderNumber}"),
                    const Divider(height: 32),
                    _buildSummaryRow("Total Paid", "₹${widget.totalAmount.toStringAsFixed(2)}"),
                    const Divider(height: 32),
                    _buildSummaryRow("Status", "PENDING", isStatus: true),
                  ],
                ),
              ),
              const Spacer(),
              // Home Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.selection();
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "BACK TO BOUTIQUE",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isStatus = false}) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color secondaryColor = Color(0xFF701235);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondaryColor.withValues(alpha: 0.4),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isStatus ? primaryColor : secondaryColor,
          ),
        ),
      ],
    );
  }
}
