import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/report_service.dart';
import '../widgets/owner_sidebar.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  Map<String, double> _categorySales = {};
  List<Map<String, dynamic>> _topItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final orders = await SupabaseService.fetchOrders();
      final menu = await SupabaseService.fetchMenu();

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(orders);
          _calculateMetrics();
        });
      }

      // Fetch items for top items analysis
      List<Map<String, dynamic>> allItems = [];
      for (var order in _orders.take(30)) { // Analyze more orders for better stats
        final items = await SupabaseService.fetchOrderItems(order['id']);
        allItems.addAll(items);
      }

      if (mounted) {
        setState(() {
          _processItems(allItems, menu);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading report data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateMetrics() {
    _totalRevenue = 0;
    _totalOrders = _orders.length;

    for (var order in _orders) {
      final priceStr = order['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0';
      final total = double.tryParse(priceStr) ?? 0.0;
      _totalRevenue += total;
    }

    _avgOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
  }

  void _processItems(List<Map<String, dynamic>> items, List<Map<String, dynamic>> menu) {
    _categorySales = {};
    Map<String, int> itemCounts = {};
    Map<String, Map<String, dynamic>> itemDetails = {};

    for (var item in items) {
      final String cakeName = item['cakeName']?.toString() ?? 'Custom Selection';
      
      // Match with menu to get category and image
      final matchingCake = menu.firstWhere(
        (c) => (c['name'] as String).toLowerCase() == cakeName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      final category = matchingCake['category'] ?? 'Custom';
      final priceStr = item['price']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final subtotal = price * qty;

      _categorySales[category] = (_categorySales[category] ?? 0) + subtotal;

      itemCounts[cakeName] = (itemCounts[cakeName] ?? 0) + qty;
      itemDetails[cakeName] = {
        'image': matchingCake['image'],
        'category': category,
      };
    }

    // Top items
    if (itemCounts.isNotEmpty) {
      var sortedItems = itemCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _topItems = sortedItems.take(5).map((e) {
        final details = itemDetails[e.key] ?? {};
        return {
          'name': e.key,
          'count': e.value,
          'image': SupabaseService.getPublicUrl(details['image']?.toString()),
          'category': details['category']?.toString() ?? 'Delicacy',
        };
      }).toList();
    }
  }

  List<FlSpot> _generateChartSpots() {
    if (_orders.isEmpty) return [const FlSpot(0, 0)];
    
    // Take last 7 orders for demo trend
    final recent = _orders.take(7).toList().reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < recent.length; i++) {
      final priceStr = recent[i]['totalPrice']?.toString().replaceAll('₹', '').replaceAll(',', '') ?? '0';
      final amount = double.tryParse(priceStr) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), amount));
    }
    if (spots.isEmpty) return [const FlSpot(0, 0)];
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: isDesktop 
                ? null 
                : IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: Text(
              "Sonna's Patisserie & Cafe",
              style: GoogleFonts.notoSerif(
                color: cs.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: 4, // Still in Settings category
                  onTap: (index) {
                    Navigator.pop(context, index);
                  },
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [
                          _buildSliverAppBar(cs),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMetricsGrid(cs),
                                  const SizedBox(height: 32),
                                  _buildRevenueChart(cs, isDark),
                                  const SizedBox(height: 32),
                                  _buildSecondaryStats(cs, isDark),
                                  const SizedBox(height: 64),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              "Sales Intelligence",
              style: GoogleFonts.notoSerif(
                color: cs.secondary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'pdf') {
                  ReportService.downloadPDF(_orders, _totalRevenue, _totalOrders, _avgOrderValue, _categorySales);
                } else if (value == 'csv') {
                  ReportService.downloadCSV(_orders, _totalRevenue, _totalOrders);
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
                    Text(
                      "Export",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red[400], size: 20),
                      const SizedBox(width: 12),
                      const Text("Download PDF"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.green[400], size: 20),
                      const SizedBox(width: 12),
                      const Text("Download CSV"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.refresh, color: cs.primary),
              onPressed: _loadData,
            ),
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
          _buildMetricCard(
            cs,
            "Total Revenue",
            NumberFormat.currency(symbol: "₹", decimalDigits: 0).format(_totalRevenue),
            Icons.account_balance_wallet_outlined,
            const Color(0xFFFF4D8D),
          ),
          _buildMetricCard(
            cs,
            "Total Orders",
            _totalOrders.toString(),
            Icons.shopping_bag_outlined,
            const Color(0xFF701235),
          ),
          _buildMetricCard(
            cs,
            "Avg. Order",
            NumberFormat.currency(symbol: "₹", decimalDigits: 0).format(_avgOrderValue),
            Icons.analytics_outlined,
            Colors.blueGrey,
          ),
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
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: accent, size: 20),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.notoSerif(
              color: cs.secondary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          LinearProgressIndicator(
            value: 0.7, // Demo value
            backgroundColor: accent.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ColorScheme cs, bool isDark) {
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
          Text(
            "Revenue Trends",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Daily performance over the last 7 entries",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.secondary.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "D${value.toInt() + 1}",
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateChartSpots(),
                    isCurved: true,
                    color: const Color(0xFFFF4D8D),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF4D8D).withValues(alpha: 0.1),
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


  Widget _buildSecondaryStats(ColorScheme cs, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTwoCol = constraints.maxWidth > 800;
      if (isTwoCol) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildTopItems(cs)),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: _buildCategoryBreakdown(cs)),
          ],
        );
      }
      return Column(
        children: [
          _buildTopItems(cs),
          const SizedBox(height: 32),
          _buildCategoryBreakdown(cs),
        ],
      );
    });
  }

  Widget _buildTopItems(ColorScheme cs) {
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
          Text(
            "Top Selling Delicacies",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ..._topItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item['image'] ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 48,
                      height: 48,
                      color: cs.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.cake, color: cs.primary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item['category'],
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.secondary.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${item['count']} sold",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: (_topItems.isNotEmpty && (_topItems.first['count'] as int) > 0)
                            ? (item['count'] as int) / (_topItems.first['count'] as int)
                            : 0,
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        borderRadius: BorderRadius.circular(2),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ColorScheme cs) {
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
          Text(
            "Category Mix",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: _generatePieSections(cs),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ..._categorySales.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  e.key,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: cs.secondary.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  NumberFormat.currency(symbol: "₹", decimalDigits: 0).format(e.value),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(ColorScheme cs) {
    List<PieChartSectionData> sections = [];
    final total = _categorySales.values.fold(0.0, (a, b) => a + b);
    
    _categorySales.forEach((key, value) {
      final percentage = (value / total) * 100;
      sections.add(PieChartSectionData(
        color: _getCategoryColor(key),
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    });
    
    return sections;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cake':
      case 'cakes':
        return const Color(0xFFFF4D8D);
      case 'pastry':
      case 'pastries':
        return const Color(0xFF701235);
      case 'artisan':
        return const Color(0xFF964261);
      default:
        return Colors.blueGrey;
    }
  }
}
