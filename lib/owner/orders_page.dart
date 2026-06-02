import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../widgets/skeleton.dart';
import 'widgets/order_card.dart';

class ManageOrdersPage extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  const ManageOrdersPage({super.key, this.onTabChanged});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ATELIER MANAGEMENT",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: cs.primary,
                indicatorWeight: 2,
                labelColor: cs.primary,
                unselectedLabelColor: cs.secondary.withValues(alpha: 0.4),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "TODAY"),
                  Tab(text: "ORDERS"),
                  Tab(text: "COMPLETED"),
                  Tab(text: "CUSTOM"),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: cs.secondary.withValues(alpha: 0.1),
              indent: 24,
              endIndent: 24,
            ),

            // Orders List/Grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(
                    cs: cs,
                    onTabChanged: widget.onTabChanged,
                    filter: _OrderFilter.today,
                  ),
                  _OrdersList(
                    cs: cs,
                    onTabChanged: widget.onTabChanged,
                    filter: _OrderFilter.all,
                  ),
                  _OrdersList(
                    cs: cs,
                    onTabChanged: widget.onTabChanged,
                    filter: _OrderFilter.completed,
                  ),
                  _OrdersList(
                    cs: cs,
                    onTabChanged: widget.onTabChanged,
                    filter: _OrderFilter.custom,
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

enum _OrderFilter { today, all, completed, custom }

class _OrdersList extends StatelessWidget {
  final ColorScheme cs;
  final ValueChanged<int>? onTabChanged;
  final _OrderFilter filter;

  const _OrdersList({
    required this.cs,
    required this.filter,
    this.onTabChanged,
  });

  String _getEmptyStateMessage(_OrderFilter filter) {
    switch (filter) {
      case _OrderFilter.custom:
        return "No bespoke creations are currently in the atelier's care.";
      case _OrderFilter.completed:
        return "The archives are quiet. No completed orders to display.";
      case _OrderFilter.all:
        return "The order book is empty for this selection.";
      case _OrderFilter.today:
        return "There are no active orders currently gracing the atelier.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderService.getRecentOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonWrapper(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder:
                  (context, index) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Skeleton(height: 50, width: 50, borderRadius: 12),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(height: 14, width: 140),
                              SizedBox(height: 8),
                              Skeleton(height: 10, width: 90),
                            ],
                          ),
                        ),
                        Skeleton(height: 24, width: 70, borderRadius: 12),
                      ],
                    ),
                  ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ErrorView(
            cs: cs,
            error: snapshot.error.toString(),
            onRetry: () {
              // Trigger a rebuild by popping and pushing or just using a key?
              // For now, providing a graceful UI is the priority.
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute<void>(
                  builder:
                      (context) => ManageOrdersPage(onTabChanged: onTabChanged),
                ),
              );
            },
          );
        }

        List<Map<String, dynamic>> rawOrders = snapshot.data ?? [];

        // Apply filtering logic
        final now = DateTime.now();
        rawOrders =
            rawOrders.where((order) {
              final isCustom = order['isCustom'] == true;
              final status = order['status'] ?? 'PENDING';
              final createdAtStr = order['createdAt'];

              DateTime? createdAt =
                  createdAtStr != null
                      ? DateTime.tryParse(createdAtStr as String)
                      : null;

              switch (filter) {
                case _OrderFilter.custom:
                  return isCustom && status != 'COMPLETED';
                case _OrderFilter.completed:
                  return status == 'COMPLETED';
                case _OrderFilter.today:
                  if (status == 'COMPLETED' || isCustom) return false;
                  if (createdAt == null) return true;
                  return createdAt.year == now.year &&
                      createdAt.month == now.month &&
                      createdAt.day == now.day;
                case _OrderFilter.all:
                  if (isCustom) return false;
                  return true;
              }
            }).toList();

        if (rawOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: cs.primary.withValues(alpha: 0.1),
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  filter == _OrderFilter.custom
                      ? "A Canvas Awaiting Color"
                      : "A Quiet Moment",
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(filter),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: cs.secondary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: rawOrders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder:
              (context, index) => OrderCardReactive(
                data: rawOrders[index],
                onTabChanged: onTabChanged,
              ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ColorScheme cs;
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.cs,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: cs.primary.withValues(alpha: 0.2),
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Interrupted",
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "The atelier's live pulse was briefly interrupted.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: cs.secondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("RECONNECT"),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
