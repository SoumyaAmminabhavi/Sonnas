import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../widgets/wasm_image.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/dashboard_provider.dart';

class GlassOrderSheet extends StatefulWidget {
  final SonnaOrder order;
  final bool showActions;

  const GlassOrderSheet({super.key, required this.order, this.showActions = true});

  static void show(BuildContext context, SonnaOrder order, {bool showActions = true}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassOrderSheet(order: order, showActions: showActions),
    );
  }

  @override
  State<GlassOrderSheet> createState() => _GlassOrderSheetState();
}

class _GlassOrderSheetState extends State<GlassOrderSheet> {
  bool _isUpdating = false;

  bool _shouldShowActionArea() {
    if (!widget.showActions) return false;
    final status = widget.order.status;
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.outForDelivery ||
        status == OrderStatus.delivered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildDragHandle(cs),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildHeader(cs),
                    const SizedBox(height: 32),
                    _buildCustomerCard(cs),
                    const SizedBox(height: 32),
                    _buildItemsList(cs),
                    const SizedBox(height: 32),
                    if (widget.order.notes?.trim().isNotEmpty == true) _buildNotes(cs),
                    SizedBox(height: _shouldShowActionArea() ? 120 : 0),
                  ],
                ),
              ),
              if (_shouldShowActionArea()) _buildActionArea(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ORDER NUMBER", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: cs.primary)),
                  Text(
                    "#${widget.order.orderNumber}", 
                    style: GoogleFonts.notoSerif(fontSize: 28, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(status: widget.order.status, cs: cs),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMMM dd, yyyy • hh:mm a').format(widget.order.createdAt),
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.secondary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.primary.withValues(alpha: 0.05))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.1), child: Icon(Icons.person_outline, color: cs.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.order.customerName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.order.phone, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.secondary.withValues(alpha: 0.6))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: cs.primary),
            onPressed: widget.order.phone.isNotEmpty
                ? () => OrderService.launchWhatsApp(widget.order.phone, "Hi ${widget.order.customerName}, regarding your order #${widget.order.orderNumber}...")
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SELECTION ITEMS", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: cs.primary)),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final itemsAsync = ref.watch(orderItemsProvider(widget.order.id));
            final menuAsync = ref.watch(menuProvider);
            final menu = menuAsync.value ?? [];

            return itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  if (widget.order.items.isNotEmpty) {
                    return Column(
                      children: widget.order.items.map((item) => _buildOrderItemRow(item, menu, cs)).toList(),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text("No items found.", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.5))),
                  );
                }
                
                return Column(
                  children: items.map((itemMap) {
                    final item = OrderItem.fromMap(itemMap);
                    return _buildOrderItemRow(item, menu, cs);
                  }).toList(),
                );
              },
              loading: () {
                if (widget.order.items.isNotEmpty) {
                  return Column(
                    children: widget.order.items.map((item) => _buildOrderItemRow(item, menu, cs)).toList(),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (err, stack) {
                if (widget.order.items.isNotEmpty) {
                  return Column(
                    children: widget.order.items.map((item) => _buildOrderItemRow(item, menu, cs)).toList(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text("Error loading items.", style: GoogleFonts.plusJakartaSans(color: cs.error)),
                );
              },
            );
          },
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TOTAL VALUE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            Text(widget.order.formattedPrice, style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(OrderItem item, List<Map<String, dynamic>> menu, ColorScheme cs) {
    String displayImageUrl = '';
    final matchingCake = item.cakeId != null
        ? menu.firstWhere(
            (c) => c['id']?.toString() == item.cakeId,
            orElse: () => menu.firstWhere(
              (c) => c['name']?.toString().toLowerCase() == item.cakeName.toLowerCase(),
              orElse: () => <String, dynamic>{},
            ),
          )
        : menu.firstWhere(
            (c) => c['name']?.toString().toLowerCase() == item.cakeName.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );
    displayImageUrl = (matchingCake['image'] as String?) ?? '';

    if (displayImageUrl.isEmpty || item.cakeName.toUpperCase().contains('CUSTOM')) {
      final customTrimmed = widget.order.customImageUrl?.trim();
      final conversationTrimmed = widget.order.conversationImageUrl?.trim();
      if (customTrimmed != null && customTrimmed.isNotEmpty) {
        displayImageUrl = customTrimmed;
      } else if (conversationTrimmed != null && conversationTrimmed.isNotEmpty) {
        displayImageUrl = conversationTrimmed;
      }
    }

    Widget imageWidget;
    if (displayImageUrl.isNotEmpty) {
      if (displayImageUrl.startsWith('data:')) {
        try {
          final bytes = UriData.parse(displayImageUrl).contentAsBytes();
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.3))),
              ),
            ),
          );
        } catch (_) {
          imageWidget = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.3))),
          );
        }
      } else {
        // Use raw URL for absolute paths, Supabase public URL for storage paths
        final bool isLocalScheme = displayImageUrl.startsWith('file://') || displayImageUrl.startsWith('whatsapp://');
        
        if (isLocalScheme) {
          imageWidget = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.3))),
          );
        } else {
          final resolvedUrl = SupabaseService.getPublicUrl(displayImageUrl, bucket: 'cakes');
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SafeWasmImage(
              imageUrl: resolvedUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          );
        }
      }
    } else {
      imageWidget = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.3))),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          imageWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.cakeName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Text("x${item.quantity}", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotes(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.error.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
              const SizedBox(width: 8),
              Text("CHEF'S NOTES", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: cs.error, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
           Text(widget.order.notes!.trim(), style: GoogleFonts.notoSerif(fontSize: 13, fontStyle: FontStyle.italic, color: cs.error.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, ColorScheme cs) {
    final status = widget.order.status;
    
    bool showButton = false;
    String buttonText = "";
    String nextStatus = "";
    Color buttonColor = cs.primary;
    
    if (status == OrderStatus.pending) {
      showButton = true;
      buttonText = "CONFIRM ORDER";
      nextStatus = "CONFIRMED";
      buttonColor = Colors.blue;
    } else if (status == OrderStatus.confirmed) {
      showButton = true;
      buttonText = "OUT FOR DELIVERY";
      nextStatus = "OUT_FOR_DELIVERY";
      buttonColor = Colors.teal;
    } else if (status == OrderStatus.outForDelivery) {
      showButton = true;
      buttonText = "MARK AS DELIVERED";
      nextStatus = "DELIVERED";
      buttonColor = cs.secondary;
    } else if (status == OrderStatus.delivered) {
      showButton = true;
      buttonText = "COMPLETE ORDER";
      nextStatus = "COMPLETED";
      buttonColor = Colors.green.shade700;
    }

    if (!showButton) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: cs.secondary.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdating ? null : () async {
                setState(() => _isUpdating = true);
                try {
                  await OrderService.updateOrderStatus(widget.order.id, nextStatus);
                  if (context.mounted) Navigator.pop(context);
                } catch (e, st) {
                  debugPrint('❌ Status update failed: $e\n$st');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Failed to update order status. Please try again."),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isUpdating = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isUpdating 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(buttonText, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  final ColorScheme cs;

  const _StatusChip({required this.status, required this.cs});

  @override
  Widget build(BuildContext context) {
    Color color = cs.primary;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(
        status.humanReadable,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
      ),
    );
  }
}
