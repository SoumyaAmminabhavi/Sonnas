import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/order_service.dart' as service;
class LandingPage extends StatelessWidget {
  final VoidCallback onViewMenu;
  const LandingPage({super.key, required this.onViewMenu});

  void _showContactInfo(BuildContext context, String title, String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title: $content"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDByacWHy0qBkvb3ebrlLczBbsGfLJBx9g4Vj3Hf4Rf569lIXYKgH5nlnkTzU9zV4vEdhwPTtSpJbUM35KeRyEkvcU8cANByCauDlJo-EbylTpSvlTVI4mi8vLC2KjT5unMk_UwxMzUa_iRFQpAWBRVM-cIwySNaEJKYvDZAga_G0__V0h0mKmn7WZfPBUWETga8cpX86pb2zsU5fiMipshkb08cFRwG1zuIO7psicDnlPSrRJrC1Wva6_OgBNVKJ0I64vcZYWy7-KE',
            fit: BoxFit.cover,
          ),
          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.85],
                colors: [
                  Color(0x662B1606), // rgba(43, 22, 6, 0.4)
                  Color(0xD9FFF8F5), // rgba(255, 248, 245, 0.85)
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Bakery Icon
                Icon(Icons.bakery_dining, size: 56, color: cs.primary),
                const SizedBox(height: 24),

                // Headline
                Text(
                  "Sonnas",
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtext
                Text(
                  "LUXURY CAKES & HANDCRAFTED DESSERTS",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Contact Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ContactGlassIcon(
                      icon: Icons.location_on_outlined,
                      cs: cs,
                      onPressed: () => _showContactInfo(
                        context,
                        "Find Us",
                        "4TH Phase, Shop No. 5,6,7 Ground Floor, Akshay Colony, Hubballi",
                      ),
                    ),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(
                      icon: Icons.mail_outline,
                      cs: cs,
                      onPressed: () => _showContactInfo(
                        context,
                        "Email Us",
                        "sonnaspatisseriecafe@gmail.com",
                      ),
                    ),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(
                      icon: Icons.photo_camera_outlined,
                      cs: cs,
                      onPressed: () =>
                          _showContactInfo(context, "Instagram", "@sonnas__"),
                    ),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(
                      icon: Icons.call_outlined,
                      cs: cs,
                      onPressed: () => _showContactInfo(
                        context,
                        "Call Us",
                        "+91 91132 31424",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Action Buttons
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    children: [
                      // View Menu Button (Gradient)
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primaryContainer],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            "ORDER ONLINE",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Custom Order Button (Glass)
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: cs.surface.withValues(alpha: 0.8),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: TextButton(
                              onPressed: () {
                                service.OrderService.launchWhatsApp(
                                  "+919113231424",
                                  "Hi Sonna, I'd like to inquire about a custom cake order."
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                "CUSTOM ENQUIRY",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Scroll down arrow
                Icon(
                  Icons.keyboard_double_arrow_down,
                  color: cs.outlineVariant,
                ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactGlassIcon extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onPressed;
  const _ContactGlassIcon({
    required this.icon,
    required this.cs,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: IconButton(
            onPressed: onPressed,
            iconSize: 20,
            icon: Icon(icon, color: cs.primary),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
