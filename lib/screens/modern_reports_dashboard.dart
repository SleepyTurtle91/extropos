import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/enum_models.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/report_export_service.dart';
import 'package:extropos/services/report_printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/category_breakdown_widget.dart';
import 'package:extropos/widgets/inventory_valuation_widget.dart';
import 'package:extropos/widgets/regular_stats_grid.dart';
import 'package:extropos/widgets/report_overlays.dart';
import 'package:extropos/widgets/sales_performance_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'modern_reports_dashboard_operations.dart';
part 'modern_reports_dashboard_futures.dart';
part 'modern_reports_dashboard_helpers.dart';
part 'modern_reports_dashboard_medium_widgets.dart';
part 'modern_reports_dashboard_small_widgets.dart';

enum TimeRange { daily, weekly, monthly, yearly, custom }

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock;
  final int min;
  final String? unit;
  final double cost;
  final String status;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.min,
    this.unit,
    required this.cost,
    required this.status,
  });
}

/// Modern reports dashboard with visual analytics and quick insights
class ModernReportsDashboard extends StatefulWidget {
  final String? initialPeriod;

  const ModernReportsDashboard({super.key, this.initialPeriod});

  @override
  State<ModernReportsDashboard> createState() => _ModernReportsDashboardState();
}

class _ModernReportsDashboardState extends State<ModernReportsDashboard> {
  final _analyticsService = AnalyticsService.instance;

  BusinessMode _activeMode = BusinessInfo.instance.selectedBusinessMode;
  TimeRange _activeTimeRange = TimeRange.daily;
  String? _activeModalReport;
  String? _exportingType;
  double _exportProgress = 0.0;
  bool _isLoading = false;
  String? _error;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  SalesSummary? _summary;
  List<CategoryPerformance> _categories = [];
  List<ProductPerformance> _topProducts = [];
  List<PaymentMethodStats> _paymentMethods = [];
  List<DailySales> _dailySales = [];
  InventoryValuationReport? _inventoryValuationReport;
  List<InventoryItem> _inventoryItems = [];

  @override


  TimeRange _timeRangeFromInitialPeriod() {
    switch (widget.initialPeriod) {
      case 'week':
        return TimeRange.weekly;
      case 'month':
        return TimeRange.monthly;
      case 'year':
        return TimeRange.yearly;
      case 'custom':
        return TimeRange.custom;
      case 'today':
      default:
        return TimeRange.daily;
    }
  }

  ReportPeriod _periodForRange(TimeRange range) {
    switch (range) {
      case TimeRange.weekly:
        return ReportPeriod.thisWeek();
      case TimeRange.monthly:
        return ReportPeriod.thisMonth();
      case TimeRange.yearly:
        return ReportPeriod.thisYear();
      case TimeRange.custom:
        return ReportPeriod(
          label: 'Custom',
          startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
          endDate: DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            23,
            59,
            59,
          ),
        );
      case TimeRange.daily:
      default:
        return ReportPeriod.today();
    }
  }


  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 800 ? 16.0 : 40.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeAndDateHeader(),
                    const SizedBox(height: 24),
                    _buildMainTitleHeader(accentColor),
                    const SizedBox(height: 40),
                    if (_activeTimeRange == TimeRange.daily)
                      _buildShiftOperations(),
                    const SizedBox(height: 40),
                    if (_error != null)
                      _buildErrorBanner()
                    else if (_isLoading && _summary == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      _buildStatsGrid(),
                      const SizedBox(height: 40),
                      _buildInventoryValuation(accentColor),
                      const SizedBox(height: 40),
                      _buildPerformanceSection(accentColor),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_activeModalReport != null) _buildReportModalOverlay(),
          if (_exportingType != null) _buildExportOverlay(),
        ],
      ),
    );
  }


  Color _getAccentColor() {
    switch (_activeMode) {
      case BusinessMode.retail:
        return const Color(0xFF4F46E5);
      case BusinessMode.cafe:
        return Colors.amber.shade800;
      case BusinessMode.restaurant:
        return Colors.red.shade600;
    }
  }








  Widget _buildShiftCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color bg,
    String key,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: key == 'Z' ? color : Colors.black),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Generate a summary of transactions and cash totals for the current shift.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _activeModalReport = key),
            style: ElevatedButton.styleFrom(
              backgroundColor: key == 'Z' ? color : Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsGrid() => RegularStatsGrid(stats: _buildStatData());
  Widget _buildInventoryValuation(Color accent) => InventoryValuationWidget(
        inventoryItems: _inventoryItems,
        onExportCsv: () => _handleExport('csv'),
        onAddStock: () {},
      );
  Widget _tableActionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : Colors.blueGrey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPerformanceChart(Color accent) => SalesPerformanceChart(
        dailySales: _dailySales,
        accent: accent,
      );
  Widget _buildCategoryBreakdown() =>
      CategoryBreakdownWidget(breakdownItems: _buildBreakdownItems());
  Widget _buildExportOverlay() => ExportProgressOverlay(
        exportingType: _exportingType,
        exportProgress: _exportProgress,
      );
  Widget _buildReportModalOverlay() => ReportModalOverlay(
        activeModalReport: _activeModalReport,
        onClose: () => setState(() => _activeModalReport = null),
      );






  /// Export sales report as PDF
  /// Print thermal report (58mm)

  /// Print thermal report (80mm)
}
