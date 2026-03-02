import 'dart:io';

import 'package:extropos/helpers/toast_helper.dart';
import 'package:extropos/models/business_info.dart';
import 'package:extropos/models/reports_models.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsExportService {
  Future<void> exportBasicReport(
    BuildContext context,
    String csvContent, {
    required bool mounted,
  }) async {
    final suggestedName =
        'report_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          if (mounted) ToastHelper.showToast(context, 'Cannot access storage');
          return;
        }

        final downloadsPath = '${directory.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '$downloadsPath/$suggestedName';
        final file = File(filePath);
        await file.writeAsString(csvContent);

        if (mounted) {
          ToastHelper.showToast(
            context,
            'Report saved to Downloads: $suggestedName',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showToast(context, 'Export failed: $e');
        }
      }
    } else {
      final location = await FilePicker.platform.saveFile(
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (location == null) return;

      final file = File(location);
      await file.writeAsString(csvContent);

      if (mounted) {
        ToastHelper.showToast(context, 'Report exported to $location');
      }
    }
  }

  Future<void> exportAdvancedReport(
    BuildContext context,
    String csvData,
    String reportTypeName, {
    required bool mounted,
  }) async {
    final fileName =
        '${reportTypeName}_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          if (mounted) ToastHelper.showToast(context, 'Cannot access storage');
          return;
        }

        final downloadsPath = '${directory.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);
        await file.writeAsString(csvData);

        if (mounted) {
          ToastHelper.showToast(
            context,
            'Report saved to Downloads: $fileName',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showToast(context, 'Export failed: $e');
        }
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final file = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file != null) {
        await File(file).writeAsString(csvData);
        if (mounted)
          ToastHelper.showToast(context, 'Report exported successfully');
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);
      if (mounted)
        ToastHelper.showToast(context, 'Report saved to ${file.path}');
    }
  }

  Future<void> printBasicReport(
    BuildContext context,
    BasicReport? currentReport,
    ReportPeriod selectedPeriod, {
    required bool mounted,
  }) async {
    if (currentReport == null) return;

    if (selectedPeriod == ReportPeriod.today() ||
        selectedPeriod == ReportPeriod.thisMonth()) {
      final receiptData =
          _createThermalReportReceiptData(currentReport, selectedPeriod);
      final printer =
          await DatabaseService.instance.getPrinters().then((p) => p.isNotEmpty ? p.first : null);
      if (printer != null) {
        final success = await PrinterService().printReceipt(
          printer,
          receiptData,
        );
        if (success && mounted) {
          ToastHelper.showToast(context, 'Report printed successfully');
        } else if (mounted) {
          ToastHelper.showToast(
            context,
            'Print failed - check printer connection',
          );
        }
      } else {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
      }
    } else {
      await _generateAndPrintBasicPDF(context, currentReport, selectedPeriod,
          mounted: mounted);
    }
  }

  Future<void> printAdvancedReport(
    BuildContext context,
    ReportFormat selectedFormat,
    ReportType selectedReportType,
    SalesSummaryReport? salesSummaryReport,
    ProductSalesReport? productSalesReport,
    DayClosingReport? dayClosingReport,
    ReportPeriod selectedPeriod, {
    required bool mounted,
  }) async {
    if (selectedFormat == ReportFormat.thermal58mm ||
        selectedFormat == ReportFormat.thermal80mm) {
      final receiptData = _createAdvancedThermalReportReceiptData(
        selectedReportType,
        salesSummaryReport,
        productSalesReport,
        dayClosingReport,
        selectedPeriod,
      );
      final printer =
          await DatabaseService.instance.getPrinters().then((p) => p.isNotEmpty ? p.first : null);
      if (printer != null) {
        final success = await PrinterService().printReceipt(
          printer,
          receiptData,
        );
        if (success && mounted) {
          ToastHelper.showToast(context, 'Report printed successfully');
        } else if (mounted) {
          ToastHelper.showToast(
            context,
            'Print failed - check printer connection',
          );
        }
      } else {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
      }
    } else {
      await _generateAndPrintAdvancedPDF(
        context,
        selectedFormat,
        selectedReportType,
        salesSummaryReport,
        productSalesReport,
        dayClosingReport,
        selectedPeriod,
        mounted: mounted,
      );
    }
  }

  Map<String, dynamic> _createThermalReportReceiptData(
    BasicReport currentReport,
    ReportPeriod selectedPeriod,
  ) {
    final info = BusinessInfo.instance;
    final now = DateTime.now();

    return {
      'store_name': info.businessName,
      'address': [
        info.fullAddress,
        if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
          'Tax No: ${info.taxNumber}',
      ],
      'title': 'SALES REPORT',
      'date':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      'customer': '',
      'bill_no': selectedPeriod.label,
      'payment_mode': '',
      'dr_ref': '',
      'currency': info.currencySymbol,
      'items': [
        {'name': 'Total Sales', 'qty': 1, 'amt': currentReport.grossSales},
        {
          'name': 'Total Orders',
          'qty': currentReport.transactionCount,
          'amt': 0.0,
        },
        {
          'name': 'Avg Order Value',
          'qty': 1,
          'amt': currentReport.averageTicket,
        },
        ...currentReport.paymentMethods.entries.map(
          (entry) => {
            'name': '${entry.key} Payments',
            'qty': 1,
            'amt': entry.value,
          },
        ),
        ...currentReport.topCategories.entries
            .take(5)
            .map((entry) => {'name': entry.key, 'qty': 1, 'amt': entry.value}),
      ],
      'sub_total_qty': 1,
      'sub_total_amt': currentReport.grossSales,
      'discount': 0.0,
      'taxes': [],
      'service_charge': 0.0,
      'total': currentReport.grossSales,
      'amount_paid': currentReport.grossSales,
      'change': 0.0,
      'footer': ['Report Generated: ${now.toString()}'],
    };
  }

  Map<String, dynamic> _createAdvancedThermalReportReceiptData(
    ReportType selectedReportType,
    SalesSummaryReport? salesSummaryReport,
    ProductSalesReport? productSalesReport,
    DayClosingReport? dayClosingReport,
    ReportPeriod selectedPeriod,
  ) {
    final info = BusinessInfo.instance;
    final now = DateTime.now();

    final items = <Map<String, dynamic>>[];

    switch (selectedReportType) {
      case ReportType.salesSummary:
        if (salesSummaryReport != null) {
          items.addAll([
            {
              'name': 'Gross Sales',
              'qty': 1,
              'amt': salesSummaryReport.grossSales,
            },
            {
              'name': 'Net Sales',
              'qty': 1,
              'amt': salesSummaryReport.netSales,
            },
            {
              'name': 'Total Transactions',
              'qty': salesSummaryReport.totalTransactions,
              'amt': 0.0,
            },
          ]);
        }
        break;
      case ReportType.productSales:
        if (productSalesReport != null) {
          items.addAll(
            productSalesReport.productSales
                .take(10)
                .map(
                  (product) => {
                    'name': product.productName,
                    'qty': product.unitsSold,
                    'amt': product.totalRevenue,
                  },
                ),
          );
        }
        break;
      case ReportType.dayClosing:
        if (dayClosingReport != null) {
          items.addAll([
            {
              'name': 'Total Sales',
              'qty': 1,
              'amt': dayClosingReport.totalSales,
            },
            {'name': 'Net Sales', 'qty': 1, 'amt': dayClosingReport.netSales},
            {
              'name': 'Cash Expected',
              'qty': 1,
              'amt': dayClosingReport.cashExpected,
            },
            {
              'name': 'Cash Actual',
              'qty': 1,
              'amt': dayClosingReport.cashActual,
            },
            {
              'name': 'Cash Variance',
              'qty': 1,
              'amt': dayClosingReport.cashVariance,
            },
          ]);
        }
        break;
      default:
        items.add({'name': 'Report data not available', 'qty': 1, 'amt': 0.0});
    }

    return {
      'store_name': info.businessName,
      'address': [
        info.fullAddress,
        if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
          'Tax No: ${info.taxNumber}',
      ],
      'title': _getReportTypeLabel(selectedReportType).toUpperCase(),
      'date':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      'customer': '',
      'bill_no': selectedPeriod.label,
      'payment_mode': '',
      'dr_ref': '',
      'currency': info.currencySymbol,
      'items': items,
      'sub_total_qty': items.length,
      'sub_total_amt': items.fold(
        0.0,
        (sum, item) => sum + (item['amt'] as double),
      ),
      'discount': 0.0,
      'taxes': [],
      'service_charge': 0.0,
      'total': items.fold(0.0, (sum, item) => sum + (item['amt'] as double)),
      'amount_paid': items.fold(
        0.0,
        (sum, item) => sum + (item['amt'] as double),
      ),
      'change': 0.0,
      'footer': ['Report Generated: ${now.toString()}'],
    };
  }

  Future<void> _generateAndPrintBasicPDF(
    BuildContext context,
    BasicReport currentReport,
    ReportPeriod selectedPeriod, {
    required bool mounted,
  }) async {
    try {
      final pdf = pw.Document();
      const reportTitle = 'Sales Report';
      final generatedDate = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: pdf.pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Period: ${selectedPeriod.label}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Generated: ${generatedDate.toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total Sales: ${FormattingService.currency(currentReport.grossSales)}',
                ),
                pw.Text('Total Orders: ${currentReport.transactionCount}'),
                pw.Text(
                  'Average Order Value: ${FormattingService.currency(currentReport.averageTicket)}',
                ),
              ],
            );
          },
        ),
      );

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          if (mounted) ToastHelper.showToast(context, 'Cannot access storage');
          return;
        }

        final downloadsPath = '${directory.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final fileName =
            'sales_report_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ToastHelper.showToast(context, 'PDF saved to Downloads: $fileName');
        }
      } else {
        await Printing.layoutPdf(
          onLayout: (pdf.PdfPageFormat format) async => pdf.save(),
        );

        if (mounted) {
          ToastHelper.showToast(context, 'PDF sent to printer');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'PDF generation failed: $e');
      }
    }
  }

  Future<void> _generateAndPrintAdvancedPDF(
    BuildContext context,
    ReportFormat selectedFormat,
    ReportType selectedReportType,
    SalesSummaryReport? salesSummaryReport,
    ProductSalesReport? productSalesReport,
    DayClosingReport? dayClosingReport,
    ReportPeriod selectedPeriod, {
    required bool mounted,
  }) async {
    try {
      final pdfDoc = pw.Document();
      final reportTitle = _getReportTypeLabel(selectedReportType);
      final generatedDate = DateTime.now();

      pdfDoc.addPage(
        pw.Page(
          pageFormat: selectedFormat == ReportFormat.pdfThermal
              ? pdf.PdfPageFormat.roll80
              : pdf.PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Period: ${selectedPeriod.label}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Generated: ${generatedDate.toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                if (selectedReportType == ReportType.dayClosing &&
                    dayClosingReport != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Sales: ${FormattingService.currency(dayClosingReport.totalSales)}',
                      ),
                      pw.Text(
                        'Net Sales: ${FormattingService.currency(dayClosingReport.netSales)}',
                      ),
                      pw.Text(
                        'Cash Expected: ${FormattingService.currency(dayClosingReport.cashExpected)}',
                      ),
                      pw.Text(
                        'Cash Actual: ${FormattingService.currency(dayClosingReport.cashActual)}',
                      ),
                      pw.Text(
                        'Cash Variance: ${FormattingService.currency(dayClosingReport.cashVariance)}',
                      ),
                    ],
                  )
                else if (selectedReportType == ReportType.salesSummary &&
                    salesSummaryReport != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Gross Sales: ${FormattingService.currency(salesSummaryReport.grossSales)}',
                      ),
                      pw.Text(
                        'Total Transactions: ${salesSummaryReport.totalTransactions}',
                      ),
                      pw.Text(
                        'Net Sales: ${FormattingService.currency(salesSummaryReport.netSales)}',
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      );

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          if (mounted) ToastHelper.showToast(context, 'Cannot access storage');
          return;
        }

        final downloadsPath = '${directory.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final fileName =
            '${selectedReportType.name}_report_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(await pdfDoc.save());

        if (mounted) {
          ToastHelper.showToast(context, 'PDF saved to Downloads: $fileName');
        }
      } else {
        await Printing.layoutPdf(
          onLayout: (pdf.PdfPageFormat format) async => pdfDoc.save(),
        );

        if (mounted) {
          ToastHelper.showToast(context, 'PDF sent to printer');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'PDF generation failed: $e');
      }
    }
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary';
      case ReportType.productSales:
        return 'Product Sales';
      case ReportType.categoryWiseSales:
        return 'Category Wise Sales';
      case ReportType.staffPerformance:
        return 'Staff Performance';
      case ReportType.dayClosing:
        return 'Day Closing';
      case ReportType.paymentSummary:
        return 'Payment Summary';
      case ReportType.discounts:
        return 'Discounts';
      case ReportType.taxReport:
        return 'Tax Report';
      case ReportType.refunds:
        return 'Refunds';
      case ReportType.voidsAndDiscounts:
        return 'Voids and Discounts';
      case ReportType.inventory:
        return 'Inventory';
      case ReportType.customers:
        return 'Customers';
      case ReportType.giftCards:
        return 'Gift Cards';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program';
      case ReportType.hoursWorked:
        return 'Hours Worked';
      case ReportType.timeClocks:
        return 'Time Clocks';
      case ReportType.dailyStaffPerformance:
        return 'Daily Staff Performance';
      case ReportType.pointOfSaleActivityLog:
        return 'Point of Sale Activity Log';
    }
  }
}
