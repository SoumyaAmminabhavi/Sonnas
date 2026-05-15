import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import 'package:intl/intl.dart';
import 'expense_reports_page.dart';
import 'sales_reports_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> with SingleTickerProviderStateMixin {
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

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: OrderService.getAllOrdersStream(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final pendingOrders = orders.where((o) => (o['paymentStatus'] ?? 'PENDING') == 'PENDING').toList();
        final completedHistory = orders.where((o) {
          if ((o['paymentStatus'] ?? 'PENDING') != 'PAID') return false;
          final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
          if (date == null) return false;
          return date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).toList();

        double totalPending = 0;
        for (var o in pendingOrders) {
          totalPending += (double.tryParse(o['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0) / 100.0;
        }

        double weeklyGross = 0;
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        for (var o in orders) {
          if ((o['paymentStatus'] ?? 'PENDING') == 'PAID') {
            final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
            if (date != null && date.isAfter(sevenDaysAgo)) {
              weeklyGross += (double.tryParse(o['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0') ?? 0) / 100.0;
            }
          }
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              toolbarHeight: 0,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: cs.primary,
                unselectedLabelColor: cs.secondary.withValues(alpha: 0.5),
                indicatorColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: "PAYMENTS"),
                  Tab(text: "EXPENSES"),
                  Tab(text: "SALES REPORTS"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildPaymentsView(context, isDesktop, weeklyGross, totalPending, pendingOrders, completedHistory),
                const ExpenseReportsPage(),
                const SalesReportsPage(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsView(BuildContext context, bool isDesktop, double weeklyGross, double totalPending, List<Map<String, dynamic>> pendingOrders, List<Map<String, dynamic>> completedHistory) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40.0 : 20.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactHero(context, isDesktop, weeklyGross, totalPending),
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
                      _buildPaymentList(context, pendingOrders, completedHistory),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 2,
                  child: _buildHistorySection(context, isCompact: true, recentCompleted: completedHistory),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildTabs(context),
                const SizedBox(height: 24),
                _buildPaymentList(context, pendingOrders, completedHistory),
                const SizedBox(height: 48),
                _buildHistorySection(context, isCompact: false, recentCompleted: completedHistory),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactHero(BuildContext context, bool isDesktop, double weeklyGross, double totalPending) {
    final cs = Theme.of(context).colorScheme;
    final monthName = DateFormat('MMMM').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
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
                    _buildCompactStat(context, "WEEKLY GROSS", "₹${weeklyGross.toInt()}", cs.onSurface),
                    _buildCompactStat(context, "PENDING", "₹${totalPending.toInt()}", cs.primary),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop)
            Container(
              height: 100,
              width: 1,
              color: cs.secondary.withValues(alpha: 0.05),
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
          if (isDesktop)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Month of $monthName",
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary.withValues(alpha: 0.3),
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
        Tab(text: "RECENTLY COMPLETED"),
      ],
    );
  }

  Widget _buildPaymentList(BuildContext context, List<Map<String, dynamic>> pending, List<Map<String, dynamic>> completed) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final items = _tabController.index == 0 ? pending : completed;
        
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text(
                "No payments found for this category.",
                style: GoogleFonts.notoSerif(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildCompactCard(context, items[index]);
          },
        );
      }
    );
  }

  Widget _buildCompactCard(BuildContext context, Map<String, dynamic> item) {
    final cs = Theme.of(context).colorScheme;
    final String status = item['paymentStatus'] ?? 'PENDING';
    final isCompleted = status == 'PAID';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
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
                  "ORDER #${item['orderNumber'] ?? '---'}",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item['customerName'] ?? 'Anonymous',
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['cakeName'] ?? 'Custom Creation',
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
                OrderService.formatPrice(item['totalPrice']),
                style: GoogleFonts.notoSerif(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () async {
                    await OrderService.updatePaymentStatus(item['id'].toString(), 'PAID');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Payment for #${item['orderNumber']} marked as completed"),
                          backgroundColor: cs.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(80, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    "MARK AS PAID",
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "PAID",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary,
                      fontSize: 9,
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

  Widget _buildHistorySection(BuildContext context, {required bool isCompact, required List<Map<String, dynamic>> recentCompleted}) {
    final cs = Theme.of(context).colorScheme;
    
    // Sort and take top 5 for history
    final historyItems = recentCompleted.take(5).toList();

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
        if (historyItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "No completed payments in the last 7 days.",
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: historyItems.map((item) {
                final date = DateTime.tryParse(item['createdAt']?.toString() ?? '');
                final dateStr = date != null ? DateFormat('MMM d, h:mm a').format(date) : 'Recently';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['customerName'] ?? 'Anonymous',
                              style: GoogleFonts.plusJakartaSans(
                                color: cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: cs.secondary.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        OrderService.formatPrice(item['totalPrice']),
                        style: GoogleFonts.notoSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
    }
}
