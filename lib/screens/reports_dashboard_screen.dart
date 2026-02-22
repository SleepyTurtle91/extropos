import 'dart:async';

import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';

// --- Data Models (For DB Mapping) ---

enum ReportsBusinessType { retail, cafe, dining }
enum ReportsTimeRange { daily, weekly, monthly, yearly, custom }

class ReportsStatData {
  final String label;
  final String value;
  final String trend;
  final bool isUp;
  final IconData icon;
  final Color color;

  ReportsStatData({
    required this.label,
    required this.value,
    required this.trend,
    required this.isUp,
    required this.icon,
    required this.color,
  });
}

class ReportsInventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock;
  final int min;
  final String? unit;
  final double cost;
  final String status;

  ReportsInventoryItem({
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

class ReportsBreakdownItem {
  final String label;
  final double percentage;
  final String amount;
  final Color color;

  ReportsBreakdownItem({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.color,
  });
}

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // --- UI State ---
  ReportsBusinessType activeMode = ReportsBusinessType.retail;
  ReportsTimeRange activeTimeRange = ReportsTimeRange.daily;
  String? activeModalReport; // 'X' or 'Z'
  String? exportingType;
  double exportProgress = 0.0;
  bool isLoading = false;

  DateTime startDate = DateTime(2026, 2, 1);
  DateTime endDate = DateTime(2026, 2, 21);

  // --- Dynamic Report Data (Populated by DB) ---
  List<ReportsStatData> currentStats = [];
  List<ReportsInventoryItem> currentInventory = [];
  List<ReportsBreakdownItem> currentBreakdown = [];
  String breakdownTitle = 'Performance Breakdown';

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  // Database Reporting Logic
  Future<void> _fetchReportData() async {
    setState(() => isLoading = true);
    final currency = BusinessInfo.instance.currencySymbol;
    final period = _buildReportPeriod();
    final previousPeriod = _buildPreviousPeriod(period);

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: period.startDate,
          endDate: period.endDate,
        ),
        _analyticsService.getSalesSummary(
          startDate: previousPeriod.startDate,
          endDate: previousPeriod.endDate,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 6,
        ),
        DatabaseService.instance.generateInventoryValuationReport(period),
      ]);

      if (!mounted) return;

      final summary = results[0] as SalesSummary;
      final previousSummary = results[1] as SalesSummary;
      final categories = results[2] as List<CategoryPerformance>;
      final inventoryReport = results[3] as InventoryValuationReport;

      final stats = _buildStats(summary, previousSummary, currency);
      final breakdown = _buildBreakdown(summary, categories, currency);
      final inventory = _buildInventoryItems(inventoryReport);

      setState(() {
        currentStats = stats;
        currentBreakdown = breakdown;
        currentInventory = inventory;
        breakdownTitle = 'Category Breakdown';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  ReportPeriod _buildReportPeriod() {
    final now = DateTime.now();
    switch (activeTimeRange) {
      case ReportsTimeRange.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return ReportPeriod(label: 'Daily', startDate: start, endDate: end);
      case ReportsTimeRange.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return ReportPeriod(label: 'Weekly', startDate: start, endDate: end);
      case ReportsTimeRange.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return ReportPeriod(label: 'Monthly', startDate: start, endDate: end);
      case ReportsTimeRange.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return ReportPeriod(label: 'Yearly', startDate: start, endDate: end);
      case ReportsTimeRange.custom:
        return ReportPeriod(
          label: 'Custom',
          startDate: startDate,
          endDate: endDate,
        );
    }
  }

  ReportPeriod _buildPreviousPeriod(ReportPeriod period) {
    final duration = period.endDate.difference(period.startDate);
    final prevEnd = period.startDate.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return ReportPeriod(
      label: 'Previous',
      startDate: prevStart,
      endDate: prevEnd,
    );
  }

  List<ReportsStatData> _buildStats(
    SalesSummary current,
    SalesSummary previous,
    String currency,
  ) {
    final revenueTrend = _buildTrend(current.totalRevenue, previous.totalRevenue);
    final ordersTrend = _buildTrend(current.orderCount.toDouble(), previous.orderCount.toDouble());
    final averageTrend = _buildTrend(current.averageOrderValue, previous.averageOrderValue);
    final itemsTrend = _buildTrend(current.itemsSold.toDouble(), previous.itemsSold.toDouble());

    return [
      ReportsStatData(
        label: 'Total Revenue',
        value: '$currency ${current.totalRevenue.toStringAsFixed(2)}',
        trend: revenueTrend.label,
        isUp: revenueTrend.isUp,
        icon: Icons.payments_rounded,
        color: const Color(0xFF4F46E5),
      ),
      ReportsStatData(
        label: 'Orders',
        value: current.orderCount.toString(),
        trend: ordersTrend.label,
        isUp: ordersTrend.isUp,
        icon: Icons.receipt_long,
        color: Colors.blueGrey.shade600,
      ),
      ReportsStatData(
        label: 'Avg Ticket',
        value: '$currency ${current.averageOrderValue.toStringAsFixed(2)}',
        trend: averageTrend.label,
        isUp: averageTrend.isUp,
        icon: Icons.trending_up,
        color: Colors.green.shade600,
      ),
      ReportsStatData(
        label: 'Items Sold',
        value: current.itemsSold.toString(),
        trend: itemsTrend.label,
        isUp: itemsTrend.isUp,
        icon: Icons.shopping_cart,
        color: Colors.orange.shade700,
      ),
    ];
  }

  List<ReportsBreakdownItem> _buildBreakdown(
    SalesSummary summary,
    List<CategoryPerformance> categories,
    String currency,
  ) {
    final total = summary.totalRevenue;
    if (total <= 0 || categories.isEmpty) return [];

    final colors = <Color>[
      const Color(0xFF4F46E5),
      Colors.blueGrey.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];

    return categories.asMap().entries.map((entry) {
      final idx = entry.key;
      final category = entry.value;
      final percentage = (category.revenue / total) * 100;
      return ReportsBreakdownItem(
        label: category.categoryName,
        percentage: percentage.isNaN ? 0.0 : percentage,
        amount: '$currency ${category.revenue.toStringAsFixed(2)}',
        color: colors[idx % colors.length],
      );
    }).toList();
  }

  List<ReportsInventoryItem> _buildInventoryItems(
    InventoryValuationReport report,
  ) {
    return report.valuationItems.map((item) {
      final qty = item.quantity;
      final status = qty <= 0
          ? 'Out'
          : (qty <= 5 ? 'Low' : 'In Stock');
      return ReportsInventoryItem(
        id: item.itemId,
        name: item.itemName,
        category: 'General',
        stock: qty.toDouble(),
        min: 0,
        unit: null,
        cost: item.costPrice,
        status: status,
      );
    }).toList();
  }

  _TrendResult _buildTrend(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return const _TrendResult('0%', true);
      }
      return const _TrendResult('New', true);
    }

    final diff = ((current - previous) / previous) * 100;
    final isUp = diff >= 0;
    final label = '${diff.abs().toStringAsFixed(1)}%';
    return _TrendResult(label, isUp);
  }

  void _handleExport(String type) {
    setState(() {
      exportingType = type;
      exportProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (exportProgress >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => exportingType = null);
        });
      } else {
        setState(() => exportProgress += 0.1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _getAccentColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeAndDateHeader(),
                const SizedBox(height: 24),
                _buildMainTitleHeader(accentColor),
                const SizedBox(height: 40),
                if (activeTimeRange == ReportsTimeRange.daily)
                  _buildShiftOperations(),
                const SizedBox(height: 40),
                if (isLoading)
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
          ),
          if (activeModalReport != null) _buildReportModalOverlay(),
          if (exportingType != null) _buildExportOverlay(),
        ],
      ),
    );
  }

  Color _getAccentColor() {
    switch (activeMode) {
      case ReportsBusinessType.retail:
        return const Color(0xFF4F46E5);
      case ReportsBusinessType.cafe:
        return Colors.amber.shade800;
      case ReportsBusinessType.dining:
        return Colors.red.shade700;
    }
  }

  Widget _buildModeAndDateHeader() {
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
            children: ReportsBusinessType.values.map((mode) {
              final isActive = activeMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() => activeMode = mode);
                  _fetchReportData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mode.name.toUpperCase(),
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
              'Reporting Period: ${activeTimeRange == ReportsTimeRange.custom ? '${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}' : '21 Feb 2026'}',
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
                '${activeMode.name[0].toUpperCase()}${activeMode.name.substring(1)} Analytics',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Detailed intelligence for ExtroPOS ${activeMode.name} owners',
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
                children: ReportsTimeRange.values.map((range) {
                  final isActive = activeTimeRange == range;
                  return GestureDetector(
                    onTap: () {
                      setState(() => activeTimeRange = range);
                      _fetchReportData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        range.name[0].toUpperCase() + range.name.substring(1),
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
            if (activeTimeRange == ReportsTimeRange.custom) ...[
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 14, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '2026-02-01 to 2026-02-21',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
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
            onPressed: () => setState(() => activeModalReport = key),
            style: ElevatedButton.styleFrom(
              backgroundColor: key == 'Z' ? color : Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (currentStats.isEmpty) return const SizedBox.shrink();
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
          itemCount: currentStats.length,
          itemBuilder: (context, index) {
            final stat = currentStats[index];
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
    final inventory = currentInventory;
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
                    _tableActionBtn(Icons.add, 'Add Stock', () {},
                        isPrimary: true),
                  ],
                ),
              ],
            ),
          ),
          if (inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('No inventory data found for this period.'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 60,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
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
                  return DataRow(cells: [
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
                          '${item.stock} ${item.unit ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          'RM ${(item.cost * item.stock).toStringAsFixed(2)}',
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
                  ]);
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildPlaceholderChart(accent)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildCategoryBreakdown()),
      ],
    );
  }

  Widget _buildPlaceholderChart(Color accent) {
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
          const Spacer(),
          const Center(
            child: Text(
              'Chart visualization ready for database stream',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
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
          Text(
            breakdownTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          if (currentBreakdown.isEmpty)
            const Expanded(child: Center(child: Text('No category data available.')))
          else
            ...currentBreakdown.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${item.percentage.toInt()}%'),
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
            )),
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
                'Generating ${exportingType?.toUpperCase()}...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: exportProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportModalOverlay() {
    final isX = activeModalReport == 'X';
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
                      '$activeModalReport-Report Detail',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => activeModalReport = null),
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
                      onPressed: () => setState(() => activeModalReport = null),
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
}

class _TrendResult {
  final String label;
  final bool isUp;

  const _TrendResult(this.label, this.isUp);
}
