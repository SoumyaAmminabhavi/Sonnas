import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_details_page.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ATELIER MANAGEMENT",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: cs.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Active Orders",
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: cs.primary,
                indicatorWeight: 2,
                labelColor: cs.primary,
                unselectedLabelColor: cs.secondary.withValues(alpha: 0.4),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "TODAY"),
                  Tab(text: "UPCOMING"),
                  Tab(text: "COMPLETED"),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12, indent: 24, endIndent: 24),

            // Orders List/Grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(cs: cs),
                  const Center(child: Text("Upcoming Orders")),
                  const Center(child: Text("Completed Orders")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final ColorScheme cs;
  const _OrdersList({required this.cs});

  @override
  Widget build(BuildContext context) {
    final orders = [
      _OrderData(
        orderId: "#1234",
        customerName: "Clarisse d'Aubigne",
        status: "In Preparation",
        item: "Valrhona Ganache Signature Cake",
        time: "Pickup at 2:30 PM",
        imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuD7Gq6HWxTdg7A6sa8OvUP1JcXAw0vz0eI2EgDEc9Eslf0i8VnMVRb_U_EHAMDTeKfhBTt76lvg7av1LhtaOwID67IDxGjhfcT1mbTj8H4qxfQGQ7oEnkHQPVspmQ720rsydY97x98wPQ-XtJQ1Y1dGQysPSmJu5SIkw_4tzVzzxvxEg5tUkJJRDS05viIfPr3bTJNVDtycTyxeXoNv3_X_jQcpYB-tZMJnM6f_0pLswGschltTUdlHnuDxpjnjF0hQQJyPW3BndGuJ",
        statusBg: cs.primaryContainer.withValues(alpha: 0.9),
        statusFg: cs.onPrimaryContainer,
      ),
      _OrderData(
        orderId: "#1245",
        customerName: "Julien Mercier",
        status: "Ready for Pickup",
        item: "Spring Palette Macaron Box (24)",
        time: "Pickup at 4:15 PM",
        imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAPSKFQqtZpwtXveJNr2d1V7tki9SvDwgoH4vFaWnqY9H7Zq-9PQTu_f3xsONjHxNG_UakkYMBEcBJL143MHo7uGp-S_Uv0aQMUpRM6UBi0bxrYlsaqLduyNaBeAn4QwTvZ8H0P4EmXzbpomz2Tuv9hrxNX90MgsnPJFgEHskhzh3D48Wom5CDl4Qsz03I3Yst0PBueJT7nkQqRbdcivgBj00OiIRNeQe5iAfmx3TcZoHYheeREYO-07qovWenzsbddoXsBIXAQAhcm",
        statusBg: const Color(0xFFFFB6D3).withValues(alpha: 0.9), // Pastel Pink
        statusFg: cs.onSecondary,
      ),
      _OrderData(
        orderId: "#1248",
        customerName: "The Ritz-Carlton Concierge",
        status: "In Preparation",
        item: "Boulangerie Morning Selection (50pcs)",
        time: "Delivery at 6:00 AM (Tomorrow)",
        imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuB2nj5HtmD6PTym29duFSO0D_Exy79sufWG0R6Icg0IEEgwZazg2A9idNWaWHQHOo5Jgo4YgkOgsdtEpu03Vcg6m659JJvSOLaa2DnYpevUxby6G6ZuMGXpKydG5nsI0ddtlG4DZiI0P4o-KNc32lbZEZPyCCuMKxR9uRKa92rhJ4orJRIVb88D_3t_Dkkx_iFIszRkWF4vg_YRha0TE_007IwHf4P7XSMvyawZ5Z9XeWTjHfrkxI6B3TGK9SrkH5S9mBwDUleyG8px",
        statusBg: cs.primaryContainer.withValues(alpha: 0.9),
        statusFg: cs.onPrimaryContainer,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _OrderCompactCard(cs: cs, data: orders[index]),
    );
  }
}

class _OrderData {
  final String orderId;
  final String customerName;
  final String status;
  final String item;
  final String time;
  final String imageUrl;
  final Color statusBg;
  final Color statusFg;

  _OrderData({
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.item,
    required this.time,
    required this.imageUrl,
    required this.statusBg,
    required this.statusFg,
  });
}

class _OrderCompactCard extends StatelessWidget {
  final ColorScheme cs;
  final _OrderData data;

  const _OrderCompactCard({
    required this.cs,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(orderId: data.orderId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              data.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.orderId,
                      style: GoogleFonts.notoSerif(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: cs.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.statusBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: data.statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.customerName,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactInfoRow(icon: Icons.cake_outlined, text: data.item, cs: cs),
                const SizedBox(height: 2),
                _CompactInfoRow(icon: Icons.schedule_outlined, text: data.time, cs: cs),
              ],
            ),
          ),
          
          // Action
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.more_vert, color: cs.secondary.withValues(alpha: 0.3)),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primaryContainer],
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.white, size: 20),
                  onPressed: () {},
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  const _CompactInfoRow({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.secondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: cs.secondary.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

