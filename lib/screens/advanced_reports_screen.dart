import 'dart:async';
import 'dart:developer' as developer;

import 'package:csv/csv.dart';
import 'package:extropos/models/advanced_reporting_features.dart' show ReportType;
import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/advanced_reports/widgets/daily_staff_performance_content.dart';
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

part 'advanced_reports_screen_export.dart';
part 'advanced_reports_screen_export_csv_helpers.dart';
part 'advanced_reports_screen_helpers.dart';
part 'advanced_reports_screen_large_widgets.dart';
part 'advanced_reports_screen_medium_widgets.dart';
part 'advanced_reports_screen_medium_widgets_part2.dart';
part 'advanced_reports_screen_medium_widgets_part3.dart';
part 'advanced_reports_screen_operations.dart';
part 'advanced_reports_screen_operations_part1.dart';
part 'advanced_reports_screen_operations_part3.dart';
part 'advanced_reports_screen_pdf_part1.dart';
part 'advanced_reports_screen_pdf_part2.dart';
part 'advanced_reports_screen_ui_helpers.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class AdvancedReportFilter {
  final String? searchText;
  final double? minAmount;
  final double? maxAmount;
  final DateTimeRange? dateRange;

  const AdvancedReportFilter({
    this.searchText,
    this.minAmount,
    this.maxAmount,
    this.dateRange,
  });
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

  bool _matchesProductFilter(dynamic _) => true;
  bool _matchesCategoryFilter(dynamic _) => true;
  bool _matchesEmployeeFilter(dynamic _) => true;
  bool _matchesCustomerFilter(dynamic _) => true;
  bool _matchesPaymentMethodFilter(dynamic _) => true;

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
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
                          _autoRefreshEnabled
                              ? Icons.timer
                              : Icons.access_time,
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



















}