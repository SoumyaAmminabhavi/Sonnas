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

      // Query unified Order table
      final orderResponse = await supabase
          .from('Order')
          .select('*')
          .eq('id', widget.orderId)
          .single();

      // Query unified OrderItem table
      final itemsResponse = await supabase
          .from('OrderItem')
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
      return Scaffold(
          body: Center(child: Text("Order not found: ${widget.orderId}")));
    }

    // deliveryDate is now a DateTime field in the schema
    final deliveryDateVal = orderData!['deliveryDate'];
    String formattedDate = "No Date";
    if (deliveryDateVal != null) {
      try {
        final date = DateTime.parse(deliveryDateVal.toString());
        formattedDate = DateFormat('EEEE, MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    // deliverySlot replaces old deliveryTime String
    final String deliverySlot = orderData!['deliverySlot'] ?? 'No Time';

    // Source of order (APP or WHATSAPP)
    final String source = orderData!['source']?.toString() ?? 'APP';

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
                  currentIndex: 1,
                  onTap: (_) => Navigator.pop(context),
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
                            // ── Header ──────────────────────────────────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "ATELIER RECEIPT",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3.0,
                                        color: cs.primary.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Source badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: source == 'WHATSAPP'
                                            ? Colors.green.shade50
                                            : cs.primaryContainer
                                                .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        source == 'WHATSAPP'
                                            ? '💬 WhatsApp Order'
                                            : '📲 App Order',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: source == 'WHATSAPP'
                                              ? Colors.green.shade700
                                              : cs.primary,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                    Icon(Icons.calendar_today_outlined,
                                        size: 16,
                                        color: cs.primary.withOpacity(0.6)),
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
                                    Icon(Icons.schedule_outlined,
                                        size: 16,
                                        color: cs.primary.withOpacity(0.6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      deliverySlot,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: cs.secondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // ── Progress Bar ─────────────────────────────────
                            _SlimProgressIndicator(
                                cs: cs,
                                status: orderData!['status'] ?? 'PENDING'),
                            const SizedBox(height: 32),

                            // ── Customer Summary ─────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    cs.surfaceContainerLow.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: cs.primary.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        cs.primaryContainer.withOpacity(0.3),
                                    child:
                                        Icon(Icons.person, color: cs.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderData!['customerName'] ??
                                              'Guest Customer',
                                          style: GoogleFonts.notoSerif(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        // customerPhone replaces old 'phone'
                                        Row(
                                          children: [
                                            SelectableText(
                                              orderData!['customerPhone'] ??
                                                  orderData!['phone'] ??
                                                  orderData!['customer_phone'] ??
                                                  'No Phone',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                color: cs.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.copy, size: 12, color: cs.primary.withOpacity(0.4)),
                                          ],
                                        ),
                                        if (orderData!['customerEmail'] !=
                                            null)
                                          Text(
                                            orderData!['customerEmail'],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: cs.secondary
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${((double.tryParse(orderData!['totalPrice'].toString()) ?? 0.0) / 100).toStringAsFixed(2)}",
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                      ),
                                      Text(
                                        orderData!['paymentStatus'] ??
                                            'PENDING',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: _paymentStatusColor(
                                              orderData!['paymentStatus']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Item List ────────────────────────────────────
                            Text(
                              "CUSTOMER'S SELECTION",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: cs.secondary.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 16),

                            ...orderItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SelectionTile(
                                    title: item['cakeName'] ??
                                        "Exquisite Creation",
                                    subtitle:
                                        "${item['size']} • Qty: ${item['quantity']}",
                                    price:
                                        "₹${((double.tryParse(item['price'].toString()) ?? 0.0) / 100).toStringAsFixed(2)}",
                                    imageUrl: orderData!['customImageUrl'] ??
                                        "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=60",
                                    cs: cs,
                                  ),
                                )),
                            const SizedBox(height: 32),

                            // ── Address & Notes ──────────────────────────────
                            _InfoSection(
                              title: "DELIVERY ADDRESS",
                              content: orderData!['address'] ??
                                  "Collection from Boutique",
                              icon: Icons.location_on_outlined,
                              cs: cs,
                            ),
                            const SizedBox(height: 16),
                            if (orderData!['notes'] != null &&
                                orderData!['notes'].toString().isNotEmpty)
                              _InfoSection(
                                title: "SPECIAL INSTRUCTIONS",
                                content: orderData!['notes'],
                                icon: Icons.edit_note,
                                cs: cs,
                              ),

                            // ── Custom Cake Info ─────────────────────────────
                            if (orderData!['isCustom'] == true) ...[
                              const SizedBox(height: 16),
                              _InfoSection(
                                title: "CUSTOM CAKE ORDER",
                                content:
                                    "Customer has provided a custom cake design image.",
                                icon: Icons.auto_awesome,
                                cs: cs,
                              ),
                            ],

                            // ── Razorpay Info ────────────────────────────────
                            if (orderData!['razorpayOrderId'] != null) ...[
                              const SizedBox(height: 16),
                              _InfoSection(
                                title: "PAYMENT REFERENCE",
                                content:
                                    orderData!['razorpayOrderId'].toString(),
                                icon: Icons.receipt_long,
                                cs: cs,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Sticky Bottom Actions ────────────────────────────
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
                              colors: [
                                cs.surface.withOpacity(0.0),
                                cs.surface,
                                cs.surface
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ElegantAction(
                                  icon: Icons.update,
                                  label: "DISPATCH / UPDATE STATUS",
                                  cs: cs,
                                  isPrimary: true,
                                  onPressed: () =>
                                      _showStatusUpdateDialog(context),
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

  Color _paymentStatusColor(dynamic status) {
    switch (status?.toString()) {
      case 'PAID':
        return Colors.green.shade700;
      case 'FAILED':
        return Colors.red.shade700;
      case 'REFUNDED':
        return Colors.blue.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  void _showStatusUpdateDialog(BuildContext context) {
    // New OrderStatus enum values
    const statuses = [
      'PENDING',
      'CONFIRMED',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'COMPLETED',
      'CANCELLED',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Update Order Status",
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isCurrent = orderData!['status'] == status;
            return ListTile(
              leading: isCurrent
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              title: Text(status,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal)),
              onTap: () async {
                if (isCurrent) {
                  Navigator.pop(context);
                  return;
                }
                try {
                  // Build update payload — set audit timestamps based on status
                  final now = DateTime.now().toUtc().toIso8601String();
                  final Map<String, dynamic> updatePayload = {
                    'status': status,
                    'updatedAt': now,
                  };
                  if (status == 'CONFIRMED') updatePayload['confirmedAt'] = now;
                  if (status == 'DELIVERED' || status == 'COMPLETED') {
                    updatePayload['deliveredAt'] = now;
                  }
                  if (status == 'CANCELLED') {
                    updatePayload['cancelledAt'] = now;
                  }

                  await Supabase.instance.client
                      .from('Order')
                      .update(updatePayload)
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

// ─── Info Section ─────────────────────────────────────────────────────────────

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
            color: cs.secondary.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary.withOpacity(0.4)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: GoogleFonts.notoSerif(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.8),
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

// ─── Progress Indicator ───────────────────────────────────────────────────────

class _SlimProgressIndicator extends StatelessWidget {
  final ColorScheme cs;
  final String status;
  const _SlimProgressIndicator({required this.cs, required this.status});

  @override
  Widget build(BuildContext context) {
    double progress;
    String message;

    switch (status) {
      case 'CONFIRMED':
        progress = 0.25;
        message = "Order confirmed — preparation will begin soon.";
        break;
      case 'OUT_FOR_DELIVERY':
        progress = 0.75;
        message = "Selection is en route to the customer.";
        break;
      case 'DELIVERED':
        progress = 0.9;
        message = "Delivered successfully. Awaiting completion.";
        break;
      case 'COMPLETED':
        progress = 1.0;
        message = "Hand-delivered with love. ✨";
        break;
      case 'CANCELLED':
        progress = 0.0;
        message = "This order has been cancelled.";
        break;
      default: // PENDING
        progress = 0.1;
        message = "Waiting to begin...";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status == 'CANCELLED' ? Colors.red : cs.primary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.notoSerif(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: status == 'CANCELLED' ? Colors.red : cs.primary,
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
            backgroundColor: cs.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                status == 'CANCELLED' ? Colors.red : cs.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.notoSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: cs.secondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ─── Selection Tile ───────────────────────────────────────────────────────────

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
            errorBuilder: (_, __, ___) => Container(
              width: 64,
              height: 64,
              color: cs.primaryContainer.withOpacity(0.2),
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
                  color: cs.secondary.withOpacity(0.5),
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

// ─── Action Button ────────────────────────────────────────────────────────────

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
            ? Border.all(color: cs.primary.withOpacity(0.1))
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: isPrimary ? Colors.white : cs.primary),
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
