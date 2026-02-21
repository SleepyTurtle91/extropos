import 'dart:typed_data';

import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart' as pos_printer;
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

/// Service for generating and printing sales reports in various formats
class ReportPrinterService {
  static final ReportPrinterService _instance = ReportPrinterService._internal();

  factory ReportPrinterService() {
    return _instance;
  }

  ReportPrinterService._internal();

  static ReportPrinterService get instance => _instance;

  /// Print a condensed thermal summary (58/80mm) using the existing printer pipeline.
  /// This is a stopgap to ensure reports can reach network/USB/Bluetooth thermal printers
  /// until full formatted PDFs are supported on all devices.
  Future<bool> printThermalSummary({
    required pos_printer.Printer printer,
    required SalesSummary summary,
    required String periodLabel,
    List<CategoryPerformance>? categories,
    List<PaymentMethodStats>? paymentMethods,
  }) async {
    final info = BusinessInfo.instance;
    final width = (printer.paperSize == pos_printer.ThermalPaperSize.mm80) ? 42 : 32;

    String padRight(String label, String value) {
      final available = width - value.length;
      final paddedLabel = label.padRight(available > 0 ? available : label.length);
      return '$paddedLabel$value';
    }

    List<String> wrap(String text) {
      if (text.isEmpty) return [''];
      final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final lines = <String>[];
      var current = '';
      for (final word in words) {
        if (current.isEmpty) {
          if (word.length <= width) {
            current = word;
          } else {
            lines.addAll(_splitWord(word, width));
          }
        } else {
          final candidate = '$current $word';
          if (candidate.length <= width) {
            current = candidate;
          } else {
            lines.add(current);
            current = word.length <= width ? word : '';
            if (word.length > width) {
              lines.addAll(_splitWord(word, width));
            }
          }
        }
      }
      if (current.isNotEmpty) lines.add(current);
      return lines;
    }

    final lines = <String>[];

    // Header
    lines.addAll(wrap(info.businessName));
    lines.addAll(wrap(info.fullAddress));
    if (info.taxNumber != null && info.taxNumber!.isNotEmpty) {
      lines.addAll(wrap('Tax No: ${info.taxNumber}'));
    }
    lines.add('-' * width);
    lines.addAll(wrap('Sales Report ($periodLabel)'));
    lines.add('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    lines.add('-' * width);

    // Summary metrics
    final c = info.currencySymbol;
    lines.add(padRight('Total Revenue', '$c ${summary.totalRevenue.toStringAsFixed(2)}'));
    lines.add(padRight('Net Sales', '$c ${summary.netSales.toStringAsFixed(2)}'));
    lines.add(padRight('Transactions', summary.transactionCount.toString()));
    lines.add(padRight('Avg Ticket', '$c ${summary.averageTransactionValue.toStringAsFixed(2)}'));
    lines.add(padRight('Total Discount', '$c ${summary.totalDiscount.toStringAsFixed(2)}'));

    // Payment methods
    if (paymentMethods != null && paymentMethods.isNotEmpty) {
      lines.add('-' * width);
      lines.add('Payments');
      for (final m in paymentMethods) {
        lines.add(padRight(
          m.paymentMethodName,
          '$c ${m.totalAmount.toStringAsFixed(2)}',
        ));
      }
    }

    // Categories
    if (categories != null && categories.isNotEmpty) {
      lines.add('-' * width);
      lines.add('Categories');
      for (final cat in categories.take(6)) {
        lines.add(padRight(
          cat.categoryName,
          '$c ${cat.revenue.toStringAsFixed(2)}',
        ));
      }
    }

    lines.add('-' * width);
    lines.add('Thank you!');

    final content = lines.join('\n');

    // Use debugForcePrint to avoid strict receipt schema requirements and send raw text
    return await PrinterService().debugForcePrint(
      printer,
      {
        'title': 'Sales Report',
        'content': content,
      },
    );
  }

  List<String> _splitWord(String word, int width) {
    final chunks = <String>[];
    for (var i = 0; i < word.length; i += width) {
      final end = (i + width) > word.length ? word.length : i + width;
      chunks.add(word.substring(i, end));
    }
    return chunks;
  }

  /// Generate PDF document for a sales report
  Future<Uint8List> generateReportPDF({
    required SalesSummary summary,
    required List<CategoryPerformance> categories,
    required List<ProductPerformance> topProducts,
    required List<PaymentMethodStats> paymentMethods,
    required String periodLabel,
  }) async {
    final doc = pw.Document();
    final businessInfo = BusinessInfo.instance;
    final currency = businessInfo.currencySymbol;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  businessInfo.businessName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Sales Report',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Period: $periodLabel',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Metric',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Value',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Total Revenue'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('$currency ${summary.totalRevenue.toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Net Sales'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('$currency ${summary.netSales.toStringAsFixed(2)}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Transactions'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${summary.transactionCount}'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Avg Ticket'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '$currency ${summary.averageTransactionValue.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Total Discount'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('$currency ${summary.totalDiscount.toStringAsFixed(2)}'),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Payment Methods Section
          pw.Text(
            'Payment Methods',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Method',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Transactions',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...paymentMethods.map(
                (method) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(method.paymentMethodName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${method.transactionCount}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$currency ${method.totalAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Top Products Section
          pw.Text(
            'Top Products',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Rank',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Product',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Units',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Revenue',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...topProducts.asMap().entries.map(
                (entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${entry.key + 1}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(entry.value.productName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${entry.value.unitsSold}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$currency ${entry.value.revenue.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Categories Section
          pw.Text(
            'Sales by Category',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Category',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Transactions',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Sales',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...categories.map(
                (cat) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(cat.categoryName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${cat.orderCount}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$currency ${cat.revenue.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'This is a computer-generated report',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Generate thermal format report for 58mm or 80mm printer
  String generateThermalReport({
    required SalesSummary summary,
    required List<ProductPerformance> topProducts,
    required List<PaymentMethodStats> paymentMethods,
    required String periodLabel,
    required int paperWidth, // 32 for 58mm, 40 for 80mm
  }) {
    final buffer = StringBuffer();
    final businessInfo = BusinessInfo.instance;
    final currency = businessInfo.currencySymbol;

    // Helper to center text
    String center(String text) {
      if (text.length >= paperWidth) {
        return text.substring(0, paperWidth);
      }
      final padding = (paperWidth - text.length) ~/ 2;
      return ' ' * padding + text;
    }

    // Helper to align right
    String alignRight(String text) =>
        text.padLeft(paperWidth);

    // Header
    buffer.writeln(center('═' * (paperWidth - 2)));
    buffer.writeln(center(businessInfo.businessName));
    buffer.writeln(center('SALES REPORT'));
    buffer.writeln(center('Period: $periodLabel'));
    buffer.writeln(center(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())));
    buffer.writeln(center('═' * (paperWidth - 2)));
    buffer.writeln();

    // Summary Section
    buffer.writeln(center('SUMMARY'));
    buffer.writeln('─' * paperWidth);
    buffer.writeln('Revenue: ${alignRight('$currency ${summary.totalRevenue.toStringAsFixed(2)}')}');
    buffer.writeln('Discount: ${alignRight('$currency ${summary.totalDiscount.toStringAsFixed(2)}')}');
    buffer.writeln('Tax: ${alignRight('$currency ${summary.totalTax.toStringAsFixed(2)}')}');
    buffer.writeln('Transactions: ${alignRight(summary.transactionCount.toString())}');
    buffer.writeln('Avg Ticket: ${alignRight('$currency ${summary.averageTransactionValue.toStringAsFixed(2)}')}');
    buffer.writeln();

    // Payment Methods
    if (paymentMethods.isNotEmpty) {
      buffer.writeln(center('PAYMENT METHODS'));
      buffer.writeln('─' * paperWidth);
      for (final method in paymentMethods) {
        buffer.writeln(
          '${method.paymentMethodName.padRight(15)} '
          '${method.transactionCount.toString().padLeft(6)} '
          '${method.totalAmount.toStringAsFixed(2).padLeft(10)}',
        );
      }
      buffer.writeln();
    }

    // Top Products
    if (topProducts.isNotEmpty) {
      buffer.writeln(center('TOP PRODUCTS'));
      buffer.writeln('─' * paperWidth);
      for (var i = 0; i < topProducts.take(10).length; i++) {
        final product = topProducts[i];
        final rank = (i + 1).toString();
        final name = product.productName.length > 15
            ? '${product.productName.substring(0, 15)}..'
            : product.productName;
        buffer.writeln(
          '$rank. ${name.padRight(14)} '
          '${product.unitsSold.toString().padLeft(3)} '
          '${product.revenue.toStringAsFixed(2).padLeft(9)}',
        );
      }
      buffer.writeln();
    }

    // Footer
    buffer.writeln('═' * paperWidth);
    buffer.writeln(center('Thank you'));
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }

  /// Print PDF to printer
  Future<void> printPDF({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String documentName,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: documentName,
      );
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  /// Print thermal report to 58mm or 80mm printer
  Future<void> printThermal({
    required BuildContext context,
    required String thermalText,
    required int paperWidth,
  }) async {
    try {
      // Prepare thermal print data
      // Show loading toast
      if (context.mounted) {
        ToastHelper.showToast(context, 'Sending to printer...');
      }

      // For now, just show the thermal format as a preview
      // In a real implementation, this would send to Android printer service
      if (context.mounted) {
        ToastHelper.showToast(
          context,
          'Report format ready. Configure printer in Settings → Printers.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  /// Export report to PDF file and return path
  Future<String?> exportToPDFFile({
    required Uint8List pdfBytes,
  }) async {
    try {
      final fileName =
          'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (Platform.isAndroid) {
        // Save to downloads folder
        final directory = await getExternalStorageDirectory();
        final downloadsPath = '${directory!.path}/Download';
        final downloadsDir = Directory(downloadsPath);

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        return filePath;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use file selector for picking save location
        // For now, save to Documents folder (common location)
        final homeDir = Directory.systemTemp.parent;
        final docsPath = '${homeDir.path}/Documents';
        final docsDir = Directory(docsPath);

        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }

        final filePath = '$docsPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        return filePath;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }
}
