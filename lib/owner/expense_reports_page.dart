import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/finance_service.dart';
import '../services/report_service.dart';
import '../services/constants.dart';

class ExpenseReportsPage extends StatefulWidget {
  final VoidCallback? onClose;
  const ExpenseReportsPage({super.key, this.onClose});

  @override
  State<ExpenseReportsPage> createState() => _ExpenseReportsPageState();
}

enum _SalesRange { today, weekly, monthly, yearly }

class _ExpenseReportsPageState extends State<ExpenseReportsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpenses = 0;
  double _monthlyBurn = 0;
  String _topCategory = "N/A";
  Map<String, double> _categoryBreakdown = {};
  String? _hoveredCategory;
  _SalesRange _selectedRange = _SalesRange.weekly;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _categories = [
    'Ingredients',
    'Packaging',
    'Rent',
    'Utilities',
    'Salaries',
    'Marketing',
    'Maintenance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final expenses = await FinanceService.fetchExpenses();
      if (mounted) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(expenses);
          _calculateMetrics();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading expense data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to fetch finance data. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _calculateMetrics() {
    _totalExpenses = 0;
    _categoryBreakdown = {};
    double currentMonthTotal = 0;
    final now = DateTime.now();

    for (var exp in _expenses) {
      final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
      final category = exp['category']?.toString() ?? 'Other';
      final date = DateTime.tryParse(exp['date']?.toString() ?? '') ?? now;

      _totalExpenses += amount;
      _categoryBreakdown[category] = (_categoryBreakdown[category] ?? 0) + amount;

      if (date.month == now.month && date.year == now.year) {
        currentMonthTotal += amount;
      }
    }

    _monthlyBurn = currentMonthTotal;

    if (_categoryBreakdown.isNotEmpty) {
      var sorted = _categoryBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topCategory = sorted.first.key;
    }
  }



  void _showAddExpenseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddExpenseDialog(
        categories: _categories,
        onSave: (expense) async {
          final messenger = ScaffoldMessenger.of(context);
          await FinanceService.addExpense(expense);
          await _loadData();
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Expense logged successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.onClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onClose?.call();
        }
      },
      child: Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Log Expense"),
      ),
      body: _isLoading
          ? _buildSkeleton(cs)
          : CustomScrollView(
              slivers: [
               _buildHeader(cs, MediaQuery.sizeOf(context).width > 1100),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricsGrid(cs),
                        const SizedBox(height: 32),
                        _buildTrendChart(cs, isDark),
                        const SizedBox(height: 32),
                        _buildSecondaryStats(cs),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ));
  }

  Widget _buildHeader(ColorScheme cs, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cost Analytics",
              style: GoogleFonts.notoSerif(
                fontSize: isDesktop ? 48 : 36,
                color: cs.secondary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Expense Overview",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pdf') {
                      await ReportService.downloadExpensePDF(_expenses, _totalExpenses, _categoryBreakdown);
                    } else if (value == 'csv') {
                      await ReportService.downloadExpenseCSV(_expenses, _totalExpenses);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: cs.primary, size: 18),
                        const SizedBox(width: 8),
                        Text("Export", style: GoogleFonts.plusJakartaSans(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pdf', child: Text("Download PDF")),
                    const PopupMenuItem(value: 'csv', child: Text("Download CSV")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: cs.secondary.withValues(alpha: 0.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(ColorScheme cs) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return GridView.count(
        crossAxisCount: isMobile ? 1 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isMobile ? 2.5 : 1.5,
        children: [
          _buildMetricCard(cs, "Total Life Expense", "${PriceConstants.currencySymbol}${_totalExpenses.toInt()}", Icons.payments_outlined, const Color(0xFF701235)),
          _buildMetricCard(cs, "Current Month Burn", "${PriceConstants.currencySymbol}${_monthlyBurn.toInt()}", Icons.local_fire_department_outlined, Colors.orange),
          _buildMetricCard(cs, "Top Spending Area", _topCategory, Icons.pie_chart_outline, Colors.blueGrey),
        ],
      );
    });
  }

  Widget _buildMetricCard(ColorScheme cs, String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(icon, color: accent, size: 20),
            ],
          ),
          Text(value, style: GoogleFonts.notoSerif(color: cs.secondary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _isInTimeWindow(DateTime date, _SalesRange range) {
    final now = DateTime.now();
    switch (range) {
      case _SalesRange.today:
        final today = DateTime(now.year, now.month, now.day);
        return date.isAfter(today.subtract(const Duration(days: 1))) && date.isBefore(today.add(const Duration(days: 1)));
      case _SalesRange.weekly:
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1))) && date.isBefore(weekStart.add(const Duration(days: 7)));
      case _SalesRange.monthly:
        final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
        final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 1);
        return date.isAfter(monthStart.subtract(const Duration(days: 1))) && date.isBefore(monthEnd);
      case _SalesRange.yearly:
        final yearStart = DateTime(_selectedYear, 1, 1);
        final yearEnd = DateTime(_selectedYear + 1, 1, 1);
        return date.isAfter(yearStart.subtract(const Duration(days: 1))) && date.isBefore(yearEnd);
    }
  }

  int _getTimeBucket(DateTime date, _SalesRange range) {
    switch (range) {
      case _SalesRange.today: return date.hour;
      case _SalesRange.weekly: return date.weekday;
      case _SalesRange.monthly: return date.day;
      case _SalesRange.yearly: return date.month;
    }
  }

  double _getMinX() {
    switch (_selectedRange) {
      case _SalesRange.today: return 0;
      case _SalesRange.weekly: return 1;
      case _SalesRange.monthly: return 1;
      case _SalesRange.yearly: return 1;
    }
  }

  double _getMaxX() {
    switch (_selectedRange) {
      case _SalesRange.today: return 23;
      case _SalesRange.weekly: return 7;
      case _SalesRange.monthly: return DateTime(_selectedYear, _selectedMonth + 1, 0).day.toDouble();
      case _SalesRange.yearly: return 12;
    }
  }

  List<FlSpot> _generateExpenseSpots() {
    if (_expenses.isEmpty) return [const FlSpot(0, 0)];

    final filtered = _expenses.where((e) {
      final dateStr = e['date']?.toString();
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      return date != null && _isInTimeWindow(date, _selectedRange);
    }).toList();

    if (filtered.isEmpty) return [const FlSpot(0, 0)];

    Map<int, double> buckets = {};
    for (var exp in filtered) {
      final dateStr = exp['date']?.toString();
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = _getTimeBucket(date, _selectedRange);
      final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
      buckets[key] = (buckets[key] ?? 0) + amount;
    }

    if (buckets.isEmpty) return [const FlSpot(0, 0)];

    List<FlSpot> spots = [];
    final sortedKeys = buckets.keys.toList()..sort();
    for (var key in sortedKeys) {
      spots.add(FlSpot(key.toDouble(), buckets[key]!));
    }
    return spots;
  }

  Widget _buildTrendChart(ColorScheme cs, bool isDark) {
    final spots = _generateExpenseSpots();
    final amounts = spots.map((s) => s.y).toList();
    double maxAmount = 500.0;
    for (var v in amounts) {
      if (v > maxAmount) maxAmount = v;
    }
    maxAmount = (maxAmount / 5).ceil() * 5.0;
    if (maxAmount == 0) maxAmount = 500.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Expense Trends", style: GoogleFonts.plusJakartaSans(color: cs.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Expenses aggregated by ${_selectedRange.name}", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: _SalesRange.values.map((range) {
                        final isSelected = _selectedRange == range;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedRange = range;
                            if (range == _SalesRange.monthly || range == _SalesRange.yearly) {
                              _selectedYear = DateTime.now().year;
                            }
                            if (range == _SalesRange.monthly) {
                              _selectedMonth = DateTime.now().month;
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  if (_selectedRange == _SalesRange.monthly || _selectedRange == _SalesRange.yearly)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedRange == _SalesRange.monthly)
                            DropdownButton<int>(
                              value: _selectedMonth,
                              underline: const SizedBox(),
                              style: GoogleFonts.plusJakartaSans(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              onChanged: (m) => m != null ? setState(() => _selectedMonth = m) : null,
                              items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][m - 1]),
                              )).toList(),
                            ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedYear,
                            underline: const SizedBox(),
                            style: GoogleFonts.plusJakartaSans(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            onChanged: (y) => y != null ? setState(() => _selectedYear = y) : null,
                            items: List.generate(5, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount / 5,
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
                        final amount = barSpot.y;
                        final formattedAmount = "${PriceConstants.currencySymbol}${amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}";
                        return LineTooltipItem(
                          'Total: $formattedAmount',
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
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxAmount / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            "${PriceConstants.currencySymbol}${value.toInt()}",
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
                      interval: _selectedRange == _SalesRange.monthly ? 5 : 1,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (_selectedRange == _SalesRange.today) {
                          if (value % 4 == 0) text = "${value.toInt()}h";
                        } else if (_selectedRange == _SalesRange.weekly) {
                          text = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][(value.toInt() - 1) % 7];
                        } else if (_selectedRange == _SalesRange.monthly) {
                          if (value % 5 == 0) text = "D${value.toInt()}";
                        } else {
                          text = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][(value.toInt() - 1) % 12];
                        }
                        return text.isEmpty
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.only(top: 8.0),
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
                maxY: maxAmount,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.7)]),
                    barWidth: 4,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(ColorScheme cs) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;
      final recentExpenses = Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Expenses", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            ..._expenses.take(10).map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text((e['title'] as String?) ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text((e['category'] as String?) ?? 'Other'),
              trailing: Text("${PriceConstants.currencySymbol}${e['amount']}", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ],
        ),
      );

      final categoryMix = Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category Mix", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _categoryBreakdown.entries.map((e) {
                    final total = _categoryBreakdown.values.fold(0.0, (a, b) => a + b);
                    final percentage = total > 0 ? (e.value / total) * 100 : 0;
                    final isHovered = _hoveredCategory == e.key;
                    return PieChartSectionData(
                      value: e.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: _getCategoryColor(e.key),
                      radius: isHovered ? 52 : 40,
                      titleStyle: GoogleFonts.plusJakartaSans(
                        fontSize: isHovered ? 11 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _hoveredCategory = null;
                          return;
                        }
                        final touchedIndex = response.touchedSection!.touchedSectionIndex;
                        if (touchedIndex >= 0 && touchedIndex < _categoryBreakdown.entries.length) {
                          _hoveredCategory = _categoryBreakdown.entries.elementAt(touchedIndex).key;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._categoryBreakdown.entries.map((e) {
              final isHovered = _hoveredCategory == e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isHovered ? 16 : 12,
                      height: isHovered ? 16 : 12,
                      decoration: BoxDecoration(color: _getCategoryColor(e.key), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${PriceConstants.currencySymbol}${e.value.toInt()}", style: TextStyle(fontWeight: isHovered ? FontWeight.bold : FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      );

      if (isMobile) {
        return Column(
          children: [
            recentExpenses,
            const SizedBox(height: 24),
            categoryMix,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: recentExpenses),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: categoryMix),
        ],
      );
    });
  }


  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('ingredient')) return Colors.green;
    if (cat.contains('rent')) return Colors.blue;
    if (cat.contains('utilit')) return Colors.orange;
    if (cat.contains('salary')) return Colors.purple;
    if (cat.contains('market')) return Colors.pink;
    return Colors.grey;
  }

  Widget _buildSkeleton(ColorScheme cs) {
    final shimmerBase = cs.surfaceContainerHighest;
    final shimmerHighlight = cs.surfaceContainer;

    Widget box({double? width, double height = 16, double radius = 12}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title
            box(width: 220, height: 44, radius: 10),
            const SizedBox(height: 16),
            box(width: 160, height: 14, radius: 8),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 32),

            // 3 metric cards
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return GridView.count(
                crossAxisCount: isMobile ? 1 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isMobile ? 2.5 : 1.5,
                children: List.generate(3, (_) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          box(width: 110, height: 12),
                          box(width: 20, height: 20, radius: 4),
                        ],
                      ),
                      box(width: 80, height: 28, radius: 8),
                      box(width: double.infinity, height: 4, radius: 4),
                    ],
                  ),
                )),
              );
            }),
            const SizedBox(height: 32),

            // Trend chart card
            Container(
              height: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 160, height: 18, radius: 8),
                  const SizedBox(height: 8),
                  box(width: 200, height: 12),
                  const Spacer(),
                  // Fake bar chart lines
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [80.0, 130.0, 60.0, 150.0, 100.0, 90.0, 120.0]
                        .map((h) => Container(
                              width: 24,
                              height: h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bottom: Recent Expenses + Category Mix
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;

              Widget recentCard = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 160, height: 18, radius: 8),
                    const SizedBox(height: 24),
                    ...List.generate(6, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        children: [
                          box(width: 36, height: 36, radius: 8),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                box(height: 13, radius: 6),
                                const SizedBox(height: 6),
                                box(width: 90, height: 10, radius: 6),
                              ],
                            ),
                          ),
                          box(width: 60, height: 16, radius: 6),
                        ],
                      ),
                    )),
                  ],
                ),
              );

              Widget categoryCard = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 140, height: 18, radius: 8),
                    const SizedBox(height: 24),
                    // Fake pie circle
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(5, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          box(width: 12, height: 12, radius: 6),
                          const SizedBox(width: 8),
                          Expanded(child: box(height: 11, radius: 6)),
                          const SizedBox(width: 8),
                          box(width: 50, height: 11, radius: 6),
                        ],
                      ),
                    )),
                  ],
                ),
              );

              if (isMobile) {
                return Column(children: [
                  recentCard,
                  const SizedBox(height: 24),
                  categoryCard,
                ]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: recentCard),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: categoryCard),
                ],
              );
            }),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final List<String> categories;
  final Future<void> Function(Map<String, dynamic> expense) onSave;

  const _AddExpenseDialog({
    required this.categories,
    required this.onSave,
  });

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController descController;
  late String selectedCategory;
  late DateTime selectedDate;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    amountController = TextEditingController();
    descController = TextEditingController();
    selectedCategory = widget.categories.first;
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSaving,
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Log New Expense",
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: _inputDecoration("Expense Title (e.g. Flour 50kg)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Amount (${PriceConstants.currencySymbol})"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: _inputDecoration("Category"),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (!context.mounted) return;
                  if (date != null) setState(() => selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: _inputDecoration("Notes (Optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Title and amount are required."),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final rawAmount = amountController.text.trim()
                  .replaceAll(PriceConstants.currencySymbol, '')
                  .replaceAll(',', '')
                  .replaceAll(' ', '');
              final amount = double.tryParse(rawAmount);
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Enter a valid non-negative amount."),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final expense = {
                'title': titleController.text,
                'amount': amount,
                'category': selectedCategory,
                'date': selectedDate.toIso8601String(),
                'description': descController.text,
              };

              setState(() => isSaving = true);
              try {
                await widget.onSave(expense);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint("Expense Log Error: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to log expense"),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => isSaving = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Save Expense"),
          ),
        ],
      ),
    );
  }
}
