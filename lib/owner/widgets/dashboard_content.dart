import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/dashboard_provider.dart';
import '../../services/order_service.dart';
import '../../services/constants.dart';
import '../../widgets/skeleton.dart';
import 'order_card.dart';

enum SalesRange { today, weekly, monthly, yearly }

class DashboardContent extends ConsumerWidget {
  final bool isDesktop;
  final SalesRange selectedRange;
  final int selectedMonth;
  final int selectedYear;
  final void Function(SalesRange) onRangeChanged;
  final void Function(int) onMonthChanged;
  final void Function(int) onYearChanged;
  final VoidCallback onViewAllOrders;

  const DashboardContent({
    super.key,
    required this.isDesktop,
    required this.selectedRange,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onRangeChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onViewAllOrders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 24.0,
          vertical: 32.0,
        ),
        children: [
          // Welcome Header
          Text(
            "Hello, Sonna.",
            style: GoogleFonts.notoSerif(
              color: cs.secondary,
              fontSize: isDesktop ? 48 : 36,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "OWNER OVERVIEW",
            style: GoogleFonts.plusJakartaSans(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: isDesktop ? 32 : 20),

          // Stats Section (Using Riverpod)
          _buildQuickStats(ref, cs),
          SizedBox(height: isDesktop ? 32 : 20),

          // Chart Section
          _buildPerformanceChart(context, ref, cs),
          SizedBox(height: isDesktop ? 32 : 20),

          // Recent Orders Header
          _RecentOrdersHeader(
            isDesktop: isDesktop,
            cs: cs,
            onViewAll: onViewAllOrders,
          ),
          SizedBox(height: isDesktop ? 20 : 12),

          // Orders List (Using Riverpod)
          _buildOrdersList(ref, cs),
          SizedBox(height: isDesktop ? 24 : 16),
        ],
      ),
    );
  }

  Widget _buildQuickStats(WidgetRef ref, ColorScheme cs) {
    final stats = ref.watch(dashboardStatsProvider);

    if (stats['isLoading'] == true) {
      return SkeletonWrapper(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : (isDesktop ? 16 : 8)),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 24 : 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: isDesktop ? 20 : 16, width: isDesktop ? 20 : 16),
                      SizedBox(height: isDesktop ? 16 : 8),
                      Skeleton(height: isDesktop ? 28 : 24, width: isDesktop ? 80 : 50),
                      const SizedBox(height: 4),
                      Skeleton(height: isDesktop ? 10 : 8, width: isDesktop ? 60 : 40),
                    ],
                  ),
                ),
              ),
            )),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatCard(title: "TOTAL ORDERS", value: stats['totalOrders'].toString(), icon: Icons.shopping_bag_outlined, cs: cs, isDesktop: isDesktop),
          SizedBox(width: isDesktop ? 16 : 8),
          _StatCard(title: "TOTAL REVENUE", value: OrderService.formatPrice((stats['totalRevenue'] as double) * PriceConstants.minorUnitsPerMajor), icon: Icons.payments_outlined, cs: cs, isDesktop: isDesktop),
          SizedBox(width: isDesktop ? 16 : 8),
          _StatCard(title: "CUSTOMERS", value: stats['activeCustomers'].toString(), icon: Icons.people_outline, cs: cs, isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildOrdersList(WidgetRef ref, ColorScheme cs) {
    final ordersAsync = ref.watch(recentOrdersProvider);

    return ordersAsync.when(
      data: (rawOrders) {
        final orders = rawOrders.take(4).toList();
        if (orders.isEmpty) return const _NoOrdersView();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 16,
            mainAxisExtent: isDesktop ? 140 : 136,
          ),
          itemCount: orders.length,
          itemBuilder:
              (context, index) => OrderCardReactive(data: orders[index]),
        );
      },
      loading:
          () => Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Skeleton(height: 122, width: double.infinity),
              ),
            ),
          ),
      error: (err, st) {
        debugPrint('Failed to load orders: $err\n$st');
        return const Center(child: Text("Failed to load orders"));
      },
    );
  }



  Widget _buildPerformanceChart(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final chartParam = SalesChartParam(
      range: selectedRange.name,
      targetMonth: (selectedRange == SalesRange.monthly) ? selectedMonth : null,
      targetYear:
          (selectedRange == SalesRange.monthly ||
                  selectedRange == SalesRange.yearly)
              ? selectedYear
              : null,
    );
    final salesChartAsync = ref.watch(salesChartProvider(chartParam));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            isDesktop: isDesktop,
            selectedRange: selectedRange,
            cs: cs,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            onRangeChanged: onRangeChanged,
            onMonthChanged: onMonthChanged,
            onYearChanged: onYearChanged,
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: salesChartAsync.when(
              data: (data) => _SalesLineChart(
                data: data,
                selectedRange: selectedRange,
                cs: cs,
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) {
                debugPrint('Chart error: $err');
                return const Center(child: Text("Failed to load chart"));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Internal Helper Widgets (Stateless for performance)

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final ColorScheme cs;
  final bool isDesktop;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.cs,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: cs.primary, size: isDesktop ? 20 : 16),
            SizedBox(height: isDesktop ? 16 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.notoSerif(
                  color: cs.secondary,
                  fontSize: isDesktop ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary.withValues(alpha: 0.4),
                  fontSize: isDesktop ? 10 : 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersHeader extends StatelessWidget {
  final bool isDesktop;
  final ColorScheme cs;
  final VoidCallback onViewAll;

  const _RecentOrdersHeader({
    required this.isDesktop,
    required this.cs,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Orders",
              style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: 24),
            ),
            Text(
              "Latest activity from the boutique",
              style: GoogleFonts.plusJakartaSans(
                color: cs.secondary.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onViewAll,
          child: Text(
            "View All Archives",
            style: GoogleFonts.notoSerif(
              color: cs.primary,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final bool isDesktop;
  final SalesRange selectedRange;
  final int selectedMonth, selectedYear;
  final ColorScheme cs;
  final void Function(SalesRange) onRangeChanged;
  final void Function(int) onMonthChanged;
  final void Function(int) onYearChanged;

  const _ChartHeader({
    required this.isDesktop,
    required this.selectedRange,
    required this.cs,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onRangeChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Orders Performance",
              style: GoogleFonts.notoSerif(
                color: cs.secondary,
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Order count trend analysis",
              style: GoogleFonts.plusJakartaSans(
                color: cs.secondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ChartControls(
          selectedRange: selectedRange,
          cs: cs,
          selectedMonth: selectedMonth,
          selectedYear: selectedYear,
          onRangeChanged: onRangeChanged,
          onMonthChanged: onMonthChanged,
          onYearChanged: onYearChanged,
        ),
      ],
    );
  }
}

class _ChartControls extends StatelessWidget {
  final SalesRange selectedRange;
  final int selectedMonth, selectedYear;
  final ColorScheme cs;
  final void Function(SalesRange) onRangeChanged;
  final void Function(int) onMonthChanged;
  final void Function(int) onYearChanged;

  const _ChartControls({
    required this.selectedRange,
    required this.cs,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onRangeChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children:
                SalesRange.values.map((range) {
                  final isSelected = selectedRange == range;
                  return GestureDetector(
                    onTap: () => onRangeChanged(range),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        range.name.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.white : cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        if (selectedRange == SalesRange.monthly ||
            selectedRange == SalesRange.yearly)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedRange == SalesRange.monthly)
                  DropdownButton<int>(
                    value: selectedMonth,
                    underline: const SizedBox(),
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (m) => m != null ? onMonthChanged(m) : null,
                    items:
                        List.generate(12, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  [
                                    'JAN',
                                    'FEB',
                                    'MAR',
                                    'APR',
                                    'MAY',
                                    'JUN',
                                    'JUL',
                                    'AUG',
                                    'SEP',
                                    'OCT',
                                    'NOV',
                                    'DEC',
                                  ][m - 1],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedYear,
                  underline: const SizedBox(),
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (y) => y != null ? onYearChanged(y) : null,
                  items:
                      List.generate(5, (i) => DateTime.now().year - i)
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text("$y")),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final Map<int, SalesChartDataPoint> data;
  final SalesRange selectedRange;
  final ColorScheme cs;
  final int? selectedMonth;
  final int? selectedYear;

  const _SalesLineChart({
    required this.data,
    required this.selectedRange,
    required this.cs,
    this.selectedMonth,
    this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    double maxOrders = 5.0;
    for (var v in data.values) {
      if (v.count > maxOrders) maxOrders = v.count.toDouble();
    }
    // Round up maxOrders for clean grid lines
    maxOrders = (maxOrders / 5).ceil() * 5.0;
    if (maxOrders == 0) maxOrders = 5.0;

    final List<FlSpot> spots = [];
    final sortedKeys = data.keys.toList()..sort();

    // Add a starting zero point if the first data point isn't at the start of the range
    final minX = _getMinX();
    if (!data.containsKey(minX.toInt())) {
      spots.add(FlSpot(minX, 0));
    }

    for (var key in sortedKeys) {
      spots.add(FlSpot(key.toDouble(), (data[key]?.count ?? 0).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxOrders / 5,
          getDrawingHorizontalLine:
              (_) => FlLine(
                color: cs.secondary.withValues(alpha: 0.05),
                strokeWidth: 1,
              ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => cs.surfaceContainerHigh,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((barSpot) {
                final point = data[barSpot.x.toInt()];
                final count = point?.count ?? 0;
                final amount = point?.amount ?? 0.0;
                final formattedAmount = "${PriceConstants.currencySymbol}${amount.toStringAsFixed(0)}";
                return LineTooltipItem(
                  'Orders: $count\nAmount: $formattedAmount',
                  GoogleFonts.plusJakartaSans(
                    color: cs.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxOrders / 5,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary.withValues(alpha: 0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: selectedRange == SalesRange.monthly ? 5 : 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (selectedRange == SalesRange.today) {
                  if (value % 4 == 0) text = "${value.toInt()}h";
                } else if (selectedRange == SalesRange.weekly) {
                  text =
                      [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN',
                      ][(value.toInt() - 1) % 7];
                } else if (selectedRange == SalesRange.monthly) {
                  if (value % 5 == 0) text = "D${value.toInt()}";
                } else if (selectedRange == SalesRange.yearly) {
                  text =
                      [
                        'JAN',
                        'FEB',
                        'MAR',
                        'APR',
                        'MAY',
                        'JUN',
                        'JUL',
                        'AUG',
                        'SEP',
                        'OCT',
                        'NOV',
                        'DEC',
                      ][(value.toInt() - 1) % 12];
                }
                return text.isEmpty
                    ? const SizedBox()
                    : Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.secondary.withValues(alpha: 0.4),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: _getMinX(),
        maxX: _getMaxX(),
        minY: 0,
        maxY: maxOrders,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMinX() {
    switch (selectedRange) {
      case SalesRange.today:
        return 0;
      case SalesRange.weekly:
        return 1;
      case SalesRange.monthly:
        return 1;
      case SalesRange.yearly:
        return 1;
    }
  }

  double _getMaxX() {
    switch (selectedRange) {
      case SalesRange.today:
        return 23;
      case SalesRange.weekly:
        return 7;
      case SalesRange.monthly:
        final m = selectedMonth ?? DateTime.now().month;
        final y = selectedYear ?? DateTime.now().year;
        return DateTime(y, m + 1, 0).day.toDouble();
      case SalesRange.yearly:
        return 12;
    }
  }
}

class _NoOrdersView extends StatelessWidget {
  const _NoOrdersView();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: cs.primary.withValues(alpha: 0.1),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "No active creations.",
              style: GoogleFonts.notoSerif(
                color: cs.secondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

