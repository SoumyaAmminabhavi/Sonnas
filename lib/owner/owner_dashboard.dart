import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_page.dart';
import 'owner_settings.dart';
import 'orders_page.dart';
import 'payments_page.dart';
import 'package:fl_chart/fl_chart.dart';

// Brand Colors - Sweet Pink Bakery Theme
const Color _bgColor = Color(0xFFFFF0F6); // Ultra pale pink
const Color _primaryColor = Color(0xFFFF4D8D); // Vibrant pink
const Color _primaryContainer = Color(0xFFFFB6D3); // Pastel pink accent
const Color _secondaryColor = Color(0xFF701235); // Deep berry for text/contrast
const Color _surfaceLow = Color(0xFFFFF5F9); // Lighter surface
const Color _errorColor = Color(0xFFE91E63);
const Color _errorContainer = Color(0xFFF8BBD0);

// Images
const _profileUrl =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDDQvYGvn7S_J3DgscTQ2hNnlLJRhww-9vSDS-Wt5d8khGCywY2mEyOlidW86WQ0V1-AhQh2KWO60drIVHQJrfu3ZZJsuR_E8nsZl3mX6iruFwf9hK3oksVyq298bTGjeXEx8IDZExP5eyrE_JD3gnXSeAn_-OlWPTcgIxt2-_1AxMAYzTIfh8rIJHZXRYfbobtQI-IAL_PTkx9ufPCiigfWZlzIDGwO6FEA9kitgjTQc_lkka6tk007AMES6uXmk5vnYroLLKQz--4";
const _imgOrder1 =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuByamhClb3gDhF3nngRFpLvkbtTTHarLWuqt4-agAtERKXjlvCqO0UX3yoFz8JcqTxXexzX6nYk_VgLcK0PhyPJcetaMu0wIt5XswIYgIbUVmdoLWucs7HsL6WEwnGYbjBT8Dju38uIOlCwkRSaksxz6v2pSSi1xjhD_tiuMHQWhwmm3o8mBSZGVB41NEqCjepzdUc_TgIx4FsF49JV6XFveVlL76uJKML55RWk6tpcySzc2TFE1MfrNg1sUXJ6BKv69tr904uK6oSO";
const _imgOrder2 =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBgLiZjc9axvI-eFs8vO1zzxXSfph_zKSHA9tUul1gcWpf1QEOdqEipFJuCWmE0P8H9Mq_9T6s6P2dAUoW4WGiI94z-4QrxdHl7AYmzfzGCy5GOgFQAo4TmUwJnSFPSTtkV8bBW20fV0MurGRSB4jnPK111Qxuv2yiTQ2CIfFHGRGyXA1CZbUmlIs-v6A3RHMYNqdsl0PoOJJxyZ_lFRObqOKAnKPqc_4mCp1DvHn01byvns9Mc3JHBquVh_j04E5LWBNRgrLU-tRzQ";
const _imgOrder3 =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCMggGL41lwe2i4Hoo75nPIBRKP9jNB-bpez1o15acouqD2kq9Xm2CMIC6RB-60FX1h5PUQijYrbv-QmjuvsF3lDd6U_RGEVfyriZZf28EktoAbAXV2gWj-r18jED5in5g8-4eXkBRTQ3p2wNkJ7zBsFW8BKvplp4rqngBkQvOcpFG8P9d92TuJRDGyFEBMaE1DFDT5ml-S7Os54bLBx8eVzGpeSDdAI0CRqWbjmGtA4TAJshbLFBBdabnvBVoFkbJlrlccy-WgIuv-";
const _imgOrder4 =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDGwlEwOUwOfvwwQYEI5N9MyD17EsoHebe0bo_ito0-cXuFY8odZg1uyWA-bpYULaxCXVb80y5fRsfUby-NaopwuLqXGs3Px7imIUA_AKJvqfZl6T6f-aZiYROl1_aPAOKt73Msdakj8PV84o8TMZ6Am7lwqTViaBG0ea75y0znTDi5-I4dRwFHp88lf1cE16C8jxp0ISgJMnZtAPjFf3z31n-Cb_fGxq-1iLfIB_Vywk7VDDLQoChnHEXjIUHzNwVnust_mYR_Uqp2";

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor.withOpacity(0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _primaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Sonna's Patisserie & Cafe",
              style: GoogleFonts.notoSerif(
                color: const Color.fromARGB(255, 146, 6, 53),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              if (isDesktop) ...[
                const _TopNavText(text: "DASHBOARD", isSelected: true),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 3),
                  child: const _TopNavText(text: "MENU"),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: const _TopNavText(text: "SETTINGS"),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryContainer, width: 2),
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
          floatingActionButton: _selectedIndex == 3
              ? FloatingActionButton(
                  backgroundColor: _primaryColor,
                  onPressed: () {
                    // Save menu item
                  },
                  elevation: 8,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                )
              : null,
          body: Row(
            children: [
              if (isDesktop)
                _Sidebar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              Expanded(
                child: _selectedIndex == 1
                    ? const ManageOrdersPage()
                    : _selectedIndex == 2
                    ? const PaymentsPage()
                    : _selectedIndex == 3
                    ? const MenuPage()
                    : _selectedIndex == 4
                    ? const OwnerSettingsPage()
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

  const _TopNavText({required this.text, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected
                ? _primaryColor
                : _secondaryColor.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white, // Pure white sidebar for contrast
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_primaryColor, _primaryContainer],
                  )
                : null,
            color: !isSelected ? Colors.transparent : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : _secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : _secondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: _bgColor.withOpacity(0.95),
      selectedItemColor: _primaryColor,
      unselectedItemColor: _secondaryColor.withOpacity(0.6),
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
    return Container(
      color: _bgColor, // Explicitly use the pink background for content
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
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Hello, Sonna.",
          style: GoogleFonts.notoSerif(
            color: _secondaryColor,
            fontSize: isDesktop ? 48 : 36,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 48,
          height: 1,
          color: _secondaryColor.withOpacity(0.3),
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
                    color: _secondaryColor,
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Latest activity from the boutique",
                  style: GoogleFonts.plusJakartaSans(
                    color: _secondaryColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onViewAllOrders,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _primaryContainer, width: 2),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "View All Archives",
                  style: GoogleFonts.notoSerif(
                    color: _primaryColor,
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
                statusColor: _primaryColor,
                statusBg: _surfaceLow,
                title: "Belgian Dark Chocolate Cake",
                customer: "Customer: Mrs. Deshpande",
                imageUrl: _imgOrder1,
              ),
              _OrderCard(
                id: "#ORD-8822",
                status: "PENDING PICKUP",
                statusColor: _secondaryColor,
                statusBg: const Color(0xFFFDBF97).withOpacity(0.2),
                title: "Wild Strawberry Cake",
                customer: "Customer: Mr. Kulkarni",
                imageUrl: _imgOrder2,
              ),
              _OrderCard(
                id: "#ORD-8823",
                status: "IN PREPARATION",
                statusColor: _primaryColor,
                statusBg: _surfaceLow,
                title: "Signature Macaron Box (24)",
                customer: "Customer: Ms. Patil",
                imageUrl: _imgOrder3,
              ),
              _OrderCard(
                id: "#ORD-8824",
                status: "CONFIRMED",
                statusColor: _primaryColor,
                statusBg: _primaryColor.withOpacity(0.1),
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
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withOpacity(0.04),
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
                      color: _secondaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Revenue trend for the past week",
                    style: GoogleFonts.plusJakartaSans(
                      color: _secondaryColor.withOpacity(0.5),
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
                  color: _primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "WEEKLY",
                  style: GoogleFonts.plusJakartaSans(
                    color: _primaryColor,
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
                      color: _secondaryColor.withOpacity(0.05),
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
                                color: _secondaryColor.withOpacity(0.4),
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
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _primaryContainer],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: _primaryColor,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withOpacity(0.2),
                          _primaryColor.withOpacity(0.0),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        id,
                        style: GoogleFonts.plusJakartaSans(
                          color: _secondaryColor.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    color: _secondaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer,
                  style: GoogleFonts.plusJakartaSans(
                    color: _secondaryColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.chevron_right, color: _secondaryColor.withOpacity(0.3)),
        ],
      ),
    );
  }
}
