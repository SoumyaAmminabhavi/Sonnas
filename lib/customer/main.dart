import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'dart:async';
import 'providers/favorites_provider.dart';
import 'providers/cart_provider.dart';
import '../services/haptic_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;
  String? _menuSearchQuery;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _statusSubscriptionEmail;
  final Set<String> _notifiedOrderStatuses = {};
  StreamSubscription? _stockSubscription;
  Timer? _abandonedCartTimer;
  final Map<String, bool> _previousStockStatus = {};

  List<Widget> _getScreens() {
    final authId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return [
      HomeScreen(onViewMenu: (query) {
        setState(() {
          _menuSearchQuery = query;
          _currentIndex = 1;
        });
      }),
      MenuScreen(
        initialSearchQuery: _menuSearchQuery,
        key: ValueKey('menu_${_menuSearchQuery ?? "none"}'),
      ),
      CartScreen(key: ValueKey('cart_$authId')),
      OrdersScreen(key: ValueKey('orders_$authId')),
      ProfileScreen(key: ValueKey('profile_$authId')),
    ];
  }

  StreamSubscription<AuthState>? _authSubscription;
  String _avatarUrl = "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=120&h=120&fit=crop";

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final cloudAvatar = metadata['avatar_url']?.toString();
    
    if (mounted) {
      setState(() {
        _avatarUrl = prefs.getString('avatar_url') ?? cloudAvatar ?? "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=120&h=120&fit=crop";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setupStatusListener();
    _setupStockListener();
    _setupAbandonedCartListener();
    _loadAvatar();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _statusSubscription?.cancel();
          _statusSubscriptionEmail?.cancel();
          _setupStatusListener();
          _loadAvatar();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    _statusSubscriptionEmail?.cancel();
    _stockSubscription?.cancel();
    _abandonedCartTimer?.cancel();
    super.dispose();
  }

  void _setupStatusListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _statusSubscription?.cancel();
    _statusSubscriptionEmail?.cancel();

    final String rawPhone = (user.userMetadata?['phone']?.toString() ?? user.phone ?? "").replaceAll(RegExp(r'\D'), '');
    final String phone = rawPhone.length > 10
        ? rawPhone.substring(rawPhone.length - 10)
        : rawPhone;
    final String? email = user.email?.trim();

    void handleOrders(List<Map<String, dynamic>> orders) {
      for (final order in orders) {
        final String orderId = order['id'] ?? '';
        final String status = order['status'] ?? '';
        final String orderNum = order['orderNumber'] ?? 'Order';
        final String notifyKey = "${orderId}_$status";

        if (_notifiedOrderStatuses.contains(notifyKey)) continue;

        if (status == 'OUT_FOR_DELIVERY') {
          _notifiedOrderStatuses.add(notifyKey);
          _showStatusNotification("🚀 $orderNum is out for delivery!");
        } else if (status == 'DELIVERED') {
          _notifiedOrderStatuses.add(notifyKey);
          _showStatusNotification("✨ $orderNum has been delivered! Enjoy!");
        }
      }
    }

    if (phone.isNotEmpty) {
      _statusSubscription = Supabase.instance.client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerPhone', phone)
          .listen(handleOrders);
    }

    if (email != null && email.isNotEmpty) {
      _statusSubscriptionEmail = Supabase.instance.client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerEmail', email)
          .listen(handleOrders);
    }
  }

  void _setupStockListener() {
    _stockSubscription = Supabase.instance.client
        .from('Cake')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> cakes) {
          if (!mounted) return;
          final favoritesProvider = context.read<FavoritesProvider>();
          
          for (final cake in cakes) {
            final bool isAvailable = cake['isAvailable'] ?? true;
            final String cakeId = cake['id'].toString();
            final String cakeName = cake['name'] ?? 'A favorite cake';

            // Only notify if it was previously UNAVAILABLE and is now AVAILABLE
            final bool wasAvailable = _previousStockStatus[cakeId] ?? true; 

            if (isAvailable && !wasAvailable && favoritesProvider.isFavorite(cakeId, cakeName)) {
              _showStatusNotification("🍰 Good news! $cakeName is back in stock!");
            }
            
            // Update the state for the next update
            _previousStockStatus[cakeId] = isAvailable;
          }
        });
  }

  void _setupAbandonedCartListener() {
    // Check every 10 minutes if the cart is abandoned
    _abandonedCartTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      final cart = context.read<CartProvider>();
      if (cart.items.isNotEmpty && _currentIndex != 2) {
        _showStatusNotification("🛒 Your bag is waiting! Don't miss out on your treats.");
      }
    });
  }

  String? _lastShownMessage;
  void _showStatusNotification(String message) {
    if (!mounted || _lastShownMessage == message) return;
    
    _lastShownMessage = message;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF4D8D),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    ).closed.then((_) {
      if (mounted && _lastShownMessage == message) {
        _lastShownMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color surfaceColor = Color(0xFFFFF0F6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: surfaceColor,
          drawer: _buildDrawer(),
          appBar: isDesktop ? null : AppBar(
            backgroundColor: surfaceColor.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: primaryColor),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            centerTitle: true,
            title: Text(
              "Sonnas",
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
                  setState(() => _currentIndex = 2);
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
                  children: _getScreens(),
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
                  _buildNavItem(0, Icons.home_outlined, "HOME"),
                  _buildNavItem(1, Icons.restaurant_menu, "MENU"),
                  _buildNavItem(2, Icons.shopping_bag_outlined, "BAG"),
                  _buildNavItem(3, Icons.receipt_long, "ORDERS"),
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
                  _buildSidebarItem(0, Icons.home_outlined, "HOME"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(1, Icons.restaurant_menu, "THE MENU"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(2, Icons.shopping_bag_outlined, "YOUR BAG"),
                  const SizedBox(height: 12),
                  _buildSidebarItem(3, Icons.receipt_long, "ORDER HISTORY"),
                ],
              ),
            ),
          ),
          
          // Bottom Profile
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () {
                setState(() => _currentIndex = 4);
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
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(_avatarUrl),
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
      onTap: () {
        HapticService.selection();
        setState(() => _currentIndex = index);
      },
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
      onTap: () {
        HapticService.selection();
        setState(() => _currentIndex = index);
      },
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

  Widget _buildDrawer() {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color secondaryColor = Color(0xFF701235);

    return Drawer(
      backgroundColor: surfaceColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: primaryColor),
            title: Text("HOME", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: primaryColor),
            title: Text("MENU", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: primaryColor),
            title: Text("MY PROFILE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: Text("LOGOUT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                unawaited(Navigator.of(context).pushReplacementNamed('/welcome'));
              }
            },
          ),
        ],
      ),
    );
  }

}
