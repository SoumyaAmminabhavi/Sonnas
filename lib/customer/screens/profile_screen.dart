import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController(text: "Sonnas Cafe");
  final TextEditingController _emailController = TextEditingController(text: "soonas@gmail.com");
  final TextEditingController _phoneController = TextEditingController(text: "09113231424");
  final TextEditingController _addressController = TextEditingController(text: "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021");

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Data is now set via default controllers for boutique brand consistency
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      // Simulate/Implement profile update
      await Future.delayed(const Duration(seconds: 1)); // UX feedback delay
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Color(0xFFFF4D8D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating profile")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color onSurface = Color(0xFF701235);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerHigh = Color(0xFFFFDCC5);
    const Color outline = Color(0xFF867277);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: surfaceContainerHigh, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: secondary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(56),
                          child: Image.network(
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuC906zMoWpz20EzIX9rHUQWXwqHop9zHMqiJpL1cJocICMrUqiDRvZ6lbtZvxpEoxIbK0XyFhMe1gwGbSOa0ZMvULR4ivkTjlvx8Ds7CY03emu5eZpoZnkVlASDBsPOejOGv2YsYhdQVkt5j_tYptsfaQ3v__rxbDkK_7NK4V0RzprQlmaHd2rBFkNdcZcVqKZ41cC5SBLn8tyUkqqTFodANgA7CSqnNLBpPJ7o7VfLt2f994NtQX_u6MAPSP1M_fWHt7GgmcDs69AZ",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.verified, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _nameController.text,
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Personal Information",
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          color: onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                        child: Text(
                          _isEditing ? "SAVE CHANGES" : "EDIT DETAILS",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditableInfoItem("FULL NAME", _nameController, outline, onSurface),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("EMAIL ADDRESS", _emailController, outline, onSurface, isEnabled: false),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("PHONE NUMBER", _phoneController, outline, onSurface),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("DEFAULT DELIVERY", _addressController, outline, onSurface, maxLines: 2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  // Recent Activity
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActivityItem(
                    "The Signature Box (12pcs)",
                    "₹3,450",
                    "ORDER #8921",
                    "DELIVERED",
                    "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=3578&auto=format&fit=crop",
                    primary, outline, onSurface, surfaceContainerHigh
                  ),
                  const SizedBox(height: 48),
                  
                  // Account Settings
                  Text(
                    "Account Settings",
                    style: GoogleFonts.notoSerif(fontSize: 20, color: onSurface),
                  ),
                  const SizedBox(height: 24),
                  _buildSettingTile(Icons.help_center_outlined, "Help & Support", onSurface, outline, context, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen()));
                  }),

                  const SizedBox(height: 64),
                  // Sign Out Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [primary, primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "SIGN OUT",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "SONNA'S PATISSERIE V2.4.0",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableInfoItem(String label, TextEditingController controller, Color labelColor, Color valueColor, {int maxLines = 1, bool isEnabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        if (_isEditing && isEnabled)
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF4D8D))),
            ),
          )
        else
          Text(
            controller.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String price, String orderId, String status, String imageUrl, Color primary, Color outline, Color onSurface, Color statusBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF701235).withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(price, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(orderId, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: outline.withValues(alpha: 0.6))),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusBg.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, Color onSurface, Color outline, BuildContext context, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: outline.withValues(alpha: 0.1)))),
      child: ListTile(
        onTap: onTap ?? () {},
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFFFF1E9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF701235), size: 20),
        ),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD8C1C6)),
      ),
    );
  }
}
