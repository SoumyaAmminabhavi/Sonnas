import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/haptic_service.dart';
import 'checkout_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isOwner;
  const ProfileSetupScreen({super.key, this.onSuccess, this.isOwner = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  static const Color primary = Color(0xFFFF4D8D);
  static const Color background = Color(0xFFFFF0F6);
  static const Color berry = Color(0xFF701235);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    unawaited(HapticService.selection());

    try {
      final supabase = Supabase.instance.client;
      
      // Update Supabase Auth metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'default_address': _addressController.text.trim(),
            'profile_setup_completed': true,
          },
        ),
      );

      // Save locally to SharedPreferences for fast, offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_name', _nameController.text.trim());
      await prefs.setString('guest_phone', _phoneController.text.trim());
      await prefs.setString('default_address', _addressController.text.trim());
      await prefs.setString('saved_addresses', Uri.encodeComponent(_addressController.text.trim()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  "Welcome to Sonna's, ${_nameController.text.trim()}!",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        setState(() {
          _isLoading = false;
        });

        // Execute post-login navigation flow
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          unawaited(Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerCheckoutScreen()),
          ));
        }
      }
    } catch (e) {
      debugPrint("Error completing profile setup: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save profile. Please try again: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Icon & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        size: 50,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome to Sonna's!",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: berry,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Just a few details to personalize your premium patisserie experience.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: berry.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    cursorColor: primary,
                    decoration: InputDecoration(
                      labelText: "FULL NAME",
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: berry.withValues(alpha: 0.5),
                      ),
                      hintText: "Enter your first and last name",
                      prefixIcon: const Icon(Icons.person_outline, color: primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter your name" : null,
                  ),
                  const SizedBox(height: 20),

                  // Mobile Number Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    cursorColor: primary,
                    decoration: InputDecoration(
                      labelText: "MOBILE NUMBER",
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: berry.withValues(alpha: 0.5),
                      ),
                      hintText: "Enter your phone number",
                      prefixText: "+91 ",
                      prefixStyle: GoogleFonts.plusJakartaSans(
                        color: berry,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined, color: primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Please enter your mobile number";
                      if (v.length != 10) return "Phone number must be 10 digits";
                      if (!RegExp(r'^[6-9]').hasMatch(v)) return "Invalid phone number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Default Address Field
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    cursorColor: primary,
                    decoration: InputDecoration(
                      labelText: "DEFAULT DELIVERY ADDRESS",
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: berry.withValues(alpha: 0.5),
                      ),
                      hintText: "Enter your address for accurate delivery",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.location_on_outlined, color: primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter your delivery address" : null,
                  ),
                  const SizedBox(height: 40),

                  // Save Profile Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "SAVE & CONTINUE",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

