import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/printer_model.dart' as printer_model;
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/report_content_builders.dart';
import 'package:extropos/screens/reports/widgets/summary_card.dart';
import 'package:extropos/screens/reports_content_screens.dart';
import 'package:extropos/services/daily_staff_performance_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/reports_export_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'reports_screen_content.dart';
part 'reports_screen_content_part1.dart';
part 'reports_screen_content_part2.dart';
part 'reports_screen_operations.dart';
part 'reports_screen_ui_helpers.dart';
part 'reports_screen_view_widgets.dart';
part 'reports_screen_view_widgets_part1.dart';
part 'reports_screen_view_widgets_part2.dart';

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












}