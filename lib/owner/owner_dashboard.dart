import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'menu_page.dart';
import 'owner_settings.dart';
import 'orders_page.dart';
import 'payments_page.dart';
import '../widgets/owner_sidebar.dart';
import '../widgets/skeleton.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/supabase_service.dart';
import 'order_details_page.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  SalesRange _selectedRange = SalesRange.weekly;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late PageController _pageController;
  StreamSubscription? _orderSubscription;
  int? _lastOrderCount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _setupOrderListener();
  }

  void _setupOrderListener() {
    _orderSubscription = SupabaseService.getRecentOrdersStream().listen((orders) {
      if (_lastOrderCount != null && orders.length > _lastOrderCount!) {
        // New order received!
        final newOrder = orders.first;
        _showNewOrderNotification(newOrder);
      }
      _lastOrderCount = orders.length;
    });
  }

  void _showNewOrderNotification(Map<String, dynamic> order) {
    final orderNumber = order['orderNumber'] ?? '---';
    final customerName = order['customerName'] ?? 'Guest';
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: isMobile ? 16 : null,
        bottom: isMobile ? null : 24,
        right: isMobile ? 16 : 24,
        left: isMobile ? 16 : null,
        width: isMobile ? null : 380,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, isMobile ? -40 * (1 - value) : 40 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D8D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D8D).withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          "$customerName (#$orderNumber)",
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
                    onPressed: () {
                      overlayEntry.remove();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OwnerOrderDetailsView(
                            orderId: orderNumber,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: () => overlayEntry.remove(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto-remove after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: cs.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Sonna's Patisserie & Cafe",
              style: GoogleFonts.notoSerif(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : _MobileBottomNav(
                  currentIndex: _selectedIndex,
                  onTap: _handleNavigation,
                ),
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: _selectedIndex,
                  onTap: _handleNavigation,
                ),
              Expanded(
                child: isDesktop
                    ? _buildPage(_selectedIndex, isDesktop)
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        children: [
                          _buildPage(0, false),
                          _buildPage(1, false),
                          _buildPage(2, false),
                          _buildPage(3, false),
                          _buildPage(4, false),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(int index, bool isDesktop) {
    if (index == 1) {
      return ManageOrdersPage(onTabChanged: _handleNavigation);
    } else if (index == 2) {
      return const PaymentsPage();
    } else if (index == 3) {
      return MenuPage(onTabChanged: _handleNavigation);
    } else if (index == 4) {
      return OwnerSettingsPage(onTabChanged: _handleNavigation);
    } else {
      return _MainContent(
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

class _MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MobileBottomNav({required this.currentIndex, required this.onTap});

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
      selectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.payments), label: "Payments"),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Menu"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  final bool isDesktop;
  final SalesRange selectedRange;
  final int selectedMonth;
  final int selectedYear;
  final Function(SalesRange) onRangeChanged;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;
  final VoidCallback onViewAllOrders;

  const _MainContent({
    required this.isDesktop,
    required this.selectedRange,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onRangeChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onViewAllOrders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 24.0,
          vertical: 32.0,
        ),
        children: [
          // Welcome Header
          Text(
            "Hello, Sonna.",
            style: GoogleFonts.notoSerif(
              color: cs.secondary,
              fontSize: isDesktop ? 48 : 36,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "OWNER OVERVIEW",
            style: GoogleFonts.plusJakartaSans(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 1,
            color: cs.secondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 48),
          _buildQuickStats(context, isDesktop),
          const SizedBox(height: 48),
          _buildPerformanceChart(context, isDesktop),
          const SizedBox(height: 48),

          // Recent Orders Header
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isDesktop
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              isDesktop
                  ? Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recent Orders",
                            style: GoogleFonts.notoSerif(
                              color: cs.secondary,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            "Latest activity from the boutique",
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Orders",
                          style: GoogleFonts.notoSerif(
                            color: cs.secondary,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          "Latest activity from the boutique",
                          style: GoogleFonts.plusJakartaSans(
                            color: cs.secondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
              if (!isDesktop) const SizedBox(height: 12),
              InkWell(
                onTap: onViewAllOrders,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: cs.primaryContainer, width: 2),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    "View All Archives",
                    style: GoogleFonts.notoSerif(
                      color: cs.primary,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Orders List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getRecentOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: cs.surfaceContainer,
                  highlightColor: cs.surface,
                  child: Column(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                    )),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _DashboardErrorView(
                  cs: cs,
                  error: snapshot.error.toString(),
                );
              }

              final rawOrders = (snapshot.data ?? []).take(4).toList();

              if (rawOrders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome_outlined, color: cs.primary.withValues(alpha: 0.1), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "No active creations.",
                          style: GoogleFonts.notoSerif(
                            color: cs.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService.fetchMenu(),
                builder: (context, menuSnapshot) {
                  final orders = rawOrders.map((data) {
                    return _OrderCardReactive(data: data, cs: cs);
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;

                      if (crossAxisCount == 2) {
                        List<Widget> rows = [];
                        for (var i = 0; i < orders.length; i += 2) {
                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                children: [
                                  Expanded(child: orders[i]),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: i + 1 < orders.length
                                        ? orders[i + 1]
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(children: rows);
                      }

                      return Column(
                        children: orders
                            .map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: o,
                              ),
                            )
                            .toList(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDesktop) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<Map<String, dynamic>>(
      stream: SupabaseService.getDashboardStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonWrapper(
            child: Row(
              children: List.generate(3, (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Skeleton(height: 10, width: 60),
                        const SizedBox(height: 12),
                        const Skeleton(height: 24, width: 40),
                      ],
                    ),
                  ),
                ),
              )),
            ),
          );
        }


        final stats =
            snapshot.data ??
            {'totalOrders': 0, 'totalRevenue': 0.0, 'activeCustomers': 0};

        return Row(
          children: [
            Expanded(
              child: _statCard(
                title: "TOTAL ORDERS",
                value: stats['totalOrders'].toString(),
                icon: Icons.shopping_bag_outlined,
                cs: cs,
                isDesktop: isDesktop,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                title: "TOTAL REVENUE",
                value: "₹${stats['totalRevenue'].toInt()}",
                icon: Icons.payments_outlined,
                cs: cs,
                isDesktop: isDesktop,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                title: "CUSTOMERS",
                value: stats['activeCustomers'].toString(),
                icon: Icons.people_outline,
                cs: cs,
                isDesktop: isDesktop,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required ColorScheme cs,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: isDesktop ? 20 : 16),
          SizedBox(height: isDesktop ? 16 : 8),
          Text(
            value,
            style: GoogleFonts.notoSerif(
              color: cs.secondary,
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.4),
              fontSize: isDesktop ? 10 : 8,
              fontWeight: FontWeight.bold,
              letterSpacing: isDesktop ? 1.0 : 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context, bool isDesktop) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isDesktop
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.start,
            children: [
              isDesktop
                  ? Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sales Performance",
                            style: GoogleFonts.notoSerif(
                              color: cs.secondary,
                              fontSize: isDesktop ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Revenue trend analysis",
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sales Performance",
                          style: GoogleFonts.notoSerif(
                            color: cs.secondary,
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Revenue trend analysis",
                          style: GoogleFonts.plusJakartaSans(
                            color: cs.secondary.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
              if (!isDesktop) const SizedBox(height: 16),
              // Range Selector & Date Pickers
              Column(
                crossAxisAlignment: isDesktop
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                        children: SalesRange.values.map((range) {
                        final isSelected = selectedRange == range;
                        return GestureDetector(
                          onTap: () => onRangeChanged(range),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              range.name.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedRange == SalesRange.monthly ||
                      selectedRange == SalesRange.yearly)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedRange == SalesRange.monthly)
                            DropdownButton<int>(
                              value: selectedMonth,
                              underline: const SizedBox(),
                              style: GoogleFonts.plusJakartaSans(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (m) =>
                                  m != null ? onMonthChanged(m) : null,
                              items: List.generate(12, (i) => i + 1).map((m) {
                                const months = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ];
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(months[m - 1].toUpperCase()),
                                );
                              }).toList(),
                            ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: selectedYear,
                            underline: const SizedBox(),
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (y) =>
                                y != null ? onYearChanged(y) : null,
                            items:
                                List.generate(
                                  5,
                                  (i) => DateTime.now().year - i,
                                ).map((y) {
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text("$y"),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: StreamBuilder<Map<int, double>>(
              stream: SupabaseService.getSalesStream(
                range: selectedRange,
                targetMonth: selectedMonth,
                targetYear: selectedYear,
              ),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {};

                double maxRevenue = 1000;
                for (var v in data.values) {
                  if (v > maxRevenue) maxRevenue = v;
                }
                maxRevenue = (maxRevenue / 100).ceil() * 100.0 + 100.0;

                final List<FlSpot> spots = [];
                final sortedKeys = data.keys.toList()..sort();
                for (var key in sortedKeys) {
                  spots.add(FlSpot(key.toDouble(), data[key] ?? 0.0));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxRevenue / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: cs.secondary.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: selectedRange == SalesRange.monthly ? 5 : 1,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (selectedRange == SalesRange.today) {
                              if (value % 4 == 0) text = "${value.toInt()}h";
                            } else if (selectedRange == SalesRange.weekly) {
                              const days = [
                                'MON',
                                'TUE',
                                'WED',
                                'THU',
                                'FRI',
                                'SAT',
                                'SUN',
                              ];
                              if (value >= 0 && value < 7) {
                                text = days[value.toInt()];
                              }
                            } else if (selectedRange == SalesRange.monthly) {
                              if (value % 5 == 0) text = "D${value.toInt()}";
                            } else if (selectedRange == SalesRange.yearly) {
                              const months = [
                                'JAN',
                                'FEB',
                                'MAR',
                                'APR',
                                'MAY',
                                'JUN',
                                'JUL',
                                'AUG',
                                'SEP',
                                'OCT',
                                'NOV',
                                'DEC',
                              ];
                              if (value >= 1 && value <= 12) {
                                text = months[value.toInt() - 1];
                              }
                            }

                            if (text.isEmpty) return const SizedBox();

                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                text,
                                style: GoogleFonts.plusJakartaSans(
                                  color: cs.secondary.withValues(alpha: 0.4),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: sortedKeys.isEmpty ? 0 : sortedKeys.first.toDouble(),
                    maxX: sortedKeys.isEmpty ? 6 : sortedKeys.last.toDouble(),
                    minY: 0,
                    maxY: maxRevenue,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primaryContainer],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: selectedRange != SalesRange.monthly,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 3,
                                color: cs.surfaceContainer,
                                strokeWidth: 2,
                                strokeColor: cs.primary,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              cs.primary.withValues(alpha: 0.15),
                              cs.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCardReactive extends StatelessWidget {
  final Map<String, dynamic> data;
  final ColorScheme cs;

  const _OrderCardReactive({required this.data, required this.cs});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        SupabaseService.fetchMenu(),
        SupabaseService.fetchOrderItems(data['id']),
      ]),
      builder: (context, snapshot) {
        final menu = snapshot.data?[0] ?? [];
        final items = snapshot.data?[1] ?? [];

        final status = data['status'] ?? 'PENDING';
        Color statusColor = cs.primary;
        if (status == 'COMPLETED') {
          statusColor = cs.secondary;
        }

        String imageUrl = data['customImageUrl'] ?? '';
        if (imageUrl.isEmpty || imageUrl.startsWith('whatsapp://')) {
          if (items.isNotEmpty) {
            final String firstName = items[0]['cakeName'] ?? '';
            final matchingCake = menu.firstWhere(
              (c) =>
                  (c['name'] as String).toLowerCase() ==
                  firstName.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            imageUrl = matchingCake['image'] ?? '';
          }
        }

        String orderSubtitle = 'Custom Creation';
        if (items.isNotEmpty) {
          final String firstName = items[0]['cakeName'] ?? 'Boutique Order';
          orderSubtitle = items.length > 1 ? "$firstName + ${items.length - 1} more" : firstName;
        }

        final paymentStatus = data['paymentStatus'] ?? 'PENDING';

        return _OrderCard(
          id: "#${data['orderNumber'] ?? '---'}",
          status: status,
          statusColor: statusColor,
          statusBg: statusColor.withValues(alpha: 0.1),
          paymentStatus: paymentStatus,
          customerName: data['customerName'] ?? 'Guest Customer',
          price: data['totalPrice'] != null
              ? SupabaseService.formatPrice(data['totalPrice'])
              : (items.isNotEmpty
                    ? SupabaseService.formatPrice(items[0]['price'])
                    : '---'),
          imageUrl: SupabaseService.getPublicUrl(imageUrl),
          deliveryDate: data['deliveryDate'] ?? 'Not scheduled',
          deliveryTime: data['deliveryTime'],
          orderSubtitle: orderSubtitle,
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String id;
  final String status;
  final String paymentStatus;
  final Color statusColor;
  final Color statusBg;
  final String customerName;
  final String price;
  final String imageUrl;
  final String deliveryDate;
  final String? deliveryTime;
  final String orderSubtitle;

  const _OrderCard({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.statusColor,
    required this.statusBg,
    required this.customerName,
    required this.price,
    required this.imageUrl,
    required this.deliveryDate,
    required this.orderSubtitle,
    this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerOrderDetailsView(orderId: id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.secondary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: cs.primary.withValues(alpha: 0.05),
                  child: Center(
                    child: Icon(
                      Icons.cake_outlined,
                      color: cs.primary.withValues(alpha: 0.2),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          id,
                          style: GoogleFonts.notoSerif(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: cs.secondary.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (paymentStatus == 'PAID' ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentStatus == 'PAID' ? "PAID" : "UNPAID",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: paymentStatus == 'PAID' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _CompactInfoRow(
                    icon: Icons.cake_outlined,
                    text: orderSubtitle,
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 2),
                  _CompactInfoRow(
                    icon: Icons.payments_outlined,
                    text: price,
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 2),
                  _CompactInfoRow(
                    icon: Icons.schedule_outlined,
                    text: deliveryTime != null ? "$deliveryDate at $deliveryTime" : deliveryDate,
                    color: cs.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CompactInfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
class _DashboardErrorView extends StatelessWidget {
  final ColorScheme cs;
  final String error;

  const _DashboardErrorView({
    required this.cs,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.primary.withValues(alpha: 0.3), size: 32),
          const SizedBox(height: 12),
          Text(
            "Connection Flickered",
            style: GoogleFonts.notoSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Live updates are paused. Refresh to reconnect.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: cs.secondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
