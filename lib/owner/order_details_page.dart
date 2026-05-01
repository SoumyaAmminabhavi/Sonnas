import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';

class OwnerOrderDetailsView extends StatelessWidget {
  final String orderId;
  final ValueChanged<int>? onTabChanged;

  const OwnerOrderDetailsView({super.key, required this.orderId, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cleanId = orderId.replaceFirst('#', '');

    return StreamBuilder<Map<String, dynamic>?>(
      stream: SupabaseService.getSingleOrderStream(cleanId),
      builder: (context, streamSnapshot) {
        final streamOrder = streamSnapshot.data;

        return FutureBuilder<Map<String, dynamic>?>(
          future: streamOrder != null
              ? SupabaseService.client
                    .from('WhatsAppOrder')
                    .select('*, WhatsAppConversation(*)')
                    .eq('id', streamOrder['id'])
                    .maybeSingle()
              : Future.value(null),
          builder: (context, futureSnapshot) {
            final order = futureSnapshot.data ?? streamOrder;
            final conversation = order?['WhatsAppConversation'];

            if (streamSnapshot.connectionState == ConnectionState.waiting &&
                order == null) {
              return Scaffold(
                backgroundColor: cs.surface,
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (order == null) {
              return Scaffold(
                backgroundColor: cs.surface,
                body: Center(child: Text("Order not found: $orderId")),
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
                            // Use popUntil to return to the OwnerDashboard specifically
                            Navigator.of(context).popUntil((route) => route.settings.name == 'OwnerDashboard' || route.isFirst);
                            onTabChanged?.call(index);
                          },
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                0,
                                24,
                                120,
                              ),
                              child: Center(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 850,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "ATELIER RECEIPT",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3.0,
                                              color: cs.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Order $orderId",
                                            style: GoogleFonts.notoSerif(
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              color: cs.onSurface,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          Text(
                                            order['deliveryDate'] != null
                                                ? "Scheduled for ${order['deliveryDate']}${order['deliveryTime'] != null ? ' at ${order['deliveryTime']}' : ''}"
                                                : "Date not scheduled yet",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: cs.secondary.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      _SlimProgressIndicator(
                                        cs: cs,
                                        status: order['status'] ?? 'PENDING',
                                      ),
                                      const SizedBox(height: 32),
                                      _CustomerInfoCard(
                                        name:
                                            order['customerName'] ??
                                            conversation?['name'] ??
                                            'Guest Customer',
                                        phone:
                                            order['phone'] ??
                                            conversation?['phone'] ??
                                            'Contact hidden',
                                        cs: cs,
                                      ),
                                      const SizedBox(height: 32),
                                      _SectionTitle(
                                        title: "Artisan Selection",
                                        cs: cs,
                                      ),
                                      const SizedBox(height: 16),
                                      FutureBuilder<List<dynamic>>(
                                        future: Future.wait([
                                          SupabaseService.fetchMenu(),
                                          SupabaseService.fetchOrderItems(
                                            order['id'],
                                          ),
                                        ]),
                                        builder: (context, snapshot) {
                                          final menu = snapshot.data?[0] ?? [];
                                          final items = snapshot.data?[1] ?? [];

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
                                            children: items.map<Widget>((item) {
                                              String displayImageUrl = '';
                                              final String cakeName =
                                                  item['cakeName'] ?? '';
                                              final matchingCake = menu
                                                  .firstWhere(
                                                    (c) =>
                                                        (c['name'] as String)
                                                            .toLowerCase() ==
                                                        cakeName.toLowerCase(),
                                                    orElse: () =>
                                                        <String, dynamic>{},
                                                  );
                                              displayImageUrl =
                                                  matchingCake['image'] ?? '';

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12.0,
                                                ),
                                                child: _OrderItemCard(
                                                  title: cakeName,
                                                  subtitle:
                                                      "${item['size'] ?? 'Standard'} • ${item['quantity'] ?? 1} Units",
                                                  price:
                                                      SupabaseService.formatPrice(
                                                        item['price'],
                                                      ),
                                                  imageUrl:
                                                      SupabaseService.getPublicUrl(
                                                        displayImageUrl,
                                                      ),
                                                  cs: cs,
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      if (order['notes'] != null &&
                                          order['notes']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 32),
                                        _SectionTitle(
                                          title: "Special Instructions",
                                          cs: cs,
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainer,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: cs.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_note,
                                                color: cs.primary.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  "\"${order['notes']}\"",
                                                  style: GoogleFonts.notoSerif(
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.8),
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
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  40,
                                ),
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
                                    constraints: const BoxConstraints(
                                      maxWidth: 850,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _ElegantAction(
                                            icon: Icons.check_circle_outline,
                                            label: "CONFIRM",
                                            cs: cs,
                                            isPrimary: true,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _ElegantAction(
                                            icon: Icons.chat_bubble_outline,
                                            label: "CONTACT",
                                            cs: cs,
                                            isPrimary: false,
                                            onPressed: () {
                                              final phone =
                                                  order['phone'] ??
                                                  conversation?['phone'];
                                              final name =
                                                  order['customerName'] ??
                                                  conversation?['name'] ??
                                                  'there';
                                              final cake =
                                                  order['cakeName'] ??
                                                  'your cake';
                                              SupabaseService.launchWhatsApp(
                                                phone,
                                                "Hi $name, this is Sonna's Patisserie. I'm contacting you regarding your order #$orderId ($cake).",
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
      },
    );
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
    String poeticNote =
        "The atelier is awaiting your review to begin the creation.";

    if (status == 'PREPARING') {
      progress = 0.65;
      statusText = "IN PREPARATION";
      poeticNote =
          "Chef Sonna is currently finishing the chocolate calligraphy.";
    } else if (status == 'OUT_FOR_DELIVERY') {
      progress = 0.85;
      statusText = "OUT FOR DELIVERY";
      poeticNote = "Your masterpiece is currently being transported with care.";
    } else if (status == 'COMPLETED') {
      progress = 1.0;
      statusText = "HANDED OVER";
      poeticNote =
          "The selection has been successfully delivered to the customer.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusText,
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
          poeticNote,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  const _SectionTitle({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: cs.secondary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final String name;
  final String phone;
  final ColorScheme cs;
  const _CustomerInfoCard({
    required this.name,
    required this.phone,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person_outline, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: cs.secondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imageUrl;
  final ColorScheme cs;

  const _OrderItemCard({
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
          child: SizedBox(
            width: 64,
            height: 64,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _ImagePlaceholder(),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.cake_outlined,
          color: cs.primary.withValues(alpha: 0.2),
          size: 24,
        ),
      ),
    );
  }
}

class _ElegantAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ElegantAction({
    required this.icon,
    required this.label,
    required this.cs,
    required this.isPrimary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? cs.primary : cs.surface,
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
        onPressed: onPressed ?? () {},
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
