import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/staff_roles.dart';
import '../profile/profile_page.dart';
import '../inventory/inventory_page.dart';
import '../management/staff_management_page.dart';
import '../operations/kitchen_page.dart';
import '../operations/orders_page.dart';
import '../../widgets/staff_sidebar.dart';
import '../../services/order_service.dart';

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
  final GlobalKey<ManageStaffPageState> _staffManagementKey = GlobalKey<ManageStaffPageState>();

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
    if (_selectedIndex == index) {
      // If tapping the same tab, check if it's the staff management tab and reset it
      // We need to find the actual index of the staff management tab
      // For simplicity, we just try to call reset on the key if it exists
      _staffManagementKey.currentState?.reset();
    }

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
      pages.add(ManageStaffPage(key: _staffManagementKey, cs: cs, isDesktop: isDesktop));
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

    final int safeIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

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
                currentIndex: safeIndex,
                onTap: _onItemTapped,
                role: widget.role,
              ),
            Expanded(
              child: isDesktop
                  ? IndexedStack(
                      index: safeIndex,
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
      case 'pending': return 'Confirm Order';
      case 'confirmed': return 'Send Out for Delivery';
      case 'out_for_delivery': return 'Mark Delivered';
      default: return null;
    }
  }

  String? _getNextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'confirmed';
      case 'confirmed': return 'out_for_delivery';
      case 'out_for_delivery': return 'delivered';
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
      stream: OrderService.getRecentOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Dashboard error: ${snapshot.error}\n${snapshot.stackTrace}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Unable to load dashboard data. Please try again.",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allOrders = snapshot.data ?? [];
        
        // --- ROLE BASED FILTERING ---
        final bool isCleaning = role == StaffRole.cleaning;
        
        final activeOrders = isCleaning ? [] : allOrders.where((o) {
          final status = (o['status'] ?? '').toLowerCase();
          return status != 'delivered' &&
                 status != 'completed' &&
                 status != 'cancelled';
        }).toList();

        final completedOrdersCount = allOrders.where((o) {
          final status = (o['status'] ?? '').toLowerCase();
          return status == 'delivered' || status == 'completed';
        }).length;

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
                
                // Hide order metrics for cleaning staff
                if (isCleaning) {
                  return _MetricCard(
                    icon: Icons.cleaning_services_outlined, 
                    value: "Standards", 
                    label: "HYGIENE COMPLIANCE", 
                    fullWidth: true
                  );
                }

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
            _TaskSectionHeader(
              title: isCleaning ? "Hygiene Tasks" : "Current Tasks", 
              color: isCleaning ? Colors.green : cs.primary, 
              isPulse: !isCleaning && activeOrders.isNotEmpty
            ),
            const SizedBox(height: 16),
            if (isCleaning)
              _MetricCard(
                icon: Icons.checklist_rtl_rounded, 
                value: "View All", 
                label: "TAP OPERATIONS FOR CHECKLIST", 
                fullWidth: true
              ),
            if (!isCleaning)
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktopList = constraints.maxWidth > 900;
                if (isDesktopList) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 180,
                    ),
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final o = activeOrders[index];
                      return _TaskCard(
                        orderNumber: o['orderNumber'] ?? '---',
                        title: o['customerName'] ?? 'Customer',
                        status: o['status']?.toString().toUpperCase() ?? 'PENDING',
                        onAction: () async {
                          final next = _getNextStatus(o['status']?.toString().toLowerCase() ?? '');
                          if (next == null) return;
                          try {
                            await OrderService.updateOrderStatus(o['id'], next);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Failed to update order status"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        actionLabel: _getActionLabel(o['status']?.toString().toLowerCase() ?? ''),
                        isGrid: true,
                        cs: cs,
                      );
                    },
                  );
                }
                return Column(
                  children: activeOrders.take(5).map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TaskCard(
                      orderNumber: o['orderNumber'] ?? '---',
                      title: o['customerName'] ?? 'Customer',
                      status: o['status']?.toString().toUpperCase() ?? 'PENDING',
                      onAction: () async {
                        final next = _getNextStatus(o['status']?.toString().toLowerCase() ?? '');
                        if (next == null) return;
                        try {
                          await OrderService.updateOrderStatus(o['id'], next);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to update order status"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      actionLabel: _getActionLabel(o['status']?.toString().toLowerCase() ?? ''),
                      cs: cs,
                    ),
                  )).toList(),
                );
              },
            ),
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
        color: cs.surfaceContainerLow,
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
  final bool isGrid;
  final ColorScheme cs;

  const _TaskCard({
    required this.orderNumber, 
    required this.title, 
    required this.status, 
    this.actionLabel, 
    this.onAction,
    this.isGrid = false,
    required this.cs,
  });

  Widget _buildContent(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              color: cs.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Ticket Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.03),
                border: Border(bottom: BorderSide(color: cs.secondary.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "REF #$orderNumber",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: cs.secondary.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            if (isGrid)
              Expanded(child: _buildContent(cs))
            else
              _buildContent(cs),

            // Standardized Footer
            if (actionLabel != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border(top: BorderSide(color: cs.secondary.withValues(alpha: 0.05))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    child: Text(actionLabel!.toUpperCase()),
                  ),
                ),
              ),
          ],
        ),
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
            if (hasKitchen) const KitchenPage(),
            if (hasOrders) const StaffOrdersPage(),
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
      decoration: BoxDecoration(color: widget.cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: widget.cs.primary.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))], border: isDone ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null),
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
