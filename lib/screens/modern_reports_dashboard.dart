import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/models/printer_model.dart' as printer_model;
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/report_printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

enum TimeRange { daily, weekly, monthly, yearly, custom }

class StatData {
  final String label;
  final String value;
  final String trend;
  final bool isUp;
  final IconData icon;
  final Color color;

  StatData({
    required this.label,
    required this.value,
    required this.trend,
    required this.isUp,
    required this.icon,
    required this.color,
  });
}

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

class BreakdownItem {
  final String label;
  final double percentage;
  final String amount;
  final Color color;

  BreakdownItem({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.color,
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
  void initState() {
    super.initState();
    _initializePeriod();
    _loadData();
  }

  void _initializePeriod() {
    _activeTimeRange = _timeRangeFromInitialPeriod();
    if (_activeTimeRange == TimeRange.custom) {
      final now = DateTime.now();
      _startDate = now.subtract(const Duration(days: 30));
      _endDate = now;
    } else {
      final period = _periodForRange(_activeTimeRange);
      _startDate = period.startDate;
      _endDate = period.endDate;
    }
  }

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

  Future<void> _loadData() async {
    final period = _periodForRange(_activeTimeRange);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 10,
        ),
        _analyticsService.getTopProducts(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 10,
        ),
        _analyticsService.getPaymentMethodStats(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getDailySales(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        DatabaseService.instance.generateInventoryValuationReport(period),
      ]);

      if (!mounted) return;

      final inventoryReport = results[5] as InventoryValuationReport;
      final inventoryItems = inventoryReport.valuationItems.map((item) {
        final status = item.quantity <= 0 ? 'Out' : 'In Stock';
        return InventoryItem(
          id: item.itemId,
          name: item.itemName,
          category: 'General',
          stock: item.quantity.toDouble(),
          min: 0,
          unit: null,
          cost: item.costPrice,
          status: status,
        );
      }).toList();

      setState(() {
        _summary = results[0] as SalesSummary;
        _categories = results[1] as List<CategoryPerformance>;
        _topProducts = results[2] as List<ProductPerformance>;
        _paymentMethods = results[3] as List<PaymentMethodStats>;
        _dailySales = results[4] as List<DailySales>;
        _inventoryValuationReport = inventoryReport;
        _inventoryItems = inventoryItems;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading reports: $_error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
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

  String _displayModeName(BusinessMode mode) {
    switch (mode) {
      case BusinessMode.retail:
        return 'Retail';
      case BusinessMode.cafe:
        return 'Cafe';
      case BusinessMode.restaurant:
        return 'Dining';
    }
  }

  String _displayRangeName(TimeRange range) {
    switch (range) {
      case TimeRange.daily:
        return 'Daily';
      case TimeRange.weekly:
        return 'Weekly';
      case TimeRange.monthly:
        return 'Monthly';
      case TimeRange.yearly:
        return 'Yearly';
      case TimeRange.custom:
        return 'Custom';
    }
  }

  Widget _buildModeAndDateHeader() {
    final periodLabel = _activeTimeRange == TimeRange.custom
        ? '${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}'
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: BusinessMode.values.map((mode) {
              final isActive = _activeMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeMode = mode);
                  _loadData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _displayModeName(mode).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Reporting Period: $periodLabel',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainTitleHeader(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_displayModeName(_activeMode)} Analytics',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Detailed intelligence for ExtroPOS ${_displayModeName(_activeMode).toLowerCase()} owners',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: TimeRange.values.map((range) {
                  final isActive = _activeTimeRange == range;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeTimeRange = range;
                        final period = _periodForRange(range);
                        _startDate = period.startDate;
                        _endDate = period.endDate;
                      });
                      _loadData();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _displayRangeName(range),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_activeTimeRange == TimeRange.custom) ...[
              const SizedBox(height: 12),
              _buildCustomDatePicker(),
            ],
            const SizedBox(height: 12),
            _buildExportDropdown(),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        );

        if (picked != null && mounted) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
            _activeTimeRange = TimeRange.custom;
          });
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportDropdown() {
    return PopupMenuButton<String>(
      onSelected: _handleExport,
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Export PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Export CSV'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Export Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftOperations() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _buildShiftCard(
                'X-Report',
                'Snapshot (Read Only)',
                Icons.description,
                const Color(0xFF4F46E5),
                Colors.indigo.shade50,
                'X',
              ),
              const SizedBox(height: 24),
              _buildShiftCard(
                'Z-Report',
                'Daily Close (Reset)',
                Icons.lock,
                Colors.red.shade600,
                Colors.red.shade50,
                'Z',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildShiftCard(
                'X-Report',
                'Snapshot (Read Only)',
                Icons.description,
                const Color(0xFF4F46E5),
                Colors.indigo.shade50,
                'X',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildShiftCard(
                'Z-Report',
                'Daily Close (Reset)',
                Icons.lock,
                Colors.red.shade600,
                Colors.red.shade50,
                'Z',
              ),
            ),
          ],
        );
      },
    );
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: key == 'Z' ? color : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
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

  Widget _buildStatsGrid() {
    final stats = _buildStatData();
    if (stats.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisExtent: 160,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: stat.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(stat.icon, color: Colors.white, size: 20),
                      ),
                      Text(
                        stat.trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: stat.isUp
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryValuation(Color accent) {
    final inventory = _inventoryItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inventory Valuation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    _tableActionBtn(
                      Icons.file_present,
                      'Export CSV',
                      () => _handleExport('csv'),
                    ),
                    const SizedBox(width: 12),
                    _tableActionBtn(
                      Icons.add,
                      'Add Stock',
                      () {},
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No inventory data found for this period.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 60,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(
                    label: Text(
                      'ID / SKU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ITEM NAME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CURRENT STOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TOTAL VALUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
                rows: inventory.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.id,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            '${item.stock.toStringAsFixed(0)} ${item.unit ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            '${BusinessInfo.instance.currencySymbol} ${(item.cost * item.stock).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.status,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

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

  Widget _buildPerformanceSection(Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _buildSalesPerformanceChart(accent),
              const SizedBox(height: 24),
              _buildCategoryBreakdown(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildSalesPerformanceChart(accent)),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _buildCategoryBreakdown()),
          ],
        );
      },
    );
  }

  Widget _buildSalesPerformanceChart(Color accent) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _dailySales.isEmpty
                ? const Center(
                    child: Text(
                      'No sales trend data available for this period',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                BusinessInfo.instance.currencySymbol +
                                    value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < _dailySales.length) {
                                final date = _dailySales[value.toInt()].date;
                                return Text(
                                  DateFormat('MMM dd').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dailySales.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.revenue);
                          }).toList(),
                          isCurved: true,
                          color: accent,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: accent.withOpacity(0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = _dailySales[spot.x.toInt()].date;
                              return LineTooltipItem(
                                '${DateFormat('MMM dd').format(date)}\n${BusinessInfo.instance.currencySymbol}${spot.y.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final breakdownItems = _buildBreakdownItems();

    return Container(
      padding: const EdgeInsets.all(32),
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          if (breakdownItems.isEmpty)
            const Expanded(child: Center(child: Text('No category data available.')))
          else
            ...breakdownItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${item.percentage.toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.percentage / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(item.color),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generating ${_exportingType?.toUpperCase()}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _exportProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportModalOverlay() {
    final isX = _activeModalReport == 'X';
    final themeColor = isX ? const Color(0xFF4F46E5) : Colors.red.shade600;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_activeModalReport-Report Detail',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _activeModalReport = null),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Connect to Shift Table for Real-time Totals',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _activeModalReport = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<StatData> _buildStatData() {
    final summary = _summary;
    if (summary == null) return [];

    final currency = BusinessInfo.instance.currencySymbol;
    final revenueTrend = _calculateTrendPercent(
      _dailySales.map((item) => item.revenue).toList(),
    );
    final transactionTrend = _calculateTrendPercent(
      _dailySales.map((item) => item.orderCount.toDouble()).toList(),
    );
    final avgTicketTrend = _calculateAverageTicketTrend();

    return [
      StatData(
        label: 'Gross Sales',
        value: '$currency ${summary.grossSales.toStringAsFixed(2)}',
        trend: _formatTrend(revenueTrend),
        isUp: revenueTrend >= 0,
        icon: Icons.trending_up,
        color: Colors.green.shade600,
      ),
      StatData(
        label: 'Net Sales',
        value: '$currency ${summary.netSales.toStringAsFixed(2)}',
        trend: _formatTrend(revenueTrend),
        isUp: revenueTrend >= 0,
        icon: Icons.attach_money,
        color: const Color(0xFF2563EB),
      ),
      StatData(
        label: 'Transactions',
        value: '${summary.transactionCount}',
        trend: _formatTrend(transactionTrend),
        isUp: transactionTrend >= 0,
        icon: Icons.receipt_long,
        color: Colors.orange.shade600,
      ),
      StatData(
        label: 'Avg Ticket',
        value: '$currency ${summary.averageTransactionValue.toStringAsFixed(2)}',
        trend: _formatTrend(avgTicketTrend),
        isUp: avgTicketTrend >= 0,
        icon: Icons.shopping_cart,
        color: Colors.purple.shade600,
      ),
    ];
  }

  double _calculateTrendPercent(List<double> values) {
    if (values.length < 2) return 0.0;
    final previous = values[values.length - 2];
    final current = values.last;
    if (previous == 0) return 0.0;
    return ((current - previous) / previous) * 100;
  }

  double _calculateAverageTicketTrend() {
    if (_dailySales.length < 2) return 0.0;
    final previous = _dailySales[_dailySales.length - 2];
    final current = _dailySales.last;
    final previousAvg = previous.orderCount == 0
        ? 0.0
        : previous.revenue / previous.orderCount;
    final currentAvg =
        current.orderCount == 0 ? 0.0 : current.revenue / current.orderCount;
    if (previousAvg == 0) return 0.0;
    return ((currentAvg - previousAvg) / previousAvg) * 100;
  }

  String _formatTrend(double value) {
    final formatted = value.abs().toStringAsFixed(1);
    return '${value >= 0 ? '+' : '-'}$formatted%';
  }

  List<BreakdownItem> _buildBreakdownItems() {
    final summary = _summary;
    if (summary == null || _categories.isEmpty) return [];

    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
    ];

    final total = summary.grossSales <= 0 ? 1.0 : summary.grossSales;
    final sorted = [..._categories]
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return sorted.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.revenue / total) * 100;
      return BreakdownItem(
        label: item.categoryName,
        percentage: percentage,
        amount:
            '${BusinessInfo.instance.currencySymbol} ${item.revenue.toStringAsFixed(2)}',
        color: colors[index % colors.length],
      );
    }).toList();
  }

  Future<void> _handleExport(String type) async {
    if (_isLoading) return;

    setState(() {
      _exportingType = type;
      _exportProgress = 0.2;
    });

    try {
      if (type == 'csv') {
        await _exportCSV();
      } else {
        await _exportPDF();
      }
      if (!mounted) return;
      setState(() => _exportProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _exportingType = null);
      }
    }
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await _generateCSV();
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
        await file.writeAsString(csv);

        if (mounted) {
          ToastHelper.showToast(
            context,
            'Report saved to Downloads: $fileName',
          );
        }
      } else {
        // Desktop: Show save dialog
        final file = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'CSV Files', extensions: ['csv']),
          ],
        );

        if (file != null) {
          await File(file.path).writeAsString(csv);
          if (mounted) {
            ToastHelper.showToast(context, 'Report exported successfully');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    }
  }

  Future<String> _generateCSV() async {
    final buffer = StringBuffer();
    final currency = BusinessInfo.instance.currencySymbol;

    // Header
    buffer.writeln('Sales Report');
    buffer.writeln('Period: ${_periodForRange(_activeTimeRange).label}');
    buffer.writeln(
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
    buffer.writeln('');

    // Summary
    buffer.writeln('Summary');
    buffer.writeln(
      'Gross Sales,$currency ${_summary?.grossSales.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln(
      'Net Sales,$currency ${_summary?.netSales.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln('Transactions,${_summary?.transactionCount ?? 0}');
    buffer.writeln(
      'Average Ticket,$currency ${_summary?.averageTransactionValue.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln('');

    // Top Products
    buffer.writeln('Top Products');
    buffer.writeln('Rank,Product Name,Units Sold,Revenue');
    for (var i = 0; i < _topProducts.length; i++) {
      final product = _topProducts[i];
      buffer.writeln(
        '${i + 1},${product.productName},${product.unitsSold},$currency ${product.revenue.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Export sales report as PDF
  Future<void> _exportPDF() async {
    try {
      // Show loading
      if (mounted) {
        ToastHelper.showToast(context, 'Generating PDF...');
      }

      final reportService = ReportPrinterService.instance;

      // Generate PDF bytes
      final pdfBytes = await reportService.generateReportPDF(
        summary: _summary!,
        categories: _categories,
        topProducts: _topProducts,
        paymentMethods: _paymentMethods,
        periodLabel: _periodForRange(_activeTimeRange).label,
      );

      if (!mounted) return;

      // Export to file
      final filePath = await reportService.exportToPDFFile(pdfBytes: pdfBytes);

      if (filePath != null && mounted) {
        ToastHelper.showToast(
          context,
          'PDF saved to: ${filePath.split('/').last}',
        );
      } else if (mounted) {
        ToastHelper.showToast(context, 'Save cancelled');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'PDF export failed: $e');
      }
    }
  }

  /// Print thermal report (58mm)
  Future<void> _printThermal58mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }

      final printer = await _getDefaultPrinter();
      if (printer == null) {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
        return;
      }

      if (mounted) {
        ToastHelper.showToast(context, 'Sending to thermal printer...');
      }

      final reportService = ReportPrinterService.instance;
      final success = await reportService.printThermalSummary(
        printer: printer,
        summary: _summary!,
        periodLabel: _periodForRange(_activeTimeRange).label,
        categories: _categories,
        paymentMethods: _paymentMethods,
      );

      if (mounted) {
        ToastHelper.showToast(
          context,
          success ? 'Report printed successfully' : 'Print failed - check printer',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  /// Print thermal report (80mm)
  Future<void> _printThermal80mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }

      final printer = await _getDefaultPrinter();
      if (printer == null) {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
        return;
      }

      if (mounted) {
        ToastHelper.showToast(context, 'Sending to thermal printer...');
      }

      final reportService = ReportPrinterService.instance;
      final success = await reportService.printThermalSummary(
        printer: printer,
        summary: _summary!,
        periodLabel: _periodForRange(_activeTimeRange).label,
        categories: _categories,
        paymentMethods: _paymentMethods,
      );

      if (mounted) {
        ToastHelper.showToast(
          context,
          success ? 'Report printed successfully' : 'Print failed - check printer',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }
}

