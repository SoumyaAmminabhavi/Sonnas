import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_page.dart';
import 'owner_settings.dart';
import 'orders_page.dart';
import 'payments_page.dart';
import '../widgets/owner_sidebar.dart';
import 'package:fl_chart/fl_chart.dart';

// Image constants for dashboard
const String _imgOrder1 = "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=200&auto=format&fit=crop";
const String _imgOrder2 = "https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?q=80&w=200&auto=format&fit=crop";
const String _imgOrder3 = "https://images.unsplash.com/photo-1559181567-c3190ca9959b?q=80&w=200&auto=format&fit=crop";
const String _imgOrder4 = "https://images.unsplash.com/photo-1481391243133-f96216dcb5d2?q=80&w=200&auto=format&fit=crop";

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  static const String _profileUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop";

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
            actions: [
              if (isDesktop) ...[
                _TopNavText(text: "DASHBOARD", isSelected: _selectedIndex == 0, cs: cs),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: _TopNavText(text: "MENU", isSelected: _selectedIndex == 3, cs: cs),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: _TopNavText(text: "SETTINGS", isSelected: _selectedIndex == 4, cs: cs),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primaryContainer, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(_profileUrl),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : _MobileBottomNav(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
          floatingActionButton: null,
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              Expanded(
                child: _selectedIndex == 1
                    ? ManageOrdersPage(
                        onTabChanged: (index) =>
                            setState(() => _selectedIndex = index),
                      )
                    : _selectedIndex == 2
                    ? const PaymentsPage()
                    : _selectedIndex == 3
                    ? MenuPage(
                        onTabChanged: (index) =>
                            setState(() => _selectedIndex = index),
                      )
                    : _selectedIndex == 4
                    ? OwnerSettingsPage(
                        onTabChanged: (index) =>
                            setState(() => _selectedIndex = index),
                      )
                    : _MainContent(
                        isDesktop: isDesktop,
                        onViewAllOrders: () =>
                            setState(() => _selectedIndex = 1),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopNavText extends StatelessWidget {
  final String text;
  final bool isSelected;
  final ColorScheme cs;

  const _TopNavText({required this.text, this.isSelected = false, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected
                ? cs.primary
                : cs.secondary.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
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
  final VoidCallback onViewAllOrders;

  const _MainContent({required this.isDesktop, required this.onViewAllOrders});

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
            "OWNER OVERVIEW",
            style: GoogleFonts.plusJakartaSans(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hello, Sonna.",
            style: GoogleFonts.notoSerif(
              color: cs.secondary,
              fontSize: isDesktop ? 48 : 36,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 1,
            color: cs.secondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 48),
          _buildPerformanceChart(context, isDesktop),
          const SizedBox(height: 48),

          // Recent Orders Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
              final isTwoCols = crossAxisCount == 2;

              final orders = [
                _OrderCard(
                  id: "#ORD-8821",
                  status: "IN PREPARATION",
                  statusColor: cs.primary,
                  statusBg: cs.surfaceContainerLow,
                  title: "Belgian Dark Chocolate Cake",
                  customer: "Customer: Mrs. Deshpande",
                  imageUrl: _imgOrder1,
                ),
                _OrderCard(
                  id: "#ORD-8822",
                  status: "PENDING PICKUP",
                  statusColor: cs.secondary,
                  statusBg: const Color(0xFFFDBF97).withValues(alpha: 0.2),
                  title: "Wild Strawberry Cake",
                  customer: "Customer: Mr. Kulkarni",
                  imageUrl: _imgOrder2,
                ),
                _OrderCard(
                  id: "#ORD-8823",
                  status: "IN PREPARATION",
                  statusColor: cs.primary,
                  statusBg: cs.surfaceContainerLow,
                  title: "Signature Macaron Box (24)",
                  customer: "Customer: Ms. Patil",
                  imageUrl: _imgOrder3,
                ),
                _OrderCard(
                  id: "#ORD-8824",
                  status: "CONFIRMED",
                  statusColor: cs.primary,
                  statusBg: cs.primary.withValues(alpha: 0.1),
                  title: "Madagascar Vanilla Bean Mousse",
                  customer: "Customer: Marc Antoine",
                  imageUrl: _imgOrder4,
                ),
              ];

              if (isTwoCols) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: orders[0]),
                        const SizedBox(width: 24),
                        Expanded(child: orders[1]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: orders[2]),
                        const SizedBox(width: 24),
                        Expanded(child: orders[3]),
                      ],
                    ),
                  ],
                );
              } else {
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
              }
            },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sales Performance",
                    style: GoogleFonts.notoSerif(
                      color: cs.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Revenue trend for the past week",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "WEEKLY",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: cs.secondary.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'MON',
                          'TUE',
                          'WED',
                          'THU',
                          'FRI',
                          'SAT',
                          'SUN',
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.plusJakartaSans(
                                color: cs.secondary.withValues(alpha: 0.4),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 25,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 14),
                      FlSpot(2, 12),
                      FlSpot(3, 20),
                      FlSpot(4, 16),
                      FlSpot(5, 22),
                      FlSpot(6, 18),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: cs.surface,
                            strokeWidth: 3,
                            strokeColor: cs.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.2),
                          cs.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String id;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String title;
  final String customer;
  final String imageUrl;

  const _OrderCard({
    required this.id,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.title,
    required this.customer,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.notoSerif(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: cs.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                  customer,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactInfoRow(
                    icon: Icons.cake_outlined, text: title, color: cs.secondary),
                const SizedBox(height: 2),
                _CompactInfoRow(
                    icon: Icons.schedule_outlined,
                    text: "Pickup at 2:30 PM",
                    color: cs.secondary),
              ],
            ),
          ),

          // Action
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.more_vert,
                    color: cs.secondary.withValues(alpha: 0.3)),
                onPressed: () {},
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.edit_note, size: 18, color: Colors.white),
              ),
            ],
          ),
        ],
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
