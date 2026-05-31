import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../services/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'expense_reports_page.dart';
import 'sales_reports_page.dart';
import '../services/constants.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
                tabs: const [
                  Tab(text: "PAYMENTS"),
                  Tab(text: "EXPENSES"),
                  Tab(text: "SALES REPORTS"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PaymentsTab(cs: cs),
                const ExpenseReportsPage(),
                const SalesReportsPage(),
              ],
            ),
        ),
    );
  }
}

class _PaymentsTab extends ConsumerStatefulWidget {
  final ColorScheme cs;
  const _PaymentsTab({required this.cs});

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> with SingleTickerProviderStateMixin {
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

  void _reloadData() {
    ref.invalidate(ordersStreamProvider);
  }


  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        String paymentStatusOf(Map<String, dynamic> o) =>
            (o['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
        
        DateTime? getPaymentDate(Map<String, dynamic> o) {
          final raw = o['paidAt']?.toString() ?? o['createdAt']?.toString() ?? '';
          return DateTime.tryParse(raw);
        }

        final pendingOrders = orders.where((o) => paymentStatusOf(o) == 'PENDING').toList();
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

        final completedHistory = orders.where((o) {
          if (paymentStatusOf(o) != 'PAID') return false;
          final date = getPaymentDate(o);
          if (date == null) return false;
          return date.isAfter(sevenDaysAgo);
        }).toList()
          ..sort((a, b) {
            final da = getPaymentDate(a);
            final db = getPaymentDate(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

        double totalPending = 0;
        for (var o in pendingOrders) {
          totalPending += PriceConstants.normalizePrice(o['totalPrice']);
        }

        double weeklyGross = 0;
        for (var o in orders) {
          if (paymentStatusOf(o) == 'PAID') {
            final date = getPaymentDate(o);
            if (date != null && date.isAfter(sevenDaysAgo)) {
              weeklyGross += PriceConstants.normalizePrice(o['totalPrice']);
            }
          }
        }

        final isDesktop = MediaQuery.of(context).size.width >= 1100;
        return _buildPaymentsView(context, isDesktop, weeklyGross, totalPending, pendingOrders, completedHistory);
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.cs.primary),
        ),
      ),
      error: (error, stackTrace) {
        debugPrint("❌ Payments load error: $error\n$stackTrace");
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: widget.cs.error.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text("Something went wrong while loading payments", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: widget.cs.error.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              Text("Please try again later or contact support.", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: widget.cs.secondary.withValues(alpha: 0.5))),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _reloadData, child: const Text("RETRY")),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsView(BuildContext context, bool isDesktop, double weeklyGross, double totalPending, List<Map<String, dynamic>> pendingOrders, List<Map<String, dynamic>> completedHistory) {
    
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
          _buildTabs(context),
          const SizedBox(height: 24),
          _buildPaymentList(context, pendingOrders, completedHistory),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _buildCompactStat(context, "WEEKLY GROSS", "${PriceConstants.currencySymbol}${weeklyGross.toStringAsFixed(2)}", cs.onSurface),
                    _buildCompactStat(context, "PENDING", "${PriceConstants.currencySymbol}${totalPending.toStringAsFixed(2)}", cs.primary),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop)
            Container(
              height: 70,
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
        fontSize: 10,
        letterSpacing: 2.0,
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
            return _PaymentCardReactive(item: items[index]);
          },
        );
      }
    );
  }


}

class _PaymentCardReactive extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _PaymentCardReactive({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final String status = (item['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
    final isCompleted = status == 'PAID';
    
    // Watch order items for this order to display actual cake name
    final itemsAsync = ref.watch(orderItemsProvider(item['id']?.toString() ?? ''));

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
                  (item['customerName'] as String?) ?? 'Anonymous',
                  style: GoogleFonts.notoSerif(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                itemsAsync.when(
                  data: (items) {
                    String subtitle = 'Custom Creation';
                    if (items.isNotEmpty) {
                      final String firstName = (items[0]['cakeName'] as String?) ?? 'Boutique Order';
                      subtitle = items.length > 1 ? "$firstName + ${items.length - 1} more" : firstName;
                    }
                    return Text(
                      subtitle,
                      style: GoogleFonts.notoSerif(
                        color: cs.secondary.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                  loading: () => Text(
                    "Loading details...",
                    style: GoogleFonts.notoSerif(
                      color: cs.secondary.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  error: (e, st) => Text(
                    "Custom Creation",
                    style: GoogleFonts.notoSerif(
                      color: cs.secondary.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
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
                    try {
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
                    } catch (e, stackTrace) {
                      debugPrint("❌ Failed to update payment status: $e\n$stackTrace");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to update payment. Please try again."),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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
}
