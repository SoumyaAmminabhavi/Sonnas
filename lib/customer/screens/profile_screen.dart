import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color onSurface = Color(0xFF2B1606);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerLow = Color(0xFFFFF1E9);
    const Color surfaceContainerHigh = Color(0xFFFFDCC5);
    const Color outline = Color(0xFF867277);

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
                              color: secondary.withOpacity(0.1),
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
                    "MEMBERSHIP STATUS",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Amelie Laurent",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceContainerHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          "CONNOISSEUR",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      Text(
                        "EDIT DETAILS",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withOpacity(0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem("FULL NAME", "Amelie Laurent", outline, onSurface),
                        const SizedBox(height: 24),
                        _buildInfoItem("EMAIL ADDRESS", "amelie.l@patisserie.com", outline, onSurface),
                        const SizedBox(height: 24),
                        _buildInfoItem("PHONE NUMBER", "+91 98765 43210", outline, onSurface),
                        const SizedBox(height: 24),
                        _buildInfoItem("DEFAULT DELIVERY", "24 Rue de Rivoli,\n75004 Paris, FR", outline, onSurface),
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
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuCT0Y9SdPbiDQgOKKd0VnCdZVa3r5dV5Ge2SEen-9xaD4d9Wo51Lv5SoKRpoLTHOxxp1i2EIgHsV8jTFMUESLm163SluyWs0K4gIC-U_k-JQ4s6IL319LcTS8tTyOL0GNAmvCnvOz0YIXMMMOlwAAGZxBZOy1917Pcw729Ow0OpdQyv7GOU9bxc0pZGrFt5BUYUcC8QtleyrkgqNSt52Ob5fLtnZfBu0mS75jY44gCwFdwmHUUADmYY9MXtRBDtWhtA_T6bjxTlRMsR",
                    primary, outline, onSurface, surfaceContainerHigh
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    "Framboise Delice",
                    "₹1,250",
                    "ORDER #8845",
                    "DELIVERED",
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuBbCIYg6eTZsFc8O_OxxkW4LwXeLL7qRzPKxMOVWaXJxG5lRg-WLCOeWeQrEPWva1dfFF_WKMoiKVSKwQ27V4fOlFlWulvr2SGr7Zi7P_gAK_H-HDE_T1_zioFzJ8hLvoxRdCxSVbHndXuZhkbIHfxSE2M4FSwzlDgM8b4RuohLVVt8Ms2EH5r-8RtmD5i-Lmc3xoTINR9OuFB-d1kuEnTC14X3yiv5fujgkIUQAgmriVrZTJNBiI0teHjKfA8voBZMGQ6U7ZdUD2u4",
                    primary, outline, onSurface, surfaceContainerHigh
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: primary.withOpacity(0.3))),
                      ),
                      child: Text(
                        "View Full Order History",
                        style: GoogleFonts.notoSerif(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  // Account Settings
                  Text(
                    "Account Settings",
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSettingTile(Icons.manage_accounts_outlined, "Profile Settings", primary, onSurface, outline, context),
                  _buildSettingTile(Icons.payments_outlined, "Payment Methods", primary, onSurface, outline, context),
                  _buildSettingTile(Icons.notifications_active_outlined, "Notification Preferences", primary, onSurface, outline, context),
                  _buildSettingTile(Icons.help_center_outlined, "Help & Support", primary, onSurface, outline, context, onTap: () {
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
                          color: primary.withOpacity(0.3),
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
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "SONNA'S PATISSERIE V2.4.0 • SONNAS-PATISSERIE.COM",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: outline.withOpacity(0.5),
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

  Widget _buildInfoItem(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: labelColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
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
          BoxShadow(
            color: const Color(0xFF701235).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
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
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      orderId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: outline.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: primary,
                        ),
                      ),
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

  Widget _buildSettingTile(IconData icon, String title, Color primary, Color onSurface, Color outline, BuildContext context, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: outline.withOpacity(0.1))),
      ),
      child: ListTile(
        onTap: onTap ?? () {},
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF701235), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD8C1C6)),
      ),
    );
  }
}
