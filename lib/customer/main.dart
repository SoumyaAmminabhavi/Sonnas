import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';


class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onViewMenu: () => setState(() => _currentIndex = 1)),
      const MenuScreen(),
      const ChatScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color surfaceColor = Color(0xFFFFF0F6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;
        
        return Scaffold(
          backgroundColor: surfaceColor,
          appBar: isDesktop ? null : AppBar(
            backgroundColor: surfaceColor.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: primaryColor),
              onPressed: () {},
            ),
            centerTitle: true,
            title: Text(
              "Sonna's Patisserie",
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: primaryColor,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: primaryColor),
                onPressed: () {
                  setState(() => _currentIndex = 3);
                },
              ),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : Container(
            height: 100,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF701235).withValues(alpha: 0.06),
                  blurRadius: 40,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 32, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.storefront, "BOUTIQUE"),
                  _buildNavItem(1, Icons.restaurant_menu, "MENU"),
                  _buildNavItem(2, Icons.chat_bubble_outline, "CHAT"),
                  _buildNavItem(3, Icons.shopping_bag_outlined, "BAG"),
                  _buildNavItem(4, Icons.receipt_long, "ORDERS"),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSidebar() {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color secondaryColor = Color(0xFF701235);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: secondaryColor.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Sidebar Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  "Sonna's",
                  style: GoogleFonts.notoSerif(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: primaryColor,
                  ),
                ),
                Text(
                  "PATISSERIE",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: secondaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          
          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSidebarItem(0, Icons.storefront, "BOUTIQUE"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(1, Icons.restaurant_menu, "THE MENU"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(2, Icons.chat_bubble_outline, "ASSISTANCE"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(3, Icons.shopping_bag_outlined, "YOUR BAG"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(4, Icons.receipt_long, "ORDER HISTORY"),
                ],
              ),
            ),
          ),
          
          // Bottom Profile
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () {
                setState(() => _currentIndex = 5);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withValues(alpha: 0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuC906zMoWpz20EzIX9rHUQWXwqHop9zHMqiJpL1cJocICMrUqiDRvZ6lbtZvxpEoxIbK0XyFhMe1gwGbSOa0ZMvULR4ivkTjlvx8Ds7CY03emu5eZpoZnkVlASDBsPOejOGv2YsYhdQVkt5j_tYptsfaQ3v__rxbDkK_7NK4V0RzprQlmaHd2rBFkNdcZcVqKZ41cC5SBLn8tyUkqqTFodANgA7CSqnNLBpPJ7o7VfLt2f994NtQX_u6MAPSP1M_fWHt7GgmcDs69AZ"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "My Profile",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF701235),
                            ),
                          ),
                          Text(
                            "ACCOUNT SETTINGS",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color secondaryColor = Color(0xFF701235);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : secondaryColor.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1.5,
                color: isSelected ? Colors.white : secondaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);
    const Color secondaryColor = Color(0xFF701235);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryContainerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : secondaryColor.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1.2,
                color: isSelected ? primaryColor : secondaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
