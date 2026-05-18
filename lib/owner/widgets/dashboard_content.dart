import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/dashboard_provider.dart';
import '../../widgets/skeleton.dart';
import 'order_card.dart';

enum SalesRange { today, weekly, monthly, yearly }

class DashboardContent extends ConsumerWidget {
  final bool isDesktop;
  final SalesRange selectedRange;
  final int selectedMonth;
  final int selectedYear;
  final Function(SalesRange) onRangeChanged;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;
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
            style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: isDesktop ? 48 : 36, height: 1.1),
          ),
          const SizedBox(height: 16),
          Text(
            "OWNER OVERVIEW",
            style: GoogleFonts.plusJakartaSans(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0),
          ),
          const SizedBox(height: 48),

          // Stats Section (Using Riverpod)
          _buildQuickStats(ref, cs),
          const SizedBox(height: 48),

          // Chart Section
          _buildPerformanceChart(context, ref, cs),
          const SizedBox(height: 48),

          // Recent Orders Header
          _RecentOrdersHeader(isDesktop: isDesktop, cs: cs, onViewAll: onViewAllOrders),
          const SizedBox(height: 24),

          // Orders List (Using Riverpod)
          _buildOrdersList(ref, cs),
        ],
      ),
    );
  }

  Widget _buildQuickStats(WidgetRef ref, ColorScheme cs) {
    final stats = ref.watch(dashboardStatsProvider);

    if (stats['isLoading'] == true) {
      return SkeletonWrapper(
        child: Row(
          children: List.generate(3, (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Skeleton(height: 10, width: 60), SizedBox(height: 12), Skeleton(height: 24, width: 40)],
                ),
              ),
            ),
          )),
        ),
      );
    }

    return Row(
      children: [
        _StatCard(title: "TOTAL ORDERS", value: stats['totalOrders'].toString(), icon: Icons.shopping_bag_outlined, cs: cs, isDesktop: isDesktop),
        const SizedBox(width: 8),
        _StatCard(title: "TOTAL REVENUE", value: "₹${stats['totalRevenue'].toInt()}", icon: Icons.payments_outlined, cs: cs, isDesktop: isDesktop),
        const SizedBox(width: 8),
        _StatCard(title: "CUSTOMERS", value: stats['activeCustomers'].toString(), icon: Icons.people_outline, cs: cs, isDesktop: isDesktop),
      ],
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
          itemBuilder: (context, index) => OrderCardReactive(data: orders[index]),
        );
      },
      loading: () => Column(
        children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 16), child: Skeleton(height: 122, width: double.infinity))),
      ),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildPerformanceChart(BuildContext context, WidgetRef ref, ColorScheme cs) {
    final chartParam = SalesChartParam(
      range: selectedRange.name,
      targetMonth: selectedMonth,
      targetYear: selectedYear,
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
            isDesktop: isDesktop, selectedRange: selectedRange, cs: cs,
            selectedMonth: selectedMonth, selectedYear: selectedYear,
            onRangeChanged: onRangeChanged, onMonthChanged: onMonthChanged, onYearChanged: onYearChanged,
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
              error: (err, _) => Center(child: Text("Error: $err")),
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

  const _StatCard({required this.title, required this.value, required this.icon, required this.cs, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 12),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: isDesktop ? 20 : 16),
            SizedBox(height: isDesktop ? 16 : 8),
            Text(value, style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: isDesktop ? 28 : 24, fontWeight: FontWeight.bold)),
            Text(title, style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.4), fontSize: isDesktop ? 10 : 8, fontWeight: FontWeight.bold)),
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

  const _RecentOrdersHeader({required this.isDesktop, required this.cs, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Orders", style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: 24)),
            Text("Latest activity from the boutique", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.6), fontSize: 14)),
          ],
        ),
        InkWell(
          onTap: onViewAll,
          child: Text("View All Archives", style: GoogleFonts.notoSerif(color: cs.primary, fontStyle: FontStyle.italic, fontSize: 14)),
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
  final Function(SalesRange) onRangeChanged;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;

  const _ChartHeader({
    required this.isDesktop, required this.selectedRange, required this.cs,
    required this.selectedMonth, required this.selectedYear,
    required this.onRangeChanged, required this.onMonthChanged, required this.onYearChanged,
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
            Text("Sales Performance", style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold)),
            Text("Revenue trend analysis", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        _ChartControls(
          selectedRange: selectedRange, cs: cs, selectedMonth: selectedMonth, selectedYear: selectedYear,
          onRangeChanged: onRangeChanged, onMonthChanged: onMonthChanged, onYearChanged: onYearChanged,
        ),
      ],
    );
  }
}

class _ChartControls extends StatelessWidget {
  final SalesRange selectedRange;
  final int selectedMonth, selectedYear;
  final ColorScheme cs;
  final Function(SalesRange) onRangeChanged;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;

  const _ChartControls({
    required this.selectedRange, required this.cs, required this.selectedMonth, required this.selectedYear,
    required this.onRangeChanged, required this.onMonthChanged, required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: SalesRange.values.map((range) {
              final isSelected = selectedRange == range;
              return GestureDetector(
                onTap: () => onRangeChanged(range),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Text(range.name.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.white : cs.primary, fontWeight: FontWeight.bold, fontSize: 9)),
                ),
              );
            }).toList(),
          ),
        ),
        if (selectedRange == SalesRange.monthly || selectedRange == SalesRange.yearly)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedRange == SalesRange.monthly)
                  DropdownButton<int>(
                    value: selectedMonth, underline: const SizedBox(),
                    style: GoogleFonts.plusJakartaSans(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    onChanged: (m) => m != null ? onMonthChanged(m) : null,
                    items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1]))).toList(),
                  ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedYear, underline: const SizedBox(),
                  style: GoogleFonts.plusJakartaSans(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  onChanged: (y) => y != null ? onYearChanged(y) : null,
                  items: List.generate(5, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final Map<int, double> data;
  final SalesRange selectedRange;
  final ColorScheme cs;
  final int? selectedMonth;
  final int? selectedYear;

  const _SalesLineChart({required this.data, required this.selectedRange, required this.cs, this.selectedMonth, this.selectedYear});

  @override
  Widget build(BuildContext context) {
    double maxRevenue = 1000;
    for (var v in data.values) { if (v > maxRevenue) maxRevenue = v; }
    maxRevenue = (maxRevenue / 100).ceil() * 100.0 + 100.0;

    final List<FlSpot> spots = [];
    final sortedKeys = data.keys.toList()..sort();
    
    // Add a starting zero point if the first data point isn't at the start of the range
    final minX = _getMinX();
    if (!data.containsKey(minX.toInt())) {
      spots.add(FlSpot(minX, 0));
    }

    for (var key in sortedKeys) {
      spots.add(FlSpot(key.toDouble(), data[key] ?? 0.0));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxRevenue / 4, getDrawingHorizontalLine: (_) => FlLine(color: cs.secondary.withValues(alpha: 0.05), strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 30, interval: selectedRange == SalesRange.monthly ? 5 : 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (selectedRange == SalesRange.today) { if (value % 4 == 0) text = "${value.toInt()}h"; }
                else if (selectedRange == SalesRange.weekly) { text = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][(value.toInt() - 1) % 7]; }
                else if (selectedRange == SalesRange.monthly) { if (value % 5 == 0) text = "D${value.toInt()}"; }
                else if (selectedRange == SalesRange.yearly) { text = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][(value.toInt() - 1) % 12]; }
                return text.isEmpty ? const SizedBox() : Padding(padding: const EdgeInsets.only(top: 10.0), child: Text(text, style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold)));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: _getMinX(),
        maxX: _getMaxX(),
        minY: 0, maxY: maxRevenue,
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
                colors: [cs.primary.withValues(alpha: 0.15), cs.primary.withValues(alpha: 0.0)],
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
            Icon(Icons.auto_awesome_outlined, color: cs.primary.withValues(alpha: 0.1), size: 48),
            const SizedBox(height: 16),
            Text("No active creations.", style: GoogleFonts.notoSerif(color: cs.secondary.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
