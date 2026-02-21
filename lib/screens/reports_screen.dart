import 'dart:io';

import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart' as printer_model;
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/report_content_builders.dart';
import 'package:extropos/services/daily_staff_performance_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_io/io.dart';

enum ReportFormat { thermal58mm, thermal80mm, pdfA4, pdfThermal }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Basic report data
  SalesReport? _currentReport;
  bool _loading = true;
  ReportPeriod _selectedPeriod = ReportPeriod.today();

  // Advanced report data
  ReportType _selectedReportType = ReportType.salesSummary;
  SalesSummaryReport? _salesSummaryReport;
  ProductSalesReport? _productSalesReport;
  CategorySalesReport? _categorySalesReport;
  PaymentMethodReport? _paymentMethodReport;
  EmployeePerformanceReport? _employeePerformanceReport;
  InventoryReport? _inventoryReport;
  ShrinkageReport? _shrinkageReport;
  LaborCostReport? _laborCostReport;
  CustomerReport? _customerReport;
  BasketAnalysisReport? _basketAnalysisReport;
  LoyaltyProgramReport? _loyaltyProgramReport;
  DayClosingReport? _dayClosingReport;
  ProfitLossReport? _profitLossReport;
  CashFlowReport? _cashFlowReport;
  TaxSummaryReport? _taxSummaryReport;
  InventoryValuationReport? _inventoryValuationReport;
  ABCAnalysisReport? _abcAnalysisReport;
  DemandForecastingReport? _demandForecastingReport;
  MenuEngineeringReport? _menuEngineeringReport;
  TablePerformanceReport? _tablePerformanceReport;
  Map<String, dynamic>? _dailyStaffPerformanceReport;

  bool _showAdvancedReports = false;
  ReportFormat _selectedFormat = ReportFormat.thermal58mm;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      if (_showAdvancedReports) {
        await _loadAdvancedReport();
      } else {
        final report = await DatabaseService.instance.generateSalesReport(
          _selectedPeriod,
        );
        if (mounted) {
          setState(() {
            _currentReport = report;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastHelper.showToast(context, 'Error loading report: $e');
      }
    }
  }

  Future<void> _loadAdvancedReport() async {
    try {
      switch (_selectedReportType) {
        case ReportType.salesSummary:
          _salesSummaryReport = await DatabaseService.instance
              .generateSalesSummaryReport(_selectedPeriod);
          break;
        case ReportType.productSales:
          _productSalesReport = await DatabaseService.instance
              .generateProductSalesReport(_selectedPeriod);
          break;
        case ReportType.categorySales:
          _categorySalesReport = await DatabaseService.instance
              .generateCategorySalesReport(_selectedPeriod);
          break;
        case ReportType.paymentMethod:
          _paymentMethodReport = await DatabaseService.instance
              .generatePaymentMethodReport(_selectedPeriod);
          break;
        case ReportType.employeePerformance:
          _employeePerformanceReport = await DatabaseService.instance
              .generateEmployeePerformanceReport(_selectedPeriod);
          break;
        case ReportType.inventory:
          _inventoryReport = await DatabaseService.instance
              .generateInventoryReport(_selectedPeriod);
          break;
        case ReportType.shrinkage:
          _shrinkageReport = await DatabaseService.instance
              .generateShrinkageReport(_selectedPeriod);
          break;
        case ReportType.laborCost:
          _laborCostReport = await DatabaseService.instance
              .generateLaborCostReport(_selectedPeriod);
          break;
        case ReportType.customerAnalysis:
          _customerReport = await DatabaseService.instance
              .generateCustomerReport(_selectedPeriod);
          break;
        case ReportType.basketAnalysis:
          _basketAnalysisReport = await DatabaseService.instance
              .generateBasketAnalysisReport(_selectedPeriod);
          break;
        case ReportType.loyaltyProgram:
          _loyaltyProgramReport = await DatabaseService.instance
              .generateLoyaltyProgramReport(_selectedPeriod);
          break;
        case ReportType.dayClosing:
          _dayClosingReport = await DatabaseService.instance
              .generateDayClosingReport(_selectedPeriod);
          break;
        case ReportType.profitLoss:
          _profitLossReport = await DatabaseService.instance
              .generateProfitLossReport(_selectedPeriod);
          break;
        case ReportType.cashFlow:
          _cashFlowReport = await DatabaseService.instance
              .generateCashFlowReport(_selectedPeriod);
          break;
        case ReportType.taxSummary:
          _taxSummaryReport = await DatabaseService.instance
              .generateTaxSummaryReport(_selectedPeriod);
          break;
        case ReportType.inventoryValuation:
          _inventoryValuationReport = await DatabaseService.instance
              .generateInventoryValuationReport(_selectedPeriod);
          break;
        case ReportType.abcAnalysis:
          _abcAnalysisReport = await DatabaseService.instance
              .generateABCAnalysisReport(_selectedPeriod);
          break;
        case ReportType.demandForecasting:
          _demandForecastingReport = await DatabaseService.instance
              .generateDemandForecastingReport(_selectedPeriod);
          break;
        case ReportType.menuEngineering:
          _menuEngineeringReport = await DatabaseService.instance
              .generateMenuEngineeringReport(_selectedPeriod);
          break;
        case ReportType.tablePerformance:
          _tablePerformanceReport = await DatabaseService.instance
              .generateTablePerformanceReport(_selectedPeriod);
          break;
        case ReportType.dailyStaffPerformance:
          // Special case: daily staff performance report uses a specific date
          // For now, use the start date of the period
          _dailyStaffPerformanceReport = await DailyStaffPerformanceService
              .instance
              .generateDailyReport(_selectedPeriod.startDate);
          break;
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastHelper.showToast(context, 'Error loading advanced report: $e');
      }
    }
  }

  Future<void> _exportReport() async {
    if (_loading) return;

    debugPrint('Reports: Export button pressed');

    try {
      if (_showAdvancedReports) {
        debugPrint('Reports: Exporting advanced report');
        await _exportAdvancedReport();
      } else {
        debugPrint('Reports: Exporting basic report');
        await _exportBasicReport();
      }
    } catch (e) {
      debugPrint('Reports: Export failed with error: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _exportBasicReport() async {
    if (_currentReport == null) return;

    // Build filename
    final bizSlug = BusinessInfo.instance.businessName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    final periodStr = _selectedPeriod == ReportPeriod.today()
        ? 'today'
        : _selectedPeriod == ReportPeriod.thisWeek()
        ? 'this_week'
        : _selectedPeriod == ReportPeriod.thisMonth()
        ? 'this_month'
        : _selectedPeriod == ReportPeriod.lastMonth()
        ? 'last_month'
        : 'custom';

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final suggestedName = 'sales_report_${bizSlug}_${periodStr}_$timestamp.csv';

    // Generate CSV content
    final csvContent = _generateReportCsv();

    if (Platform.isAndroid) {
      // For Android, save directly to Downloads directory
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
      // For desktop platforms, use file picker
      final location = await getSaveLocation(suggestedName: suggestedName);
      if (location == null) return;

      // Write to file
      final file = File(location.path);
      await file.writeAsString(csvContent);

      if (mounted)
        ToastHelper.showToast(context, 'Report exported to ${location.path}');
    }
  }

  Future<void> _exportAdvancedReport() async {
    final csvData = _generateAdvancedCSVData();
    final fileName =
        '${_selectedReportType.name}_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

    if (Platform.isAndroid) {
      // For Android, save directly to Downloads directory
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
      final file = await getSaveLocation(suggestedName: fileName);
      if (file != null) {
        await File(file.path).writeAsString(csvData);
        if (mounted)
          ToastHelper.showToast(context, 'Report exported successfully');
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);
      // Share file on mobile
      if (mounted)
        ToastHelper.showToast(context, 'Report saved to ${file.path}');
    }
  }

  Future<void> _printReport() async {
    if (_loading) return;

    debugPrint('Reports: Print button pressed');

    try {
      if (_showAdvancedReports) {
        debugPrint(
          'Reports: Printing advanced report, format: $_selectedFormat',
        );
        await _printAdvancedReport();
      } else {
        debugPrint('Reports: Printing basic report, format: $_selectedFormat');
        await _printBasicReport();
      }
    } catch (e) {
      debugPrint('Reports: Print failed with error: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print failed: $e');
      }
    }
  }

  Future<void> _printBasicReport() async {
    if (_currentReport == null) return;

    // For daily/monthly reports, use thermal printing
    if (_selectedPeriod == ReportPeriod.today() ||
        _selectedPeriod == ReportPeriod.thisMonth()) {
      final receiptData = _createThermalReportReceiptData();
      final printer = await _getDefaultPrinter();
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
      // For other periods, generate PDF
      await _generateAndPrintPDF();
    }
  }

  Future<void> _printAdvancedReport() async {
    if (_selectedFormat == ReportFormat.thermal58mm ||
        _selectedFormat == ReportFormat.thermal80mm) {
      final receiptData = _createAdvancedThermalReportReceiptData();
      final printer = await _getDefaultPrinter();
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
      await _generateAndPrintAdvancedPDF();
    }
  }

  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }

  Map<String, dynamic> _createThermalReportReceiptData() {
    if (_currentReport == null) return {};

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
      'bill_no': _selectedPeriod.label,
      'payment_mode': '',
      'dr_ref': '',
      'currency': info.currencySymbol,
      'items': [
        {'name': 'Total Sales', 'qty': 1, 'amt': _currentReport!.grossSales},
        {
          'name': 'Total Orders',
          'qty': _currentReport!.transactionCount,
          'amt': 0.0,
        },
        {
          'name': 'Avg Order Value',
          'qty': 1,
          'amt': _currentReport!.averageTicket,
        },
        ..._currentReport!.paymentMethods.entries.map(
          (entry) => {
            'name': '${entry.key} Payments',
            'qty': 1,
            'amt': entry.value,
          },
        ),
        ..._currentReport!.topCategories.entries
            .take(5)
            .map((entry) => {'name': entry.key, 'qty': 1, 'amt': entry.value}),
      ],
      'sub_total_qty': 1,
      'sub_total_amt': _currentReport!.grossSales,
      'discount': 0.0,
      'taxes': [],
      'service_charge': 0.0,
      'total': _currentReport!.grossSales,
      'amount_paid': _currentReport!.grossSales,
      'change': 0.0,
      'footer': ['Report Generated: ${now.toString()}'],
    };
  }

  Map<String, dynamic> _createAdvancedThermalReportReceiptData() {
    final info = BusinessInfo.instance;
    final now = DateTime.now();

    final items = <Map<String, dynamic>>[];

    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          items.addAll([
            {
              'name': 'Gross Sales',
              'qty': 1,
              'amt': _salesSummaryReport!.grossSales,
            },
            {
              'name': 'Net Sales',
              'qty': 1,
              'amt': _salesSummaryReport!.netSales,
            },
            {
              'name': 'Total Transactions',
              'qty': _salesSummaryReport!.totalTransactions,
              'amt': 0.0,
            },
          ]);
        }
        break;
      case ReportType.productSales:
        if (_productSalesReport != null) {
          items.addAll(
            _productSalesReport!.productSales
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
        if (_dayClosingReport != null) {
          items.addAll([
            {
              'name': 'Total Sales',
              'qty': 1,
              'amt': _dayClosingReport!.totalSales,
            },
            {'name': 'Net Sales', 'qty': 1, 'amt': _dayClosingReport!.netSales},
            {
              'name': 'Cash Expected',
              'qty': 1,
              'amt': _dayClosingReport!.cashExpected,
            },
            {
              'name': 'Cash Actual',
              'qty': 1,
              'amt': _dayClosingReport!.cashActual,
            },
            {
              'name': 'Cash Variance',
              'qty': 1,
              'amt': _dayClosingReport!.cashVariance,
            },
          ]);
        }
        break;
      // Add other report types as needed
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
      'title': _getReportTypeLabel(_selectedReportType).toUpperCase(),
      'date':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      'customer': '',
      'bill_no': _selectedPeriod.label,
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

  Future<void> _generateAndPrintPDF() async {
    try {
      final pdf = pw.Document();
      final reportTitle = 'Sales Report';
      final generatedDate = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: _selectedFormat == ReportFormat.pdfThermal
              ? PdfPageFormat.roll80
              : PdfPageFormat.a4,
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
                  'Period: ${_selectedPeriod.label}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Generated: ${generatedDate.toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                _buildBasicPDFContent(),
              ],
            );
          },
        ),
      );

      // For Android, save PDF to Downloads and show success message
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
        // For other platforms, use printing dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
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

  Future<void> _generateAndPrintAdvancedPDF() async {
    try {
      final pdf = pw.Document();
      final reportTitle = _getReportTypeLabel(_selectedReportType);
      final generatedDate = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: _selectedFormat == ReportFormat.pdfThermal
              ? PdfPageFormat.roll80
              : PdfPageFormat.a4,
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
                  'Period: ${_selectedPeriod.label}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Generated: ${generatedDate.toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                _buildAdvancedPDFContent(),
              ],
            );
          },
        ),
      );

      // For Android, save PDF to Downloads and show success message
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
            '${_selectedReportType.name}_report_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ToastHelper.showToast(context, 'PDF saved to Downloads: $fileName');
        }
      } else {
        // For other platforms, use printing dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
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

  pw.Widget _buildBasicPDFContent() {
    if (_currentReport == null) return pw.Text('No data available');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Summary
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Sales: ${FormattingService.currency(_currentReport!.grossSales)}',
        ),
        pw.Text('Total Orders: ${_currentReport!.transactionCount}'),
        pw.Text(
          'Average Order Value: ${FormattingService.currency(_currentReport!.averageTicket)}',
        ),
        pw.SizedBox(height: 20),

        // Payment Methods
        pw.Text(
          'Payment Methods',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ..._currentReport!.paymentMethods.entries.map((entry) {
          final percentage = _currentReport!.grossSales > 0
              ? (entry.value / _currentReport!.grossSales * 100)
              : 0.0;
          return pw.Text(
            '${entry.key}: ${FormattingService.currency(entry.value)} (${percentage.toStringAsFixed(1)}%)',
          );
        }),
      ],
    );
  }

  pw.Widget _buildAdvancedPDFContent() {
    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Gross Sales: ${FormattingService.currency(_salesSummaryReport!.grossSales)}',
              ),
              pw.Text(
                'Total Transactions: ${_salesSummaryReport!.totalTransactions}',
              ),
              pw.Text(
                'Net Sales: ${FormattingService.currency(_salesSummaryReport!.netSales)}',
              ),
            ],
          );
        }
        break;
      case ReportType.dayClosing:
        if (_dayClosingReport != null) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Business Session Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total Sales: ${FormattingService.currency(_dayClosingReport!.totalSales)}',
              ),
              pw.Text(
                'Net Sales: ${FormattingService.currency(_dayClosingReport!.netSales)}',
              ),
              pw.Text(
                'Cash Expected: ${FormattingService.currency(_dayClosingReport!.cashExpected)}',
              ),
              pw.Text(
                'Cash Actual: ${FormattingService.currency(_dayClosingReport!.cashActual)}',
              ),
              pw.Text(
                'Cash Variance: ${FormattingService.currency(_dayClosingReport!.cashVariance)}',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Cash Reconciliation',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Opening Float: ${FormattingService.currency(_dayClosingReport!.cashReconciliation.openingFloat)}',
              ),
              pw.Text(
                'Cash Sales: ${FormattingService.currency(_dayClosingReport!.cashReconciliation.cashSales)}',
              ),
              pw.Text(
                'Cash Refunds: ${FormattingService.currency(_dayClosingReport!.cashReconciliation.cashRefunds)}',
              ),
              pw.Text(
                'Paid Outs: ${FormattingService.currency(_dayClosingReport!.cashReconciliation.paidOuts)}',
              ),
              pw.Text(
                'Paid Ins: ${FormattingService.currency(_dayClosingReport!.cashReconciliation.paidIns)}',
              ),
            ],
          );
        }
        break;
      // Add other report types
      default:
        return pw.Text('Report content not available');
    }
    return pw.Text('No data available');
  }

  String _generateReportCsv() {
    if (_currentReport == null) return '';

    final buffer = StringBuffer();

    // Header
    buffer.writeln('Sales Report');
    buffer.writeln(
      'Period: ${_selectedPeriod.startDate.toString().split(' ')[0]} to ${_selectedPeriod.endDate.toString().split(' ')[0]}',
    );
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Sales,${_currentReport!.grossSales}');
    buffer.writeln('Total Orders,${_currentReport!.transactionCount}');
    buffer.writeln('Average Order Value,${_currentReport!.averageTicket}');
    buffer.writeln('');

    // Payment Methods
    buffer.writeln('PAYMENT METHODS');
    buffer.writeln('Method,Amount,Percentage');
    final totalSales = _currentReport!.grossSales;
    for (final entry in _currentReport!.paymentMethods.entries) {
      final percentage = totalSales > 0
          ? (entry.value / totalSales * 100)
          : 0.0;
      buffer.writeln(
        '${entry.key},${entry.value.toStringAsFixed(2)},${percentage.toStringAsFixed(1)}%',
      );
    }
    buffer.writeln('');

    // Top Items
    buffer.writeln('TOP CATEGORIES');
    buffer.writeln('Category,Revenue');
    for (final entry in _currentReport!.topCategories.entries) {
      buffer.writeln('${entry.key},${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    // Note about hourly sales
    buffer.writeln('Note: Hourly sales data requires enhanced reporting.');

    return buffer.toString();
  }

  String _generateAdvancedCSVData() {
    final buffer = StringBuffer();
    final reportTitle = _getReportTypeLabel(_selectedReportType);

    buffer.writeln(reportTitle);
    buffer.writeln('Period: ${_selectedPeriod.label}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          final netProfit =
              _salesSummaryReport!.netSales -
              _salesSummaryReport!.totalDiscounts;
          buffer.writeln('Gross Sales,${_salesSummaryReport!.grossSales}');
          buffer.writeln(
            'Total Transactions,${_salesSummaryReport!.totalTransactions}',
          );
          buffer.writeln('Net Sales,${_salesSummaryReport!.netSales}');
          buffer.writeln('Net Profit,$netProfit');
        }
        break;
      case ReportType.productSales:
        if (_productSalesReport != null) {
          buffer.writeln('Product,Quantity Sold,Revenue');
          for (final product in _productSalesReport!.productSales) {
            buffer.writeln(
              '${product.productName},${product.unitsSold},${product.totalRevenue}',
            );
          }
        }
        break;
      case ReportType.dayClosing:
        if (_dayClosingReport != null) {
          buffer.writeln('Business Session Summary');
          buffer.writeln('Total Sales,${_dayClosingReport!.totalSales}');
          buffer.writeln('Net Sales,${_dayClosingReport!.netSales}');
          buffer.writeln('Cash Expected,${_dayClosingReport!.cashExpected}');
          buffer.writeln('Cash Actual,${_dayClosingReport!.cashActual}');
          buffer.writeln('Cash Variance,${_dayClosingReport!.cashVariance}');
          buffer.writeln('');
          buffer.writeln('Cash Reconciliation Details');
          buffer.writeln(
            'Opening Float,${_dayClosingReport!.cashReconciliation.openingFloat}',
          );
          buffer.writeln(
            'Cash Sales,${_dayClosingReport!.cashReconciliation.cashSales}',
          );
          buffer.writeln(
            'Cash Refunds,${_dayClosingReport!.cashReconciliation.cashRefunds}',
          );
          buffer.writeln(
            'Paid Outs,${_dayClosingReport!.cashReconciliation.paidOuts}',
          );
          buffer.writeln(
            'Paid Ins,${_dayClosingReport!.cashReconciliation.paidIns}',
          );
          buffer.writeln('');
          buffer.writeln('Shift Summaries');
          buffer.writeln(
            'Employee,Shift Start,Shift End,Sales,Cash Handled,Duration',
          );
          for (final shift in _dayClosingReport!.shiftSummaries) {
            final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
            buffer.writeln(
              '${shift.employeeName},${shift.shiftStart.toIso8601String()},$endTime,${shift.salesDuringShift},${shift.cashHandled},${shift.shiftDuration.inHours}h ${shift.shiftDuration.inMinutes % 60}m',
            );
          }
        }
        break;
      // Add other report types as needed
      default:
        buffer.writeln('Report data not available for CSV export');
    }

    return buffer.toString();
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary Report';
      case ReportType.productSales:
        return 'Product Sales Report';
      case ReportType.categorySales:
        return 'Category Sales Report';
      case ReportType.paymentMethod:
        return 'Payment Method Report';
      case ReportType.employeePerformance:
        return 'Employee Performance Report';
      case ReportType.inventory:
        return 'Inventory Report';
      case ReportType.shrinkage:
        return 'Shrinkage Report';
      case ReportType.laborCost:
        return 'Labor Cost Report';
      case ReportType.customerAnalysis:
        return 'Customer Analysis Report';
      case ReportType.basketAnalysis:
        return 'Basket Analysis Report';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program Report';
      case ReportType.dayClosing:
        return 'Day Closing Report';
      case ReportType.profitLoss:
        return 'Profit & Loss Report';
      case ReportType.cashFlow:
        return 'Cash Flow Report';
      case ReportType.taxSummary:
        return 'Tax Summary Report';
      case ReportType.inventoryValuation:
        return 'Inventory Valuation Report';
      case ReportType.abcAnalysis:
        return 'ABC Analysis Report';
      case ReportType.demandForecasting:
        return 'Demand Forecasting Report';
      case ReportType.menuEngineering:
        return 'Menu Engineering Report';
      case ReportType.tablePerformance:
        return 'Table Performance Report';
      case ReportType.dailyStaffPerformance:
        return 'Daily Staff Performance Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAdvancedReports ? 'Advanced Reports' : 'Sales Reports',
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          // Report type toggle
          TextButton(
            onPressed: () {
              setState(() {
                _showAdvancedReports = !_showAdvancedReports;
                _loadReport();
              });
            },
            child: Text(
              _showAdvancedReports ? 'Basic' : 'Advanced',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Export button
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export Report',
              onPressed: _exportReport,
            ),
          // Print button
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print Report',
              onPressed: _printReport,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showAdvancedReports
          ? _buildAdvancedReportsView()
          : _buildBasicReportsView(),
    );
  }

  Widget _buildBasicReportsView() {
    if (_currentReport == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selector for printing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Print Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Thermal 58mm'),
                        selected: _selectedFormat == ReportFormat.thermal58mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal58mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('Thermal 80mm'),
                        selected: _selectedFormat == ReportFormat.thermal80mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal80mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF A4'),
                        selected: _selectedFormat == ReportFormat.pdfA4,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfA4,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF Thermal'),
                        selected: _selectedFormat == ReportFormat.pdfThermal,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfThermal,
                            );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Period Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Period',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Today'),
                        selected:
                            _selectedPeriod.startDate.day == DateTime.now().day,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.today(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('This Week'),
                        selected:
                            _selectedPeriod.startDate.weekday == 1 &&
                            _selectedPeriod.endDate
                                    .difference(_selectedPeriod.startDate)
                                    .inDays ==
                                6,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.thisWeek(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('This Month'),
                        selected:
                            _selectedPeriod.startDate.day == 1 &&
                            _selectedPeriod.endDate.month ==
                                DateTime.now().month,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.thisMonth(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Last Month'),
                        selected:
                            _selectedPeriod.startDate.month ==
                            (DateTime.now().month == 1
                                ? 12
                                : DateTime.now().month - 1),
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedPeriod = ReportPeriod.lastMonth(),
                            );
                            _loadReport();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Sales',
                  value: FormattingService.currency(_currentReport!.grossSales),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Orders',
                  value: _currentReport!.transactionCount.toString(),
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Avg Order Value',
                  value: FormattingService.currency(
                    _currentReport!.averageTicket,
                  ),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Period',
                  value:
                      '${_selectedPeriod.startDate.toString().split(' ')[0]} to ${_selectedPeriod.endDate.toString().split(' ')[0]}',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Methods Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._currentReport!.paymentMethods.entries.map((
                    entry,
                  ) {
                    final percentage = _currentReport!.grossSales > 0
                        ? (entry.value / _currentReport!.grossSales * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(
                            FormattingService.currency(entry.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top Selling Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._currentReport!.topCategories.entries
                      .take(10)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text(
                                FormattingService.currency(entry.value),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Sales Chart (Simple)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hourly Sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Hourly sales chart requires enhanced reporting model
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Hourly sales data not available.\nEnable enhanced reporting in settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
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

  Widget _buildAdvancedReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReportType.values.map((type) {
                      return FilterChip(
                        label: Text(_getReportTypeLabel(type)),
                        selected: _selectedReportType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedReportType = type);
                            _loadReport();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Format selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Thermal 58mm'),
                        selected: _selectedFormat == ReportFormat.thermal58mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal58mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('Thermal 80mm'),
                        selected: _selectedFormat == ReportFormat.thermal80mm,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.thermal80mm,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF A4'),
                        selected: _selectedFormat == ReportFormat.pdfA4,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfA4,
                            );
                        },
                      ),
                      FilterChip(
                        label: const Text('PDF Thermal'),
                        selected: _selectedFormat == ReportFormat.pdfThermal,
                        onSelected: (selected) {
                          if (selected)
                            setState(
                              () => _selectedFormat = ReportFormat.pdfThermal,
                            );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Period selector (for time-based reports)
          if (_selectedReportType != ReportType.inventory)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Today'),
                          selected: _selectedPeriod == ReportPeriod.today(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () => _selectedPeriod = ReportPeriod.today(),
                              );
                              _loadReport();
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('This Week'),
                          selected: _selectedPeriod == ReportPeriod.thisWeek(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () => _selectedPeriod = ReportPeriod.thisWeek(),
                              );
                              _loadReport();
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('This Month'),
                          selected: _selectedPeriod == ReportPeriod.thisMonth(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _selectedPeriod = ReportPeriod.thisMonth(),
                              );
                              _loadReport();
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Last Month'),
                          selected: _selectedPeriod == ReportPeriod.lastMonth(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _selectedPeriod = ReportPeriod.lastMonth(),
                              );
                              _loadReport();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Report content
          _buildAdvancedReportContent(),
        ],
      ),
    );
  }

  Widget _buildAdvancedReportContent() {
    switch (_selectedReportType) {
      case ReportType.salesSummary:
        return _buildSalesSummaryContent();
      case ReportType.productSales:
        return _buildProductSalesContent();
      case ReportType.categorySales:
        return _buildCategorySalesContent();
      case ReportType.paymentMethod:
        return _buildPaymentMethodContent();
      case ReportType.employeePerformance:
        return _buildEmployeePerformanceContent();
      case ReportType.inventory:
        return _buildInventoryContent();
      case ReportType.shrinkage:
        return _buildShrinkageContent();
      case ReportType.laborCost:
        return _buildLaborCostContent();
      case ReportType.customerAnalysis:
        return _buildCustomerContent();
      case ReportType.basketAnalysis:
        return _buildBasketAnalysisContent();
      case ReportType.loyaltyProgram:
        return _buildLoyaltyProgramContent();
      case ReportType.dayClosing:
        return _buildDayClosingContent();
      case ReportType.profitLoss:
        return ReportContentBuilders.buildProfitLossContent(_profitLossReport);
      case ReportType.cashFlow:
        return ReportContentBuilders.buildCashFlowContent(_cashFlowReport);
      case ReportType.taxSummary:
        return ReportContentBuilders.buildTaxSummaryContent(_taxSummaryReport);
      case ReportType.inventoryValuation:
        return ReportContentBuilders.buildInventoryValuationContent(
          _inventoryValuationReport,
        );
      case ReportType.abcAnalysis:
        return ReportContentBuilders.buildABCAnalysisContent(
          _abcAnalysisReport,
        );
      case ReportType.demandForecasting:
        return ReportContentBuilders.buildDemandForecastingContent(
          _demandForecastingReport,
        );
      case ReportType.menuEngineering:
        return ReportContentBuilders.buildMenuEngineeringContent(
          _menuEngineeringReport,
        );
      case ReportType.tablePerformance:
        return ReportContentBuilders.buildTablePerformanceContent(
          _tablePerformanceReport,
        );
      case ReportType.dailyStaffPerformance:
        return _buildDailyStaffPerformanceContent();
    }
  }

  Widget _buildSalesSummaryContent() {
    if (_salesSummaryReport == null)
      return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Gross Sales',
                value: FormattingService.currency(
                  _salesSummaryReport!.grossSales,
                ),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Total Transactions',
                value: _salesSummaryReport!.totalTransactions.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Net Sales',
                value: FormattingService.currency(
                  _salesSummaryReport!.netSales,
                ),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Avg Transaction',
                value: FormattingService.currency(
                  _salesSummaryReport!.averageTransactionValue,
                ),
                icon: Icons.analytics,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductSalesContent() {
    if (_productSalesReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._productSalesReport!.productSales
                .take(20)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(product.productName)),
                        Text('${product.unitsSold} sold'),
                        const SizedBox(width: 16),
                        Text(FormattingService.currency(product.totalRevenue)),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySalesContent() {
    if (_categorySalesReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._categorySalesReport!.categorySales.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.categoryName)),
                    Text('${entry.value.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(entry.value.revenue)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent() {
    if (_paymentMethodReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._paymentMethodReport!.paymentBreakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.methodName)),
                    Text('${entry.value.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(entry.value.totalAmount)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceContent() {
    if (_employeePerformanceReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._employeePerformanceReport!.employeePerformance.map(
              (employee) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(employee.employeeName)),
                    Text('${employee.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(employee.totalSales)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryContent() {
    if (_inventoryReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._inventoryReport!.inventoryItems
                .take(50)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.itemName)),
                        Text('${item.currentStock} in stock'),
                        const SizedBox(width: 16),
                        Text(
                          item.stockStatus == 'low_stock'
                              ? 'LOW STOCK'
                              : item.stockStatus == 'out_of_stock'
                              ? 'OUT OF STOCK'
                              : 'OK',
                          style: TextStyle(
                            color:
                                item.stockStatus == 'low_stock' ||
                                    item.stockStatus == 'out_of_stock'
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildShrinkageContent() {
    if (_shrinkageReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shrinkage Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Shrinkage: ${FormattingService.currency(_shrinkageReport!.totalShrinkageValue)}',
            ),
            Text(
              'Shrinkage Percentage: ${_shrinkageReport!.totalShrinkagePercentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborCostContent() {
    if (_laborCostReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Labor Cost Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Labor Cost: ${FormattingService.currency(_laborCostReport!.totalLaborCost)}',
            ),
            Text(
              'Labor Cost Percentage: ${_laborCostReport!.laborCostPercentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerContent() {
    if (_customerReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Active Customers: ${_customerReport!.totalActiveCustomers}',
            ),
            Text(
              'Average Customer Lifetime Value: ${FormattingService.currency(_customerReport!.averageCustomerLifetimeValue)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketAnalysisContent() {
    if (_basketAnalysisReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basket Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Frequently Bought Together Items: ${_basketAnalysisReport!.frequentlyBoughtTogether.length}',
            ),
            Text(
              'Recommended Product Bundles: ${_basketAnalysisReport!.recommendedBundles.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyProgramContent() {
    if (_loyaltyProgramReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loyalty Program',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Points Issued: ${_loyaltyProgramReport!.totalPointsIssued}',
            ),
            Text(
              'Total Points Redeemed: ${_loyaltyProgramReport!.totalPointsRedeemed}',
            ),
            Text('Active Members: ${_loyaltyProgramReport!.activeMembers}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDayClosingContent() {
    if (_dayClosingReport == null)
      return const Center(child: Text('No data available'));

    return Column(
      children: [
        // Business Session Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Session Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Sales',
                        value: FormattingService.currency(
                          _dayClosingReport!.totalSales,
                        ),
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Net Sales',
                        value: FormattingService.currency(
                          _dayClosingReport!.netSales,
                        ),
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Cash Expected',
                        value: FormattingService.currency(
                          _dayClosingReport!.cashExpected,
                        ),
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Cash Variance',
                        value: FormattingService.currency(
                          _dayClosingReport!.cashVariance,
                        ),
                        icon: _dayClosingReport!.cashVariance >= 0
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _dayClosingReport!.cashVariance >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cash Reconciliation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash Reconciliation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReconciliationRow(
                  'Opening Float',
                  _dayClosingReport!.cashReconciliation.openingFloat,
                ),
                _buildReconciliationRow(
                  'Cash Sales',
                  _dayClosingReport!.cashReconciliation.cashSales,
                ),
                _buildReconciliationRow(
                  'Cash Refunds',
                  -_dayClosingReport!.cashReconciliation.cashRefunds,
                ),
                _buildReconciliationRow(
                  'Paid Outs',
                  -_dayClosingReport!.cashReconciliation.paidOuts,
                ),
                _buildReconciliationRow(
                  'Paid Ins',
                  _dayClosingReport!.cashReconciliation.paidIns,
                ),
                const Divider(),
                _buildReconciliationRow(
                  'Expected Cash',
                  _dayClosingReport!.cashReconciliation.expectedCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Actual Cash',
                  _dayClosingReport!.cashReconciliation.actualCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Variance',
                  _dayClosingReport!.cashReconciliation.variance,
                  isTotal: true,
                  isVariance: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shift Summaries
        if (_dayClosingReport!.shiftSummaries.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shift Summaries',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._dayClosingReport!.shiftSummaries.map(
                    (shift) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(shift.employeeName)),
                          Expanded(
                            child: Text(_formatDuration(shift.shiftDuration)),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(
                                shift.salesDuringShift,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(shift.cashHandled),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReconciliationRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isVariance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isVariance
                    ? (amount >= 0 ? Colors.green : Colors.red)
                    : null,
              ),
            ),
          ),
          Text(
            FormattingService.currency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isVariance
                  ? (amount >= 0 ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildDailyStaffPerformanceContent() {
    if (_dailyStaffPerformanceReport == null ||
        _dailyStaffPerformanceReport!['error'] != null) {
      return const Center(child: Text('No data available'));
    }

    final data = _dailyStaffPerformanceReport!;
    final staffData = data['staffData'] as List<dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;
    final businessDate = DateTime.parse(data['businessDate'] as String);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Staff Performance Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Business Date: ${FormattingService.formatDate(businessDate.toIso8601String())}',
                  ),
                  Text('Report Type: Consolidated Staff Summary'),
                  Text(
                    'Tax Entity: ${BusinessInfo.instance.businessName} | SST No: ${BusinessInfo.instance.taxNumber ?? 'N/A'}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sales Performance Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Sales Performance Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Login Time')),
                        DataColumn(label: Text('Logout Time')),
                        DataColumn(label: Text('Gross Sales (RM)')),
                        DataColumn(label: Text('Disc (RM)')),
                        DataColumn(label: Text('Net Sales (RM)')),
                        DataColumn(label: Text('Trans Count')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(
                                  _formatTime(staff['loginTime'] as String?),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatTime(staff['logoutTime'] as String?),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['grossSales'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['discounts'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['netSales'] as double,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  (staff['transactionCount'] as int).toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalGrossSales'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalDiscounts'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalNetSales'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalTransactions'] as int)
                                    .toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SST & Tax Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. SST & Tax Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('SST 6% (F&B)')),
                        DataColumn(label: Text('SST 8% (Other)')),
                        DataColumn(label: Text('Tax-Exempt')),
                        DataColumn(label: Text('Total SST (RM)')),
                      ],
                      rows: [
                        ...staffData.map((staff) {
                          final taxBreakdown =
                              staff['taxBreakdown'] as Map<String, dynamic>;
                          final totalTax = taxBreakdown.values.fold<double>(
                            0,
                            (sum, amount) => sum + (amount as double),
                          );
                          return DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    taxBreakdown['0.06'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    taxBreakdown['0.08'] ?? 0,
                                  ),
                                ),
                              ),
                              const DataCell(Text('0.00')),
                              DataCell(
                                Text(FormattingService.currency(totalTax)),
                              ),
                            ],
                          );
                        }),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map)['0.06'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map)['0.08'] ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const DataCell(
                              Text(
                                '0.00',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['taxBreakdown'] as Map).values
                                      .fold<double>(
                                        0,
                                        (sum, amount) =>
                                            sum + (amount as double),
                                      ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method Audit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. Payment Method Audit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Cash (RM)')),
                        DataColumn(label: Text('Credit Card')),
                        DataColumn(label: Text('TNG / GrabPay')),
                        DataColumn(label: Text('ShopeePay')),
                      ],
                      rows: [
                        ...staffData.map((staff) {
                          final paymentMethods =
                              staff['paymentMethods'] as Map<String, dynamic>;
                          return DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    paymentMethods['Cash'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    paymentMethods['Credit Card'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    paymentMethods['TNG / GrabPay'] ?? 0,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    paymentMethods['ShopeePay'] ?? 0,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals']
                                          as Map)['Cash'] ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals']
                                          as Map)['Credit Card'] ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals']
                                          as Map)['TNG / GrabPay'] ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  (summary['paymentMethodTotals']
                                          as Map)['ShopeePay'] ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error & Security Log
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4. Error & Security Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Staff Name')),
                        DataColumn(label: Text('Voids/Deleted Items')),
                        DataColumn(label: Text('Manual Overrides')),
                        DataColumn(label: Text('Refund Amount (RM)')),
                      ],
                      rows: [
                        ...staffData.map(
                          (staff) => DataRow(
                            cells: [
                              DataCell(Text(staff['userName'] as String)),
                              DataCell(
                                Text((staff['voids'] as int).toString()),
                              ),
                              DataCell(
                                Text((staff['overrides'] as int).toString()),
                              ),
                              DataCell(
                                Text(
                                  FormattingService.currency(
                                    staff['refunds'] as double,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataRow(
                          cells: [
                            const DataCell(
                              Text(
                                'TOTAL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalVoids'] as int).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (summary['totalOverrides'] as int).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                FormattingService.currency(
                                  summary['totalRefunds'] as double,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
