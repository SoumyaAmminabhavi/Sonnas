import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/dashboard_provider.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../models/order.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderService.getKitchenOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.plusJakartaSans(color: cs.error)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((o) {
          final s = o['status']?.toString().trim().toUpperCase() ?? '';
          return s == 'PENDING' || s == 'CONFIRMED';
        }).toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "NO ACTIVE ORDERS",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: cs.secondary.withValues(alpha: 0.3),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            mainAxisExtent: 320,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            return KitchenOrderCard(orderMap: activeOrders[index], cs: cs);
          },
        );
      },
    );
  }
}

class KitchenOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderMap;
  final ColorScheme cs;

  const KitchenOrderCard({super.key, required this.orderMap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final order = SonnaOrder.fromMap(orderMap);
    final String status = order.status.dbValue;
    
    // Highlight confirmed (ready-to-dispatch) orders
    bool isConfirmed = status == 'CONFIRMED';
    
    final elapsed = DateTime.now().difference(order.createdAt);
    final String timeLabel = elapsed.inMinutes < 60 
        ? "${elapsed.inMinutes}m" 
        : "${elapsed.inHours}h";
    
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isConfirmed ? cs.primary.withValues(alpha: 0.2) : cs.secondary.withValues(alpha: 0.08),
            width: isConfirmed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isConfirmed ? cs.primary.withValues(alpha: 0.08) : cs.primary.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isConfirmed ? cs.primary.withValues(alpha: 0.05) : cs.primary.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${order.orderNumber}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: cs.secondary.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: GoogleFonts.notoSerif(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: cs.secondary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          final menuAsync = ref.watch(menuProvider);
                          final itemsAsync = ref.watch(orderItemsProvider(order.id));
                          final items = itemsAsync.value ?? [];
                          return _buildKitchenImage(orderMap, items, menuAsync.value ?? [], cs);
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final itemsAsync = ref.watch(orderItemsProvider(order.id));
                      return itemsAsync.when(
                        data: (items) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...items.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.cake_outlined, size: 14, color: cs.primary.withValues(alpha: 0.4)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${item['quantity'] ?? 1}x ${item['cakeName'] ?? 'Unknown'}",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.secondary.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (items.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 24),
                                child: Text(
                                  "+ ${items.length - 3} more creations",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: cs.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (err, stack) => Text("Error: ${err.toString().split(':').last.trim()}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.error.withValues(alpha: 0.7))),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    String? nextStatus;
                    if (status == 'PENDING') {
                      nextStatus = 'CONFIRMED';
                    } else if (status == 'CONFIRMED') {
                      nextStatus = 'OUT_FOR_DELIVERY';
                    } else {
                      return;
                    }
                    
                    try {
                      await OrderService.updateOrderStatus(order.id, nextStatus);
                    } catch (e) {
                      debugPrint("Kitchen order status update failed: $e");
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmed ? Colors.teal : cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: cs.primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    _getButtonLabel(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'OUT_FOR_DELIVERY': return Colors.teal;
      default: return cs.secondary;
    }
  }

  String _getButtonLabel(String status) {
    switch (status) {
      case 'PENDING': return "CONFIRM ORDER";
      case 'CONFIRMED': return "DISPATCH ORDER";
      default: return "VIEW DETAILS";
    }
  }

  Widget _buildKitchenImage(Map<String, dynamic> data, List<Map<String, dynamic>> items, List<Map<String, dynamic>> menu, ColorScheme cs) {
    // 1. Try customImageUrl from the order
    String imageUrl = data['customImageUrl']?.toString().trim() ?? '';
    final whatsAppData = data['WhatsAppConversation'];
    if (imageUrl.isEmpty && whatsAppData is Map) {
      imageUrl = whatsAppData['customImageUrl']?.toString().trim() ?? '';
    }

    String? version;

    // 2. Fallback to Menu Item image if still empty
    if (imageUrl.isEmpty || imageUrl.startsWith('whatsapp://') || imageUrl.startsWith('file://') || imageUrl.toLowerCase() == 'cake_placeholder.png') {
      imageUrl = ''; // Clear corrupted/unsupported values
      if (items.isNotEmpty && menu.isNotEmpty) {
        final String firstName = items[0]['cakeName'] ?? '';
        final String? firstCakeId = items[0]['cakeId']?.toString();
        final matchingCake = menu.firstWhere(
          (c) => (firstCakeId != null && c['id']?.toString() == firstCakeId) ||
                 (c['name']?.toString().toLowerCase() == firstName.toLowerCase()),
          orElse: () => <String, dynamic>{},
        );
        imageUrl = matchingCake['image'] ?? '';
        version = matchingCake['updatedAt']?.toString();
      }
    }

    // Final check for unsupported URIs before rendering
    if (imageUrl.startsWith('file://') || imageUrl.startsWith('whatsapp://') || imageUrl.toLowerCase() == 'cake_placeholder.png') {
      imageUrl = '';
    }

    if (imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
      );
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final bytes = UriData.parse(imageUrl).contentAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
            ),
          ),
        );
      } catch (_) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
        );
      }
    }

    final resolvedUrl = (() {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        if (version == null) return imageUrl;
        return imageUrl.contains('?') ? '$imageUrl&v=$version' : '$imageUrl?v=$version';
      }
      final base = SupabaseService.getPublicUrl(imageUrl, bucket: 'cakes');
      if (version == null) return base;
      return base.contains('?') ? '$base&v=$version' : '$base?v=$version';
    })();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 60,
          height: 60,
          color: cs.primary.withValues(alpha: 0.05),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 60,
          height: 60,
          color: cs.primary.withValues(alpha: 0.05),
          child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
