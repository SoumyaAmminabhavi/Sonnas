import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                            // Poetic Header
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
                                  "Scheduled for Pickup today at 2:30 PM",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: cs.secondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                // Slim Progress Bar
                _SlimProgressIndicator(cs: cs),
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
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuCmN-AwCh057FLeCOX0kTTxAGI-o_RIO6GsuHfIUULg5LhdEmRO-KeG7U97a-80Fxhn5lLWd-Cny6iuaZH0OERFel2YXLKHJb3inAFMf5blT38kQ2iHbjytRyHjbKJsakX4prViV0HdTN1lGS-KGrQ32ysHwKonnR8eD_QQVCB8eNSbftaFEJ0Rl_uCyfo5pODYDusQcHJ3JsHK7rYDOPWTULpmh7IcL22IjAlLwLllGB458PQUroymGWQW7amlmq2nfUCbdXU7XD4M",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Madame Dupont",
                              style: GoogleFonts.notoSerif(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              "Premium Boutique Member",
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
                            "₹5,900",
                            style: GoogleFonts.notoSerif(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            "PAID ONLINE",
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
                  "YOUR SELECTION",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: cs.secondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Refined Item Tiles
                _SelectionTile(
                  title: "Valrhona Chocolate Noir",
                  subtitle: "1kg Artisan Tier",
                  price: "₹3,500",
                  imageUrl:
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuBcgLx1wB_YtTPx7L-WwIzghvzvQLj43G009Tgdx1uD4KLxn2vWlH6YUZ1Q-lGTQDvpN7xaz-2nVbwjmzbWH5ylkGSkDiW8LNpmC5ljF6E-YfV1jzZ722iWXWt54gfNS20E0rusxK9a6S6r-7-OF0xFjPztm4XQ1cgCxkjCtUyNihoSVuaq8U0Mod44tySWkS4pqXYdjaaQfrsGu29MLQQJ8kscebLKA_DsNJP8ivJhk-YGokXGBIpPivIso3tcIiM_1tlyEnfpI0Od",
                  cs: cs,
                ),
                const SizedBox(height: 12),
                _SelectionTile(
                  title: "Rose Petal Macarons",
                  subtitle: "Box of 12",
                  price: "₹2,400",
                  imageUrl:
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuCM8kvDF0eQhzkrDce4yaFTqilGBWhOLlO7wx60ONJurXiVrOtd_OxtCoHsnovhs-8sOoq92Ge3JOQgpTx1oNV_v1IzLMg43-0LwUsR9OzGAfZccvybEMZ22DzEIM-srgN-y7WK9b4AR1SDByB7KIYM2HGlZM-MoZp92RfDAUA8G4G0UdbTulmCbP2ZjUea_9_CaMYy7htLKkWx57MRNRlbGuIw8KS6KwLl8N_IJE6tln_1kG0Yew4Fdjq7GVdOV1cKn4T_Ya6-u7-M",
                  cs: cs,
                ),
                const SizedBox(height: 32),

                // Note
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: cs.primary.withValues(alpha: 0.4)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "\"Birthday message in chocolate calligraphy: Happy Birthday Julian!\"",
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
                      icon: Icons.download_outlined,
                      label: "INVOICE",
                      cs: cs,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ElegantAction(
                      icon: Icons.chat_bubble_outline,
                      label: "CONTACT",
                      cs: cs,
                      isPrimary: true,
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
}

class _SlimProgressIndicator extends StatelessWidget {
  final ColorScheme cs;
  const _SlimProgressIndicator({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "IN PREPARATION",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "65%",
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
            value: 0.65,
            minHeight: 4,
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Chef Sonna is currently finishing the chocolate calligraphy.",
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

  const _ElegantAction({
    required this.icon,
    required this.label,
    required this.cs,
    required this.isPrimary,
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
        onPressed: () {},
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
