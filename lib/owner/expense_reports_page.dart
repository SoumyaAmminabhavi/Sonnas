import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/finance_service.dart';
import '../services/report_service.dart';

class ExpenseReportsPage extends StatefulWidget {
  final VoidCallback? onClose;
  const ExpenseReportsPage({super.key, this.onClose});

  @override
  State<ExpenseReportsPage> createState() => _ExpenseReportsPageState();
}

class _ExpenseReportsPageState extends State<ExpenseReportsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpenses = 0;
  double _monthlyBurn = 0;
  String _topCategory = "N/A";
  Map<String, double> _categoryBreakdown = {};

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
          SnackBar(
            content: const Text("Unable to fetch finance data. Please try again."),
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

  List<FlSpot> _generateChartSpots() {
    if (_expenses.isEmpty) return [const FlSpot(0, 0)];
    
    // Group by date for last 7 entries
    final recent = _expenses.take(7).toList().reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < recent.length; i++) {
      final amount = (recent[i]['amount'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), amount));
    }
    return spots;
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = _categories.first;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  decoration: _inputDecoration("Amount (₹)"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: _inputDecoration("Category"),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
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
                    if (date != null) setDialogState(() => selectedDate = date);
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
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || amountController.text.isEmpty) return;
                
                final expense = {
                  'title': titleController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'category': selectedCategory,
                  'date': selectedDate.toIso8601String(),
                  'description': descController.text,
                };

                try {
                  await FinanceService.addExpense(expense);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Expense logged successfully!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Expense Log Error: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Failed to log expense"),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final close = widget.onClose;
          if (close != null) {
            close();
          } else {
            Navigator.of(context).pop();
          }
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
          _buildMetricCard(cs, "Total Life Expense", "₹${_totalExpenses.toInt()}", Icons.payments_outlined, const Color(0xFF701235)),
          _buildMetricCard(cs, "Current Month Burn", "₹${_monthlyBurn.toInt()}", Icons.local_fire_department_outlined, Colors.orange),
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

  Widget _buildTrendChart(ColorScheme cs, bool isDark) {
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
          Text("Expense Trends", style: GoogleFonts.plusJakartaSans(color: cs.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Last 7 transactions trend", style: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 48),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateChartSpots(),
                    isCurved: true,
                    color: cs.primary,
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.1)),
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
              title: Text(e['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(e['category'] ?? 'Other'),
              trailing: Text("₹${e['amount']}", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  sections: _categoryBreakdown.entries.map((e) => PieChartSectionData(
                    value: e.value,
                    title: '',
                    color: _getCategoryColor(e.key),
                    radius: 40,
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._categoryBreakdown.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _getCategoryColor(e.key), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("₹${e.value.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
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
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainer,
      highlightColor: cs.surface,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
