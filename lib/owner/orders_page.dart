import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'order_details_page.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

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
                    "SONNA'S MANAGEMENT",
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
                  Tab(text: "PENDING"),
                  Tab(text: "PREPARING"),
                  Tab(text: "SHIPPED/DONE"),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12, indent: 24, endIndent: 24),

            // Orders List/Grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(cs: cs, status: 'PENDING'),
                  _OrdersList(cs: cs, status: 'PREPARING'),
                  _OrdersList(cs: cs, status: 'SHIPPED_OR_DELIVERED'),
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
  final String status;
  const _OrdersList({required this.cs, required this.status});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    final stream = status == 'SHIPPED_OR_DELIVERED'
        ? supabase.from('WhatsAppOrder').stream(primaryKey: ['id']).order('createdAt', ascending: false)
        : supabase.from('WhatsAppOrder').stream(primaryKey: ['id']).eq('status', status).order('createdAt', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var data = snapshot.data ?? [];
        if (status == 'SHIPPED_OR_DELIVERED') {
          // Note: supabase_flutter stream doesn't support .inFilter yet, so we filter locally
          // for the combined view but keep it optimized by only streaming relevant columns if needed.
          data = data.where((o) => o['status'] == 'SHIPPED' || o['status'] == 'DELIVERED').toList();
        }

        if (data.isEmpty) {
          return Center(
            child: Text(
              "No ${status == 'SHIPPED_OR_DELIVERED' ? 'SHIPPED/DONE' : status} orders",
              style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.4)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: data.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = data[index];
            final String deliveryDateStr = order['deliveryDate'] ?? '';
            String formattedDate = "No Date";
            if (deliveryDateStr.isNotEmpty) {
              try {
                final date = DateTime.parse(deliveryDateStr);
                formattedDate = DateFormat('MMM dd, yyyy').format(date);
              } catch (_) {}
            }

            final String createdAtStr = order['createdAt'] ?? '';
            String orderTime = "N/A";
            if (createdAtStr.isNotEmpty) {
              try {
                final date = DateTime.parse(createdAtStr).toLocal();
                orderTime = DateFormat('hh:mm a').format(date);
              } catch (_) {}
            }

            return _OrderCompactCard(
              cs: cs,
              data: _OrderData(
                orderId: order['id'] ?? '',
                orderNumber: order['orderNumber'] ?? 'N/A',
                customerName: order['customerName'] ?? 'Guest',
                status: order['status'] ?? 'PENDING',
                item: "Order Details",
                time: order['deliveryTime'] ?? 'No Time',
                date: formattedDate,
                orderTime: orderTime,
                imageUrl: order['customImageUrl'] ?? "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=60",
                statusBg: status == 'PENDING' ? Colors.orange.shade100 : (status == 'PREPARING' ? cs.primaryContainer : Colors.green.shade100),
                statusFg: status == 'PENDING' ? Colors.orange.shade900 : (status == 'PREPARING' ? cs.onPrimaryContainer : Colors.green.shade900),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrderData {
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String status;
  final String item;
  final String time;
  final String date;
  final String orderTime;
  final String imageUrl;
  final Color statusBg;
  final Color statusFg;

  _OrderData({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.item,
    required this.time,
    required this.date,
    required this.orderTime,
    required this.imageUrl,
    required this.statusBg,
    required this.statusFg,
  });
}

class _OrderCompactCard extends StatelessWidget {
  final ColorScheme cs;
  final _OrderData data;

  const _OrderCompactCard({
    required this.cs,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(orderId: data.orderId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                data.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: cs.primaryContainer.withValues(alpha: 0.2),
                  child: Icon(Icons.cake, color: cs.primary),
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
                      Text(
                        "${data.orderNumber} • Ordered at ${data.orderTime}",
                        style: GoogleFonts.notoSerif(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: cs.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: data.statusBg.withValues(alpha: 0.8),
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
                  ),
                  const SizedBox(height: 6),
                  _CompactInfoRow(icon: Icons.calendar_today_outlined, text: data.date, cs: cs),
                  const SizedBox(height: 2),
                  _CompactInfoRow(icon: Icons.schedule_outlined, text: data.time, cs: cs),
                ],
              ),
            ),
            
            // Action
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: cs.secondary.withValues(alpha: 0.3)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.white, size: 20),
                    onPressed: () {},
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
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
  const _CompactInfoRow({required this.icon, required this.text, required this.cs});

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


