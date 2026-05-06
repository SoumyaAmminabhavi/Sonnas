import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';
import 'staff_roles.dart';
import 'profile_page.dart';
import 'inventory_page.dart';
import 'manage_staff_page.dart';
import '../services/supabase_service.dart';

class StaffDashboard extends StatefulWidget {
  final StaffRole role;
  final Map<String, dynamic>? staffData;
  const StaffDashboard({super.key, this.role = StaffRole.manager, this.staffData});

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
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    final List<Widget> pages = [
      _DashboardContent(cs: cs, isDesktop: isDesktop, role: widget.role),
    ];

    // Operations Tab (Combines Kitchen, Orders, Hygiene)
    final bool hasKitchen = widget.role == StaffRole.chef || widget.role == StaffRole.manager;
    final bool hasOrders = widget.role == StaffRole.support || widget.role == StaffRole.cashier || widget.role == StaffRole.manager;
    final bool hasHygiene = widget.role == StaffRole.cleaning || widget.role == StaffRole.manager;

    if (hasKitchen || hasOrders || hasHygiene) {
      pages.add(_OperationsCombinedPage(
        cs: cs,
        isDesktop: isDesktop,
        role: widget.role,
        shift: widget.staffData?['shift'] ?? 'MORNING',
        hasKitchen: hasKitchen,
        hasOrders: hasOrders,
        hasHygiene: hasHygiene,
      ));
    }

    if (widget.role == StaffRole.manager || widget.role == StaffRole.chef) {
      pages.add(StaffInventoryPage(cs: cs, isDesktop: isDesktop));
    }

    if (widget.role == StaffRole.manager) {
      pages.add(ManageStaffPage(cs: cs, isDesktop: isDesktop));
    }

    pages.add(
      StaffProfilePage(
        cs: cs, 
        isDesktop: isDesktop, 
        role: widget.role,
        staffId: widget.staffData?['id'] ?? 'unknown',
        currentBiometricStatus: widget.staffData?['biometricEnabled'] ?? false,
        staffData: widget.staffData,
      ),
    );

    // Ensure _selectedIndex doesn't exceed bounds if role changes
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0; 
    }

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
        actions: const [
          SizedBox(width: 24),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            StaffSidebar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              role: widget.role,
            ),
          Expanded(
            child: isDesktop
                ? IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  )
                : PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    children: pages,
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
            role: widget.role,
          ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ColorScheme cs;
  final bool isDesktop;
  final StaffRole role;
  const _DashboardContent({required this.cs, required this.isDesktop, required this.role});

  String? _getActionLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Start Prep';
      case 'prep': return 'To Oven';
      case 'baking': return 'To Decorating';
      case 'decorating': return 'Mark Ready';
      case 'ready': return 'Dispatch';
      case 'dispatched': return 'Delivered';
      default: return null;
    }
  }

  String? _getNextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'prep';
      case 'prep': return 'baking';
      case 'baking': return 'decorating';
      case 'decorating': return 'ready';
      case 'ready': return 'dispatched';
      case 'dispatched': return 'delivered';
      default: return null;
    }
  }

  bool _canAction(String status) {
    final lower = status.toLowerCase();
    if (role == StaffRole.manager) return true;
    if (role == StaffRole.chef) {
      return ['pending', 'prep', 'baking', 'decorating'].contains(lower);
    }
    if (role == StaffRole.delivery) {
      return ['ready', 'dispatched'].contains(lower);
    }
    if (role == StaffRole.cashier) {
      return lower == 'ready'; // Cashier hands over pickup orders
    }
    return false;
  }

  bool _shouldSeeOrder(String status) {
    final lower = status.toLowerCase();
    if (role == StaffRole.manager) return true; // Manager sees all
    if (role == StaffRole.chef) {
      return ['pending', 'prep', 'baking', 'decorating'].contains(lower);
    }
    if (role == StaffRole.delivery) {
      return ['ready', 'dispatched', 'delivered'].contains(lower);
    }
    if (role == StaffRole.cashier) {
      return true; // Cashier might need to see all to answer customer queries
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    String greeting;
    switch (role) {
      case StaffRole.chef: greeting = "Bonjour, Chef"; break;
      case StaffRole.support: greeting = "Bonjour, Support"; break;
      case StaffRole.cleaning: greeting = "Bonjour, Hygiene Specialist"; break;
      case StaffRole.cashier: greeting = "Bonjour, Cashier"; break;
      case StaffRole.delivery: greeting = "Bonjour, Delivery"; break;
      case StaffRole.manager: greeting = "Bonjour, Manager"; break;
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data ?? [];
        
        // Filter orders by role visibility
        final visibleOrders = allOrders.where((o) => _shouldSeeOrder(o['status'] ?? 'pending')).toList();
        
        final completedOrders = visibleOrders.where((o) => (o['status'] ?? '').toLowerCase() == 'delivered').toList();
        final activeOrders = visibleOrders.where((o) => (o['status'] ?? '').toLowerCase() != 'delivered').toList();
        final urgentOrders = activeOrders.where((o) => (o['status'] ?? '').toLowerCase() == 'pending').toList(); // Simplified urgency
        final inProgressOrders = activeOrders.where((o) => !urgentOrders.contains(o)).toList();

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
                  greeting,
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

            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _MetricCard(icon: Icons.bakery_dining_rounded, value: "${allOrders.length}", label: "TOTAL ORDERS")),
                  const SizedBox(width: 24),
                  Expanded(child: _MetricCard(icon: Icons.task_alt_rounded, value: "${completedOrders.length}", label: "COMPLETED")),
                  const SizedBox(width: 24),
                  Expanded(child: _MetricCard(icon: Icons.timer_rounded, value: "${activeOrders.length}", label: "ACTIVE")),
                ],
              )
            else
              _ProductionHeroCard(),
            
            const SizedBox(height: 48),

            // Urgent Tasks
            if (urgentOrders.isNotEmpty) ...[
              _TaskSectionHeader(title: "Needs Attention", color: const Color(0xFFBA1A1A), isPulse: true),
              const SizedBox(height: 16),
              ...urgentOrders.map((o) {
                final status = o['status'] ?? 'pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TaskCard(
                    orderNumber: o['orderNumber'] ?? '#---',
                    title: o['customerName'] ?? 'Walk-in Customer',
                    status: status.toUpperCase(),
                    tag: "Priority",
                    isUrgent: true,
                    tagColor: const Color(0xFFFFDAD6),
                    tagTextColor: const Color(0xFF93000A),
                    actionLabel: _canAction(status) ? _getActionLabel(status) : null,
                    onAction: () {
                      final next = _getNextStatus(status);
                      if (next != null) SupabaseService.updateOrderStatus(o['id'], next);
                    },
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],

            // In Progress
            if (inProgressOrders.isNotEmpty) ...[
              _TaskSectionHeader(title: "In Progress", color: const Color(0xFFF48FB1)),
              const SizedBox(height: 16),
              ...inProgressOrders.map((o) {
                final status = o['status'] ?? 'pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TaskCard(
                    orderNumber: o['orderNumber'] ?? '#---',
                    title: o['customerName'] ?? 'Customer',
                    status: status.toUpperCase(),
                    tag: status.toUpperCase(),
                    tagColor: const Color(0xFFFFDCC6),
                    tagTextColor: const Color(0xFF784C2B),
                    actionLabel: _canAction(status) ? _getActionLabel(status) : null,
                    onAction: () {
                      final next = _getNextStatus(status);
                      if (next != null) SupabaseService.updateOrderStatus(o['id'], next);
                    },
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],

            // Completed
            if (completedOrders.isNotEmpty) ...[
              _TaskSectionHeader(title: "Completed", isCompleted: true),
              const SizedBox(height: 16),
              Opacity(
                opacity: 0.6,
                child: Column(
                  children: completedOrders.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CompletedCard(
                      orderNumber: o['orderNumber'] ?? '#---', 
                      title: o['customerName'] ?? 'Customer'
                    ),
                  )).toList(),
                ),
              ),
            ],
            const SizedBox(height: 100), // Space for bottom nav
          ],
        );
      }
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
        color: Colors.white,
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TaskCard({
    required this.orderNumber,
    required this.title,
    required this.status,
    required this.tag,
    this.isUrgent = false,
    required this.tagColor,
    required this.tagTextColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    if (actionLabel != null && onAction != null)
                      GestureDetector(
                        onTap: onAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            actionLabel!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
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
  final StaffRole role;

  const _StaffBottomNav({required this.currentIndex, required this.onTap, required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final List<Map<String, dynamic>> navItems = [
      {'icon': currentIndex == 0 ? Icons.grid_view_rounded : Icons.grid_view_outlined, 'label': "Dashboard"},
    ];

    final bool hasKitchen = role == StaffRole.chef || role == StaffRole.manager;
    final bool hasOrders = role == StaffRole.support || role == StaffRole.cashier || role == StaffRole.manager;
    final bool hasHygiene = role == StaffRole.cleaning || role == StaffRole.manager;

    if (hasKitchen || hasOrders || hasHygiene) {
      navItems.add({
        'icon': currentIndex == navItems.length ? Icons.bakery_dining_rounded : Icons.bakery_dining_outlined, 
        'label': "Operations"
      });
    }

    if (role == StaffRole.manager || role == StaffRole.chef) {
      navItems.add({'icon': currentIndex == navItems.length ? Icons.inventory_2_rounded : Icons.inventory_2_outlined, 'label': "Inventory"});
    }

    if (role == StaffRole.manager) {
      navItems.add({'icon': currentIndex == navItems.length ? Icons.people_rounded : Icons.people_outline_rounded, 'label': "Staff"});
    }

    navItems.add({'icon': currentIndex == navItems.length ? Icons.person_rounded : Icons.person_outline_rounded, 'label': "Profile"});

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
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          return _NavItem(
            index: index,
            currentIndex: currentIndex,
            onTap: onTap,
            icon: item['icon'],
            label: item['label'],
          );
        }),
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

class _CleaningTasksPage extends StatelessWidget {
  final ColorScheme cs;
  final String shift;
  const _CleaningTasksPage({required this.cs, required this.shift});

  @override
  Widget build(BuildContext context) {
    final bool isMorning = shift.toUpperCase() == 'MORNING';
    final List<String> tasks = isMorning 
      ? ["Floor Sanitization", "Utensil Sterilization", "Ingredient Organization", "Oven Surface Cleaning"]
      : ["Kitchen Closing Sweep", "Waste Disposal", "Deep Utensil Scrub", "Cold Storage Check"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HYGIENE & MAINTENANCE",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Hygiene Standards",
            style: GoogleFonts.notoSerif(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${shift.toUpperCase()} SHIFT",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...tasks.map((task) => _TaskItem(task: task, cs: cs)),
          const SizedBox(height: 48),
          _buildCompletionCard(),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, const Color(0xFFFFB6D3)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            "SHIFT COMPLETION",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Submit your shift tasks for review by the manager.",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("SUBMIT REPORT"),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatefulWidget {
  final String task;
  final ColorScheme cs;
  const _TaskItem({required this.task, required this.cs});

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
  bool isDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.cs.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: isDone ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            onChanged: (v) => setState(() => isDone = v ?? false),
            activeColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.task,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                color: isDone ? widget.cs.secondary.withValues(alpha: 0.5) : widget.cs.secondary,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}

class _OperationsCombinedPage extends StatelessWidget {
  final ColorScheme cs;
  final bool isDesktop;
  final StaffRole role;
  final String shift;
  final bool hasKitchen;
  final bool hasOrders;
  final bool hasHygiene;

  const _OperationsCombinedPage({
    required this.cs,
    required this.isDesktop,
    required this.role,
    required this.shift,
    required this.hasKitchen,
    required this.hasOrders,
    required this.hasHygiene,
  });

  @override
  Widget build(BuildContext context) {
    int tabCount = 0;
    if (hasKitchen) tabCount++;
    if (hasOrders) tabCount++;
    if (hasHygiene) tabCount++;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: cs.primary,
              labelColor: cs.primary,
              unselectedLabelColor: cs.secondary.withValues(alpha: 0.5),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                letterSpacing: 1.2,
              ),
              tabs: [
                if (hasKitchen) const Tab(text: "KITCHEN"),
                if (hasOrders) const Tab(text: "ORDERS"),
                if (hasHygiene) const Tab(text: "HYGIENE"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            if (hasKitchen) const Center(child: Text("Kitchen Tasks (Coming Soon)")),
            if (hasOrders) const Center(child: Text("Live Orders (Coming Soon)")),
            if (hasHygiene) _CleaningTasksPage(cs: cs, shift: shift),
          ],
        ),
      ),
    );
  }
}
