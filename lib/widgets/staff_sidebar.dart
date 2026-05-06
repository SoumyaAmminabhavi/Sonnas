import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../staff/shared/staff_roles.dart';

class StaffSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final StaffRole role;

  const StaffSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.grid_view_rounded, 'title': "DASHBOARD"},
    ];

    final bool hasKitchen = role == StaffRole.chef || role == StaffRole.manager;
    final bool hasOrders = role == StaffRole.support || role == StaffRole.cashier || role == StaffRole.manager;
    final bool hasHygiene = role == StaffRole.cleaning || role == StaffRole.manager;

    if (hasKitchen || hasOrders || hasHygiene) {
      menuItems.add({'icon': Icons.bakery_dining_rounded, 'title': "OPERATIONS"});
    }

    if (role == StaffRole.manager || role == StaffRole.chef) {
      menuItems.add({'icon': Icons.inventory_2_outlined, 'title': "INVENTORY"});
    }

    if (role == StaffRole.manager) {
      menuItems.add({'icon': Icons.people_outline_rounded, 'title': "STAFF"});
    }

    menuItems.add({'icon': Icons.person_outline_rounded, 'title': "PROFILE"});

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
          ...List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            return _DrawerEntry(
              icon: item['icon'],
              title: item['title'],
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
            );
          }),
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
