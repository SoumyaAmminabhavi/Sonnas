import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/supabase_service.dart';

class GlassOrderSheet extends StatelessWidget {
  final WhatsAppOrder order;
  final bool showActions;

  const GlassOrderSheet({super.key, required this.order, this.showActions = true});

  static void show(BuildContext context, WhatsAppOrder order, {bool showActions = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassOrderSheet(order: order, showActions: showActions),
    );
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
                    if (order.notes != null) _buildNotes(cs),
                    const SizedBox(height: 120), // Padding for actions
                  ],
                ),
              ),
              if (showActions) _buildActionArea(context, cs),
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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ORDER NUMBER", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: cs.primary)),
                Text("#${order.orderNumber}", style: GoogleFonts.notoSerif(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            _StatusChip(status: order.status, cs: cs),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMMM dd, yyyy • hh:mm a').format(order.createdAt),
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
                Text(order.customerName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(order.phone, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.secondary.withValues(alpha: 0.6))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: cs.primary),
            onPressed: () => OrderService.launchWhatsApp(order.phone, "Hi ${order.customerName}, regarding your order #${order.orderNumber}..."),
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
        ...order.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Icon(Icons.cake_outlined, color: cs.primary.withValues(alpha: 0.3))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.cakeName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (item.options != null) Text(item.options!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cs.secondary.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Text("x${item.quantity}", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
            ],
          ),
        )),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TOTAL VALUE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            Text(order.formattedPrice, style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary)),
          ],
        ),
      ],
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
          Text(order.notes!, style: GoogleFonts.notoSerif(fontSize: 13, fontStyle: FontStyle.italic, color: cs.error.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: cs.secondary.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          if (order.status == OrderStatus.pending)
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, 'ACCEPTED');
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("ACCEPT ORDER", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          if (order.status == OrderStatus.accepted)
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, 'READY');
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("MARK AS READY", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
    if (status == OrderStatus.ready) color = Colors.green.shade700;
    if (status == OrderStatus.completed) color = cs.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(
        status.name,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
      ),
    );
  }
}
