import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;
  late PageController _pageController;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

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
        centerTitle: !isDesktop,
        title: Text(
          "Sonna's Patisserie & Cafe",
          style: GoogleFonts.notoSerif(
            color: cs.primary,
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: cs.primary),
                onPressed: () {},
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            StaffSidebar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: [
                _DashboardContent(cs: cs, isDesktop: isDesktop),
                const Center(child: Text("Kitchen Page")),
                const Center(child: Text("Orders Page")),
                const Center(child: Text("Profile Page")),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0 && !isDesktop)
        ? FloatingActionButton(
            onPressed: () {},
            backgroundColor: cs.primary,
            shape: const CircleBorder(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, const Color(0xFFFFB6D3)],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          )
        : null,
      bottomNavigationBar: isDesktop 
        ? null 
        : _StaffBottomNav(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ColorScheme cs;
  final bool isDesktop;
  const _DashboardContent({required this.cs, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24, 
        vertical: 32,
      ),
      children: [
        // Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STAFF PORTAL",
              style: GoogleFonts.plusJakartaSans(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Bonjour, Chef",
              style: GoogleFonts.notoSerif(
                fontSize: isDesktop ? 48 : 36,
                color: cs.secondary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 48,
              height: 1,
              color: cs.secondary.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const SizedBox(height: 48),
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _MetricCard(icon: Icons.bakery_dining_rounded, value: "24", label: "TOTAL ORDERS")),
              const SizedBox(width: 24),
              Expanded(child: _MetricCard(icon: Icons.task_alt_rounded, value: "18", label: "COMPLETED")),
              const SizedBox(width: 24),
              Expanded(child: _MetricCard(icon: Icons.timer_rounded, value: "6", label: "PENDING")),
            ],
          )
        else
          _ProductionHeroCard(),
        
        const SizedBox(height: 48),

        // Urgent Tasks
        _TaskSectionHeader(title: "Urgent Tasks", color: const Color(0xFFBA1A1A), isPulse: true),
        const SizedBox(height: 16),
        _TaskCard(
          orderNumber: "#ORD-9012",
          title: "Wild Berry Chantilly",
          status: "Due 5:00 PM",
          tag: "High Priority",
          isUrgent: true,
          tagColor: const Color(0xFFFFDAD6),
          tagTextColor: const Color(0xFF93000A),
        ),
        const SizedBox(height: 16),
        _TaskCard(
          orderNumber: "#ORD-9015",
          title: "Dark Chocolate Truffle",
          status: "ASAP",
          tag: "Decorating",
          isUrgent: true,
          tagColor: const Color(0xFFFFDAD6),
          tagTextColor: const Color(0xFF93000A),
        ),
        const SizedBox(height: 40),

        // In Progress
        _TaskSectionHeader(title: "In Progress", color: const Color(0xFFF48FB1)),
        const SizedBox(height: 16),
        _TaskCard(
          orderNumber: "#ORD-8992",
          title: "Lemon Lavender Tart",
          status: "In Oven",
          tag: "Classic Collection",
          tagColor: const Color(0xFFFFDCC6),
          tagTextColor: const Color(0xFF784C2B),
        ),
        const SizedBox(height: 16),
        _TaskCard(
          orderNumber: "#ORD-8995",
          title: "Pistachio Rose Cake",
          status: "Chilling",
          tag: "Wedding Order",
          tagColor: const Color(0xFFFFDCC6),
          tagTextColor: const Color(0xFF784C2B),
        ),
        const SizedBox(height: 40),

        // Completed
        _TaskSectionHeader(title: "Completed Today", isCompleted: true),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.6,
          child: Column(
            children: [
              _CompletedCard(orderNumber: "#ORD-8881", title: "Matcha Opera Cake"),
              const SizedBox(height: 16),
              _CompletedCard(orderNumber: "#ORD-8875", title: "Classic Tiramisu"),
            ],
          ),
        ),
        const SizedBox(height: 100), // Space for bottom nav
      ],
    );
  }
}

class _ProductionHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.bakery_dining_rounded, size: 120, color: cs.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Production",
                  style: GoogleFonts.notoSerif(
                    color: cs.secondary,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "24",
                      style: GoogleFonts.notoSerif(
                        color: cs.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TOTAL ORDERS",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.secondary.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final bool isPulse;
  final bool isCompleted;

  const _TaskSectionHeader({
    required this.title,
    this.color,
    this.isPulse = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            color: isCompleted ? cs.secondary.withValues(alpha: 0.6) : cs.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
        else if (color != null)
          isPulse ? _PulseIndicator(color: color!) : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String orderNumber;
  final String title;
  final String status;
  final String tag;
  final bool isUrgent;
  final Color tagColor;
  final Color tagTextColor;

  const _TaskCard({
    required this.orderNumber,
    required this.title,
    required this.status,
    required this.tag,
    this.isUrgent = false,
    required this.tagColor,
    required this.tagTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isUrgent)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: const Color(0xFFBA1A1A)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderNumber,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: cs.secondary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: isUrgent ? cs.error : cs.secondary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        fontStyle: isUrgent ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    color: cs.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: tagTextColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final String orderNumber;
  final String title;

  const _CompletedCard({required this.orderNumber, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: cs.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  color: cs.secondary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: cs.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "READY",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StaffBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.primary.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
            icon: currentIndex == 0 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
            label: "Dashboard",
          ),
          _NavItem(
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
            icon: currentIndex == 1 ? Icons.bakery_dining_rounded : Icons.bakery_dining_outlined,
            label: "Kitchen",
          ),
          _NavItem(
            index: 2,
            currentIndex: currentIndex,
            onTap: onTap,
            icon: currentIndex == 2 ? Icons.assignment_rounded : Icons.assignment_outlined,
            label: "Orders",
          ),
          _NavItem(
            index: 3,
            currentIndex: currentIndex,
            onTap: onTap,
            icon: currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData icon;
  final String label;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isActive = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? cs.primary : cs.secondary.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? cs.primary : cs.secondary.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.notoSerif(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: cs.secondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
