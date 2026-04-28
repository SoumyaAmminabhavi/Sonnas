import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40.0 : 20.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactHero(context, isDesktop),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabs(context),
                        const SizedBox(height: 24),
                        _buildPaymentList(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 2,
                    child: _buildHistorySection(context, isCompact: true),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildTabs(context),
                  const SizedBox(height: 24),
                  _buildPaymentList(context),
                  const SizedBox(height: 48),
                  _buildHistorySection(context, isCompact: false),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHero(BuildContext context, bool isDesktop) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FINANCIAL OVERVIEW",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Atelier Revenue",
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: isDesktop ? 32 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _buildCompactStat(context, "WEEKLY GROSS", "₹12,480", cs.onSurface),
                    _buildCompactStat(context, "PENDING", "₹286", cs.primary),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop)
            Container(
              height: 100,
              width: 1,
              color: Colors.black.withValues(alpha: 0.05),
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
          if (isDesktop)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Month of October",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "LIVE DATA",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black26,
            fontWeight: FontWeight.bold,
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: cs.primary,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      labelColor: cs.primary,
      unselectedLabelColor: cs.secondary.withValues(alpha: 0.4),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
      tabs: const [
        Tab(text: "PENDING PAYMENTS"),
        Tab(text: "COMPLETED TODAY"),
      ],
    );
  }

  Widget _buildPaymentList(BuildContext context) {
    final pendingItems = [
      {"id": "#8825", "name": "Madame Dupont", "amount": "₹142", "desc": "Macaron Tower"},
      {"id": "#8826", "name": "Julian Vane", "amount": "₹54", "desc": "Petit Four x2"},
      {"id": "#8827", "name": "Sophie Laurent", "amount": "₹90", "desc": "Signature Cake"},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = pendingItems[index];
        return _buildCompactCard(context, item);
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, Map<String, String> item) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ORDER ${item['id']}",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black26,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item['name']!,
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['desc']!,
                  style: GoogleFonts.notoSerif(
                    color: cs.secondary.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['amount']!,
                style: GoogleFonts.notoSerif(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "MARK AS PAID",
                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, {required bool isCompact}) {
    final cs = Theme.of(context).colorScheme;
    final historyItems = [
      {"name": "Laurant Boulangerie", "date": "Oct 24", "amount": "₹1,240"},
      {"name": "Jean-Luc Coffee", "date": "Oct 22", "amount": "₹845"},
      {"name": "Atelier Uniforms", "date": "Oct 19", "amount": "₹430"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent History",
              style: GoogleFonts.notoSerif(
                color: cs.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "View All",
              style: GoogleFonts.plusJakartaSans(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: historyItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item['date']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item['amount']!,
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
