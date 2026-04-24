import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_page.dart';

void main() {
  runApp(const PatisserieApp());
}

class PatisserieApp extends StatelessWidget {
  const PatisserieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonna\'s Patisserie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF964261),
          secondary: Color(0xFF825433),
          surface: Color(0xFFFFF8F5),
          onSurface: Color(0xFF2B1606),
          onSurfaceVariant: Color(0xFF534247),
          primaryContainer: Color(0xFFF48FB1),
          onPrimaryContainer: Color(0xFF722544),
          surfaceContainer: Color(0xFFFFEADD),
          surfaceContainerLow: Color(0xFFFFF1E9),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.notoSerif(
            color: const Color(0xFF2B1606),
            fontWeight: FontWeight.w400,
          ),
          headlineLarge: GoogleFonts.notoSerif(
            color: const Color(0xFF2B1606),
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF825433),
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      home: const AppNavigation(),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LandingPage(onViewMenu: () => _onTabSelected(1)),
          const MenuPage(),
          const Placeholder(), // Orders
          const Placeholder(), // Profile
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  final VoidCallback onViewMenu;
  const LandingPage({super.key, required this.onViewMenu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: cs.surface,
      drawer: const ModernDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent on Landing
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: cs.primary),
        title: const Text(" "),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDByacWHy0qBkvb3ebrlLczBbsGfLJBx9g4Vj3Hf4Rf569lIXYKgH5nlnkTzU9zV4vEdhwPTtSpJbUM35KeRyEkvcU8cANByCauDlJo-EbylTpSvlTVI4mi8vLC2KjT5unMk_UwxMzUa_iRFQpAWBRVM-cIwySNaEJKYvDZAga_G0__V0h0mKmn7WZfPBUWETga8cpX86pb2zsU5fiMipshkb08cFRwG1zuIO7psicDnlPSrRJrC1Wva6_OgBNVKJ0I64vcZYWy7-KE',
            fit: BoxFit.cover,
          ),
          // Gradient Overlay exactly mapping to CSS hero-gradient-overlay
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
                  "Sonna's Patisserie",
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Contact Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ContactGlassIcon(icon: Icons.location_on_outlined, cs: cs),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(icon: Icons.mail_outline, cs: cs),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(
                      icon: Icons.photo_camera_outlined,
                      cs: cs,
                    ),
                    const SizedBox(width: 24),
                    _ContactGlassIcon(icon: Icons.call_outlined, cs: cs),
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
                              color: cs.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: onViewMenu,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            "VIEW MENU",
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
                          color: cs.surface.withOpacity(0.8),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MenuPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                "CUSTOM ORDER",
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
                  color: const Color(0xFFD8C1C6), // outline-variant
                ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ],
      ),
      // Bottom nav is now handled by AppNavigation
    );
  }
}

// --------------------------------------------------------------------------
// Components
// --------------------------------------------------------------------------

class _ContactGlassIcon extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  const _ContactGlassIcon({required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surface.withOpacity(0.5),
        border: Border.all(color: const Color(0xFFD8C1C6).withOpacity(0.3)),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: IconButton(
            iconSize: 20,
            icon: Icon(icon, color: cs.primary),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: const Color(0xFFFFF1E9), // surface-container-low
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "L'Atelier",
                    style: GoogleFonts.notoSerif(
                      color: cs.primary,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              _DrawerItem(
                icon: Icons.admin_panel_settings_outlined,
                label: "Login as Owner",
              ),
              _DrawerItem(icon: Icons.badge_outlined, label: "Login as Staff"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: const Color(0xFFD8C1C6).withOpacity(0.3)),
              ),

              _DrawerItem(icon: Icons.info_outline, label: "Business Info"),

              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD8C1C6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LOCATION",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "123 Rue de la Paix\n75002 Paris, France",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DrawerItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      hoverColor: cs.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.storefront_outlined,
                    label: "Boutique",
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                    cs: cs,
                  ),
                  _BottomNavItem(
                    icon: Icons.restaurant_menu_outlined,
                    label: "Menu",
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                    cs: cs,
                  ),
                  _BottomNavItem(
                    icon: Icons.auto_stories_outlined,
                    label: "Orders",
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                    cs: cs,
                  ),
                  _BottomNavItem(
                    icon: Icons.person_outline,
                    label: "Profile",
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                    cs: cs,
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final ColorScheme cs;

  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? cs.primaryContainer.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              children: [
                Icon(icon, color: isActive ? cs.primary : cs.secondary),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isActive ? cs.primary : cs.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
