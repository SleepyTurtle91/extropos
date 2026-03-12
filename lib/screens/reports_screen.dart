import 'dart:io';

import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/shift_reports_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/kpi_card.dart';
import 'package:extropos/widgets/report_date_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

/// Modern Reports Dashboard Screen
/// Provides comprehensive analytics and reporting capabilities
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth();
  String? _selectedCategory;
  String? _selectedStaff;
  bool _showComparison = false;

  SalesSummary? _salesSummary;
  SalesSummary? _comparisonSummary;
  List<ProductPerformance> _topProducts = [];
  List<StaffPerformance> _staffPerformance = [];
  List<ProductAnalytics> _productAnalytics = [];
  List<DailySales> _dailySales = [];
  List<String> _categories = [];
  final List<String> _staffMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadReportsData();
  }

  Future<void> _loadFilters() async {
    try {
      final categories = await DatabaseService.instance.getCategories();

      setState(() {
        _categories = categories.map((c) => c.name).toList();
      });
    } catch (e) {
      // Silently handle filter loading errors
    }
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);

    try {
      // Load current period data
      final summary = await DatabaseService.instance.getSalesSummary(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
      );

      // Load comparison data if enabled
      SalesSummary? comparisonSummary;
      if (_showComparison) {
        final comparisonPeriod = _getComparisonPeriod();
        comparisonSummary = await DatabaseService.instance.getSalesSummary(
          startDate: comparisonPeriod.startDate,
          endDate: comparisonPeriod.endDate,
          categoryId: _selectedCategory,
          staffId: _selectedStaff,
        );
      }

      // Load top products
      final topProducts = await DatabaseService.instance.getTopProducts(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
        limit: 10,
      );

      // Load staff performance
      final staffPerformance = await DatabaseService.instance.getStaffPerformance(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
      );

      // Load product analytics
      final productAnalytics = await DatabaseService.instance.getProductAnalytics(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
      );

      // Load daily sales data
      final dailySales = await DatabaseService.instance.getDailySales(
        startDate: _selectedPeriod.startDate,
        endDate: _selectedPeriod.endDate,
        categoryId: _selectedCategory,
        staffId: _selectedStaff,
      );

      // Load categories for filter
      final categories = await DatabaseService.instance.getCategories();
      final categoryNames = categories.map((c) => c.name).toList();

      setState(() {
        _salesSummary = summary;
        _comparisonSummary = comparisonSummary;
        _topProducts = topProducts;
        _staffPerformance = staffPerformance;
        _productAnalytics = productAnalytics;
        _dailySales = dailySales;
        _categories = categoryNames;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load reports data');
        setState(() => _isLoading = false);
      }
    }
  }

  ReportPeriod _getComparisonPeriod() {
    final currentStart = _selectedPeriod.startDate;
    final currentEnd = _selectedPeriod.endDate;
    final duration = currentEnd.difference(currentStart);

    return ReportPeriod(
      label: 'Previous Period',
      startDate: currentStart.subtract(duration + const Duration(days: 1)),
      endDate: currentStart.subtract(const Duration(days: 1)),
    );
  }

  void _onPeriodChanged(ReportPeriod newPeriod) {
    setState(() => _selectedPeriod = newPeriod);
    _loadReportsData();
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    _loadReportsData();
  }

  void _onStaffChanged(String? staff) {
    setState(() => _selectedStaff = staff);
    _loadReportsData();
  }

  void _toggleComparison(bool value) {
    setState(() => _showComparison = value);
    _loadReportsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Advanced Filters
                    _buildAdvancedFilters(),
                    const SizedBox(height: 24),

                    // KPI Cards with Comparison
                    if (_salesSummary != null) ...[
                      _buildKPIGrid(_salesSummary!, _comparisonSummary),
                      const SizedBox(height: 32),
                    ],

                    // Charts Section
                    const Text(
                      'Sales Trends',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSalesChart(),
                    const SizedBox(height: 32),

                    // Staff Performance
                    const Text(
                      'Staff Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStaffPerformance(),
                    const SizedBox(height: 32),

                    // Product Analytics
                    const Text(
                      'Product Analytics (ABC Analysis)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProductAnalytics(),
                    const SizedBox(height: 32),

                    // Top Products
                    const Text(
                      'Top Performing Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProductsList(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSalesChart() {
    if (_dailySales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No sales data available for the selected period'),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Sales Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    final maxRevenue = _dailySales.isNotEmpty
        ? _dailySales.map((d) => d.revenue).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _dailySales.map((daily) {
        final height = (daily.revenue / maxRevenue) * 200;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RM ${daily.revenue.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  height: height.clamp(20, 200),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MM/dd').format(daily.date),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No product sales data available'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topProducts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = _topProducts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(product.productName),
            subtitle: Text('${product.unitsSold} units sold'),
            trailing: Text(
              'RM ${product.revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Sales History',
                Icons.history,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SalesHistoryScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Shift Reports',
                Icons.access_time,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShiftReportsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Product Reports',
                Icons.inventory,
                Colors.orange,
                () => _showProductReports(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Financial Reports',
                Icons.account_balance,
                Colors.purple,
                () => _showFinancialReports(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductReports() {
    if (_topProducts.isEmpty && _productAnalytics.isEmpty) {
      ToastHelper.showToast(context, 'No product report data available');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._topProducts.take(5).map(
                  (product) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.productName),
                    subtitle: Text('${product.unitsSold} units sold'),
                    trailing: Text('RM ${product.revenue.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToCSV();
                        },
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export CSV'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToPDF();
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinancialReports() {
    final summary = _salesSummary;
    if (summary == null) {
      ToastHelper.showToast(context, 'No financial report data available');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Financial Report Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gross Sales: RM ${summary.grossSales.toStringAsFixed(2)}'),
              Text('Net Sales: RM ${summary.netSales.toStringAsFixed(2)}'),
              Text('Tax: RM ${summary.totalTax.toStringAsFixed(2)}'),
              Text('Service Charge: RM ${summary.totalServiceCharge.toStringAsFixed(2)}'),
              Text('Discounts: RM ${summary.totalDiscount.toStringAsFixed(2)}'),
              Text('Transactions: ${summary.transactionCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToCSV();
              },
              child: const Text('Export CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToPDF();
              },
              child: const Text('Export PDF'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category),
                          )),
                    ],
                    onChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedStaff,
                    decoration: const InputDecoration(
                      labelText: 'Staff Member',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Staff'),
                      ),
                      ..._staffMembers.map((staff) => DropdownMenuItem<String?>(
                            value: staff,
                            child: Text(staff),
                          )),
                    ],
                    onChanged: _onStaffChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ReportDateSelector(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: _onPeriodChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Comparison'),
                    subtitle: const Text('Compare with previous period'),
                    value: _showComparison,
                    onChanged: _toggleComparison,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(SalesSummary summary, SalesSummary? comparison) {
    final currentAverageOrderValue = summary.transactionCount > 0
        ? summary.netSales / summary.transactionCount
        : 0.0;
    final comparisonAverageOrderValue = (comparison != null && comparison.transactionCount > 0)
        ? comparison.netSales / comparison.transactionCount
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth < 600) columns = 1;
        else if (constraints.maxWidth < 900) columns = 2;
        else if (constraints.maxWidth < 1200) columns = 3;
        else columns = 4;

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            KPICard(
              title: 'Total Revenue',
              value: 'RM ${summary.grossSales.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
              subtitle: comparison != null
                  ? _calculatePercentageChange(summary.grossSales, comparison.grossSales)
                  : null,
            ),
            KPICard(
              title: 'Net Sales',
              value: 'RM ${summary.netSales.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.blue,
              subtitle: comparison != null
                  ? _calculatePercentageChange(summary.netSales, comparison.netSales)
                  : null,
            ),
            KPICard(
              title: 'Total Orders',
              value: summary.transactionCount.toString(),
              icon: Icons.receipt,
              color: Colors.orange,
              subtitle: comparison != null
                  ? _calculatePercentageChange(summary.transactionCount.toDouble(), comparison.transactionCount.toDouble())
                  : null,
            ),
            KPICard(
              title: 'Avg Order Value',
              value: 'RM ${currentAverageOrderValue.toStringAsFixed(2)}',
              icon: Icons.inventory,
              color: Colors.purple,
              subtitle: comparison != null
                  ? _calculatePercentageChange(
                      currentAverageOrderValue,
                      comparisonAverageOrderValue,
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }

  String _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return '+∞%';
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  Widget _buildStaffPerformance() {
    if (_staffPerformance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No staff performance data available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff Performance Metrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _staffPerformance.length,
              itemBuilder: (context, index) {
                final staff = _staffPerformance[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(staff.name[0].toUpperCase()),
                  ),
                  title: Text(staff.name),
                  subtitle: Text('${staff.transactionCount} transactions'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${staff.totalSales.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Avg: RM ${staff.averageOrderValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAnalytics() {
    if (_productAnalytics.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No product analytics data available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Performance (ABC Analysis)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Revenue')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('ABC Class')),
                  DataColumn(label: Text('Margin %')),
                ],
                rows: _productAnalytics.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(Text('RM ${product.revenue.toStringAsFixed(2)}')),
                      DataCell(Text(product.quantitySold.toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getABCClassColor(product.abcClass),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.abcClass,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${product.profitMargin.toStringAsFixed(1)}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getABCClassColor(String abcClass) {
    switch (abcClass) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = _generateCSVData();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvData);

      if (mounted) {
        ToastHelper.showToast(context, 'CSV exported to: $fileName');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to export CSV: $e');
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                if (_salesSummary != null) ...[
                  pw.Text('Total Revenue: RM ${_salesSummary!.grossSales.toStringAsFixed(2)}'),
                  pw.Text('Net Sales: RM ${_salesSummary!.netSales.toStringAsFixed(2)}'),
                  pw.Text('Total Orders: ${_salesSummary!.transactionCount}'),
                  pw.SizedBox(height: 20),
                ],
                pw.Text('Top Products:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ..._topProducts.map((product) =>
                  pw.Text('${product.itemName}: RM ${product.revenue.toStringAsFixed(2)} (${product.quantitySold} sold)')
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ToastHelper.showToast(context, 'PDF exported to: $fileName');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to export PDF: $e');
      }
    }
  }

  String _generateCSVData() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Sales Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    buffer.writeln('');

    // Summary
    if (_salesSummary != null) {
      buffer.writeln('Summary');
      buffer.writeln('Total Revenue,RM ${_salesSummary!.grossSales.toStringAsFixed(2)}');
      buffer.writeln('Net Sales,RM ${_salesSummary!.netSales.toStringAsFixed(2)}');
      buffer.writeln('Total Orders,${_salesSummary!.transactionCount}');
      buffer.writeln('');
    }

    // Top Products
    buffer.writeln('Top Products');
    buffer.writeln('Product Name,Revenue,Quantity Sold');
    for (final product in _topProducts) {
      buffer.writeln('${product.itemName},RM ${product.revenue.toStringAsFixed(2)},${product.quantitySold}');
    }
    buffer.writeln('');

    // Staff Performance
    if (_staffPerformance.isNotEmpty) {
      buffer.writeln('Staff Performance');
      buffer.writeln('Staff Name,Total Sales,Transaction Count,Average Order Value');
      for (final staff in _staffPerformance) {
        buffer.writeln('${staff.name},RM ${staff.totalSales.toStringAsFixed(2)},${staff.transactionCount},RM ${staff.averageOrderValue.toStringAsFixed(2)}');
      }
      buffer.writeln('');
    }

    // Product Analytics
    if (_productAnalytics.isNotEmpty) {
      buffer.writeln('Product Analytics (ABC Analysis)');
      buffer.writeln('Product Name,Revenue,Quantity Sold,ABC Class,Profit Margin %');
      for (final product in _productAnalytics) {
        buffer.writeln('${product.name},RM ${product.revenue.toStringAsFixed(2)},${product.quantitySold},${product.abcClass},${product.profitMargin.toStringAsFixed(1)}');
      }
    }

    return buffer.toString();
  }
}