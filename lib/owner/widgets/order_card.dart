import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/order_service.dart';
import '../../services/dashboard_provider.dart';
import '../../services/order_provider.dart';
import '../order_details_page.dart';

class OrderCardReactive extends ConsumerWidget {
  final Map<String, dynamic> data;
  final ValueChanged<int>? onTabChanged;

  const OrderCardReactive({super.key, required this.data, this.onTabChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    
    // Watch cached menu and order items
    final menuAsync = ref.watch(menuProvider);
    final itemsAsync = ref.watch(orderItemsProvider(data['id'] ?? ''));

    return itemsAsync.when(
      data: (items) {
        final status = data['status'] ?? 'PENDING';
        Color statusColor = status == 'COMPLETED' ? cs.secondary : cs.primary;

        String imageUrl = data['customImageUrl'] ?? '';
        if (imageUrl.isEmpty || imageUrl.startsWith('whatsapp://')) {
          if (items.isNotEmpty && menuAsync.hasValue) {
            final String firstName = items[0]['cakeName'] ?? '';
            final matchingCake = menuAsync.value!.firstWhere(
              (c) => (c['name'] as String).toLowerCase() == firstName.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            imageUrl = matchingCake['image'] ?? '';
          }
        }

        String orderSubtitle = 'Custom Creation';
        if (items.isNotEmpty) {
          final String firstName = items[0]['cakeName'] ?? 'Boutique Order';
          orderSubtitle = items.length > 1 ? "$firstName + ${items.length - 1} more" : firstName;
        }

        // Calculate actual total if totalPrice is null
        double calculatedTotal = 0.0;
        if (items.isNotEmpty) {
          calculatedTotal = items.fold(0.0, (sum, item) {
            final p = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
            final q = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            return sum + (p * q);
          });
        }

        return _OrderCardBase(
          id: "#${data['orderNumber'] ?? '---'}",
          status: status,
          statusColor: statusColor,
          paymentStatus: data['paymentStatus'] ?? 'PENDING',
          customerName: data['customerName'] ?? 'Guest Customer',
          price: data['totalPrice'] != null
              ? OrderService.formatPrice(data['totalPrice'])
              : OrderService.formatPrice(calculatedTotal),
          imageUrl: SupabaseService.getPublicUrl(imageUrl, width: 200, height: 200),
          deliveryDate: data['deliveryDate'] ?? 'Not scheduled',
          deliveryTime: data['deliveryTime'],
          orderSubtitle: orderSubtitle,
          onWhatsAppPressed: () => OrderService.launchWhatsApp(data['customerPhone'] ?? '', "Hi ${data['customerName'] ?? ''}, your order from Sonna's is ready!"),
          onTabChanged: onTabChanged,
        );
      },
      loading: () => const _OrderCardSkeleton(),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }
}

class _OrderCardBase extends StatelessWidget {
  final String id;
  final String status;
  final String paymentStatus;
  final Color statusColor;
  final String customerName;
  final String price;
  final String imageUrl;
  final String deliveryDate;
  final String? deliveryTime;
  final String orderSubtitle;

  final VoidCallback? onWhatsAppPressed;
  final ValueChanged<int>? onTabChanged;

  const _OrderCardBase({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.statusColor,
    required this.customerName,
    required this.price,
    required this.imageUrl,
    required this.deliveryDate,
    required this.orderSubtitle,
    this.deliveryTime,
    this.onWhatsAppPressed,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OwnerOrderDetailsView(
            orderId: id.replaceAll('#', ''),
            onTabChanged: onTabChanged,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _CardImage(imageUrl: imageUrl, cs: cs),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(id: id, paymentStatus: paymentStatus, status: status, statusColor: statusColor, cs: cs),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: cs.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(icon: Icons.cake_outlined, text: orderSubtitle, cs: cs),
                  _InfoRow(icon: Icons.payments_outlined, text: price, cs: cs),
                  _InfoRow(icon: Icons.schedule_outlined, text: deliveryTime != null ? "$deliveryDate at $deliveryTime" : deliveryDate, cs: cs),
                ],
              ),
            ),
            if (onWhatsAppPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onWhatsAppPressed,
                icon: const Icon(Icons.message_outlined, size: 20),
                color: Colors.teal.shade700,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.teal.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final ColorScheme cs;
  const _CardImage({required this.imageUrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90, height: 90, color: cs.primary.withValues(alpha: 0.05),
          child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.2), size: 32),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String id, paymentStatus, status;
  final Color statusColor;
  final ColorScheme cs;

  const _CardHeader({required this.id, required this.paymentStatus, required this.status, required this.statusColor, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(id, style: GoogleFonts.notoSerif(fontSize: 10, fontStyle: FontStyle.italic, color: cs.secondary.withValues(alpha: 0.5)), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        _Badge(label: paymentStatus, color: paymentStatus == 'PAID' ? Colors.green : Colors.orange),
        const SizedBox(width: 8),
        _Badge(label: status, color: statusColor),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  const _InfoRow({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.secondary.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.secondary.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(height: 122, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)));
  }
}
