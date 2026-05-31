import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart' deferred as pdf_lib;
import 'package:pdf/widgets.dart' deferred as pw;
import 'package:printing/printing.dart' deferred as printing_lib;
import 'package:csv/csv.dart' deferred as csv_lib;
import 'package:intl/intl.dart';
import 'constants.dart';

class ReportService {
  static Future<void> _ensureDeferred() async {
    await Future.wait([
      pdf_lib.loadLibrary(),
      pw.loadLibrary(),
      printing_lib.loadLibrary(),
      csv_lib.loadLibrary(),
    ]);
  }

  static Future<void> downloadCSV(List<Map<String, dynamic>> orders, double totalRevenue, int totalOrders) async {
    await _ensureDeferred();
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(["Order Number", "Date", "Customer", "Total Price", "Status", "Items"]);
    
    for (var order in orders) {
      DateTime? dt;
      final createdAt = order['createdAt'];
      if (createdAt != null) {
        dt = DateTime.tryParse(createdAt.toString());
      }
      String dateStr = dt != null ? DateFormat('dd-MM-yyyy HH:mm').format(dt) : 'N/A';

      final double price = PriceConstants.normalizePrice(order['totalPrice']);

      rows.add([
        order['orderNumber']?.toString() ?? 'N/A',
        dateStr,
        order['customerName']?.toString() ?? 'Guest',
        price.toStringAsFixed(2),
        order['status']?.toString() ?? 'PENDING',
        order['notes']?.toString() ?? '',
      ]);
    }
    
    // Summary
    rows.add([]);
    rows.add(["SUMMARY"]);
    rows.add(["Total Orders", totalOrders]);
    rows.add(["Total Revenue", totalRevenue]);
    
    String csv = csv_lib.ListToCsvConverter().convert(rows);
    
    // Add UTF-8 BOM so Excel opens it with correct encoding
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    
    await printing_lib.Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'sonna_sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
  }

  static Future<void> downloadPDF(
    List<Map<String, dynamic>> orders, 
    double totalRevenue, 
    int totalOrders,
    double avgOrder,
    Map<String, double> categorySales,
  ) async {
    await _ensureDeferred();
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey),
            ),
          ),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Sonnas", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Sales Report", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}"),
                    pw.Text("Total Orders: ${totalOrders.toString()}"),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Total Revenue: Rs. ${totalRevenue.toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Avg Order Value: Rs. ${avgOrder.toStringAsFixed(0)}"),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text("Category Performance", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ...categorySales.entries.map((e) => pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key.toString().isNotEmpty ? e.key.toString() : "Uncategorized"),
                  pw.Text("Rs. ${e.value.toStringAsFixed(0)}"),
                ],
              ),
            )),
            pw.SizedBox(height: 30),
            pw.Text("Recent Orders (Last 20)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ["Order #", "Customer", "Status", "Amount"],
              data: orders.take(20).map((o) {
                final double price = PriceConstants.normalizePrice(o['totalPrice']);
                return [
                  o['orderNumber']?.toString() ?? 'N/A',
                  o['customerName']?.toString() ?? 'Guest',
                  o['status']?.toString() ?? 'PENDING',
                  "Rs. ${price.toStringAsFixed(2)}",
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      await printing_lib.Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'sonna_sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e, stack) {
      debugPrint("PDF Generation Error: $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static Future<void> downloadExpenseCSV(List<Map<String, dynamic>> expenses, double totalExpenses) async {
    await _ensureDeferred();
    
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(["Title", "Date", "Category", "Amount", "Description"]);
    
    for (var exp in expenses) {
      DateTime? dt;
      final dateValue = exp['date'];
      if (dateValue != null) {
        dt = DateTime.tryParse(dateValue.toString());
      }
      String dateStr = dt != null ? DateFormat('dd-MM-yyyy').format(dt) : 'N/A';

      rows.add([
        exp['title']?.toString() ?? 'N/A',
        dateStr,
        exp['category']?.toString() ?? 'Other',
        exp['amount']?.toString() ?? '0',
        exp['description']?.toString() ?? '',
      ]);
    }
    
    // Summary
    rows.add([]);
    rows.add(["SUMMARY"]);
    rows.add(["Total Expenses", totalExpenses]);
    
    String csv = csv_lib.ListToCsvConverter().convert(rows);
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    
    await printing_lib.Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'sonna_expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
  }

  static Future<void> downloadExpensePDF(
    List<Map<String, dynamic>> expenses, 
    double totalExpenses,
    Map<String, double> categoryBreakdown,
  ) async {
    await _ensureDeferred();
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(fontSize: 10, color: pdf_lib.PdfColors.grey),
            ),
          ),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Sonnas", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Expense Report", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}"),
                pw.Text("Total Expenses: Rs. ${totalExpenses.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text("Category Breakdown", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ...categoryBreakdown.entries.map((e) => pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key),
                  pw.Text("Rs. ${e.value.toStringAsFixed(2)}"),
                ],
              ),
            )),
            pw.SizedBox(height: 30),
            pw.Text("Expense Entries (Last 50)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ["Date", "Title", "Category", "Amount"],
              data: expenses.take(50).map((e) {
                final dt = DateTime.tryParse(e['date']?.toString() ?? '');
                final dateStr = dt != null ? DateFormat('dd MMM').format(dt) : 'N/A';
                return [
                  dateStr,
                  e['title']?.toString() ?? 'N/A',
                  e['category']?.toString() ?? 'Other',
                  "Rs. ${e['amount']?.toString() ?? '0'}",
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      await printing_lib.Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'sonna_expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint("Expense PDF Error: $e");
      rethrow;
    }
  }
}

