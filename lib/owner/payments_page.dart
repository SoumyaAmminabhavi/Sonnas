import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 24.0,
          vertical: 32.0,
        ),
        children: [
          _buildHeroSection(context, isDesktop),
          const SizedBox(height: 48),
          _buildTabs(context),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                return _buildPendingGrid(context, isDesktop);
              } else {
                return _buildCompletedGrid(context, isDesktop);
              }
            },
          ),
          const SizedBox(height: 64),
          _buildHistorySection(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SONNA'S REVENUE",
                style: GoogleFonts.plusJakartaSans(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: isDesktop ? 64 : 40,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: "Financial\n"),
                    TextSpan(
                      text: "Overview",
                      style: GoogleFonts.notoSerif(
                        fontStyle: FontStyle.italic,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildStat(context, "WEEKLY GROSS", "₹12,480", cs.onSurface),
                  const SizedBox(width: 48),
                  _buildStat(context, "PENDING", "₹286", cs.primary),
                ],
              ),
            ],
          ),
        ),
        if (isDesktop)
          Expanded(
            flex: 5,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: -32,
                  left: -32,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.035, // 2 degrees in radians
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.secondary.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Image.network(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuDLgTd3sT9MGvor_eOWALRzNAkMhYFIfuN4m2hav6d1I_IQ0rtw2Akg4gL_LwpijH6guIKyHN7OlZgQvfHjvk0mYuEtR6bF68iZyzBM-sbDt-ArO5pd6L0g0XYIy3GPDyIGo38l-OuQG9SuhAb--HSh3jkLR_uDTTc9NeChlAhlSVt-mFqikgv7WWf8etKb_3NRufxRzWfLAduneoPWi-SvPwZokI21ZYnqK8niPOo6UeQOkbq0EvGaGm5Ove7Lwsyk0cL-rkuNDPkv",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStat(
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
            color: const Color(0xFF825433).withOpacity(0.6),
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            color: valueColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD8C1C6).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: cs.primary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelColor: cs.primary,
        unselectedLabelColor: cs.secondary.withOpacity(0.5),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
        tabs: const [
          Tab(text: "PENDING"),
          Tab(text: "COMPLETED"),
        ],
      ),
    );
  }

  Widget _buildPendingGrid(BuildContext context, bool isDesktop) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('Order')
          .stream(primaryKey: ['id'])
          .inFilter('status', ['PENDING', 'CONFIRMED'])
          .order('createdAt', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return _buildEmptyPaymentsState(context, "No Pending Payments");
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100 ? 3 : constraints.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: 320,
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final priceVal = (double.tryParse(order['totalPrice']?.toString() ?? '0') ?? 0.0) / 100.0;
                
                return _buildPaymentCard(context, {
                  "id": "#${order['orderNumber']?.toString().split('-').last ?? '0000'}",
                  "name": order['customerName'] ?? "Guest",
                  "amount": "₹${priceVal.toStringAsFixed(0)}",
                  "description": "Order for ${order['customerPhone'] ?? 'Unknown'}\n${order['address'] ?? 'Self-Pickup'}",
                  "orderId": order['id'].toString(),
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, String> item) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: cs.secondary.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ORDER ${item['id']}",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['name']!,
                    style: GoogleFonts.notoSerif(color: cs.onSurface, fontSize: 24),
                  ),
                ],
              ),
              Icon(Icons.receipt_long, color: cs.primaryContainer.withOpacity(0.4)),
            ],
          ),
          const Spacer(),
          Text(
            item['amount']!,
            style: GoogleFonts.notoSerif(color: cs.onSurface, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.0),
          ),
          Text(
            item['description']!,
            style: GoogleFonts.notoSerif(color: cs.secondary.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
            ),
            child: TextButton(
              onPressed: () async {
                final supabase = Supabase.instance.client;
                await supabase.from('Order').update({'status': 'CONFIRMED'}).eq('id', item['orderId']!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment marked as received")));
                }
              },
              child: Text(
                "MARK AS PAID",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedGrid(BuildContext context, bool isDesktop) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('Order')
          .stream(primaryKey: ['id'])
          .inFilter('status', ['DELIVERED', 'COMPLETED'])
          .order('createdAt', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return _buildEmptyPaymentsState(context, "No Completed Payments");
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100 ? 3 : constraints.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: 320,
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final priceVal = (double.tryParse(order['totalPrice']?.toString() ?? '0') ?? 0.0) / 100.0;
                
                return _buildPaymentCard(context, {
                  "id": "#${order['orderNumber']?.toString().split('-').last ?? '0000'}",
                  "name": order['customerName'] ?? "Guest",
                  "amount": "₹${priceVal.toStringAsFixed(0)}",
                  "description": "${order['customerPhone'] ?? 'Unknown'} • ${order['address'] ?? 'Pickup'}\nCompleted on ${order['deliveryDate'] ?? 'N/A'}",
                  "orderId": order['id'].toString(),
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyPaymentsState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final historyItems = [
      {
        "recipient": "Laurant Boulangerie",
        "ref": "INV-9902",
        "date": "Oct 24, 2023",
        "amount": "₹1,240",
      },
      {
        "recipient": "Jean-Luc Coffee Roasters",
        "ref": "INV-9901",
        "date": "Oct 22, 2023",
        "amount": "₹845",
      },
      {
        "recipient": "Patisserie Uniforms",
        "ref": "INV-9888",
        "date": "Oct 19, 2023",
        "amount": "₹430",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment History",
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: 28,
                  ),
                ),
                Text(
                  "Archived transactions for the month of October",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.primaryContainer.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                "View Full Ledger",
                style: GoogleFonts.notoSerif(
                  color: cs.primary,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildTableHeader(context),
              ...historyItems.map((item) => _buildTableRow(context, item)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD8C1C6).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText("RECIPIENT", cs)),
          Expanded(flex: 2, child: _headerText("REFERENCE", cs)),
          Expanded(flex: 2, child: _headerText("DATE", cs)),
          Expanded(
            flex: 2,
            child: _headerText("AMOUNT", cs, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _headerText(
    String text,
    ColorScheme cs, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.plusJakartaSans(
        color: cs.secondary.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Map<String, String> item) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD8C1C6).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item['recipient']!,
              style: GoogleFonts.notoSerif(
                color: cs.onSurface,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['ref']!,
              style: GoogleFonts.plusJakartaSans(
                color: cs.secondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['date']!,
              style: GoogleFonts.plusJakartaSans(
                color: cs.secondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['amount']!,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSerif(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
