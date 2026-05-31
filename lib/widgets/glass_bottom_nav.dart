import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
                    label: "Home",
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
                  ? cs.primaryContainer.withValues(alpha: 0.1)
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
