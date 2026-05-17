import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/dashboard_provider.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../models/order.dart';
import '../../widgets/glass_order_sheet.dart';

class StaffOrdersPage extends StatelessWidget {
  const StaffOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderService.getRecentOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("❌ Orders stream error: ${snapshot.error}");
          return Center(child: Text("Failed to load orders", style: GoogleFonts.plusJakartaSans(color: cs.error)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];

        if (allOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: cs.secondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  "NO ORDERS FOUND",
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          itemCount: allOrders.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StaffOrderCard(orderMap: allOrders[index], cs: cs),
            );
          },
        );
      },
    );
  }
}

class StaffOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderMap;
  final ColorScheme cs;

  const StaffOrderCard({super.key, required this.orderMap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final order = SonnaOrder.fromMap(orderMap);
    
    return InkWell(
      onTap: () => GlassOrderSheet.show(context, order),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStaffOrderImage(order, cs),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, child) {
                      final itemsAsync = ref.watch(orderItemsProvider(order.id));
                      return itemsAsync.when(
                        data: (items) => Text(
                          "#${order.orderNumber} • ${items.length} items",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        loading: () => Text(
                          "#${order.orderNumber} • ... items",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        error: (err, stack) => Text(
                          "#${order.orderNumber} • — items",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.formattedPrice,
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusBadge(status: order.status, cs: cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.hourglass_empty;
      case OrderStatus.confirmed: return Icons.check_circle_outline;
      case OrderStatus.outForDelivery: return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
      case OrderStatus.completed: return Icons.done_all;
      default: return Icons.shopping_bag_outlined;
    }
  }

  Color _getStatusColor(OrderStatus status, ColorScheme cs) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.outForDelivery: return Colors.teal;
      case OrderStatus.delivered:
      case OrderStatus.completed: return cs.secondary;
      default: return cs.primary;
    }
  }

  Widget _buildStaffOrderImage(SonnaOrder order, ColorScheme cs) {
    final customUrl = order.customImageUrl?.trim();
    final convoUrl = order.conversationImageUrl?.trim();
    String imageUrl = (customUrl != null && customUrl.isNotEmpty)
        ? customUrl
        : (convoUrl ?? '');
    
    if (imageUrl.isEmpty || imageUrl.startsWith('file://') || imageUrl.startsWith('whatsapp://')) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          _getStatusIcon(order.status), 
          color: _getStatusColor(order.status, cs).withValues(alpha: 0.7),
          size: 22,
        ),
      );
    }

    final resolvedUrl = (imageUrl.startsWith('http') || imageUrl.startsWith('data:') || imageUrl.startsWith('whatsapp://') || imageUrl.startsWith('file://'))
        ? imageUrl
        : SupabaseService.getPublicUrl(imageUrl, bucket: 'cakes');

    if (imageUrl.startsWith('data:')) {
      try {
        final bytes = UriData.parse(imageUrl).contentAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            bytes,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status, cs).withValues(alpha: 0.7),
            size: 22,
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 52,
          height: 52,
          color: cs.primary.withValues(alpha: 0.05),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 52,
          height: 52,
          color: cs.primary.withValues(alpha: 0.05),
          child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status, cs).withValues(alpha: 0.7), size: 22),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final ColorScheme cs;

  const _StatusBadge({required this.status, required this.cs});

  @override
  Widget build(BuildContext context) {
    Color color = cs.primary;
    String label = status.humanReadable;

    if (status == OrderStatus.pending) {
      color = Colors.orange;
    } else if (status == OrderStatus.confirmed) {
      color = Colors.blue;
    } else if (status == OrderStatus.outForDelivery) {
      color = Colors.teal;
    } else if (status == OrderStatus.delivered || status == OrderStatus.completed) {
      color = cs.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
