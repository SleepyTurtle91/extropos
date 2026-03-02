import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart' as printer_model;
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/report_printer_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

/// Service to handle report exports and printing operations
class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();

  factory ReportExportService() {
    return _instance;
  }

  ReportExportService._internal();

  /// Generate CSV export content
  Future<String> generateCSV({
    required double grossSales,
    required double netSales,
    required int transactionCount,
    required double avgTicket,
    required List<dynamic> topProducts,
    required String periodLabel,
  }) async {
    final buffer = StringBuffer();
    final currency = BusinessInfo.instance.currencySymbol;

    // Header
    buffer.writeln('Sales Report');
    buffer.writeln('Period: $periodLabel');
    buffer.writeln(
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
    buffer.writeln('');

    // Summary
    buffer.writeln('Summary');
    buffer.writeln('Gross Sales,$currency ${grossSales.toStringAsFixed(2)}');
    buffer.writeln('Net Sales,$currency ${netSales.toStringAsFixed(2)}');
    buffer.writeln('Transactions,$transactionCount');
    buffer.writeln('Average Ticket,$currency ${avgTicket.toStringAsFixed(2)}');
    buffer.writeln('');

    // Top Products
    buffer.writeln('Top Products');
    buffer.writeln('Rank,Product Name,Units Sold,Revenue');
    for (var i = 0; i < topProducts.length; i++) {
      final product = topProducts[i];
      buffer.writeln(
        '${i + 1},${product.productName},${product.unitsSold},$currency ${product.revenue.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Export CSV to file
  Future<bool> exportCSVToFile(String csvContent) async {
    try {
      final fileName =
          'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Save to downloads
        final directory = await getExternalStorageDirectory();
        final downloadsPath = '${directory!.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);
        await file.writeAsString(csvContent);
        return true;
      } else {
        // Desktop: Show save dialog
        final file = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'CSV Files', extensions: ['csv']),
          ],
        );

        if (file != null) {
          await File(file.path).writeAsString(csvContent);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Export PDF report
  Future<bool> exportPDF({
    required dynamic summary,
    required List<dynamic> categories,
    required List<dynamic> topProducts,
    required List<dynamic> paymentMethods,
    required String periodLabel,
  }) async {
    try {
      final reportService = ReportPrinterService.instance;

      // Generate PDF bytes
      final pdfBytes = await reportService.generateReportPDF(
        summary: summary,
        categories: categories,
        topProducts: topProducts,
        paymentMethods: paymentMethods,
        periodLabel: periodLabel,
      );

      // Export to file
      final filePath = await reportService.exportToPDFFile(pdfBytes: pdfBytes);
      return filePath != null;
    } catch (e) {
      return false;
    }
  }

  /// Print thermal 80mm receipt
  Future<bool> printThermal80mm({
    required dynamic summary,
    required List<dynamic> categories,
    required List<dynamic> paymentMethods,
    required String periodLabel,
  }) async {
    try {
      final printer = await _getDefaultPrinter();
      if (printer == null) return false;

      final reportService = ReportPrinterService.instance;
      return await reportService.printThermalSummary(
        printer: printer,
        summary: summary,
        periodLabel: periodLabel,
        categories: categories,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get default printer
  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }
}
