import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/dashboard_provider.dart';

class OwnerOrderDetailsView extends StatefulWidget {
  final String orderId;
  final ValueChanged<int>? onTabChanged;

  const OwnerOrderDetailsView({super.key, required this.orderId, this.onTabChanged});

  @override
  State<OwnerOrderDetailsView> createState() => _OwnerOrderDetailsViewState();
}

class _OwnerOrderDetailsViewState extends State<OwnerOrderDetailsView> {
  late Future<Map<String, dynamic>?> _orderFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final cleanId = widget.orderId.replaceAll(RegExp(r'[#]'), '');
    _orderFuture = OrderService.fetchOrderByIdOrNumber(cleanId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        final order = snapshot.data;
        final conversation = order?['WhatsAppConversation'];

        if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: cs.surface,
                body: Shimmer.fromColors(
                  baseColor: cs.surfaceContainer,
                  highlightColor: cs.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 56),
                        Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
                        const SizedBox(height: 24),
                        Container(width: 200, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 12),
                        Container(width: 140, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 32),
                        ...List.generate(5, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: cs.surface,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text("Unable to load this order right now.",
                        style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () {
                          final newFuture = OrderService.fetchOrderByIdOrNumber(widget.orderId.replaceAll(RegExp(r'[#]'), ''));
                          setState(() {
                            _orderFuture = newFuture;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (order == null) {
              return Scaffold(
                backgroundColor: cs.surface,
                body: Center(child: Text("Order not found: ${widget.orderId}")),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;

                return Scaffold(
                  backgroundColor: cs.surface,
                  appBar: AppBar(
                    backgroundColor: cs.surface.withValues(alpha: 0.9),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: cs.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      isDesktop ? "Sonna's Patisserie & Cafe" : "Order Details",
                      style: GoogleFonts.notoSerif(
                        color: isDesktop
                            ? const Color.fromARGB(255, 146, 6, 53)
                            : cs.primary,
                        fontStyle: isDesktop
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: isDesktop
                            ? FontWeight.w600
                            : FontWeight.bold,
                        fontSize: isDesktop ? 20 : 18,
                        letterSpacing: isDesktop ? -0.5 : 0,
                      ),
                    ),
                  ),
                  body: Row(
                    children: [
                      if (isDesktop)
                        OwnerSidebar(
                          currentIndex: 1,
                          onTap: (index) {
                            if (!context.mounted) return;
                            Navigator.of(context).popUntil((route) => route.settings.name == 'OwnerDashboard' || route.isFirst);
                            widget.onTabChanged?.call(index);
                          },
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              child: Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 850),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "ATELIER RECEIPT",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3.0,
                                              color: cs.primary.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Order #${order['orderNumber'] ?? '---'}",
                                            style: GoogleFonts.notoSerif(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              color: cs.onSurface,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          Text(
                                            () {
                                              if (order['deliveryDate'] == null) return "Date not scheduled yet";
                                              final date = OrderService.parseDate(order['deliveryDate'].toString());
                                              if (date != null) {
                                                final formattedDate = DateFormat('MMMM d, y').format(date);
                                                final time = order['deliverySlot'] != null ? ' at ${order['deliverySlot']}' : '';
                                                return "Scheduled for $formattedDate$time";
                                              }
                                              return "Scheduled for ${order['deliveryDate']}${order['deliverySlot'] != null ? ' at ${order['deliverySlot']}' : ''}";
                                            }(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: cs.secondary.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      _SlimProgressIndicator(cs: cs, status: order['status'] ?? 'PENDING'),
                                      const SizedBox(height: 32),
                                      _CustomerInfoCard(
                                        name: order['customerName'] ?? conversation?['name'] ?? 'Guest Customer',
                                        phone: (() {
                                          final p = order['customerPhone']?.toString().trim();
                                          final fallbackPhone = conversation?['phone']?.toString().trim();
                                          return (p != null && p.isNotEmpty)
                                              ? p
                                              : ((fallbackPhone != null && fallbackPhone.isNotEmpty)
                                                  ? fallbackPhone
                                                  : 'Contact hidden');
                                        })(),
                                        address: (order['address'] ?? conversation?['address'] ?? 'No location provided').toString().replaceAll('Location: ', '').trim(),
                                        cs: cs,
                                      ),
                                      const SizedBox(height: 32),
                                      const SizedBox(height: 32),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _SectionTitle(title: "Artisan Selection", cs: cs),
                                       () {
                                         final String? rawUrl = (order['customImageUrl']?.toString() ?? conversation?['customImageUrl']?.toString())?.trim();
                                         final decoded = decodeDataUrlToBytes(rawUrl);
                                         
                                         if (decoded.imageBytes != null || decoded.url != null) {
                                           return IconButton(
                                             icon: const Icon(Icons.view_in_ar_outlined, size: 20),
                                             color: cs.primary,
                                             tooltip: "Holographic 3D View",
                                             onPressed: () {
                                               showDialog(
                                                 context: context,
                                                 builder: (context) => _HolographicViewer(
                                                   imageUrl: decoded.url,
                                                   imageBytes: decoded.imageBytes,
                                                   cs: cs,
                                                 ),
                                               );
                                             },
                                           );
                                         }
                                         return const SizedBox.shrink();
                                       }(),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final menuAsync = ref.watch(menuProvider);
                                          final itemsAsync = ref.watch(orderItemsProvider(order['id']));

                                          return menuAsync.when(
                                            loading: () => const Center(child: CircularProgressIndicator()),
                                            error: (e, _) => Text("Error loading menu: $e"),
                                            data: (menu) => itemsAsync.when(
                                              loading: () => const Center(child: CircularProgressIndicator()),
                                              error: (e, _) => Text("Error loading items: $e"),
                                              data: (items) {
                                                if (items.isEmpty) {
                                                  return Center(
                                                    child: Text(
                                                      "No items found for this selection.",
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 13,
                                                        color: cs.secondary.withValues(alpha: 0.4),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return Column(
                                                  children: [
                                                     ...items.map<Widget>((item) {
                                                       String displayImageUrl = '';
                                                       Uint8List? displayImageBytes;
                                                       final String cakeName = item['cakeName'] ?? '';
                                                       final String? cakeId = item['cakeId']?.toString();
                                                       // Prefer cakeId match for reliability; fall back to name match
                                                       final matchingCake = cakeId != null
                                                           ? menu.firstWhere(
                                                               (c) => c['id']?.toString() == cakeId,
                                                               orElse: () => menu.firstWhere(
                                                                 (c) => (c['name']?.toString().toLowerCase() ?? '') == cakeName.toLowerCase(),
                                                                 orElse: () => <String, dynamic>{},
                                                               ),
                                                             )
                                                           : menu.firstWhere(
                                                               (c) => (c['name']?.toString().toLowerCase() ?? '') == cakeName.toLowerCase(),
                                                               orElse: () => <String, dynamic>{},
                                                             );
                                                       displayImageUrl = matchingCake['image'] ?? '';

                                                       final rawCustomUrl = order['customImageUrl']?.toString() ?? conversation?['customImageUrl']?.toString();
                                                       final decodedCustom = decodeDataUrlToBytes(rawCustomUrl);
                                                       final resolvedCustomUrl = decodedCustom.url;
                                                       final resolvedCustomBytes = decodedCustom.imageBytes;
                                                       bool isCustomUrl = false;
                                                       if ((displayImageUrl.isEmpty || cakeName.toUpperCase().contains('CUSTOM')) &&
                                                           (resolvedCustomUrl != null || resolvedCustomBytes != null)) {
                                                         if (resolvedCustomBytes != null) {
                                                           displayImageBytes = resolvedCustomBytes;
                                                         } else {
                                                           displayImageUrl = resolvedCustomUrl!;
                                                         }
                                                         isCustomUrl = true;
                                                       }

                                                       final finalImageUrl = (displayImageBytes == null && displayImageUrl.isNotEmpty)
                                                           ? ((isCustomUrl || displayImageUrl.startsWith('http')) ? displayImageUrl : SupabaseService.getPublicUrl(displayImageUrl, bucket: 'cakes'))
                                                           : '';

                                                       return Padding(
                                                         padding: const EdgeInsets.only(bottom: 12.0),
                                                         child: _OrderItemCard(
                                                           title: cakeName,
                                                           subtitle: "${item['size'] ?? 'Standard'} • ${item['quantity'] ?? 1} Units",
                                                           price: OrderService.formatPrice(item['price']),
                                                           imageUrl: finalImageUrl,
                                                           imageBytes: displayImageBytes,
                                                           cs: cs,
                                                         ),
                                                       );
                                                     }),
                                                    const SizedBox(height: 24),
                                                    const Divider(height: 1, thickness: 0.5),
                                                    const SizedBox(height: 24),
                                                    _SummaryRow(
                                                      label: "Subtotal",
                                                      value: OrderService.formatPrice(items.fold(0.0, (sum, item) {
                                                        final p = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                                                        final q = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                                                        return sum + (p * q);
                                                      })),
                                                      cs: cs,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _SummaryRow(
                                                      label: "Delivery Fee",
                                                      value: "FREE",
                                                      cs: cs,
                                                      isAccent: true,
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _SummaryRow(
                                                      label: "Total",
                                                      value: order['totalPrice'] != null 
                                                        ? OrderService.formatPrice(order['totalPrice'])
                                                        : OrderService.formatPrice(items.fold(0.0, (sum, item) {
                                                            final p = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                                                            final q = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                                                            return sum + (p * q);
                                                          })),
                                                      cs: cs,
                                                      isTotal: true,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 32),
                                        _SectionTitle(title: "Special Instructions", cs: cs),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainer,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_note, color: cs.primary.withValues(alpha: 0.4)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  "\"${order['notes']}\"",
                                                  style: GoogleFonts.notoSerif(
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                    color: cs.onSurface.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                                      cs.surface.withValues(alpha: 0.0),
                                      cs.surface,
                                      cs.surface,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 850, maxHeight: 56),
                                    child: Row(
                                      children: [
                                          Expanded(
                                            flex: 3,
                                            child: () {
                                            final status = (order['status'] ?? 'PENDING').toString().toUpperCase();
                                            String label = "CONFIRM";
                                            String next = "CONFIRMED";
                                            IconData icon = Icons.check_circle_outline;
                                            bool active = true;

                                            if (status == 'PENDING') {
                                              label = "CONFIRM ORDER";
                                              next = "CONFIRMED";
                                            } else if (status == 'CONFIRMED') {
                                              label = "DISPATCH ORDER";
                                              next = "OUT_FOR_DELIVERY";
                                              icon = Icons.local_shipping_outlined;
                                            } else if (status == 'OUT_FOR_DELIVERY') {
                                              label = "MARK DELIVERED";
                                              next = "DELIVERED";
                                              icon = Icons.check_circle_outline;
                                            } else if (status == 'DELIVERED') {
                                              label = "COMPLETE ORDER";
                                              next = "COMPLETED";
                                              icon = Icons.done_all;
                                            } else {
                                              label = status;
                                              active = false;
                                            }

                                            return _ElegantAction(
                                              icon: icon,
                                              label: label,
                                              cs: cs,
                                              isPrimary: active,
                                                onPressed: (active && !_isUpdating) ? () async {
                                                  setState(() {
                                                    _isUpdating = true;
                                                  });
                                                  try {
                                                    await OrderService.updateOrderStatus(order['id'], next);
                                                    if (!context.mounted) return;
                                                    final newFuture = OrderService.fetchOrderByIdOrNumber(widget.orderId.replaceAll(RegExp(r'[#]'), ''));
                                                    setState(() {
                                                      _orderFuture = newFuture;
                                                    });
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              const Icon(Icons.check_circle_outline, color: Colors.white),
                                                              const SizedBox(width: 12),
                                                              Expanded(child: Text("Order updated to $next")),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e, st) {
                                                    debugPrint('Order status update failed: $e\n$st');
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text("Failed to update order. Please try again."),
                                                        ),
                                                      );
                                                    }
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isUpdating = false;
                                                      });
                                                    }
                                                  }
                                                } : null,
                                            );
                                          }(),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: _ElegantAction(
                                            icon: Icons.chat_bubble_outline,
                                            label: "CONTACT",
                                            cs: cs,
                                            isPrimary: false,
                                            onPressed: () async {
                                              final rawPhone = order['customerPhone']?.toString().trim();
                                              final fallbackPhone = conversation?['phone']?.toString().trim();
                                              final phone = (rawPhone != null && rawPhone.isNotEmpty)
                                                  ? rawPhone
                                                  : ((fallbackPhone != null && fallbackPhone.isNotEmpty)
                                                      ? fallbackPhone
                                                      : '');
                                              if (phone.isEmpty) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                                          const SizedBox(width: 12),
                                                          Expanded(child: Text("No contact number available.")),
                                                        ],
                                                      ),
                                                      backgroundColor: Colors.orange,
                                                    ),
                                                  );
                                                }
                                                return;
                                              }
                                              final name = order['customerName'] ?? conversation?['name'] ?? 'there';
                                              String cake = 'your selection';
                                              try {
                                                final items = await OrderService.fetchOrderItems(order['id']);
                                                if (items.isNotEmpty) {
                                                  cake = items.first['cakeName'] ?? 'your selection';
                                                }
                                              } catch (_) {}
                                               final orderNum = order['orderNumber']?.toString();
                                               final orderRef = (orderNum != null && orderNum.isNotEmpty)
                                                   ? 'your order #$orderNum'
                                                   : 'your order';
                                               OrderService.launchWhatsApp(
                                                 phone,
                                                 "Hi $name, this is Sonna's Patisserie. I'm contacting you regarding $orderRef ($cake).",
                                               );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
  }

  ({String? url, Uint8List? imageBytes}) decodeDataUrlToBytes(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return (url: null, imageBytes: null);
    final trimmed = rawUrl.trim();
    if (trimmed.toLowerCase().startsWith('data:')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx != -1) {
        try {
          return (url: null, imageBytes: base64Decode(trimmed.substring(commaIdx + 1)));
        } catch (_) {}
      }
      return (url: null, imageBytes: null);
    }
    final lower = trimmed.toLowerCase();
    if (lower.contains('://') && !lower.startsWith('http')) {
      return (url: null, imageBytes: null);
    }
    
    final url = lower.startsWith('http')
        ? trimmed
        : SupabaseService.getPublicUrl(trimmed, bucket: 'cakes');
    return (url: url, imageBytes: null);
  }
}

class _SlimProgressIndicator extends StatelessWidget {
  final ColorScheme cs;
  final String status;
  const _SlimProgressIndicator({required this.cs, required this.status});

  @override
  Widget build(BuildContext context) {
    double progress = 0.35;
    String statusText = "AWAITING CONFIRMATION";
    String poeticNote = "The atelier is awaiting your review to begin the creation.";
    final normalizedStatus = status.toUpperCase();

    if (normalizedStatus == 'CONFIRMED') {
      progress = 0.40;
      statusText = "ORDER CONFIRMED";
      poeticNote = "The selection has been confirmed and is being prepared for dispatch.";
    } else if (normalizedStatus == 'OUT_FOR_DELIVERY') {
      progress = 0.70;
      statusText = "OUT FOR DELIVERY";
      poeticNote = "The creation is on its way to you — the final journey begins.";
    } else if (normalizedStatus == 'DELIVERED') {
      progress = 0.90;
      statusText = "DELIVERED";
      poeticNote = "The selection has reached its destination.";
    } else if (normalizedStatus == 'COMPLETED') {
      progress = 1.0;
      statusText = "COMPLETED";
      poeticNote = "The order is complete. Thank you for choosing Sonna's Patisserie.";
    } else if (normalizedStatus == 'CANCELLED') {
      progress = 0.0;
      statusText = "CANCELLED";
      poeticNote = "The order has been cancelled.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(statusText, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 1.0)),
            Text("${(progress * 100).toInt()}%", style: GoogleFonts.notoSerif(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
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
        Text(poeticNote, style: GoogleFonts.notoSerif(fontSize: 12, fontStyle: FontStyle.italic, color: cs.secondary.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  const _SectionTitle({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: cs.secondary.withValues(alpha: 0.4)),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final ColorScheme cs;
  const _CustomerInfoCard({required this.name, required this.phone, required this.address, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surfaceContainerLow.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.1), child: Icon(Icons.person_outline, color: cs.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: cs.secondary)),
                Text(_formatPhone(phone), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.secondary.withValues(alpha: 0.6))),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isCoordinates(address) ? () => OrderService.launchMaps(address) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: _isCoordinates(address) ? cs.primary : cs.primary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(address, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.5)))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String p) {
    if (p == 'Contact hidden') return p;
    final clean = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) return "+91 ${clean.substring(0, 5)} ${clean.substring(5)}";
    if (clean.length == 12 && clean.startsWith('91')) return "+91 ${clean.substring(2, 7)} ${clean.substring(7)}";
    return p.startsWith('+') ? p : '+$p';
  }

  bool _isCoordinates(String s) {
    return RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$').hasMatch(s.trim());
  }
}

class _OrderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imageUrl;
  final Uint8List? imageBytes;
  final ColorScheme cs;
  const _OrderItemCard({required this.title, required this.subtitle, required this.price, required this.imageUrl, this.imageBytes, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const _ImagePlaceholder(),
                    errorWidget: (context, url, error) => const _ImagePlaceholder(),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.notoSerif(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.5))),
            ],
          ),
        ),
        Text(price, style: GoogleFonts.notoSerif(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primary.withValues(alpha: 0.05),
      child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2), size: 24)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool isTotal;
  final bool isAccent;
  const _SummaryRow({required this.label, required this.value, required this.cs, this.isTotal = false, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: cs.secondary.withValues(alpha: isTotal ? 1.0 : 0.5))),
        Text(value, style: GoogleFonts.notoSerif(fontSize: isTotal ? 20 : 14, fontWeight: FontWeight.bold, color: isAccent ? Colors.teal : (isTotal ? cs.primary : cs.secondary))),
      ],
    );
  }
}

class _ElegantAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final bool isPrimary;
  final VoidCallback? onPressed;
  const _ElegantAction({required this.icon, required this.label, required this.cs, required this.isPrimary, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color disabledColor = cs.onSurface.withValues(alpha: 0.3);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: (isPrimary && !isDisabled) ? LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        color: isDisabled 
            ? (isPrimary ? cs.primary.withValues(alpha: 0.1) : cs.surface)
            : (!isPrimary ? cs.surface : null),
        borderRadius: BorderRadius.circular(16),
        border: !isPrimary || isDisabled ? Border.all(
          color: isDisabled 
              ? cs.onSurface.withValues(alpha: 0.05) 
              : cs.primary.withValues(alpha: 0.15), 
          width: 1.5
        ) : null,
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: isPrimary ? cs.primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isDisabled ? disabledColor : (isPrimary ? Colors.white : cs.primary)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDisabled ? disabledColor : (isPrimary ? Colors.white : cs.primary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HolographicViewer extends StatefulWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final ColorScheme cs;
  const _HolographicViewer({this.imageUrl, this.imageBytes, required this.cs});

  @override
  State<_HolographicViewer> createState() => _HolographicViewerState();
}

class _HolographicViewerState extends State<_HolographicViewer> {
  double _rotationX = 0;
  double _rotationY = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: (details) {
              if (details.pointerCount == 1) {
                setState(() {
                  _rotationY += details.focalPointDelta.dx * 0.01;
                  _rotationX -= details.focalPointDelta.dy * 0.01;
                });
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(32)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("3D HOLOGRAPHIC VIEW", style: GoogleFonts.plusJakartaSans(color: widget.cs.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4)),
                  const SizedBox(height: 40),
                  Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(_rotationX)..rotateY(_rotationY),
                    alignment: FractionalOffset.center,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: widget.cs.primary.withValues(alpha: 0.3), blurRadius: 100, spreadRadius: 10)]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            maxScale: 5.0,
                            child: widget.imageBytes != null
                                ? Image.memory(
                                    widget.imageBytes!,
                                    fit: BoxFit.contain,
                                    height: 400,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.white),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: widget.imageUrl ?? '',
                                    fit: BoxFit.contain,
                                    height: 400,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                                  ),
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text("SWIPE TO ROTATE • PINCH TO ZOOM", style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
          ),
          Positioned(top: 20, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }
}
