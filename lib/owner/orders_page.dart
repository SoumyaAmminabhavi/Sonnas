import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_details_page.dart';
import '../services/supabase_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                  Tab(text: "UPCOMING"),
                  Tab(text: "COMPLETED"),
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
                  _OrdersList(cs: cs, onTabChanged: widget.onTabChanged),
                  const Center(child: Text("Upcoming Orders")),
                  const Center(child: Text("Completed Orders")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final ColorScheme cs;
  final ValueChanged<int>? onTabChanged;
  const _OrdersList({required this.cs, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        final List<Map<String, dynamic>> rawOrders = snapshot.data ?? [];

        if (rawOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_outlined, color: cs.primary.withValues(alpha: 0.1), size: 64),
                const SizedBox(height: 24),
                Text(
                  "A Quiet Moment",
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "There are no active orders currently gracing the atelier.",
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
        final String time = data['deliveryDate'] ?? 'Not scheduled';

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
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: cs.secondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: cs.secondary.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: cs.secondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: cs.secondary.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
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
