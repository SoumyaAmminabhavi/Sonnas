import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _primaryColor = Color(0xFFFF4D8D);

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
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
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
                color: _primaryColor,
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
            icon: Icons.payments,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF85B3), Color(0xFFFFB6D3)],
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF701235),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isSelected ? Colors.white : const Color(0xFF701235),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
