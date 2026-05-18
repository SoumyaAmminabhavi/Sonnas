import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import '../services/menu_service.dart';
import '../services/report_service.dart';
import '../services/constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SalesReportsPage extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const SalesReportsPage({super.key, this.onClose});

  @override
  ConsumerState<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends ConsumerState<SalesReportsPage> {
  bool _isLoading = true;
  bool _isLoadingData = false;
  List<Map<String, dynamic>> _orders = [];
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  Map<String, double> _categorySales = {};
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _cachedMenu = [];
  String _lastProcessedIds = "";
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  int _pendingFetchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    try {
      final orders = await OrderService.fetchOrders();
      final menu = await MenuService.fetchMenu();

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(orders);
          _calculateMetrics();
          _cachedMenu = List<Map<String, dynamic>>.from(menu);
        });
      }

       // Performance Fix: Use bulk fetch instead of a loop (N+1 fix)
        final paidOrderIds = _paidOrders.map((o) => o['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        if (paidOrderIds.isEmpty) {
          if (mounted) {
            setState(() {
              _pendingFetchVersion++;
              _topItems = [];
              _categorySales = {};
              _lastProcessedIds = '';
              _isLoading = false;
            });
          }
          if (mounted) {
            _setupOrdersSubscription();
          }
          return;
        }
        try {
          final allItems = await OrderService.fetchBulkOrderItems(paidOrderIds);
          if (mounted) {
            setState(() {
              _processItems(allItems, menu);
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint("❌ Failed to fetch bulk items: $e");
          if (mounted) setState(() => _isLoading = false);
        }

        if (mounted) {
          _setupOrdersSubscription();
        }
    } catch (e) {
      debugPrint("Error loading report data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Unable to load sales analytics. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isLoadingData = false;
    }
  }

  List<Map<String, dynamic>> get _paidOrders {
    return _orders.where((order) {
      final pStatus = (order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
      return pStatus == 'PAID';
    }).toList();
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    final valStr = value.toString().trim();
    if (valStr.isEmpty) return 0.0;
    final hasDecimal = valStr.contains('.');
    String str = valStr.replaceAll(RegExp(r'[₹$]'), '')
        .replaceAll(RegExp(r'^(INR|Rs\.?|rs\.?)\s*', caseSensitive: false), '')
        .replaceAll('/-', '')
        .replaceAll(',', '')
        .trim();
    final parsed = double.tryParse(str) ?? 0.0;
    if (hasDecimal) {
      return parsed;
    }
    return parsed / PriceConstants.minorUnitsPerMajor;
  }

  void _calculateMetrics() {
    _totalRevenue = 0;
    final paidOrders = _paidOrders;
    _totalOrders = paidOrders.length;

    for (var order in paidOrders) {
      final total = _parsePrice(order['totalPrice']);
      _totalRevenue += total;
    }

    _avgOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
  }

  void _processItems(List<Map<String, dynamic>> items, List<Map<String, dynamic>> menu) {
    _categorySales = {};
    Map<String, int> itemCounts = {};
    Map<String, Map<String, dynamic>> itemDetails = {};

    for (var item in items) {
      final String? cakeId = item['cakeId']?.toString();
      final String cakeName = item['cakeName']?.toString() ?? 'Custom Selection';
      
      // Match with menu to get category and image (Prefer ID, fallback to name)
      final matchingCake = menu.firstWhere(
        (c) => (cakeId != null && c['id']?.toString() == cakeId) || (c['name']?.toString().toLowerCase() == cakeName.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );

      final category = matchingCake['Category']?['name'] ?? 'Custom';
      final itemPrice = _parsePrice(item['price']);
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final subtotal = itemPrice * qty;

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
        final rawImage = details['image']?.toString();
        final resolvedImage = (rawImage != null && rawImage.isNotEmpty)
            ? SupabaseService.getPublicUrl(rawImage, bucket: 'cakes')
            : null;
        return {
          'name': e.key,
          'count': e.value,
          'image': resolvedImage,
          'category': details['category']?.toString() ?? 'Delicacy',
        };
      }).toList();
    } else {
      _topItems = [];
    }
  }

  void _processItemsFromOrders(List<Map<String, dynamic>> orders, List<Map<String, dynamic>> menu) {
    if (orders.isEmpty) {
      _topItems = [];
      _categorySales = {};
      _lastProcessedIds = '';
      return;
    }
    
    // Performance: Only fetch if order IDs have changed
    final paidOrders = orders.where((order) {
      final pStatus = (order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
      return pStatus == 'PAID';
    }).toList();

    final currentIds = paidOrders.map((o) {
      final id = o['id']?.toString() ?? '';
      final updated = o['updatedAt']?.toString() ?? '';
      return "$id|$updated";
    }).join(',');
    
    if (currentIds == _lastProcessedIds) return;
    _lastProcessedIds = currentIds;

    final ids = paidOrders.map((o) => o['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (ids.isEmpty) {
      _pendingFetchVersion++;
      _topItems = [];
      _categorySales = {};
      _lastProcessedIds = '';
      return;
    }

    final fetchVersion = ++_pendingFetchVersion;

    OrderService.fetchBulkOrderItems(ids).then((items) {
      if (mounted && fetchVersion == _pendingFetchVersion) {
        setState(() {
          _processItems(items, menu);
        });
      }
    }).catchError((e) {
      debugPrint("Error processing live items: $e");
    });
  }

  Widget _buildExportButton(ColorScheme cs) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        try {
          if (value == 'pdf') {
            await ReportService.downloadPDF(_paidOrders, _totalRevenue, _totalOrders, _avgOrderValue, _categorySales);
          } else if (value == 'csv') {
            await ReportService.downloadCSV(_paidOrders, _totalRevenue, _totalOrders);
          }
        } catch (e) {
          debugPrint("Export failed: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Export failed. Please try again."),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Container(
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
              "EXPORT",
              style: GoogleFonts.plusJakartaSans(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text("Download PDF")),
        const PopupMenuItem(value: 'csv', child: Text("Download CSV")),
      ],
    );
  }

  List<FlSpot> _generateChartSpots() {
    final paidOrders = _paidOrders;
    if (paidOrders.isEmpty) return [const FlSpot(0, 0)];
    final recent = paidOrders.take(7).toList().reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < recent.length; i++) {
      final amount = _parsePrice(recent[i]['totalPrice']);
      spots.add(FlSpot(i.toDouble(), amount));
    }
    if (spots.isEmpty) return [const FlSpot(0, 0)];
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildSkeleton(cs);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sales Intelligence",
                    style: GoogleFonts.notoSerif(
                      fontSize: 48,
                      color: cs.secondary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Performance Overview",
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onClose != null)
                            IconButton(
                              icon: Icon(Icons.close, color: cs.secondary.withValues(alpha: 0.4)),
                              onPressed: () => widget.onClose?.call(),
                            ),
                          _buildExportButton(cs),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: cs.secondary.withValues(alpha: 0.1)),
                  const SizedBox(height: 32),
                  _buildMetricsGrid(cs),
                  const SizedBox(height: 32),
                  _buildRevenueChart(cs, isDark),
                  const SizedBox(height: 32),
                  _buildSecondaryStats(cs, isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
            NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(_totalRevenue),
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
            NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(_avgOrderValue),
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
            value: 0.7,
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
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: (_totalRevenue > 100 ? _totalRevenue / 4 : 100),
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}K';
                        } else {
                          text = value.toInt().toString();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            text,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                item['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item['image'],
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 48,
                            height: 48,
                            color: cs.primary.withValues(alpha: 0.05),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (c, e, s) => Container(
                            width: 48,
                            height: 48,
                            color: cs.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.cake, color: cs.primary, size: 20),
                          ),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.cake, color: cs.primary, size: 20),
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
                  NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(e.value),
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
    if (total == 0) return [];
    
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
    final cat = category.toLowerCase();
    if (cat.contains('chocolate')) return const Color(0xFF3E2723);
    if (cat.contains('vanilla')) return const Color(0xFFE1C16E);
    if (cat.contains('tea')) return const Color(0xFF7B8E7E);
    if (cat.contains('seasonal')) return const Color(0xFFC88D67);
    if (cat.contains('pastry')) return const Color(0xFF701235);
    if (cat.contains('cake')) return const Color(0xFFFF4D8D);
    if (cat.contains('artisan')) return const Color(0xFF964261);
    
    final colors = [
      const Color(0xFFFF4D8D),
      const Color(0xFF701235),
      const Color(0xFF964261),
      const Color(0xFF3E2723),
      const Color(0xFF7B8E7E),
      const Color(0xFFC88D67),
      const Color(0xFF5D4037),
      Colors.blueGrey,
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  Widget _buildSkeleton(ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: Shimmer.fromColors(
        baseColor: cs.surfaceContainer,
        highlightColor: cs.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: List.generate(3, (_) => Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                )),
              ),
              const SizedBox(height: 32),
              Container(height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Container(height: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(height: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setupOrdersSubscription() {
    _ordersSubscription?.cancel();
    _ordersSubscription = OrderService.getAllOrdersStream().listen((streamOrders) {
      if (mounted) {
        setState(() {
          final orderMap = <String, Map<String, dynamic>>{};
          for (final o in _orders) {
            final id = o['id']?.toString();
            if (id != null) orderMap[id] = o;
          }
          for (final o in streamOrders) {
            final id = o['id']?.toString();
            if (id != null) orderMap[id] = o;
          }
          final sortedOrders = orderMap.values.toList();
          sortedOrders.sort((a, b) {
            final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          _orders = sortedOrders;
          _calculateMetrics();
          _processItemsFromOrders(_orders, _cachedMenu);
        });
      }
    }, onError: (error) {
      debugPrint("Sales reports stream error: $error");
    });
  }
}
