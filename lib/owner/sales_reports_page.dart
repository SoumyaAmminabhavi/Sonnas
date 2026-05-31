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

enum _SalesRange { today, weekly, monthly, yearly }

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
  String? _hoveredCategory;
  _SalesRange _selectedRange = _SalesRange.weekly;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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
          const SnackBar(
            content: Text("Unable to load sales analytics. Please try again."),
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
    return PriceConstants.normalizePrice(value);
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
      String cakeName = item['cakeName']?.toString() ?? 'Custom Selection';
      
      // Normalize: strip size/type suffixes for matching (e.g. "(1kg)", "(Slice)", "(Plate)")
      final normalizedName = cakeName.replaceAll(RegExp(r'\s*\(.*?\)\s*$'), '').trim().toLowerCase();
      
      // Match with menu to get category and image (Prefer ID, fallback to name)
      var matchingCake = <String, dynamic>{};
      if (cakeId != null) {
        matchingCake = menu.firstWhere(
          (c) => c['id']?.toString() == cakeId,
          orElse: () => <String, dynamic>{},
        );
      }
      if (matchingCake.isEmpty) {
        // Try exact match on normalized name
        matchingCake = menu.firstWhere(
          (c) => c['name']?.toString().toLowerCase() == normalizedName,
          orElse: () => <String, dynamic>{},
        );
      }
      if (matchingCake.isEmpty) {
        // Try contains match (handles "Almond Brittle Slice" → "Almond Brittle with Salted Caramel Ganache")
        matchingCake = menu.firstWhere(
          (c) {
            final menuName = c['name']?.toString().toLowerCase() ?? '';
            return menuName.contains(normalizedName) || normalizedName.contains(menuName);
          },
          orElse: () => <String, dynamic>{},
        );
      }
      if (matchingCake.isEmpty) {
        // Try stripping common trailing type words ("slice", "cake", "mousse", etc.)
        final strippedName = normalizedName.replaceAll(RegExp(r'\s+(slice|cake|mousse|macaron|pastry)\s*$'), '').trim();
        if (strippedName != normalizedName) {
          matchingCake = menu.firstWhere(
            (c) {
              final menuName = c['name']?.toString().toLowerCase() ?? '';
              return menuName.contains(strippedName) || strippedName.contains(menuName);
            },
            orElse: () => <String, dynamic>{},
          );
        }
      }

      final String category = (matchingCake['Category']?['name'] as String?) ?? 'Custom';
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
        final rawImage = details['image']?.toString().trim();
        final String? resolvedImage;
        if (rawImage == null || rawImage.isEmpty) {
          resolvedImage = null;
        } else if (rawImage.startsWith('data:') ||
            rawImage.startsWith('http://') ||
            rawImage.startsWith('https://')) {
          // Enforce HTTPS to prevent mixed-content warnings
          resolvedImage = rawImage.startsWith('http://') ? rawImage.replaceFirst('http://', 'https://') : rawImage;
        } else {
          resolvedImage = SupabaseService.getPublicUrl(rawImage, bucket: 'cakes');
        }
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
          _lastProcessedIds = currentIds;
        });
      }
    }).catchError((Object e) {
      debugPrint("Error processing live items: $e");
    });
  }

  Future<void> _showExportDialog(ColorScheme cs, String exportFormat) async {
    String selectedRangeType = 'all';
    DateTimeRange? customRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    String selectedLimit = 'all';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: cs.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            exportFormat == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Export Report",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: cs.secondary,
                                ),
                              ),
                              Text(
                                "Format: ${exportFormat.toUpperCase()}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: cs.secondary.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "SELECT DATE RANGE",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: cs.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: cs.surfaceContainer,
                      initialValue: selectedRangeType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.secondary.withValues(alpha: 0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("All Time")),
                        DropdownMenuItem(value: 'today', child: Text("Today")),
                        DropdownMenuItem(value: '7days', child: Text("Last 7 Days")),
                        DropdownMenuItem(value: '30days', child: Text("Last 30 Days")),
                        DropdownMenuItem(value: 'custom', child: Text("Custom Range...")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedRangeType = val;
                          });
                        }
                      },
                    ),
                    if (selectedRangeType == 'custom') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: customRange!.start,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(context).colorScheme.copyWith(
                                          primary: cs.primary,
                                          onPrimary: Colors.white,
                                          surface: cs.surfaceContainer,
                                          onSurface: cs.secondary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (d != null) {
                                  setDialogState(() {
                                    final end = customRange!.end;
                                    if (d.isAfter(end)) {
                                      customRange = DateTimeRange(start: d, end: d);
                                    } else {
                                      customRange = DateTimeRange(start: d, end: end);
                                    }
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cs.secondary.withValues(alpha: 0.12)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "FROM DATE",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        color: cs.secondary.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(customRange!.start),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: cs.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: customRange!.end,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(context).colorScheme.copyWith(
                                          primary: cs.primary,
                                          onPrimary: Colors.white,
                                          surface: cs.surfaceContainer,
                                          onSurface: cs.secondary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (d != null) {
                                  setDialogState(() {
                                    final start = customRange!.start;
                                    if (d.isBefore(start)) {
                                      customRange = DateTimeRange(start: d, end: d);
                                    } else {
                                      customRange = DateTimeRange(start: start, end: d);
                                    }
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cs.secondary.withValues(alpha: 0.12)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TO DATE",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        color: cs.secondary.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(customRange!.end),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: cs.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      "SELECT ORDER LIMIT",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: cs.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: cs.surfaceContainer,
                      initialValue: selectedLimit,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.secondary.withValues(alpha: 0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("No Limit (All Orders)")),
                        DropdownMenuItem(value: '20', child: Text("Last 20 Orders")),
                        DropdownMenuItem(value: '50', child: Text("Last 50 Orders")),
                        DropdownMenuItem(value: '100', child: Text("Last 100 Orders")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedLimit = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.plusJakartaSans(
                              color: cs.secondary.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'rangeType': selectedRangeType,
                              'customRange': customRange,
                              'limit': selectedLimit,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            "Download",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    final String rangeType = result['rangeType'] as String;
    final DateTimeRange? range = result['customRange'] as DateTimeRange?;
    final String limitStr = result['limit'] as String;

    List<Map<String, dynamic>> filteredOrders = List<Map<String, dynamic>>.from(_paidOrders);

    final now = DateTime.now();
    if (rangeType == 'today') {
      final todayStart = DateTime(now.year, now.month, now.day);
      filteredOrders = filteredOrders.where((o) {
        final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
        return date != null && date.isAfter(todayStart);
      }).toList();
    } else if (rangeType == '7days') {
      final start = now.subtract(const Duration(days: 7));
      filteredOrders = filteredOrders.where((o) {
        final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
        return date != null && date.isAfter(start);
      }).toList();
    } else if (rangeType == '30days') {
      final start = now.subtract(const Duration(days: 30));
      filteredOrders = filteredOrders.where((o) {
        final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
        return date != null && date.isAfter(start);
      }).toList();
    } else if (rangeType == 'custom' && range != null) {
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      filteredOrders = filteredOrders.where((o) {
        final date = DateTime.tryParse(o['createdAt']?.toString() ?? '');
        return date != null && date.isAfter(start) && date.isBefore(end);
      }).toList();
    }

    if (limitStr != 'all') {
      final limitVal = int.tryParse(limitStr) ?? 9999;
      if (filteredOrders.length > limitVal) {
        filteredOrders = filteredOrders.take(limitVal).toList();
      }
    }

    if (filteredOrders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No transactions found for the selected filter."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    double totalRevenue = 0;
    final validOrders = filteredOrders;
    final totalOrders = validOrders.length;
    for (var order in validOrders) {
      totalRevenue += _parsePrice(order['totalPrice']);
    }
    final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    Map<String, double> filteredCategorySales = {};
    final filteredIds = filteredOrders.map((o) => o['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (filteredIds.isNotEmpty) {
      try {
        final items = await OrderService.fetchBulkOrderItems(filteredIds);
        for (var item in items) {
          final String? cakeId = item['cakeId']?.toString();
          String cakeName = item['cakeName']?.toString() ?? 'Custom Selection';
          final normalizedName = cakeName.replaceAll(RegExp(r'\s*\(.*?\)\s*$'), '').trim().toLowerCase();

          var matchingCake = <String, dynamic>{};
          if (cakeId != null) {
            matchingCake = _cachedMenu.firstWhere(
              (c) => c['id']?.toString() == cakeId,
              orElse: () => <String, dynamic>{},
            );
          }
          if (matchingCake.isEmpty) {
            matchingCake = _cachedMenu.firstWhere(
              (c) => c['name']?.toString().toLowerCase() == normalizedName,
              orElse: () => <String, dynamic>{},
            );
          }
          if (matchingCake.isEmpty) {
            matchingCake = _cachedMenu.firstWhere(
              (c) {
                final menuName = c['name']?.toString().toLowerCase() ?? '';
                return menuName.contains(normalizedName) || normalizedName.contains(menuName);
              },
              orElse: () => <String, dynamic>{},
            );
          }
          final String category = (matchingCake['Category']?['name'] as String?) ?? 'Custom';
          final itemPrice = _parsePrice(item['price']);
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final subtotal = itemPrice * qty;
          filteredCategorySales[category] = (filteredCategorySales[category] ?? 0) + subtotal;
        }
      } catch (e) {
        debugPrint("Error fetching item details for export: $e");
      }
    }

    if (exportFormat == 'pdf') {
      await ReportService.downloadPDF(filteredOrders, totalRevenue, totalOrders, avgOrder, filteredCategorySales);
    } else if (exportFormat == 'csv') {
      await ReportService.downloadCSV(filteredOrders, totalRevenue, totalOrders);
    }
  }

  Widget _buildExportButton(ColorScheme cs) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        try {
          if (value == 'pdf') {
            await _showExportDialog(cs, 'pdf');
          } else if (value == 'csv') {
            await _showExportDialog(cs, 'csv');
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

  List<FlSpot> _generateChartSpots() {
    final paidOrders = _paidOrders;
    if (paidOrders.isEmpty) return [const FlSpot(0, 0)];

    final filtered = paidOrders.where((o) {
      final dateStr = o['createdAt']?.toString() ?? o['paidAt']?.toString();
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      return date != null && _isInTimeWindow(date, _selectedRange);
    }).toList();

    if (filtered.isEmpty) return [const FlSpot(0, 0)];

    Map<int, double> buckets = {};
    for (var order in filtered) {
      final dateStr = order['createdAt']?.toString() ?? order['paidAt']?.toString();
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = _getTimeBucket(date, _selectedRange);
      final amount = _parsePrice(order['totalPrice']);
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

  Widget _buildRevenueLineChart(ColorScheme cs) {
    final spots = _generateChartSpots();
    final amounts = spots.map((s) => s.y).toList();
    double maxRevenue = 500.0;
    for (var v in amounts) {
      if (v > maxRevenue) maxRevenue = v;
    }
    maxRevenue = (maxRevenue / 5).ceil() * 5.0;
    if (maxRevenue == 0) maxRevenue = 500.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue / 5,
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
                  'Revenue: $formattedAmount',
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
              reservedSize: 40,
              interval: maxRevenue / 5,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) return const SizedBox();
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
        maxY: maxRevenue,
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "PERFORMANCE OVERVIEW",
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
                          _buildExportButton(cs),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: cs.secondary.withValues(alpha: 0.1)),
                  SizedBox(height: MediaQuery.sizeOf(context).width > 800 ? 32 : 20),
                  _buildMetricsGrid(cs),
                  SizedBox(height: MediaQuery.sizeOf(context).width > 800 ? 32 : 20),
                  _buildRevenueChart(cs, isDark),
                  SizedBox(height: MediaQuery.sizeOf(context).width > 800 ? 32 : 20),
                  _buildSecondaryStats(cs, isDark),
                  SizedBox(height: MediaQuery.sizeOf(context).width > 800 ? 100 : 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ColorScheme cs) {
    final isDesktop = MediaQuery.sizeOf(context).width > 800;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildMetricCard(
              cs,
              "Total Revenue",
              NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(_totalRevenue),
              Icons.account_balance_wallet_outlined,
              const Color(0xFFFF4D8D),
              isDesktop,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              cs,
              "Total Orders",
              _totalOrders.toString(),
              Icons.shopping_bag_outlined,
              const Color(0xFF701235),
              isDesktop,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              cs,
              "Avg. Order",
              NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(_avgOrderValue),
              Icons.analytics_outlined,
              Colors.blueGrey,
              isDesktop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(ColorScheme cs, String title, String value, IconData icon, Color accent, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent, size: isDesktop ? 20 : 16),
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
              title.toUpperCase(),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final titleCol = Column(
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
                "Revenue aggregated by ${_selectedRange.name}",
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          );

          final actionsCol = Column(
            crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                titleCol,
                const SizedBox(height: 16),
                actionsCol,
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleCol,
                    actionsCol,
                  ],
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                height: 300,
                child: _buildRevenueLineChart(cs),
              ),
            ],
          );
        },
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
                          imageUrl: item['image'] as String,
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
                        item['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item['category'] as String,
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
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                    final eventType = event.runtimeType.toString();
                    final isHoverExit = eventType.contains('PointerExit');
                    if (response == null || response.touchedSection == null) {
                      if (isHoverExit) {
                        setState(() => _hoveredCategory = null);
                      }
                      return;
                    }
                    final idx = response.touchedSection!.touchedSectionIndex;
                    if (idx >= 0 && idx < _categorySales.length) {
                      if (!eventType.contains('PointerUp') && !eventType.contains('TapUp')) {
                        setState(() => _hoveredCategory = _categorySales.keys.elementAt(idx));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ..._categorySales.entries.map((e) {
            final isHovered = _hoveredCategory == e.key;
            final color = _getCategoryColor(e.key);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_hoveredCategory == e.key) {
                    _hoveredCategory = null;
                  } else {
                    _hoveredCategory = e.key;
                  }
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredCategory = e.key),
                onExit: (_) => setState(() => _hoveredCategory = null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isHovered ? color.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: isHovered ? color : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isHovered ? 14 : 10,
                      height: isHovered ? 14 : 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: isHovered
                            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                          color: isHovered ? cs.secondary : cs.secondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: PriceConstants.currencySymbol, decimalDigits: 0).format(e.value),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
                        color: isHovered ? color : cs.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
      final isHovered = _hoveredCategory == key;
      sections.add(PieChartSectionData(
        color: _getCategoryColor(key),
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isHovered ? 62 : 50,
        titleStyle: GoogleFonts.plusJakartaSans(
          fontSize: isHovered ? 12 : 10,
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
    }, onError: (Object error) {
      debugPrint("Sales reports stream error: $error");
    });
  }
}
