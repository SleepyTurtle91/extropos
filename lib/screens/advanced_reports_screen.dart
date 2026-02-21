import 'dart:async';
import 'dart:developer' as developer;

import 'package:csv/csv.dart';
import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/report_content_builders.dart';
import 'package:extropos/services/daily_staff_performance_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/responsive_layout.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

// Value object used to hold advanced filter settings for the AdvancedReportsScreen.
// Defined at file scope so it can be reused and tested easily.
class AdvancedReportFilter {
  final String? searchText;
  final double? minAmount;
  final double? maxAmount;
  final DateTimeRange? dateRange; // override the report period

  const AdvancedReportFilter({
    this.searchText,
    this.minAmount,
    this.maxAmount,
    this.dateRange,
  });

  AdvancedReportFilter copyWith({
    String? searchText,
    double? minAmount,
    double? maxAmount,
    DateTimeRange? dateRange,
  }) {
    return AdvancedReportFilter(
      searchText: searchText ?? this.searchText,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> {
  ReportType _selectedReportType = ReportType.salesSummary;
  ReportPeriod _selectedPeriod = ReportPeriod.today();

  // Report data
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

  bool _isLoading = false;
  bool _autoRefreshEnabled = false;
  int _autoRefreshIntervalMinutes = 5; // Default 5 minutes
  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshTime;
  AdvancedReportFilter? _currentFilter;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _startAutoRefreshIfEnabled();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

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
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Error loading report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  // Simple filter model for advanced reports
  // Includes search text, min/max amount, and optional date range override
  // Note: dateRange, if set, will update _selectedPeriod and reload the report
  // Numeric filters are applied client-side to the already-loaded report data
  // (keeps DatabaseService API unchanged)
  // This class is intentionally small; expand as needed in the future

  // Filter object definition
  // AdvancedReportFilter is a small value object defined at file scope and
  // used by this screen to allow the user to apply simple client-side
  // filters to the currently-loaded report data.

  void _startAutoRefreshIfEnabled() {
    if (_autoRefreshEnabled && _autoRefreshTimer == null) {
      _autoRefreshTimer = Timer.periodic(
        Duration(minutes: _autoRefreshIntervalMinutes),
        (timer) => _autoRefreshReport(),
      );
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _autoRefreshReport() async {
    if (_isLoading) return; // Don't refresh if already loading

    try {
      // Only refresh if the screen is still mounted and visible
      if (!mounted) {
        _stopAutoRefresh();
        return;
      }

      await _loadReport();
      _lastRefreshTime = DateTime.now();

      if (mounted) ToastHelper.showToast(context, 'Report auto-refreshed');
    } catch (e) {
      // Silently handle auto-refresh errors to avoid spamming the user
      developer.log('Auto-refresh failed: $e');
    }
  }

  void _toggleAutoRefresh() {
    if (!_autoRefreshEnabled) {
      // Show dialog to configure auto-refresh interval
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Auto-refresh Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose refresh interval:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [1, 5, 10, 15, 30].map((minutes) {
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _autoRefreshIntervalMinutes == minutes,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _autoRefreshIntervalMinutes = minutes);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _autoRefreshEnabled = true);
                _startAutoRefreshIfEnabled();
                if (mounted)
                  ToastHelper.showToast(
                    context,
                    'Auto-refresh enabled ($_autoRefreshIntervalMinutes min)',
                  );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _autoRefreshEnabled = false);
      _stopAutoRefresh();
      if (mounted) ToastHelper.showToast(context, 'Auto-refresh disabled');
    }
  }

  Future<void> _exportReport() async {
    if (_isLoading) return;

    try {
      final csvData = _generateCSVData();
      final fileName =
          '${_selectedReportType.name}_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use file selector to save
        final file = await getSaveLocation(suggestedName: fileName);
        if (file != null) {
          await File(file.path).writeAsString(csvData);
          if (mounted)
            ToastHelper.showToast(context, 'Report exported successfully');
        }
      } else {
        // Mobile: Share file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvData);
        await SharePlus.instance.share(
          ShareParams(text: 'Exported Report', sharePositionOrigin: Rect.zero),
        );
      }
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'Export failed: $e');
    }
  }

  Future<void> _exportPDF() async {
    if (_isLoading) return;

    try {
      final pdf = pw.Document();
      final reportTitle = _getReportTypeLabel(_selectedReportType);
      final generatedDate = DateTime.now();

      // Add title page
      pdf.addPage(
        pw.Page(
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
                _buildPDFContent(),
              ],
            );
          },
        ),
      );

      // Save or share the PDF
      final fileName =
          '${_selectedReportType.name}_${generatedDate.toIso8601String().substring(0, 10)}.pdf';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use file selector to save
        final file = await getSaveLocation(suggestedName: fileName);
        if (file != null) {
          final bytes = await pdf.save();
          await File(file.path).writeAsBytes(bytes);
          if (mounted)
            ToastHelper.showToast(context, 'PDF exported successfully');
        }
      } else {
        // Mobile: Use printing package to share/print
        await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      }
    } catch (e) {
      if (mounted) ToastHelper.showToast(context, 'PDF export failed: $e');
    }
  }

  pw.Widget _buildPDFContent() {
    switch (_selectedReportType) {
      case ReportType.salesSummary:
        return _buildSalesSummaryPDF();
      case ReportType.productSales:
        return _buildProductSalesPDF();
      case ReportType.categorySales:
        return _buildCategorySalesPDF();
      case ReportType.paymentMethod:
        return _buildPaymentMethodPDF();
      case ReportType.employeePerformance:
        return _buildEmployeePerformancePDF();
      case ReportType.inventory:
        return _buildInventoryPDF();
      case ReportType.shrinkage:
        return _buildShrinkagePDF();
      case ReportType.laborCost:
        return _buildLaborCostPDF();
      case ReportType.customerAnalysis:
        return _buildCustomerAnalysisPDF();
      case ReportType.basketAnalysis:
        return _buildBasketAnalysisPDF();
      case ReportType.loyaltyProgram:
        return _buildLoyaltyProgramPDF();
      case ReportType.dayClosing:
        return _buildDayClosingPDF();
      case ReportType.profitLoss:
        return _buildProfitLossPDF();
      case ReportType.cashFlow:
        return _buildCashFlowPDF();
      case ReportType.taxSummary:
        return _buildTaxSummaryPDF();
      case ReportType.inventoryValuation:
        return _buildInventoryValuationPDF();
      case ReportType.abcAnalysis:
        return _buildABCAnalysisPDF();
      case ReportType.demandForecasting:
        return _buildDemandForecastingPDF();
      case ReportType.menuEngineering:
        return _buildMenuEngineeringPDF();
      case ReportType.tablePerformance:
        return _buildTablePerformancePDF();
      case ReportType.dailyStaffPerformance:
        return _buildDailyStaffPerformancePDF();
    }
  }

  String _generateCSVData() {
    final csvData = <List<String>>[];

    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add([
            'Gross Sales',
            _salesSummaryReport!.grossSales.toStringAsFixed(2),
          ]);
          csvData.add([
            'Net Sales',
            _salesSummaryReport!.netSales.toStringAsFixed(2),
          ]);
          csvData.add([
            'Total Discounts',
            _salesSummaryReport!.totalDiscounts.toStringAsFixed(2),
          ]);
          csvData.add([
            'Total Refunds',
            _salesSummaryReport!.totalRefunds.toStringAsFixed(2),
          ]);
          csvData.add([
            'Tax Collected',
            _salesSummaryReport!.taxCollected.toStringAsFixed(2),
          ]);
          csvData.add([
            'Average Transaction Value',
            _salesSummaryReport!.averageTransactionValue.toStringAsFixed(2),
          ]);
          csvData.add([
            'Total Transactions',
            _salesSummaryReport!.totalTransactions.toString(),
          ]);
        }
        break;

      case ReportType.productSales:
        if (_productSalesReport != null) {
          csvData.add([
            'Product Name',
            'Category',
            'Units Sold',
            'Total Revenue',
            'Average Price',
          ]);
          for (final product in _productSalesReport!.productSales.where((
            product,
          ) {
            final f = _currentFilter;
            if (f == null) return true;
            var ok = true;
            if (f.searchText != null && f.searchText!.isNotEmpty) {
              ok =
                  product.productName.toLowerCase().contains(
                    f.searchText!.toLowerCase(),
                  ) ||
                  product.category.toLowerCase().contains(
                    f.searchText!.toLowerCase(),
                  );
            }
            if (f.minAmount != null)
              ok = ok && product.totalRevenue >= f.minAmount!;
            if (f.maxAmount != null)
              ok = ok && product.totalRevenue <= f.maxAmount!;
            return ok;
          })) {
            csvData.add([
              product.productName,
              product.category,
              product.unitsSold.toString(),
              product.totalRevenue.toStringAsFixed(2),
              product.averagePrice.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.categorySales:
        if (_categorySalesReport != null) {
          csvData.add([
            'Category',
            'Revenue',
            'Transactions',
            'Average Transaction',
          ]);
          for (final entry in _categorySalesReport!.categorySales.entries) {
            final name = entry.key;
            final data = entry.value;
            final f = _currentFilter;
            if (f != null) {
              if (f.searchText != null &&
                  f.searchText!.isNotEmpty &&
                  !name.toLowerCase().contains(f.searchText!.toLowerCase()))
                continue;
              if (f.minAmount != null && data.revenue < f.minAmount!) continue;
              if (f.maxAmount != null && data.revenue > f.maxAmount!) continue;
            }
            csvData.add([
              name,
              data.revenue.toStringAsFixed(2),
              data.transactionCount.toString(),
              data.averageTransactionValue.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.paymentMethod:
        if (_paymentMethodReport != null) {
          csvData.add([
            'Payment Method',
            'Total Amount',
            'Transactions',
            'Average Transaction',
            'Percentage',
          ]);
          for (final entry in _paymentMethodReport!.paymentBreakdown.entries) {
            final name = entry.key;
            final data = entry.value;
            final f = _currentFilter;
            if (f != null) {
              if (f.searchText != null &&
                  f.searchText!.isNotEmpty &&
                  !name.toLowerCase().contains(f.searchText!.toLowerCase()))
                continue;
              if (f.minAmount != null && data.totalAmount < f.minAmount!)
                continue;
              if (f.maxAmount != null && data.totalAmount > f.maxAmount!)
                continue;
            }
            csvData.add([
              name,
              data.totalAmount.toStringAsFixed(2),
              data.transactionCount.toString(),
              data.averageTransaction.toStringAsFixed(2),
              '${data.percentageOfTotal.toStringAsFixed(1)}%',
            ]);
          }
        }
        break;

      case ReportType.employeePerformance:
        if (_employeePerformanceReport != null) {
          csvData.add([
            'Employee',
            'Total Sales',
            'Transactions',
            'Average Transaction',
            'Discounts Given',
          ]);
          for (final employee
              in _employeePerformanceReport!.employeePerformance.where((
                employee,
              ) {
                final f = _currentFilter;
                if (f == null) return true;
                var ok = true;
                if (f.searchText != null && f.searchText!.isNotEmpty)
                  ok = employee.employeeName.toLowerCase().contains(
                    f.searchText!.toLowerCase(),
                  );
                if (f.minAmount != null)
                  ok = ok && employee.totalSales >= f.minAmount!;
                if (f.maxAmount != null)
                  ok = ok && employee.totalSales <= f.maxAmount!;
                return ok;
              })) {
            csvData.add([
              employee.employeeName,
              employee.totalSales.toStringAsFixed(2),
              employee.transactionCount.toString(),
              employee.averageTransactionValue.toStringAsFixed(2),
              employee.totalDiscountsGiven.toStringAsFixed(2),
            ]);
          }
        }
        break;

      case ReportType.inventory:
        if (_inventoryReport != null) {
          csvData.add([
            'Item Name',
            'Category',
            'Stock Level',
            'Reorder Point',
            'Status',
            'Days Since Last Sale',
          ]);
          for (final item in _inventoryReport!.inventoryItems) {
            csvData.add([
              item.itemName,
              item.category,
              item.currentStock.toString(),
              item.reorderPoint.toString(),
              item.stockStatus,
              item.daysSinceLastSale.toString(),
            ]);
          }
        }
        break;

      case ReportType.shrinkage:
        if (_shrinkageReport != null) {
          csvData.add([
            'Item Name',
            'Expected Quantity',
            'Actual Quantity',
            'Variance',
            'Reason',
            'Last Count Date',
          ]);
          for (final item in _shrinkageReport!.shrinkageItems) {
            csvData.add([
              item.itemName,
              item.expectedQuantity.toString(),
              item.actualQuantity.toString(),
              item.variance.toString(),
              item.reason,
              item.lastCountDate.toString(),
            ]);
          }
        }
        break;

      case ReportType.laborCost:
        if (_laborCostReport != null) {
          csvData.add(['Department', 'Labor Cost', 'Percentage of Sales']);
          for (final entry in _laborCostReport!.laborCostByDepartment.entries) {
            final dept = entry.key;
            final cost = entry.value;
            csvData.add([
              dept,
              cost.toStringAsFixed(2),
              '${_laborCostReport!.laborCostPercentage.toStringAsFixed(1)}%',
            ]);
          }
        }
        break;

      case ReportType.customerAnalysis:
        if (_customerReport != null) {
          csvData.add([
            'Customer Name',
            'Total Spent',
            'Visit Count',
            'Average Order Value',
            'Last Visit',
          ]);
          for (final customer in _customerReport!.topCustomers.where((
            customer,
          ) {
            final f = _currentFilter;
            if (f == null) return true;
            var ok = true;
            if (f.searchText != null && f.searchText!.isNotEmpty)
              ok = customer.customerName.toLowerCase().contains(
                f.searchText!.toLowerCase(),
              );
            if (f.minAmount != null)
              ok = ok && customer.totalSpent >= f.minAmount!;
            if (f.maxAmount != null)
              ok = ok && customer.totalSpent <= f.maxAmount!;
            return ok;
          })) {
            csvData.add([
              customer.customerName,
              customer.totalSpent.toStringAsFixed(2),
              customer.visitCount.toString(),
              customer.averageOrderValue.toStringAsFixed(2),
              customer.lastVisit.toString(),
            ]);
          }
        }
        break;

      case ReportType.basketAnalysis:
        if (_basketAnalysisReport != null) {
          csvData.add(['Analysis Type', 'Details']);
          csvData.add([
            'Frequently Bought Together',
            _basketAnalysisReport!.frequentlyBoughtTogether.length.toString(),
          ]);
          csvData.add([
            'Product Affinities',
            _basketAnalysisReport!.productAffinityScores.length.toString(),
          ]);
          csvData.add([
            'Recommended Bundles',
            _basketAnalysisReport!.recommendedBundles.length.toString(),
          ]);
        }
        break;

      case ReportType.loyaltyProgram:
        if (_loyaltyProgramReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add([
            'Total Members',
            _loyaltyProgramReport!.totalMembers.toString(),
          ]);
          csvData.add([
            'Active Members',
            _loyaltyProgramReport!.activeMembers.toString(),
          ]);
          csvData.add([
            'Points Issued',
            _loyaltyProgramReport!.totalPointsIssued.toString(),
          ]);
          csvData.add([
            'Points Redeemed',
            _loyaltyProgramReport!.totalPointsRedeemed.toString(),
          ]);
          csvData.add([
            'Redemption Rate',
            '${_loyaltyProgramReport!.redemptionRate.toStringAsFixed(1)}%',
          ]);
        }
        break;

      case ReportType.dayClosing:
        if (_dayClosingReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add([
            'Total Sales',
            _dayClosingReport!.totalSales.toStringAsFixed(2),
          ]);
          csvData.add([
            'Net Sales',
            _dayClosingReport!.netSales.toStringAsFixed(2),
          ]);
          csvData.add([
            'Cash Expected',
            _dayClosingReport!.cashExpected.toStringAsFixed(2),
          ]);
          csvData.add([
            'Cash Actual',
            _dayClosingReport!.cashActual.toStringAsFixed(2),
          ]);
          csvData.add([
            'Cash Variance',
            _dayClosingReport!.cashVariance.toStringAsFixed(2),
          ]);
          csvData.add(['', '']); // Empty row
          csvData.add(['Cash Reconciliation Details', '']);
          csvData.add([
            'Opening Float',
            _dayClosingReport!.cashReconciliation.openingFloat.toStringAsFixed(
              2,
            ),
          ]);
          csvData.add([
            'Cash Sales',
            _dayClosingReport!.cashReconciliation.cashSales.toStringAsFixed(2),
          ]);
          csvData.add([
            'Cash Refunds',
            _dayClosingReport!.cashReconciliation.cashRefunds.toStringAsFixed(
              2,
            ),
          ]);
          csvData.add([
            'Paid Outs',
            _dayClosingReport!.cashReconciliation.paidOuts.toStringAsFixed(2),
          ]);
          csvData.add([
            'Paid Ins',
            _dayClosingReport!.cashReconciliation.paidIns.toStringAsFixed(2),
          ]);
          csvData.add(['', '']); // Empty row
          csvData.add([
            'Employee',
            'Shift Start',
            'Shift End',
            'Sales',
            'Cash Handled',
            'Duration',
          ]);
          for (final shift in _dayClosingReport!.shiftSummaries) {
            final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
            csvData.add([
              shift.employeeName,
              shift.shiftStart.toIso8601String(),
              endTime,
              shift.salesDuringShift.toStringAsFixed(2),
              shift.cashHandled.toStringAsFixed(2),
              '${shift.shiftDuration.inHours}h ${shift.shiftDuration.inMinutes % 60}m',
            ]);
          }
        }
        break;
      case ReportType.profitLoss:
        if (_profitLossReport != null) {
          csvData.add(['Metric', 'Value']);
          csvData.add([
            'Total Revenue',
            _profitLossReport!.totalRevenue.toStringAsFixed(2),
          ]);
          csvData.add([
            'Cost of Goods Sold',
            _profitLossReport!.costOfGoodsSold.toStringAsFixed(2),
          ]);
          csvData.add([
            'Gross Profit',
            _profitLossReport!.grossProfit.toStringAsFixed(2),
          ]);
          csvData.add([
            'Operating Expenses',
            _profitLossReport!.operatingExpenses.toStringAsFixed(2),
          ]);
          csvData.add([
            'Net Profit',
            _profitLossReport!.netProfit.toStringAsFixed(2),
          ]);
          csvData.add([
            'Profit Margin',
            '${_profitLossReport!.profitMargin.toStringAsFixed(1)}%',
          ]);
        }
        break;
      case ReportType.cashFlow:
        if (_cashFlowReport != null) {
          csvData.add(['Cash Flow Type', 'Amount']);
          csvData.add([
            'Opening Cash',
            _cashFlowReport!.openingCash.toStringAsFixed(2),
          ]);
          csvData.add([
            'Closing Cash',
            _cashFlowReport!.closingCash.toStringAsFixed(2),
          ]);
          csvData.add([
            'Net Cash Flow',
            _cashFlowReport!.netCashFlow.toStringAsFixed(2),
          ]);
          csvData.add(['', '']); // Empty row
          csvData.add(['Inflows', '']);
          for (final entry in _cashFlowReport!.inflowBreakdown.entries) {
            final key = entry.key;
            final value = entry.value;
            csvData.add([key, value.toStringAsFixed(2)]);
          }
          csvData.add(['', '']); // Empty row
          csvData.add(['Outflows', '']);
          for (final entry in _cashFlowReport!.outflowBreakdown.entries) {
            final key = entry.key;
            final value = entry.value;
            csvData.add([key, (-value).toStringAsFixed(2)]);
          }
        }
        break;
      case ReportType.taxSummary:
        if (_taxSummaryReport != null) {
          csvData.add(['Tax Rate', 'Amount Collected']);
          csvData.add([
            'Total Tax Collected',
            _taxSummaryReport!.totalTaxCollected.toStringAsFixed(2),
          ]);
          csvData.add([
            'Tax Liability',
            _taxSummaryReport!.taxLiability.toStringAsFixed(2),
          ]);
          csvData.add(['', '']); // Empty row
          for (final entry in _taxSummaryReport!.taxBreakdown.entries) {
            final rate = entry.key;
            final amount = entry.value;
            csvData.add([rate, amount.toStringAsFixed(2)]);
          }
        }
        break;
      case ReportType.inventoryValuation:
        if (_inventoryValuationReport != null) {
          csvData.add(['Item', 'Cost Value', 'Retail Value', 'Units']);
          for (final item in _inventoryValuationReport!.valuationItems) {
            csvData.add([
              item.itemName,
              item.totalCostValue.toStringAsFixed(2),
              item.totalRetailValue.toStringAsFixed(2),
              item.quantity.toString(),
            ]);
          }
        }
        break;
      case ReportType.abcAnalysis:
        if (_abcAnalysisReport != null) {
          csvData.add(['Item', 'Category', 'Revenue', 'Percentage']);
          for (final item in _abcAnalysisReport!.abcItems) {
            csvData.add([
              item.itemName,
              item.category,
              item.revenue.toStringAsFixed(2),
              '${item.percentageOfTotal.toStringAsFixed(1)}%',
            ]);
          }
        }
        break;
      case ReportType.demandForecasting:
        if (_demandForecastingReport != null) {
          csvData.add([
            'Item',
            'Historical Sales',
            'Forecasted Sales',
            'Confidence',
          ]);
          for (final item in _demandForecastingReport!.forecastItems) {
            csvData.add([
              item.itemName,
              item.historicalSales.last.toStringAsFixed(0),
              item.forecastedSales.last.toStringAsFixed(0),
              '${(item.confidenceLevel * 100).toStringAsFixed(0)}%',
            ]);
          }
        }
        break;
      case ReportType.menuEngineering:
        if (_menuEngineeringReport != null) {
          csvData.add(['Item', 'Category', 'Popularity %', 'Profitability %']);
          for (final item in _menuEngineeringReport!.menuItems) {
            csvData.add([
              item.itemName,
              item.category,
              item.popularity.toStringAsFixed(1),
              item.profitability.toStringAsFixed(1),
            ]);
          }
        }
        break;
      case ReportType.tablePerformance:
        if (_tablePerformanceReport != null) {
          csvData.add([
            'Table',
            'Revenue',
            'Orders',
            'Avg Occupancy',
            'Revenue/Hour',
          ]);
          for (final table in _tablePerformanceReport!.tableData) {
            csvData.add([
              table.tableName,
              table.totalRevenue.toStringAsFixed(2),
              table.totalOrders.toString(),
              '${table.averageOccupancyTime.inHours}h ${table.averageOccupancyTime.inMinutes % 60}m',
              table.revenuePerHour.toStringAsFixed(2),
            ]);
          }
        }
        break;
      case ReportType.dailyStaffPerformance:
        if (_dailyStaffPerformanceReport != null) {
          final data = _dailyStaffPerformanceReport!;
          final staffData = data['staffData'] as List<dynamic>;
          final summary = data['summary'] as Map<String, dynamic>;

          csvData.add([
            'Staff Name',
            'Login Time',
            'Logout Time',
            'Gross Sales',
            'Discounts',
            'Net Sales',
            'Transactions',
            'SST 6%',
            'SST 8%',
            'Total SST',
            'Cash',
            'Credit Card',
            'TNG/GrabPay',
            'ShopeePay',
            'Voids',
            'Overrides',
            'Refunds',
          ]);

          for (final staff in staffData) {
            final taxBreakdown = staff['taxBreakdown'] as Map<String, dynamic>;
            final paymentMethods =
                staff['paymentMethods'] as Map<String, dynamic>;
            final totalTax = taxBreakdown.values.fold<double>(
              0,
              (sum, amount) => sum + (amount as double),
            );

            csvData.add([
              staff['userName'] as String,
              _formatTime(staff['loginTime'] as String?),
              _formatTime(staff['logoutTime'] as String?),
              (staff['grossSales'] as double).toStringAsFixed(2),
              (staff['discounts'] as double).toStringAsFixed(2),
              (staff['netSales'] as double).toStringAsFixed(2),
              (staff['transactionCount'] as int).toString(),
              (taxBreakdown['0.06'] ?? 0).toStringAsFixed(2),
              (taxBreakdown['0.08'] ?? 0).toStringAsFixed(2),
              totalTax.toStringAsFixed(2),
              (paymentMethods['Cash'] ?? 0).toStringAsFixed(2),
              (paymentMethods['Credit Card'] ?? 0).toStringAsFixed(2),
              (paymentMethods['TNG / GrabPay'] ?? 0).toStringAsFixed(2),
              (paymentMethods['ShopeePay'] ?? 0).toStringAsFixed(2),
              (staff['voids'] as int).toString(),
              (staff['overrides'] as int).toString(),
              (staff['refunds'] as double).toStringAsFixed(2),
            ]);
          }

          // Add totals row
          final totalTax = (summary['taxBreakdown'] as Map).values.fold<double>(
            0,
            (sum, amount) => sum + (amount as double),
          );
          csvData.add([
            'TOTAL',
            '',
            '',
            (summary['totalGrossSales'] as double).toStringAsFixed(2),
            (summary['totalDiscounts'] as double).toStringAsFixed(2),
            (summary['totalNetSales'] as double).toStringAsFixed(2),
            (summary['totalTransactions'] as int).toString(),
            ((summary['taxBreakdown'] as Map)['0.06'] ?? 0).toStringAsFixed(2),
            ((summary['taxBreakdown'] as Map)['0.08'] ?? 0).toStringAsFixed(2),
            totalTax.toStringAsFixed(2),
            ((summary['paymentMethodTotals'] as Map)['Cash'] ?? 0)
                .toStringAsFixed(2),
            ((summary['paymentMethodTotals'] as Map)['Credit Card'] ?? 0)
                .toStringAsFixed(2),
            ((summary['paymentMethodTotals'] as Map)['TNG / GrabPay'] ?? 0)
                .toStringAsFixed(2),
            ((summary['paymentMethodTotals'] as Map)['ShopeePay'] ?? 0)
                .toStringAsFixed(2),
            (summary['totalVoids'] as int).toString(),
            (summary['totalOverrides'] as int).toString(),
            (summary['totalRefunds'] as double).toStringAsFixed(2),
          ]);
        }
        break;
    }

    return const ListToCsvConverter().convert(csvData);
  }

  pw.Widget _buildSalesSummaryPDF() {
    if (_salesSummaryReport == null) return pw.Text('No data available');

    final report = _salesSummaryReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Gross Sales', 'RM${report.grossSales.toStringAsFixed(2)}'],
            ['Net Sales', 'RM${report.netSales.toStringAsFixed(2)}'],
            ['Total Transactions', report.totalTransactions.toString()],
            [
              'Average Transaction',
              'RM${report.averageTransactionValue.toStringAsFixed(2)}',
            ],
            ['Tax Collected', 'RM${report.taxCollected.toStringAsFixed(2)}'],
            [
              'Total Discounts',
              'RM${report.totalDiscounts.toStringAsFixed(2)}',
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildProductSalesPDF() {
    if (_productSalesReport == null) return pw.Text('No data available');

    final report = _productSalesReport!;
    final filteredProducts = report.productSales
        .where((p) => _matchesProductFilter(p))
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Products: ${filteredProducts.length}'),
        pw.Text(
          'Total Units Sold: ${filteredProducts.fold<int>(0, (s, p) => s + p.unitsSold)}',
        ),
        pw.Text(
          'Total Revenue: RM${filteredProducts.fold<double>(0, (s, p) => s + p.totalRevenue).toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Top Products',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Product', 'Category', 'Units Sold', 'Revenue'],
          data: filteredProducts
              .take(20)
              .map(
                (product) => [
                  product.productName,
                  product.category,
                  product.unitsSold.toString(),
                  'RM${product.totalRevenue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildCategorySalesPDF() {
    if (_categorySalesReport == null) return pw.Text('No data available');

    final report = _categorySalesReport!;
    final filteredEntries = report.categorySales.entries
        .where(_matchesCategoryFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Performance',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Category', 'Revenue', 'Transactions', 'Avg Transaction'],
          data: filteredEntries
              .map(
                (entry) => [
                  entry.key,
                  'RM${entry.value.revenue.toStringAsFixed(2)}',
                  entry.value.transactionCount.toString(),
                  'RM${entry.value.averageTransactionValue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentMethodPDF() {
    if (_paymentMethodReport == null) return pw.Text('No data available');

    final report = _paymentMethodReport!;
    final filteredPaymentEntries = report.paymentBreakdown.entries
        .where(_matchesPaymentMethodFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Method Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Processed: RM${filteredPaymentEntries.fold<double>(0.0, (s, e) => s + e.value.totalAmount).toStringAsFixed(2)}',
        ),
        pw.Text('Most Used: ${report.mostUsedMethod}'),
        pw.Text('Highest Revenue: ${report.highestRevenueMethod}'),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: [
            'Method',
            'Amount',
            'Transactions',
            'Average',
            'Percentage',
          ],
          data: filteredPaymentEntries
              .map(
                (entry) => [
                  entry.key,
                  'RM${entry.value.totalAmount.toStringAsFixed(2)}',
                  entry.value.transactionCount.toString(),
                  'RM${entry.value.averageTransaction.toStringAsFixed(2)}',
                  '${entry.value.percentageOfTotal.toStringAsFixed(1)}%',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildEmployeePerformancePDF() {
    if (_employeePerformanceReport == null) return pw.Text('No data available');

    final report = _employeePerformanceReport!;
    final filteredEmployees = report.employeePerformance
        .where(_matchesEmployeeFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Performance',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: [
            'Employee',
            'Sales',
            'Transactions',
            'Avg Transaction',
            'Discounts',
          ],
          data: filteredEmployees
              .map(
                (employee) => [
                  employee.employeeName,
                  'RM${employee.totalSales.toStringAsFixed(2)}',
                  employee.transactionCount.toString(),
                  'RM${employee.averageTransactionValue.toStringAsFixed(2)}',
                  'RM${employee.totalDiscountsGiven.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryPDF() {
    if (_inventoryReport == null) return pw.Text('No data available');

    final report = _inventoryReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Overview',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Items: ${report.inventoryItems.length}'),
        pw.Text('Low Stock Items: ${report.lowStockItems.length}'),
        pw.Text('Out of Stock: ${report.outOfStockItems.length}'),
        pw.Text(
          'Total Value: RM${report.totalInventoryValue.toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Inventory Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Stock', 'Reorder Point', 'Status'],
          data: report.inventoryItems
              .take(30)
              .map(
                (item) => [
                  item.itemName,
                  item.currentStock.toString(),
                  item.reorderPoint.toString(),
                  item.stockStatus,
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildShrinkagePDF() {
    if (_shrinkageReport == null) return pw.Text('No data available');

    final report = _shrinkageReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Shrinkage Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Shrinkage Items: ${report.shrinkageItems.length}'),
        pw.Text(
          'Total Shrinkage Value: RM${report.totalShrinkageValue.toStringAsFixed(2)}',
        ),
        pw.Text(
          'Shrinkage Percentage: ${report.totalShrinkagePercentage.toStringAsFixed(1)}%',
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Variance', 'Value', 'Reason', 'Last Count'],
          data: report.shrinkageItems
              .take(20)
              .map(
                (item) => [
                  item.itemName,
                  item.variance.toString(),
                  'RM${item.varianceValue.toStringAsFixed(2)}',
                  item.reason,
                  item.lastCountDate.toString().substring(0, 10),
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildLaborCostPDF() {
    if (_laborCostReport == null) return pw.Text('No data available');

    final report = _laborCostReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Labor Cost Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Labor Cost: RM${report.totalLaborCost.toStringAsFixed(2)}',
        ),
        pw.Text(
          'Labor Cost Percentage: ${report.laborCostPercentage.toStringAsFixed(1)}%',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Cost by Department',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Department', 'Labor Cost'],
          data: report.laborCostByDepartment.entries
              .map(
                (entry) => [entry.key, 'RM${entry.value.toStringAsFixed(2)}'],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAnalysisPDF() {
    if (_customerReport == null) return pw.Text('No data available');

    final report = _customerReport!;
    final filteredCustomers = report.topCustomers
        .where(_matchesCustomerFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Customer Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Customers: ${report.totalActiveCustomers}'),
        pw.Text(
          'Average Lifetime Value: RM${report.averageCustomerLifetimeValue.toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Top Customers',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Customer', 'Total Spent', 'Visits', 'Avg Order'],
          data: filteredCustomers
              .take(15)
              .map(
                (customer) => [
                  customer.customerName,
                  'RM${customer.totalSpent.toStringAsFixed(2)}',
                  customer.visitCount.toString(),
                  'RM${customer.averageOrderValue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildBasketAnalysisPDF() {
    if (_basketAnalysisReport == null) return pw.Text('No data available');

    final report = _basketAnalysisReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Basket Analysis Insights',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Frequently Bought Together: ${report.frequentlyBoughtTogether.length} combinations',
        ),
        pw.Text(
          'Product Affinities: ${report.productAffinityScores.length} scores calculated',
        ),
        pw.Text(
          'Recommended Bundles: ${report.recommendedBundles.length} suggestions',
        ),
      ],
    );
  }

  pw.Widget _buildLoyaltyProgramPDF() {
    if (_loyaltyProgramReport == null) return pw.Text('No data available');

    final report = _loyaltyProgramReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Loyalty Program Analytics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Members: ${report.totalMembers}'),
        pw.Text('Active Members: ${report.activeMembers}'),
        pw.Text(
          'Points Issued: ${report.totalPointsIssued.toStringAsFixed(0)}',
        ),
        pw.Text(
          'Points Redeemed: ${report.totalPointsRedeemed.toStringAsFixed(0)}',
        ),
        pw.Text(
          'Redemption Rate: ${report.redemptionRate.toStringAsFixed(1)}%',
        ),
        pw.Text(
          'Revenue from Loyalty Members: RM${report.revenueFromLoyaltyMembers.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  pw.Widget _buildDayClosingPDF() {
    if (_dayClosingReport == null) return pw.Text('No data available');

    final report = _dayClosingReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Day Closing Report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        // Business Session Summary
        pw.Text(
          'Business Session Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Sales: ${FormattingService.currency(report.totalSales)}',
        ),
        pw.Text('Net Sales: ${FormattingService.currency(report.netSales)}'),
        pw.Text(
          'Cash Expected: ${FormattingService.currency(report.cashExpected)}',
        ),
        pw.Text(
          'Cash Actual: ${FormattingService.currency(report.cashActual)}',
        ),
        pw.Text(
          'Cash Variance: ${FormattingService.currency(report.cashVariance)}',
        ),
        pw.SizedBox(height: 20),

        // Cash Reconciliation
        pw.Text(
          'Cash Reconciliation',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Opening Float: ${FormattingService.currency(report.cashReconciliation.openingFloat)}',
        ),
        pw.Text(
          'Cash Sales: ${FormattingService.currency(report.cashReconciliation.cashSales)}',
        ),
        pw.Text(
          'Cash Refunds: ${FormattingService.currency(report.cashReconciliation.cashRefunds)}',
        ),
        pw.Text(
          'Paid Outs: ${FormattingService.currency(report.cashReconciliation.paidOuts)}',
        ),
        pw.Text(
          'Paid Ins: ${FormattingService.currency(report.cashReconciliation.paidIns)}',
        ),
        pw.Text(
          'Expected Cash: ${FormattingService.currency(report.cashReconciliation.expectedCash)}',
        ),
        pw.Text(
          'Actual Cash: ${FormattingService.currency(report.cashReconciliation.actualCash)}',
        ),
        pw.Text(
          'Variance: ${FormattingService.currency(report.cashReconciliation.variance)}',
        ),
        pw.SizedBox(height: 20),

        // Shift Summaries
        if (report.shiftSummaries.isNotEmpty) ...[
          pw.Text(
            'Shift Summaries',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...report.shiftSummaries.map((shift) {
            final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
            return pw.Text(
              '${shift.employeeName}: ${shift.shiftStart.toIso8601String()} - $endTime, Sales: ${FormattingService.currency(shift.salesDuringShift)}, Cash: ${FormattingService.currency(shift.cashHandled)}, Duration: ${_formatDuration(shift.shiftDuration)}',
            );
          }),
        ],
      ],
    );
  }

  pw.Widget _buildProfitLossPDF() {
    if (_profitLossReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Profit & Loss Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Revenue: ${FormattingService.currency(_profitLossReport!.totalRevenue)}',
        ),
        pw.Text(
          'Cost of Goods Sold: ${FormattingService.currency(_profitLossReport!.costOfGoodsSold)}',
        ),
        pw.Text(
          'Gross Profit: ${FormattingService.currency(_profitLossReport!.grossProfit)}',
        ),
        pw.Text(
          'Operating Expenses: ${FormattingService.currency(_profitLossReport!.operatingExpenses)}',
        ),
        pw.Text(
          'Net Profit: ${FormattingService.currency(_profitLossReport!.netProfit)}',
        ),
        pw.Text(
          'Profit Margin: ${_profitLossReport!.profitMargin.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  pw.Widget _buildCashFlowPDF() {
    if (_cashFlowReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cash Flow Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Opening Cash: ${FormattingService.currency(_cashFlowReport!.openingCash)}',
        ),
        pw.Text(
          'Closing Cash: ${FormattingService.currency(_cashFlowReport!.closingCash)}',
        ),
        pw.Text(
          'Net Cash Flow: ${FormattingService.currency(_cashFlowReport!.netCashFlow)}',
        ),
      ],
    );
  }

  pw.Widget _buildTaxSummaryPDF() {
    if (_taxSummaryReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tax Summary Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Tax Collected: ${FormattingService.currency(_taxSummaryReport!.totalTaxCollected)}',
        ),
        pw.Text(
          'Tax Liability: ${FormattingService.currency(_taxSummaryReport!.taxLiability)}',
        ),
        ..._taxSummaryReport!.taxBreakdown.entries.map(
          (entry) => pw.Text(
            '${entry.key} Tax Rate: ${FormattingService.currency(entry.value)}',
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryValuationPDF() {
    if (_inventoryValuationReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Valuation Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Value: ${FormattingService.currency(_inventoryValuationReport!.totalInventoryValue)}',
        ),
        pw.Text(
          'Turnover Ratio: ${_inventoryValuationReport!.inventoryTurnoverRatio.toStringAsFixed(2)}',
        ),
        ..._inventoryValuationReport!.valuationItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName}: ${FormattingService.currency(item.totalRetailValue)}',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildABCAnalysisPDF() {
    if (_abcAnalysisReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ABC Analysis Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.aCategoryRevenue)}',
        ),
        pw.Text(
          'B Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.bCategoryRevenue)}',
        ),
        pw.Text(
          'C Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.cCategoryRevenue)}',
        ),
        ..._abcAnalysisReport!.abcItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.percentageOfTotal.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildDemandForecastingPDF() {
    if (_demandForecastingReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Demand Forecasting Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Forecasting Method: ${_demandForecastingReport!.forecastingMethod}',
        ),
        pw.Text(
          'Forecast Accuracy: ${(_demandForecastingReport!.forecastAccuracy * 100).toStringAsFixed(1)}%',
        ),
        ..._demandForecastingReport!.forecastItems
            .take(5)
            .map(
              (item) => pw.Text(
                '${item.itemName}: Historical ${item.historicalSales.last.toStringAsFixed(0)}, Forecast ${item.forecastedSales.last.toStringAsFixed(0)}',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildMenuEngineeringPDF() {
    if (_menuEngineeringReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Menu Engineering Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Stars: ${_menuEngineeringReport!.starsCount}'),
        pw.Text('Plowhorses: ${_menuEngineeringReport!.plowhorsesCount}'),
        pw.Text('Puzzles: ${_menuEngineeringReport!.puzzlesCount}'),
        pw.Text('Dogs: ${_menuEngineeringReport!.dogsCount}'),
        ..._menuEngineeringReport!.menuItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.popularity.toStringAsFixed(1)}% / ${item.profitability.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildTablePerformancePDF() {
    if (_tablePerformanceReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Table Performance Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Tables: ${_tablePerformanceReport!.totalTables}'),
        pw.Text('Occupied Tables: ${_tablePerformanceReport!.occupiedTables}'),
        pw.Text(
          'Average Turnover: ${_tablePerformanceReport!.averageTableTurnover.toStringAsFixed(1)}',
        ),
        pw.Text(
          'Average Revenue/Table: ${FormattingService.currency(_tablePerformanceReport!.averageRevenuePerTable)}',
        ),
        ..._tablePerformanceReport!.tableData
            .take(10)
            .map(
              (table) => pw.Text(
                '${table.tableName}: ${FormattingService.currency(table.totalRevenue)}, ${table.totalOrders} orders',
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        backgroundColor: const Color(0xFF2563EB),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadReport(),
            tooltip: 'Refresh Report',
          ),
          IconButton(
            icon: Icon(_autoRefreshEnabled ? Icons.timer_off : Icons.timer),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefreshEnabled
                ? 'Disable Auto-refresh'
                : 'Enable Auto-refresh',
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _currentFilter != null ? Colors.amberAccent : null,
            ),
            onPressed: _showFilterDialog,
            tooltip: _currentFilter != null ? 'Filters (Active)' : 'Filters',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onSelected: (value) {
              switch (value) {
                case 'csv':
                  _exportReport();
                  break;
                case 'pdf':
                  _exportPDF();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveLayout(
        builder: (context, constraints, info) {
          return Column(
            children: [
              // Report Type Selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
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
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: _selectedReportType == type
                                ? Colors.white
                                : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Period: ${_selectedPeriod.label}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        if (_currentFilter != null)
                          Flexible(
                            child: GestureDetector(
                              onTap: _showFilterDialog,
                              child: Chip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.amber[50],
                                label: Text(
                                  _filterSummary(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showPeriodSelector,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Change Period'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _autoRefreshEnabled ? Icons.timer : Icons.access_time,
                          size: 16,
                          color: _autoRefreshEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _autoRefreshEnabled
                              ? 'Auto-refresh: ${_autoRefreshIntervalMinutes}min'
                              : 'Manual refresh only',
                          style: TextStyle(
                            fontSize: 12,
                            color: _autoRefreshEnabled
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        if (_lastRefreshTime != null) ...[
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.update,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last updated: ${_formatLastRefreshTime()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Report Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildReportContent(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportContent() {
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
        return _buildCustomerAnalysisContent();
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
    if (_salesSummaryReport == null) return const SizedBox.shrink();

    final report = _salesSummaryReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Metrics Cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Gross Sales',
              'RM${report.grossSales.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Net Sales',
              'RM${report.netSales.toStringAsFixed(2)}',
              Icons.trending_up,
            ),
            _buildMetricCard(
              'Total Transactions',
              report.totalTransactions.toString(),
              Icons.receipt,
            ),
            _buildMetricCard(
              'Avg Transaction',
              'RM${report.averageTransactionValue.toStringAsFixed(2)}',
              Icons.analytics,
            ),
            _buildMetricCard(
              'Tax Collected',
              'RM${report.taxCollected.toStringAsFixed(2)}',
              Icons.account_balance,
            ),
            _buildMetricCard(
              'Total Discounts',
              'RM${report.totalDiscounts.toStringAsFixed(2)}',
              Icons.discount,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Hourly Sales Chart
        const Text(
          'Sales by Hour',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(24, (hour) {
                return BarChartGroupData(
                  x: hour,
                  barRods: [
                    BarChartRodData(
                      toY: report.hourlySales[hour.toString()] ?? 0,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        Text('${value.toInt()}:00'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSalesContent() {
    if (_productSalesReport == null) return const SizedBox.shrink();

    final report = _productSalesReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Products',
              report.productSales
                  .where(_matchesProductFilter)
                  .length
                  .toString(),
              Icons.inventory,
            ),
            _buildMetricCard(
              'Total Units Sold',
              report.productSales
                  .where(_matchesProductFilter)
                  .fold<int>(0, (sum, p) => sum + p.unitsSold)
                  .toString(),
              Icons.shopping_cart,
            ),
            _buildMetricCard(
              'Total Revenue',
              'RM${report.productSales.where(_matchesProductFilter).fold<double>(0, (sum, p) => sum + p.totalRevenue).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Top Selling Products
        const Text(
          'Top Selling Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.productSales
                  .where((product) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok =
                          product.productName.toLowerCase().contains(
                            f.searchText!.toLowerCase(),
                          ) ||
                          product.category.toLowerCase().contains(
                            f.searchText!.toLowerCase(),
                          );
                    }
                    if (f.minAmount != null) {
                      ok = ok && product.totalRevenue >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && product.totalRevenue <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .take(10)
                  .map((product) {
                    return ListTile(
                      title: Text(product.productName),
                      subtitle: Text(
                        '${product.category} • ${product.unitsSold} units',
                      ),
                      trailing: Text(
                        'RM${product.totalRevenue.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySalesContent() {
    if (_categorySalesReport == null) return const SizedBox.shrink();

    final report = _categorySalesReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Categories',
              report.categorySales.entries
                  .where(_matchesCategoryFilter)
                  .length
                  .toString(),
              Icons.category,
            ),
            _buildMetricCard(
              'Top Category',
              (report.categorySales.entries
                      .where(_matchesCategoryFilter)
                      .isEmpty
                  ? report.topPerformingCategory
                  : report.categorySales.entries
                        .where(_matchesCategoryFilter)
                        .reduce(
                          (a, b) => a.value.revenue > b.value.revenue ? a : b,
                        )
                        .key),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Category Performance
        const Text(
          'Category Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.categorySales.entries
                  .where((entry) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = entry.key.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && entry.value.revenue >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && entry.value.revenue <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((entry) {
                    final data = entry.value;
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${data.transactionCount} transactions'),
                      trailing: Text('RM${data.revenue.toStringAsFixed(2)}'),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodContent() {
    if (_paymentMethodReport == null) return const SizedBox.shrink();

    final report = _paymentMethodReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Processed',
              'RM${report.paymentBreakdown.entries.where(_matchesPaymentMethodFilter).fold<double>(0.0, (sum, e) => sum + e.value.totalAmount).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Most Used',
              (report.paymentBreakdown.entries
                      .where(_matchesPaymentMethodFilter)
                      .isEmpty
                  ? report.mostUsedMethod
                  : report.paymentBreakdown.entries
                        .where(_matchesPaymentMethodFilter)
                        .reduce(
                          (a, b) =>
                              a.value.transactionCount >
                                  b.value.transactionCount
                              ? a
                              : b,
                        )
                        .key),
              Icons.payment,
            ),
            _buildMetricCard(
              'Highest Revenue',
              (report.paymentBreakdown.entries
                      .where(_matchesPaymentMethodFilter)
                      .isEmpty
                  ? report.highestRevenueMethod
                  : report.paymentBreakdown.entries
                        .where(_matchesPaymentMethodFilter)
                        .reduce(
                          (a, b) =>
                              a.value.totalAmount > b.value.totalAmount ? a : b,
                        )
                        .key),
              Icons.trending_up,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Payment Method Breakdown
        const Text(
          'Payment Method Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.paymentBreakdown.entries
                  .where((entry) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = entry.key.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && entry.value.totalAmount >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && entry.value.totalAmount <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((entry) {
                    final data = entry.value;
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        '${data.transactionCount} transactions • ${data.percentageOfTotal.toStringAsFixed(1)}%',
                      ),
                      trailing: Text(
                        'RM${data.totalAmount.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeePerformanceContent() {
    if (_employeePerformanceReport == null) return const SizedBox.shrink();

    final report = _employeePerformanceReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Employees',
              report.employeePerformance
                  .where(_matchesEmployeeFilter)
                  .length
                  .toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Top Performer',
              (report.employeePerformance.where(_matchesEmployeeFilter).isEmpty
                  ? report.topPerformer
                  : report.employeePerformance
                        .where(_matchesEmployeeFilter)
                        .reduce((a, b) => a.totalSales > b.totalSales ? a : b)
                        .employeeName),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Employee Performance Table
        const Text(
          'Employee Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.employeePerformance
                  .where((employee) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = employee.employeeName.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && employee.totalSales >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && employee.totalSales <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((employee) {
                    return ListTile(
                      title: Text(employee.employeeName),
                      subtitle: Text(
                        '${employee.transactionCount} transactions • Avg: RM${employee.averageTransactionValue.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'RM${employee.totalSales.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Filter helpers ------------------
  String _filterSummary() {
    final f = _currentFilter;
    if (f == null) return '';
    final parts = <String>[];
    if (f.searchText != null && f.searchText!.isNotEmpty)
      parts.add('Q: ${f.searchText}');
    if (f.minAmount != null)
      parts.add('Min: ${f.minAmount!.toStringAsFixed(2)}');
    if (f.maxAmount != null)
      parts.add('Max: ${f.maxAmount!.toStringAsFixed(2)}');
    if (f.dateRange != null)
      parts.add(
        '${f.dateRange!.start.toIso8601String().substring(0, 10)} - ${f.dateRange!.end.toIso8601String().substring(0, 10)}',
      );
    return parts.join(' | ');
  }

  bool _matchesProductFilter(ProductSalesData product) {
    final f = _currentFilter;
    if (f == null) return true;
    var ok = true;
    if (f.searchText != null && f.searchText!.isNotEmpty) {
      ok =
          product.productName.toLowerCase().contains(
            f.searchText!.toLowerCase(),
          ) ||
          product.category.toLowerCase().contains(f.searchText!.toLowerCase());
    }
    if (f.minAmount != null) ok = ok && product.totalRevenue >= f.minAmount!;
    if (f.maxAmount != null) ok = ok && product.totalRevenue <= f.maxAmount!;
    return ok;
  }

  bool _matchesCategoryFilter(MapEntry<String, CategorySalesData> entry) {
    final f = _currentFilter;
    if (f == null) return true;
    var ok = true;
    if (f.searchText != null && f.searchText!.isNotEmpty)
      ok = entry.key.toLowerCase().contains(f.searchText!.toLowerCase());
    if (f.minAmount != null) ok = ok && entry.value.revenue >= f.minAmount!;
    if (f.maxAmount != null) ok = ok && entry.value.revenue <= f.maxAmount!;
    return ok;
  }

  bool _matchesPaymentMethodFilter(MapEntry<String, PaymentMethodData> entry) {
    final f = _currentFilter;
    if (f == null) return true;
    var ok = true;
    if (f.searchText != null && f.searchText!.isNotEmpty)
      ok = entry.key.toLowerCase().contains(f.searchText!.toLowerCase());
    if (f.minAmount != null) ok = ok && entry.value.totalAmount >= f.minAmount!;
    if (f.maxAmount != null) ok = ok && entry.value.totalAmount <= f.maxAmount!;
    return ok;
  }

  bool _matchesEmployeeFilter(EmployeeData employee) {
    final f = _currentFilter;
    if (f == null) return true;
    var ok = true;
    if (f.searchText != null && f.searchText!.isNotEmpty)
      ok = employee.employeeName.toLowerCase().contains(
        f.searchText!.toLowerCase(),
      );
    if (f.minAmount != null) ok = ok && employee.totalSales >= f.minAmount!;
    if (f.maxAmount != null) ok = ok && employee.totalSales <= f.maxAmount!;
    return ok;
  }

  bool _matchesCustomerFilter(TopCustomerData customer) {
    final f = _currentFilter;
    if (f == null) return true;
    var ok = true;
    if (f.searchText != null && f.searchText!.isNotEmpty)
      ok = customer.customerName.toLowerCase().contains(
        f.searchText!.toLowerCase(),
      );
    if (f.minAmount != null) ok = ok && customer.totalSpent >= f.minAmount!;
    if (f.maxAmount != null) ok = ok && customer.totalSpent <= f.maxAmount!;
    return ok;
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary';
      case ReportType.productSales:
        return 'Product Sales';
      case ReportType.categorySales:
        return 'Category Sales';
      case ReportType.paymentMethod:
        return 'Payment Methods';
      case ReportType.inventory:
        return 'Inventory';
      case ReportType.shrinkage:
        return 'Shrinkage';
      case ReportType.employeePerformance:
        return 'Employee Performance';
      case ReportType.laborCost:
        return 'Labor Cost';
      case ReportType.customerAnalysis:
        return 'Customer Analysis';
      case ReportType.basketAnalysis:
        return 'Basket Analysis';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program';
      case ReportType.dayClosing:
        return 'Day Closing';
      case ReportType.profitLoss:
        return 'Profit & Loss';
      case ReportType.cashFlow:
        return 'Cash Flow';
      case ReportType.taxSummary:
        return 'Tax Summary';
      case ReportType.inventoryValuation:
        return 'Inventory Valuation';
      case ReportType.abcAnalysis:
        return 'ABC Analysis';
      case ReportType.demandForecasting:
        return 'Demand Forecasting';
      case ReportType.menuEngineering:
        return 'Menu Engineering';
      case ReportType.tablePerformance:
        return 'Table Performance';
      case ReportType.dailyStaffPerformance:
        return 'Daily Staff Performance';
    }
  }

  String _formatLastRefreshTime() {
    if (_lastRefreshTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime!);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showFilterDialog() {
    final searchController = TextEditingController(
      text: _currentFilter?.searchText,
    );
    final minController = TextEditingController(
      text: _currentFilter?.minAmount?.toString(),
    );
    final maxController = TextEditingController(
      text: _currentFilter?.maxAmount?.toString(),
    );
    DateTimeRange? pickedRange = _currentFilter?.dateRange;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Advanced Filter'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Product, category, customer, etc.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Min Amount',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Max Amount',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDateRange: pickedRange,
                            );
                            setDialogState(() => pickedRange = range);
                          },
                          child: Text(
                            pickedRange == null
                                ? 'Choose Date Range'
                                : '${pickedRange!.start.toLocal().toIso8601String().substring(0, 10)} - ${pickedRange!.end.toLocal().toIso8601String().substring(0, 10)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            pickedRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _currentFilter = null);
                  Navigator.of(ctx).pop();
                  _loadReport();
                  if (mounted)
                    ToastHelper.showToast(context, 'Filters cleared');
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  final searchText = searchController.text.trim().isEmpty
                      ? null
                      : searchController.text.trim();
                  final min = double.tryParse(minController.text);
                  final max = double.tryParse(maxController.text);

                  setState(() {
                    _currentFilter = AdvancedReportFilter(
                      searchText: searchText,
                      minAmount: min,
                      maxAmount: max,
                      dateRange: pickedRange,
                    );
                  });

                  if (pickedRange != null) {
                    setState(
                      () => _selectedPeriod = ReportPeriod(
                        label: 'Custom',
                        startDate: pickedRange!.start,
                        endDate: pickedRange!.end,
                      ),
                    );
                  }

                  Navigator.of(ctx).pop();
                  _loadReport();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Report Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Today'),
              onTap: () {
                setState(() => _selectedPeriod = ReportPeriod.today());
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('Yesterday'),
              onTap: () {
                final yesterday = DateTime.now().subtract(
                  const Duration(days: 1),
                );
                setState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'Yesterday',
                    startDate: DateTime(
                      yesterday.year,
                      yesterday.month,
                      yesterday.day,
                    ),
                    endDate: DateTime(
                      yesterday.year,
                      yesterday.month,
                      yesterday.day,
                      23,
                      59,
                      59,
                    ),
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('This Week'),
              onTap: () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(
                  Duration(days: now.weekday - 1),
                );
                setState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'This Week',
                    startDate: DateTime(
                      startOfWeek.year,
                      startOfWeek.month,
                      startOfWeek.day,
                    ),
                    endDate: now,
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                setState(
                  () => _selectedPeriod = ReportPeriod(
                    label: 'This Month',
                    startDate: DateTime(now.year, now.month, 1),
                    endDate: now,
                  ),
                );
                Navigator.of(context).pop();
                _loadReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryContent() {
    if (_inventoryReport == null) return const SizedBox.shrink();

    final report = _inventoryReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Items',
              report.inventoryItems.length.toString(),
              Icons.inventory,
            ),
            _buildMetricCard(
              'Low Stock Items',
              report.lowStockItems.length.toString(),
              Icons.warning,
            ),
            _buildMetricCard(
              'Out of Stock',
              report.outOfStockItems.length.toString(),
              Icons.error,
            ),
            _buildMetricCard(
              'Total Value',
              'RM${report.totalInventoryValue.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Inventory Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.inventoryItems.take(20).map((item) {
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    '${item.category} • Stock: ${item.currentStock}',
                  ),
                  trailing: Text(item.stockStatus),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShrinkageContent() {
    if (_shrinkageReport == null) return const SizedBox.shrink();

    final report = _shrinkageReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Shrinkage Items',
              report.shrinkageItems.length.toString(),
              Icons.warning,
            ),
            _buildMetricCard(
              'Total Shrinkage Value',
              'RM${report.totalShrinkageValue.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Shrinkage %',
              '${report.totalShrinkagePercentage.toStringAsFixed(1)}%',
              Icons.percent,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Shrinkage Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.shrinkageItems.take(20).map((item) {
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    'Variance: ${item.variance} • Reason: ${item.reason}',
                  ),
                  trailing: Text('RM${item.varianceValue.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLaborCostContent() {
    if (_laborCostReport == null) return const SizedBox.shrink();

    final report = _laborCostReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Labor Cost',
              'RM${report.totalLaborCost.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Labor Cost %',
              '${report.laborCostPercentage.toStringAsFixed(1)}%',
              Icons.percent,
            ),
            _buildMetricCard(
              'Efficiency Data Points',
              report.efficiencyData.length.toString(),
              Icons.analytics,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Labor Cost by Department',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.laborCostByDepartment.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text('RM${entry.value.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerAnalysisContent() {
    if (_customerReport == null) return const SizedBox.shrink();

    final report = _customerReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Customers',
              report.topCustomers
                  .where(_matchesCustomerFilter)
                  .length
                  .toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Avg Lifetime Value',
              'RM${(report.topCustomers.where(_matchesCustomerFilter).fold<double>(0.0, (s, c) => s + c.totalSpent) / (report.topCustomers.where(_matchesCustomerFilter).isEmpty ? 1 : report.topCustomers.where(_matchesCustomerFilter).length)).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Top Customers',
              report.topCustomers
                  .where(_matchesCustomerFilter)
                  .length
                  .toString(),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Top Customers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.topCustomers
                  .where((customer) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = customer.customerName.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null)
                      ok = ok && customer.totalSpent >= f.minAmount!;
                    if (f.maxAmount != null)
                      ok = ok && customer.totalSpent <= f.maxAmount!;
                    return ok;
                  })
                  .take(10)
                  .map((customer) {
                    return ListTile(
                      title: Text(customer.customerName),
                      subtitle: Text(
                        '${customer.visitCount} visits • Avg: RM${customer.averageOrderValue.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'RM${customer.totalSpent.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasketAnalysisContent() {
    if (_basketAnalysisReport == null) return const SizedBox.shrink();

    final report = _basketAnalysisReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Frequently Bought Together',
              report.frequentlyBoughtTogether.length.toString(),
              Icons.shopping_basket,
            ),
            _buildMetricCard(
              'Product Affinities',
              report.productAffinityScores.length.toString(),
              Icons.link,
            ),
            _buildMetricCard(
              'Recommended Bundles',
              report.recommendedBundles.length.toString(),
              Icons.card_giftcard,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Basket Analysis Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Frequently Bought Together'),
                  subtitle: Text(
                    '${report.frequentlyBoughtTogether.length} item combinations identified',
                  ),
                ),
                ListTile(
                  title: const Text('Product Affinities'),
                  subtitle: Text(
                    '${report.productAffinityScores.length} affinity scores calculated',
                  ),
                ),
                ListTile(
                  title: const Text('Recommended Bundles'),
                  subtitle: Text(
                    '${report.recommendedBundles.length} bundle recommendations available',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyProgramContent() {
    if (_loyaltyProgramReport == null) return const SizedBox.shrink();

    final report = _loyaltyProgramReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Members',
              report.totalMembers.toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Active Members',
              report.activeMembers.toString(),
              Icons.check_circle,
            ),
            _buildMetricCard(
              'Points Issued',
              report.totalPointsIssued.toStringAsFixed(0),
              Icons.add_circle,
            ),
            _buildMetricCard(
              'Points Redeemed',
              report.totalPointsRedeemed.toStringAsFixed(0),
              Icons.remove_circle,
            ),
            _buildMetricCard(
              'Redemption Rate',
              '${report.redemptionRate.toStringAsFixed(1)}%',
              Icons.percent,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Loyalty Program Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Revenue from Loyalty Members'),
                  trailing: Text(
                    'RM${report.revenueFromLoyaltyMembers.toStringAsFixed(2)}',
                  ),
                ),
                ListTile(
                  title: const Text('Points by Tier'),
                  subtitle: Text('${report.pointsByTier.length} tiers tracked'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayClosingContent() {
    if (_dayClosingReport == null) return const SizedBox.shrink();

    final report = _dayClosingReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMetricCard(
                      'Total Sales',
                      FormattingService.currency(report.totalSales),
                      Icons.attach_money,
                    ),
                    _buildMetricCard(
                      'Net Sales',
                      FormattingService.currency(report.netSales),
                      Icons.trending_up,
                    ),
                    _buildMetricCard(
                      'Cash Expected',
                      FormattingService.currency(report.cashExpected),
                      Icons.account_balance_wallet,
                    ),
                    _buildMetricCard(
                      'Cash Variance',
                      FormattingService.currency(report.cashVariance),
                      report.cashVariance >= 0
                          ? Icons.check_circle
                          : Icons.warning,
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
                  report.cashReconciliation.openingFloat,
                ),
                _buildReconciliationRow(
                  'Cash Sales',
                  report.cashReconciliation.cashSales,
                ),
                _buildReconciliationRow(
                  'Cash Refunds',
                  -report.cashReconciliation.cashRefunds,
                ),
                _buildReconciliationRow(
                  'Paid Outs',
                  -report.cashReconciliation.paidOuts,
                ),
                _buildReconciliationRow(
                  'Paid Ins',
                  report.cashReconciliation.paidIns,
                ),
                const Divider(),
                _buildReconciliationRow(
                  'Expected Cash',
                  report.cashReconciliation.expectedCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Actual Cash',
                  report.cashReconciliation.actualCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Variance',
                  report.cashReconciliation.variance,
                  isTotal: true,
                  isVariance: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shift Summaries
        if (report.shiftSummaries.isNotEmpty)
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
                  ...report.shiftSummaries.map(
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

  pw.Widget _buildDailyStaffPerformancePDF() {
    if (_dailyStaffPerformanceReport == null)
      return pw.Text('No data available');

    final data = _dailyStaffPerformanceReport!;
    final staffData = data['staffData'] as List<dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;
    final businessDate = DateTime.parse(data['businessDate'] as String);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Staff Performance Report',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Business Date: ${FormattingService.formatDate(businessDate.toIso8601String())}',
        ),
        pw.Text('Tax Entity: ${BusinessInfo.instance.businessName}'),
        pw.SizedBox(height: 16),

        // Sales Performance Summary
        pw.Text(
          '1. Sales Performance Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'Login',
            'Logout',
            'Gross Sales',
            'Discounts',
            'Net Sales',
            'Transactions',
          ],
          data: [
            ...staffData.map(
              (staff) => [
                staff['userName'] as String,
                _formatTime(staff['loginTime'] as String?),
                _formatTime(staff['logoutTime'] as String?),
                FormattingService.currency(staff['grossSales'] as double),
                FormattingService.currency(staff['discounts'] as double),
                FormattingService.currency(staff['netSales'] as double),
                (staff['transactionCount'] as int).toString(),
              ],
            ),
            [
              'TOTAL',
              '',
              '',
              FormattingService.currency(summary['totalGrossSales'] as double),
              FormattingService.currency(summary['totalDiscounts'] as double),
              FormattingService.currency(summary['totalNetSales'] as double),
              (summary['totalTransactions'] as int).toString(),
            ],
          ],
        ),

        pw.SizedBox(height: 16),

        // SST & Tax Breakdown
        pw.Text(
          '2. SST & Tax Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'SST 6% (F&B)',
            'SST 8% (Other)',
            'Tax-Exempt',
            'Total SST',
          ],
          data: [
            ...staffData.map((staff) {
              final taxBreakdown =
                  staff['taxBreakdown'] as Map<String, dynamic>;
              final totalTax = taxBreakdown.values.fold<double>(
                0,
                (sum, amount) => sum + (amount as double),
              );
              return [
                staff['userName'] as String,
                FormattingService.currency(taxBreakdown['0.06'] ?? 0),
                FormattingService.currency(taxBreakdown['0.08'] ?? 0),
                '0.00',
                FormattingService.currency(totalTax),
              ];
            }),
            [
              'TOTAL',
              FormattingService.currency(
                (summary['taxBreakdown'] as Map)['0.06'] ?? 0,
              ),
              FormattingService.currency(
                (summary['taxBreakdown'] as Map)['0.08'] ?? 0,
              ),
              '0.00',
              FormattingService.currency(
                (summary['taxBreakdown'] as Map).values.fold<double>(
                  0,
                  (sum, amount) => sum + (amount as double),
                ),
              ),
            ],
          ],
        ),

        pw.SizedBox(height: 16),

        // Payment Method Audit
        pw.Text(
          '3. Payment Method Audit',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'Cash',
            'Credit Card',
            'TNG/GrabPay',
            'ShopeePay',
          ],
          data: [
            ...staffData.map((staff) {
              final paymentMethods =
                  staff['paymentMethods'] as Map<String, dynamic>;
              return [
                staff['userName'] as String,
                FormattingService.currency(paymentMethods['Cash'] ?? 0),
                FormattingService.currency(paymentMethods['Credit Card'] ?? 0),
                FormattingService.currency(
                  paymentMethods['TNG / GrabPay'] ?? 0,
                ),
                FormattingService.currency(paymentMethods['ShopeePay'] ?? 0),
              ];
            }),
            [
              'TOTAL',
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['Cash'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['Credit Card'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['TNG / GrabPay'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['ShopeePay'] ?? 0,
              ),
            ],
          ],
        ),

        pw.SizedBox(height: 16),

        // Error & Security Log
        pw.Text(
          '4. Error & Security Log',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['Staff Name', 'Voids', 'Overrides', 'Refunds'],
          data: [
            ...staffData.map(
              (staff) => [
                staff['userName'] as String,
                (staff['voids'] as int).toString(),
                (staff['overrides'] as int).toString(),
                FormattingService.currency(staff['refunds'] as double),
              ],
            ),
            [
              'TOTAL',
              (summary['totalVoids'] as int).toString(),
              (summary['totalOverrides'] as int).toString(),
              FormattingService.currency(summary['totalRefunds'] as double),
            ],
          ],
        ),
      ],
    );
  }
}
