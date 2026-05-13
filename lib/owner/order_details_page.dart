import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/owner_sidebar.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? orderData;
  List<dynamic> orderItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final orderResponse = await supabase
          .from('WhatsAppOrder')
          .select('*')
          .eq('id', widget.orderId)
          .single();

      final itemsResponse = await supabase
          .from('WhatsAppOrderItem')
          .select('*')
          .eq('orderId', widget.orderId);

      if (mounted) {
        setState(() {
          orderData = orderResponse;
          orderItems = itemsResponse;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching order details: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (orderData == null) {
      return Scaffold(body: Center(child: Text("Order not found: ${widget.orderId}")));
    }

    final String deliveryDateStr = orderData!['deliveryDate'] ?? '';
    String formattedDate = "No Date";
    if (deliveryDateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(deliveryDateStr);
        formattedDate = DateFormat('EEEE, MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    final String deliveryTime = orderData!['deliveryTime'] ?? 'No Time';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: const Color(0xFFFFF0F6),
          appBar: isDesktop
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Sonna's Patisserie & Cafe",
                    style: GoogleFonts.notoSerif(
                      color: const Color(0xFFD9B87A),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
          extendBodyBehindAppBar: !isDesktop,
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: 1, // Active under Orders
                  onTap: (index) {
                    Navigator.pop(context); // Go back to dashboard with selected index
                  },
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFFFF0F6),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          isDesktop ? 40 : 100,
                          24,
                          120,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SONNA'S RECEIPT",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.0,
                                    color: cs.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Order ${orderData!['orderNumber'] ?? widget.orderId}",
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: cs.onSurface,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 16, color: cs.primary.withValues(alpha: 0.6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: cs.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.schedule_outlined, size: 16, color: cs.primary.withValues(alpha: 0.6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      deliveryTime,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: cs.secondary.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Progress Bar
                            _SlimProgressIndicator(cs: cs, status: orderData!['status'] ?? 'PENDING'),
                            const SizedBox(height: 32),

                            // Quick Info Row (Customer & Summary)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                                    child: Icon(Icons.person, color: cs.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderData!['customerName'] ?? 'Guest Customer',
                                          style: GoogleFonts.notoSerif(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        Text(
                                          orderData!['phone'] ?? 'No Phone',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: cs.primary.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${(orderData!['totalPrice'] / 100).toStringAsFixed(2)}",
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                      ),
                                      Text(
                                        "STATUS: ${orderData!['status']}",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Selection Header
                            Text(
                              "CUSTOMER'S SELECTION",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: cs.secondary.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Real Item Tiles
                            ...orderItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SelectionTile(
                                    title: item['cakeName'] ?? "Exquisite Creation",
                                    subtitle: "Quantity: ${item['quantity']}",
                                    price: "₹${(item['price'] / 100).toStringAsFixed(2)}",
                                    imageUrl: orderData!['customImageUrl'] ??
                                        "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=60",
                                    cs: cs,
                                  ),
                                )),
                            const SizedBox(height: 32),

                            // Address & Notes
                            _InfoSection(
                              title: "DELIVERY ADDRESS",
                              content: orderData!['address'] ?? "Collection from Boutique",
                              icon: Icons.location_on_outlined,
                              cs: cs,
                            ),
                            const SizedBox(height: 16),
                            if (orderData!['notes'] != null && orderData!['notes'].toString().isNotEmpty)
                              _InfoSection(
                                title: "SPECIAL INSTRUCTIONS",
                                content: orderData!['notes'],
                                icon: Icons.edit_note,
                                cs: cs,
                              ),
                          ],
                        ),
                      ),

                      // Sticky Bottom Actions
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [cs.surface.withValues(alpha: 0.0), cs.surface, cs.surface],
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ElegantAction(
                                  icon: Icons.update,
                                  label: "UPDATE STATUS",
                                  cs: cs,
                                  isPrimary: true,
                                  onPressed: () => _showStatusUpdateDialog(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ElegantAction(
                                  icon: Icons.chat_bubble_outline,
                                  label: "WHATSAPP",
                                  cs: cs,
                                  isPrimary: false,
                                  onPressed: () {},
                                ),
                              ),
                            ],
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
      },
    );
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['PENDING', 'PREPARING', 'SHIPPED', 'DELIVERED'].map((status) {
            return ListTile(
              title: Text(status),
              onTap: () async {
                try {
                  await Supabase.instance.client
                      .from('WhatsAppOrder')
                      .update({
                        'status': status,
                        'updatedAt': DateTime.now().toUtc().toIso8601String(),
                      })
                      .eq('id', widget.orderId);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _fetchOrderDetails();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final ColorScheme cs;

  const _InfoSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: cs.secondary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: GoogleFonts.notoSerif(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlimProgressIndicator extends StatelessWidget {
  final ColorScheme cs;
  final String status;
  const _SlimProgressIndicator({required this.cs, required this.status});

  @override
  Widget build(BuildContext context) {
    double progress = 0.1;
    String message = "Waiting to begin...";
    if (status == 'PREPARING') {
      progress = 0.5;
      message = "Chef Sonna is currently crafting this selection.";
    } else if (status == 'SHIPPED') {
      progress = 0.8;
      message = "Selection is en route to the customer.";
    } else if (status == 'DELIVERED') {
      progress = 1.0;
      message = "Hand-delivered with love.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.notoSerif(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.notoSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: cs.secondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imageUrl;
  final ColorScheme cs;

  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 64,
              height: 64,
              color: cs.primaryContainer.withValues(alpha: 0.2),
              child: Icon(Icons.cake, color: cs.primary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: cs.secondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.notoSerif(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

class _ElegantAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ElegantAction({
    required this.icon,
    required this.label,
    required this.cs,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? cs.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isPrimary
            ? Border.all(color: cs.primary.withValues(alpha: 0.1))
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isPrimary ? Colors.white : cs.primary,
        ),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isPrimary ? Colors.white : cs.primary,
          ),
        ),
      ),
    );
  }
}

