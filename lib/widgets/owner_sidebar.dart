import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const OwnerSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(10, 0),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Menu",
              style: GoogleFonts.notoSerif(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DrawerEntry(
            icon: Icons.dashboard,
            title: "DASHBOARD",
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _DrawerEntry(
            icon: Icons.shopping_bag,
            title: "ORDERS",
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _DrawerEntry(
            icon: Icons.payment,
            title: "PAYMENTS",
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _DrawerEntry(
            icon: Icons.inventory_2,
            title: "MENU",
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _DrawerEntry(
            icon: Icons.settings,
            title: "SETTINGS",
            isSelected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _DrawerEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerEntry({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(colors: [cs.primary, cs.primaryContainer])
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : cs.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 1.5,
                    color: isSelected ? Colors.white : cs.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
