import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const OwnerBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: cs.surface.withValues(alpha: 0.95),
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.secondary.withValues(alpha: 0.6),
      selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.payments), label: "Finance"),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Menu"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}
