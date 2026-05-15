import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import 'menu_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_provider.dart';

class MenuDetailsPage extends ConsumerWidget {
  final String cakeId;
  final ValueChanged<int>? onTabChanged;

  const MenuDetailsPage({super.key, required this.cakeId, this.onTabChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final menuAsync = ref.watch(menuProvider);

    return menuAsync.when(
      loading: () => Scaffold(
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
                Container(height: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
                const SizedBox(height: 24),
                Container(width: 220, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 12),
                Container(width: 100, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                const SizedBox(height: 32),
                Container(width: 120, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 16),
                ...List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
                )),
              ],
            ),
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, color: cs.error, size: 48),
              const SizedBox(height: 16),
              Text("Connection Error", style: GoogleFonts.notoSerif(fontSize: 18, color: cs.secondary)),
              Text("Unable to fetch artisan details.", style: GoogleFonts.plusJakartaSans(color: cs.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("GO BACK"),
              ),
            ],
          ),
        ),
      ),
      data: (allCakes) {
        final cake = allCakes.firstWhere(
          (c) => c['id'] == cakeId,
          orElse: () => <String, dynamic>{},
        );

        if (cake.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return Scaffold(
            backgroundColor: cs.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final options = cake['CakeOption'] as List? ?? [];
        final imageUrl = SupabaseService.getPublicUrl(cake['image'], bucket: 'cakes');

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
                  isDesktop ? "Sonna's Patisserie & Cafe" : "Menu Details",
                  style: GoogleFonts.notoSerif(
                    color: cs.primary,
                    fontStyle: isDesktop ? FontStyle.italic : FontStyle.normal,
                    fontWeight: isDesktop ? FontWeight.w600 : FontWeight.bold,
                    fontSize: isDesktop ? 20 : 18,
                  ),
                ),
              ),
              body: Row(
                children: [
                  if (isDesktop)
                    OwnerSidebar(
                      currentIndex: 3,
                      onTap: (index) {
                        if (!context.mounted) return;
                        Navigator.of(context).popUntil((route) => route.settings.name == 'OwnerDashboard' || route.isFirst);
                        onTabChanged?.call(index);
                      },
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                "ATELIER SPECIFICATION",
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: cs.primary),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                cake['name'] ?? 'Untitled Creation',
                                style: GoogleFonts.notoSerif(fontSize: isDesktop ? 42 : 32, height: 1.1, color: cs.secondary),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                height: isDesktop ? 450 : 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: cs.secondary.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Container(
                                      color: cs.surfaceContainer,
                                      child: Icon(Icons.restaurant, color: cs.primary, size: 48),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                "ARTISAN DESCRIPTION",
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: cs.secondary.withValues(alpha: 0.4)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                cake['description'] ?? 'No description provided.',
                                style: GoogleFonts.notoSerif(fontSize: 16, height: 1.6, color: cs.onSurface.withValues(alpha: 0.8)),
                              ),
                              const SizedBox(height: 48),
                              Row(
                                children: [
                                  _InfoBadge(
                                    icon: Icons.category_outlined,
                                    label: "COLLECTION",
                                    value: (cake['Category']?['name']?.toString() ?? 'General'),
                                    cs: cs,
                                  ),
                                  const SizedBox(width: 24),
                                  _InfoBadge(icon: Icons.timer_outlined, label: "EST. WEIGHT", value: "600-800g", cs: cs),
                                ],
                              ),
                              const SizedBox(height: 48),
                              Text(
                                "AVAILABLE CONFIGURATIONS",
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: cs.secondary.withValues(alpha: 0.4)),
                              ),
                              const SizedBox(height: 16),
                              ...options.map((opt) => _OptionCard(opt: opt, cs: cs)),
                              if (options.isEmpty)
                                Text(
                                  "No size configurations found for this item.",
                                  style: GoogleFonts.plusJakartaSans(fontStyle: FontStyle.italic, color: cs.onSurface.withValues(alpha: 0.5)),
                                ),
                              const SizedBox(height: 64),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuPage(cakeData: cake, onTabChanged: onTabChanged)));
                },
                backgroundColor: cs.primary,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                label: Text("EDIT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ColorScheme cs;
  const _InfoBadge({required this.icon, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.secondary.withValues(alpha: 0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 14, color: cs.primary), const SizedBox(width: 8), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.0))]),
            const SizedBox(height: 8),
            Text(value.toUpperCase(), style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: cs.secondary)),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Map<String, dynamic> opt;
  final ColorScheme cs;
  const _OptionCard({required this.opt, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.secondary.withValues(alpha: 0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SIZE / SERVINGS", style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: cs.secondary.withValues(alpha: 0.4), letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text("Serves ${opt['serves']?.toString() ?? 'N/A'}", style: GoogleFonts.notoSerif(fontSize: 15, fontWeight: FontWeight.bold, color: cs.secondary)),
            ],
          ),
          Text(OrderService.formatPrice(opt['price']), style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
        ],
      ),
    );
  }
}
