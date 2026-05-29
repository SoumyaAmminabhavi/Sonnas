import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/order_service.dart';
import '../../services/dashboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final itemsAsync = ref.watch(orderItemsProvider((data['id'] as String?) ?? ''));

    return itemsAsync.when(
      data: (items) {
        final String status = (data['status'] as String?) ?? 'PENDING';
        final Color statusColor = status == 'COMPLETED' ? cs.secondary : cs.primary;

        // 1. Try customImageUrl from the order
        String imageUrl = data['customImageUrl']?.toString().trim() ?? '';

        // Normalize invalid order images (whatsapp:// or file://)
        if (imageUrl.isNotEmpty && (imageUrl.startsWith('whatsapp://') || imageUrl.startsWith('file://'))) {
          imageUrl = '';
        }

        // 2. Try to find an image from the associated WhatsApp Conversation if order image is missing
        final rawConversation = data['WhatsAppConversation'];
        if (imageUrl.isEmpty && rawConversation is Map) {
          imageUrl = rawConversation['customImageUrl']?.toString().trim() ?? '';
        }

        // 3. Fallback to Menu Item image if still empty or invalid
        if (imageUrl.isEmpty || imageUrl.startsWith('whatsapp://') || imageUrl.startsWith('file://')) {
          imageUrl = '';
          if (items.isNotEmpty && menuAsync.hasValue) {
            final String firstName = (items[0]['cakeName'] as String?) ?? '';
            final String? firstCakeId = items[0]['cakeId']?.toString();
            final matchingCake = menuAsync.value!.firstWhere(
              (c) => (firstCakeId != null && c['id']?.toString() == firstCakeId) ||
                     (c['name']?.toString().toLowerCase() == firstName.toLowerCase()),
              orElse: () => <String, dynamic>{},
            );
            imageUrl = (matchingCake['image'] as String?) ?? '';
          }
        }

        String orderSubtitle = 'Custom Creation';
        if (items.isNotEmpty) {
          final String firstName = (items[0]['cakeName'] as String?) ?? 'Boutique Order';
          orderSubtitle = items.length > 1 ? "$firstName + ${items.length - 1} more" : firstName;
        }

        // Calculate actual total if totalPrice is null
        double calculatedTotal = 0.0;
        if (items.isNotEmpty) {
          calculatedTotal = items.fold<double>(0.0, (sum, item) {
            final rawPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
            final q = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            return sum + (rawPrice * q);
          });
        }

        final address = (data['address'] ?? '').toString().toLowerCase();
        final isPickup = address.contains('pickup') || address.contains('checkout') || address.contains('store');

        return _OrderCardBase(
          orderId: data['id']?.toString() ?? '',
          id: "#${data['orderNumber'] ?? '---'}",
          status: status,
          statusColor: statusColor,
          paymentStatus: (data['paymentStatus'] ?? 'PENDING').toString().toUpperCase(),
          customerName: (data['customerName'] as String?) ?? 'Guest Customer',
          price: data['totalPrice'] != null
              ? OrderService.formatPrice(data['totalPrice'])
              : OrderService.formatPrice(calculatedTotal),
          imageUrl: SupabaseService.getPublicUrl(imageUrl, bucket: 'cakes'),
          deliveryDate: (() {
            final rawDate = data['deliveryDate']?.toString();
            if (rawDate == null || rawDate.isEmpty) return 'Not scheduled';
            final parsed = OrderService.parseDate(rawDate);
            if (parsed != null) {
              return DateFormat('MMMM d, y').format(parsed);
            }
            return rawDate;
          })(),
          deliveryTime: data['deliverySlot']?.toString() ?? data['deliveryTime']?.toString(),
          orderSubtitle: orderSubtitle,
          isPickup: isPickup,
          onWhatsAppPressed: () async {
            final rawConversation = data['WhatsAppConversation'];
            final conversation = rawConversation is Map ? rawConversation : null;
            final String customerName = (data['customerName'] as String?) ?? (conversation?['name'] as String?) ?? 'Guest Customer';
            final String customerPhone = data['customerPhone']?.toString() ?? 
                conversation?['phone']?.toString() ?? 
                data['phone']?.toString() ?? 
                '';
            final String orderId = data['orderNumber']?.toString() ?? '---';
            
            if (customerPhone.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No phone number available for this customer.')),
                );
              }
              return;
            }
            
            // Get first item name for the message
            String cakeName = 'your order';
            if (items.isNotEmpty) {
              cakeName = (items.first['cakeName'] as String?) ?? 'your order';
            }

            await OrderService.launchWhatsApp(
              customerPhone, 
              "Hi $customerName, this is Sonnas. Your order #$orderId ($cakeName) is ready for you!"
            );
          },
          onTabChanged: onTabChanged,
        );
      },
      loading: () => const _OrderCardSkeleton(),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }
}

class _OrderCardBase extends StatelessWidget {
  final String orderId;
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
  final bool isPickup;

  final VoidCallback? onWhatsAppPressed;
  final ValueChanged<int>? onTabChanged;

  const _OrderCardBase({
    required this.orderId,
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.statusColor,
    required this.customerName,
    required this.price,
    required this.imageUrl,
    required this.deliveryDate,
    required this.orderSubtitle,
    required this.isPickup,
    this.deliveryTime,
    this.onWhatsAppPressed,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: orderId.isEmpty ? null : () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => OwnerOrderDetailsView(
            orderId: orderId,
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
                  const SizedBox(height: 2),
                  Text(
                    customerName,
                    style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: cs.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _InfoRow(icon: Icons.cake_outlined, text: orderSubtitle, cs: cs),
                  _InfoRow(icon: Icons.payments_outlined, text: price, cs: cs),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    text: deliveryTime != null
                        ? (() {
                            final time = deliveryTime!.toLowerCase().trim();
                            final isImmediate = time == 'immediate' ||
                                time == 'immediate delivery' ||
                                time.contains('immediate') ||
                                time.contains('imidate') ||
                                time.contains('immidate');
                            if (isImmediate) {
                              return isPickup ? "Immediate Pickup ($deliveryDate)" : "Immediate Delivery ($deliveryDate)";
                            }
                            return isPickup ? "Pickup: $deliveryDate at $deliveryTime" : "$deliveryDate at $deliveryTime";
                          })()
                        : deliveryDate,
                    cs: cs,
                  ),
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
    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          height: 90,
          color: cs.primary.withValues(alpha: 0.05),
          child: Icon(Icons.cake_outlined,
              color: cs.primary.withValues(alpha: 0.2), size: 32),
        ),
      );
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final bytes = UriData.parse(imageUrl).contentAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 90,
            height: 90,
            color: cs.primary.withValues(alpha: 0.05),
            child: Icon(Icons.cake_outlined,
                color: cs.primary.withValues(alpha: 0.2), size: 32),
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 90,
          height: 90,
          color: cs.primary.withValues(alpha: 0.05),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 90,
          height: 90,
          color: cs.primary.withValues(alpha: 0.05),
          child: Icon(Icons.cake_outlined,
              color: cs.primary.withValues(alpha: 0.2), size: 32),
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
