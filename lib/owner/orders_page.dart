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

class _ManageOrdersPageState extends State<ManageOrdersPage> with SingleTickerProviderStateMixin {
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
            Divider(height: 1, thickness: 0.5, color: cs.secondary.withValues(alpha: 0.1), indent: 24, endIndent: 24),

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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final List<Map<String, dynamic>> rawOrders = snapshot.data ?? [];
        
        if (rawOrders.isEmpty) {
          return const Center(child: Text("No active orders found."));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: SupabaseService.fetchMenu(), // Fetch menu for image lookups
          builder: (context, menuSnapshot) {
            final menu = menuSnapshot.data ?? [];
            
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
  final ColorScheme cs;
  final Color statusBg;
  final Color statusFg;
  final ValueChanged<int>? onTabChanged;

  const _OrderTile({
    required this.data,
    required this.cs,
    required this.statusBg,
    required this.statusFg,
    this.onTabChanged,
  });

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
        
        String imageUrl = data['customImageUrl'] ?? '';
        if (imageUrl.isEmpty || imageUrl.startsWith('whatsapp://')) {
          if (items.isNotEmpty) {
            final String firstName = items[0]['cakeName'] ?? '';
            final matchingCake = menu.firstWhere(
              (c) => (c['name'] as String).toLowerCase() == firstName.toLowerCase(),
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
            : (items.isNotEmpty ? SupabaseService.formatPrice(items[0]['price']) : '---');
        final String time = data['deliveryDate'] ?? 'Not scheduled';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsPage(
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
                              color: cs.secondaryContainer.withValues(alpha: 0.1),
                              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(cs: cs),
                        );
                      }
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          Icon(Icons.cake_outlined, size: 14, color: cs.secondary.withValues(alpha: 0.4)),
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
                          Icon(Icons.access_time, size: 14, color: cs.secondary.withValues(alpha: 0.4)),
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
                Icon(Icons.arrow_forward_ios, size: 12, color: cs.secondary.withValues(alpha: 0.2)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderData {
  final String orderId;
  final String customerName;
  final String status;
  final String item;
  final String time;
  final String imageUrl;
  final Color statusBg;
  final Color statusFg;

  _OrderData({
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.item,
    required this.time,
    required this.imageUrl,
    required this.statusBg,
    required this.statusFg,
  });
}

class _OrderCompactCard extends StatelessWidget {
  final ColorScheme cs;
  final _OrderData data;
  final ValueChanged<int>? onTabChanged;

  const _OrderCompactCard({
    required this.cs,
    required this.data,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(
              orderId: data.orderId,
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
              child: Builder(
                builder: (context) {
                  final url = data.imageUrl;
                  return url.startsWith('http') 
                    ? Image.network(
                        url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 90, height: 90,
                            color: cs.secondaryContainer.withValues(alpha: 0.1),
                            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(cs: cs),
                      )
                    : _ImagePlaceholder(cs: cs);
                }
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
                          data.orderId,
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
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: data.statusBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.status.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: data.statusFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.customerName,
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
                      icon: Icons.cake_outlined, text: data.item, cs: cs),
                  const SizedBox(height: 2),
                  _CompactInfoRow(
                      icon: Icons.schedule_outlined, text: data.time, cs: cs),
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
  final ColorScheme cs;
  const _CompactInfoRow(
      {required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.secondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: cs.secondary.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
