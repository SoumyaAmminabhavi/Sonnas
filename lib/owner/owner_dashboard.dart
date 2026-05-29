import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'menu_page.dart';
import 'owner_settings.dart';
import 'orders_page.dart';
import 'payments_page.dart';
import '../widgets/owner_sidebar.dart';
import '../services/dashboard_provider.dart';
import 'order_details_page.dart';
import 'widgets/dashboard_content.dart';
import 'widgets/owner_bottom_nav.dart';
import '../services/settings_service.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _selectedIndex = 0;
  SalesRange _selectedRange = SalesRange.weekly;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late PageController _pageController;
  int? _lastOrderCount;
  int _settingsResetCounter = 0;
  String? _lastNotifiedOrderId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    setState(() {
      if (_selectedIndex == index && index == 4) {
        _settingsResetCounter++;
      }
      _selectedIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showNewOrderNotification(Map<String, dynamic> order) {
    final orderNumber = (order['orderNumber'] as String?) ?? '---';
    final customerName = (order['customerName'] as String?) ?? 'Guest';
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    late OverlayEntry overlayEntry;
    final child = Material(
      color: Colors.transparent,
      child: _NotificationWidget(
        customerName: customerName,
        orderNumber: orderNumber,
        isMobile: isMobile,
        onView: () async {
          final String? orderId = order['id']?.toString();
          if (orderId == null || orderId.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid order ID')),
            );
            if (overlayEntry.mounted) overlayEntry.remove();
            return;
          }
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'OwnerOrderDetails'),
              builder: (context) => OwnerOrderDetailsView(
                orderId: orderId,
                onTabChanged: _handleNavigation,
              ),
            ),
          );
          if (overlayEntry.mounted) overlayEntry.remove();
        },
        onDismiss: () {
          if (overlayEntry.mounted) overlayEntry.remove();
        },
      ),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: isMobile ? 0 : null,
        bottom: isMobile ? null : 24,
        right: isMobile ? 16 : 24,
        left: isMobile ? 16 : null,
        width: isMobile ? null : 380,
        child: isMobile
            ? SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: child,
                ),
              )
            : child,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recentOrdersProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final orders = next.value!;
        if (_lastOrderCount == null) {
          _lastOrderCount = orders.length;
          if (orders.isNotEmpty) {
            _lastNotifiedOrderId = orders.first['id']?.toString();
          }
          return;
        }
        if (orders.isNotEmpty) {
          final latestOrderId = orders.first['id']?.toString();
          if (latestOrderId != null && latestOrderId != _lastNotifiedOrderId && orders.length > _lastOrderCount!) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final pushEnabled = await SettingsService.getPushNotificationsEnabled();
              if (mounted && pushEnabled) {
                _showNewOrderNotification(orders.first);
              }
            });
            _lastNotifiedOrderId = latestOrderId;
          }
        }
        _lastOrderCount = orders.length;
      }
    });
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: isDesktop ? null : IconButton(icon: Icon(Icons.arrow_back, color: cs.primary), onPressed: () => Navigator.of(context).pop()),
            title: Text("Sonnas", style: GoogleFonts.notoSerif(color: cs.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
          ),
          bottomNavigationBar: isDesktop ? null : OwnerBottomNav(currentIndex: _selectedIndex, onTap: _handleNavigation),
          body: Row(
            children: [
              if (isDesktop) OwnerSidebar(currentIndex: _selectedIndex, onTap: _handleNavigation),
              Expanded(
                child: isDesktop
                    ? _buildPage(_selectedIndex, isDesktop)
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _selectedIndex = index),
                        children: List.generate(5, (i) => _buildPage(i, false)),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(int index, bool isDesktop) {
    switch (index) {
      case 1: return ManageOrdersPage(onTabChanged: _handleNavigation);
      case 2: return const PaymentsPage();
      case 3: return MenuPage(onTabChanged: _handleNavigation);
      case 4: 
        return OwnerSettingsPage(
          key: ValueKey("settings_$_settingsResetCounter"),
          onTabChanged: _handleNavigation
        );
      default:
        return DashboardContent(
          isDesktop: isDesktop,
          selectedRange: _selectedRange,
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
          onRangeChanged: (range) => setState(() => _selectedRange = range),
          onMonthChanged: (m) => setState(() => _selectedMonth = m),
          onYearChanged: (y) => setState(() => _selectedYear = y),
          onViewAllOrders: () => _handleNavigation(1),
        );
    }
  }
}

class _NotificationWidget extends StatefulWidget {
  final String customerName, orderNumber;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final bool isMobile;

  const _NotificationWidget({
    required this.customerName,
    required this.orderNumber,
    required this.onView,
    required this.onDismiss,
    required this.isMobile,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _slideAnimation = Tween<Offset>(
      begin: widget.isMobile ? const Offset(0, -1.0) : const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D8D),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8D).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "NEW ORDER RECEIVED",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.customerName} (#${widget.orderNumber})",
                      style: GoogleFonts.notoSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.onView,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "VIEW",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF4D8D),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
