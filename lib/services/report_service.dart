import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> downloadCSV(List<Map<String, dynamic>> orders, double totalRevenue, int totalOrders) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(["Order Number", "Date", "Customer", "Total Price", "Status", "Items"]);
    
    for (var order in orders) {
      rows.add([
        order['orderNumber'] ?? 'N/A',
        order['createdAt'] ?? 'N/A',
        order['customerName'] ?? 'Guest',
        order['totalPrice'] ?? '0',
        order['status'] ?? 'PENDING',
        order['notes'] ?? '',
      ]);
    }
    
    // Summary
    rows.add([]);
    rows.add(["SUMMARY"]);
    rows.add(["Total Orders", totalOrders]);
    rows.add(["Total Revenue", totalRevenue]);
    
    String csv = ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    
    await Printing.sharePdf(
      bytes: bytes,
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
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Sonna's Patisserie & Cafe", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                  pw.Text("Total Orders: $totalOrders"),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Total Revenue: ${NumberFormat.currency(symbol: "Rs. ", decimalDigits: 0).format(totalRevenue)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Avg Order Value: ${NumberFormat.currency(symbol: "Rs. ", decimalDigits: 0).format(avgOrder)}"),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text("Category Performance", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          ...categorySales.entries.map((e) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key),
                pw.Text(NumberFormat.currency(symbol: "Rs. ", decimalDigits: 0).format(e.value)),
              ],
            ),
          )),
          pw.SizedBox(height: 30),
          pw.Text("Recent Orders", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ["Order #", "Customer", "Status", "Amount"],
            data: orders.take(20).map((o) => [
              o['orderNumber'] ?? 'N/A',
              o['customerName'] ?? 'Guest',
              o['status'] ?? 'PENDING',
              o['totalPrice'] ?? '0',
            ]).toList(),
          ),
          pw.Footer(
            margin: const pw.EdgeInsets.only(top: 20),
            trailing: pw.Text("Page ${context.pageNumber} of ${context.pagesCount}"),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
