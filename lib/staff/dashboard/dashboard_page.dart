import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/staff_roles.dart';
import '../profile/profile_page.dart';
import '../inventory/inventory_page.dart';
import '../management/staff_management_page.dart';
import '../operations/kitchen_page.dart';
import '../operations/orders_page.dart';
import '../../widgets/staff_sidebar.dart';
import '../../services/supabase_service.dart';

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

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0; 
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isDesktop ? null : IconButton(
          icon: Icon(Icons.menu_rounded, color: cs.primary),
          onPressed: () {
            // Optional: Handle drawer or menu
          },
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
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: cs.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
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
      ),
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
      case 'accepted': return 'Mark Ready';
      case 'ready': return 'Deliver';
      default: return null;
    }
  }

  String? _getNextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'accepted';
      case 'accepted': return 'ready';
      case 'ready': return 'delivered';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String greeting = "Bonjour, Manager";
    switch (role) {
      case StaffRole.chef: greeting = "Bonjour, Chef"; break;
      case StaffRole.support: greeting = "Bonjour, Support"; break;
      case StaffRole.cleaning: greeting = "Bonjour, Hygiene"; break;
      case StaffRole.cashier: greeting = "Bonjour, Cashier"; break;
      case StaffRole.delivery: greeting = "Bonjour, Delivery"; break;
      case StaffRole.manager: greeting = "Bonjour, Manager"; break;
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((o) => (o['status'] ?? '').toLowerCase() != 'delivered').toList();
        final completedOrdersCount = allOrders.length - activeOrders.length;

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
          children: [
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
                Container(height: 1, color: cs.secondary.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool useGrid = constraints.maxWidth < 600;
                if (useGrid) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _MetricCard(icon: Icons.bakery_dining_rounded, value: "${allOrders.length}", label: "TOTAL")),
                          const SizedBox(width: 16),
                          Expanded(child: _MetricCard(icon: Icons.timer_rounded, value: "${activeOrders.length}", label: "ACTIVE")),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MetricCard(icon: Icons.task_alt_rounded, value: "$completedOrdersCount", label: "COMPLETED", fullWidth: true),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _MetricCard(icon: Icons.bakery_dining_rounded, value: "${allOrders.length}", label: "TOTAL ORDERS")),
                    const SizedBox(width: 16),
                    Expanded(child: _MetricCard(icon: Icons.timer_rounded, value: "${activeOrders.length}", label: "ACTIVE")),
                    const SizedBox(width: 16),
                    Expanded(child: _MetricCard(icon: Icons.task_alt_rounded, value: "$completedOrdersCount", label: "DONE")),
                  ],
                );
              }
            ),
            const SizedBox(height: 48),
            _TaskSectionHeader(title: "Current Tasks", color: cs.primary, isPulse: activeOrders.isNotEmpty),
            const SizedBox(height: 16),
            if (activeOrders.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text("All caught up!", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.4))),
              ))
            else
              ...activeOrders.take(5).map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TaskCard(
                  orderNumber: o['orderNumber'] ?? '#---',
                  title: o['customerName'] ?? 'Customer',
                  status: o['status']?.toString().toUpperCase() ?? 'PENDING',
                  onAction: () {
                    final next = _getNextStatus(o['status']?.toString().toLowerCase() ?? '');
                    if (next != null) SupabaseService.updateOrderStatus(o['id'], next);
                  },
                  actionLabel: _getActionLabel(o['status']?.toString().toLowerCase() ?? ''),
                ),
              )),
          ],
        );
      }
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool fullWidth;
  const _MetricCard({required this.icon, required this.value, required this.label, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.notoSerif(fontSize: 24, fontWeight: FontWeight.bold, color: cs.secondary)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: cs.secondary.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final bool isPulse;
  const _TaskSectionHeader({required this.title, this.color, this.isPulse = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.notoSerif(fontSize: 20, color: cs.secondary, fontWeight: FontWeight.bold)),
        if (color != null)
          isPulse ? _PulseIndicator(color: color!) : Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller), child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
  }
}

class _TaskCard extends StatelessWidget {
  final String orderNumber;
  final String title;
  final String status;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TaskCard({required this.orderNumber, required this.title, required this.status, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: GoogleFonts.plusJakartaSans(fontSize: 10, letterSpacing: 1.5, color: cs.secondary.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 10, letterSpacing: 1.5, color: cs.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.notoSerif(fontSize: 18, color: cs.secondary, fontWeight: FontWeight.bold)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(actionLabel!),
              ),
            ),
          ],
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
    final bool hasOps = role == StaffRole.chef || role == StaffRole.manager || role == StaffRole.support || role == StaffRole.cashier || role == StaffRole.cleaning;
    if (hasOps) navItems.add({'icon': currentIndex == navItems.length ? Icons.bakery_dining_rounded : Icons.bakery_dining_outlined, 'label': "Operations"});
    if (role == StaffRole.manager || role == StaffRole.chef) navItems.add({'icon': currentIndex == navItems.length ? Icons.inventory_2_rounded : Icons.inventory_2_outlined, 'label': "Inventory"});
    if (role == StaffRole.manager) navItems.add({'icon': currentIndex == navItems.length ? Icons.people_rounded : Icons.people_outline_rounded, 'label': "Staff"});
    navItems.add({'icon': currentIndex == navItems.length ? Icons.person_rounded : Icons.person_outline_rounded, 'label': "Profile"});

    return Container(
      height: 70,
      decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.primary.withValues(alpha: 0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final bool isActive = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], color: isActive ? cs.primary : cs.secondary.withValues(alpha: 0.5), size: 24),
                  const SizedBox(height: 4),
                  Text(item['label'], style: GoogleFonts.plusJakartaSans(color: isActive ? cs.primary : cs.secondary.withValues(alpha: 0.5), fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
                ],
              ),
            ),
          );
        }),
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
          preferredSize: Size.fromHeight(isDesktop ? 200 : 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ATELIER MANAGEMENT", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 2.0)),
                    const SizedBox(height: 8),
                    Text("Operations", style: GoogleFonts.notoSerif(fontSize: isDesktop ? 48 : 36, color: cs.secondary, height: 1.1)),
                    const SizedBox(height: 24),
                    Container(height: 1, color: cs.secondary.withValues(alpha: 0.3)),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: cs.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelColor: cs.primary,
                unselectedLabelColor: cs.secondary.withValues(alpha: 0.4),
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  if (hasKitchen) const Tab(text: "KITCHEN"),
                  if (hasOrders) const Tab(text: "ORDERS"),
                  if (hasHygiene) const Tab(text: "HYGIENE"),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (hasKitchen) KitchenPage(cs: cs),
            if (hasOrders) OrdersPage(cs: cs),
            if (hasHygiene) _CleaningTasksPage(cs: cs, shift: shift),
          ],
        ),
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
          Text("HYGIENE & MAINTENANCE", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text("Hygiene Standards", style: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.bold, color: cs.secondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text("${shift.toUpperCase()} SHIFT", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 1.5))),
          const SizedBox(height: 32),
          ...tasks.map((task) => _TaskItem(task: task, cs: cs)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: widget.cs.primary.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))], border: isDone ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null),
      child: Row(
        children: [
          Checkbox(value: isDone, onChanged: (v) => setState(() => isDone = v ?? false), activeColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.task, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: isDone ? FontWeight.normal : FontWeight.w600, color: isDone ? widget.cs.secondary.withValues(alpha: 0.5) : widget.cs.secondary, decoration: isDone ? TextDecoration.lineThrough : null))),
          if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
