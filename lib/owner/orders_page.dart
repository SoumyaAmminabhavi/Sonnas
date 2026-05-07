import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'order_details_page.dart';
import '../services/supabase_service.dart';
import '../widgets/skeleton.dart';

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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: cs.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Active Orders",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary,
                      letterSpacing: -0.5,
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
                  _OrdersList(cs: cs, onTabChanged: widget.onTabChanged, filter: _OrderFilter.today),
                  _AllOrdersFilterView(cs: cs, onTabChanged: widget.onTabChanged),
                  _OrdersList(cs: cs, onTabChanged: widget.onTabChanged, filter: _OrderFilter.completed),
                  _OrdersList(cs: cs, onTabChanged: widget.onTabChanged, filter: _OrderFilter.custom),
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

  final String? statusFilter;

  const _OrdersList({
    required this.cs,
    required this.filter,
    this.onTabChanged,
    this.statusFilter,
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
      stream: SupabaseService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonWrapper(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Skeleton(height: 50, width: 50, borderRadius: 12),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Skeleton(height: 14, width: 140),
                          const SizedBox(height: 8),
                          const Skeleton(height: 10, width: 90),
                        ],
                      ),
                    ),
                    const Skeleton(height: 24, width: 70, borderRadius: 12),
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ManageOrdersPage(onTabChanged: onTabChanged)),
              );
            },
          );
        }

        List<Map<String, dynamic>> rawOrders = snapshot.data ?? [];

        // Apply filtering logic
        final now = DateTime.now();
        rawOrders = rawOrders.where((order) {
          final isCustom = order['isCustom'] == true;
          final status = order['status'] ?? 'PENDING';
          final createdAtStr = order['createdAt'];
          
          DateTime? createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

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
              if (statusFilter != null && statusFilter != 'ALL') {
                return status == statusFilter;
              }
              return true;
          }
        }).toList();

        if (rawOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_outlined, color: cs.primary.withValues(alpha: 0.1), size: 64),
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

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: SupabaseService.fetchMenu(), // Fetch menu for image lookups
          builder: (context, menuSnapshot) {
            final orders = rawOrders.map((data) {
              final status = data['status'] ?? 'PENDING';
              Color statusBg = cs.primaryContainer;
              Color statusFg = cs.primary;

              if (status == 'COMPLETED') {
                statusBg = cs.secondaryContainer;
                statusFg = cs.secondary;
              }

              return _OrderTile(
                data: data,
                menu: menuSnapshot.data ?? [],
                cs: cs,
                statusBg: statusBg,
                statusFg: statusFg,
                onTabChanged: onTabChanged,
              );
            }).toList();

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => orders[index],
            );
          },
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> menu;
  final ColorScheme cs;
  final Color statusBg;
  final Color statusFg;
  final ValueChanged<int>? onTabChanged;

  const _OrderTile({
    required this.data,
    required this.menu,
    required this.cs,
    required this.statusBg,
    required this.statusFg,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchOrderItems(data['id']),
      builder: (context, itemSnapshot) {
        final items = itemSnapshot.data ?? [];

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

        final String orderId = "#${data['orderNumber'] ?? '---'}";
        final String customerName = data['customerName'] ?? 'Boutique Order';
        final String status = data['status'] ?? 'PENDING';
        final String price = data['totalPrice'] != null
            ? SupabaseService.formatPrice(data['totalPrice'])
            : (items.isNotEmpty
                  ? SupabaseService.formatPrice(items[0]['price'])
                  : '---');
        final String rawDate = data['deliveryDate'] ?? '';
        String dateStr = 'Not scheduled';
        if (rawDate.isNotEmpty) {
          final dt = DateTime.tryParse(rawDate);
          if (dt != null) {
            dateStr = DateFormat('dd MMM yyyy').format(dt);
          } else {
            dateStr = rawDate; // Fallback to raw if parsing fails
          }
        }
        
        final String? timeStr = data['deliveryTime'];
        final String schedule = timeStr != null ? "$dateStr at $timeStr" : dateStr;


        String orderSubtitle = 'Custom Creation';
        if (items.isNotEmpty) {
          final String firstName = items[0]['cakeName'] ?? 'Boutique Order';
          orderSubtitle = items.length > 1 ? "$firstName + ${items.length - 1} more" : firstName;
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerOrderDetailsView(
                  orderId: orderId,
                  onTabChanged: onTabChanged,
                ),
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
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Builder(
                      builder: (context) {
                        final url = SupabaseService.getPublicUrl(imageUrl);
                        if (url.isEmpty) return _ImagePlaceholder(cs: cs);
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: cs.secondaryContainer.withValues(
                                alpha: 0.1,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _ImagePlaceholder(cs: cs),
                        );
                      },
                    ),
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
                          Flexible(
                            child: Text(
                              orderId,
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
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.plusJakartaSans(
                                color: statusFg,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
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
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _IconInfoRow(
                        icon: Icons.cake_outlined,
                        text: orderSubtitle,
                        cs: cs,
                      ),
                      const SizedBox(height: 4),
                      _IconInfoRow(
                        icon: Icons.payments_outlined,
                        text: price,
                        cs: cs,
                      ),
                      const SizedBox(height: 4),
                      _IconInfoRow(
                        icon: Icons.schedule_outlined,
                        text: schedule,
                        cs: cs,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: cs.secondary.withValues(alpha: 0.2),
                ),
              ],
            ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: cs.primary.withValues(alpha: 0.5),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Interrupted",
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "The atelier's live pulse was briefly interrupted. Let's try to reconnect your view.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: cs.secondary.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text("RECONNECT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "DEBUG INFO: ${error.length > 60 ? '${error.substring(0, 60)}...' : error}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: cs.secondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ImagePlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.cake_outlined,
          color: cs.primary.withValues(alpha: 0.3),
          size: 32,
        ),
      ),
    );
  }
}

class _IconInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;

  const _IconInfoRow({
    required this.icon,
    required this.text,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: cs.secondary.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: cs.secondary.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
class _AllOrdersFilterView extends StatefulWidget {
  final ColorScheme cs;
  final ValueChanged<int>? onTabChanged;

  const _AllOrdersFilterView({required this.cs, this.onTabChanged});

  @override
  State<_AllOrdersFilterView> createState() => _AllOrdersFilterViewState();
}

class _AllOrdersFilterViewState extends State<_AllOrdersFilterView> {
  String _selectedStatus = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text(
                "FILTER BY STATUS",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: widget.cs.secondary.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.cs.secondary.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    icon: Icon(Icons.keyboard_arrow_down, size: 16, color: widget.cs.primary),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.cs.secondary,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                    items: <String>['ALL', 'PENDING', 'CONFIRMED', 'SHIPPED', 'CANCELLED']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _OrdersList(
            cs: widget.cs,
            onTabChanged: widget.onTabChanged,
            filter: _OrderFilter.all,
            statusFilter: _selectedStatus,
          ),
        ),
      ],
    );
  }
}
