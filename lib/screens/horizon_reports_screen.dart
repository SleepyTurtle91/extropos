import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_charts.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Horizon Admin - Reports & Analytics Screen
/// Comprehensive business analytics with charts and comparisons
class HorizonReportsScreen extends StatefulWidget {
  const HorizonReportsScreen({super.key});

  @override
  State<HorizonReportsScreen> createState() => _HorizonReportsScreenState();
}

class _HorizonReportsScreenState extends State<HorizonReportsScreen> {
  final HorizonDataService _dataService = HorizonDataService();
  DateTimeRange? _dateRange;
  String _reportType = 'Daily';
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Report data
  Map<String, dynamic> _salesSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<int, double> _hourlySales = {};
  Map<int, double> _previousHourlySales = {};
  Map<String, double> _categorySales = {};
  Map<String, double> _paymentMethods = {};
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // Initialize Appwrite client
      final appwriteService = AppwriteService.instance;
      if (!appwriteService.isInitialized) {
        await appwriteService.initialize();
      }

      // Initialize data service
      if (appwriteService.client != null) {
        await _dataService.initialize(appwriteService.client!);
      } else {
        throw Exception('Appwrite client is null');
      }

      // Load report data
      await _loadReportData();
      
      // Subscribe to real-time updates
      _subscribeToUpdates();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final startDate = _dateRange?.start;
      final endDate = _dateRange?.end;

      // Load sales summary
      final summary = await _dataService.getSalesSummary(
        startDate: startDate,
        endDate: endDate,
      );

      // Load top products
      final products = await _dataService.getTopSellingProducts(
        startDate: startDate,
        endDate: endDate,
        limit: 10,
      );

      // Load hourly sales for the selected period
      final hourly = await _dataService.getHourlySalesData(
        date: _dateRange?.end ?? DateTime.now(),
      );

      // Load previous period hourly sales (previous day)
      final previousDate = (_dateRange?.end ?? DateTime.now()).subtract(Duration(days: 1));
      final previousHourly = await _dataService.getHourlySalesData(
        date: previousDate,
      );

      // Load category sales
      final categorySales = await _dataService.getCategorySalesData(
        startDate: startDate,
        endDate: endDate,
      );

      // Load payment method data
      final paymentData = await _dataService.getPaymentMethodData(
        startDate: startDate,
        endDate: endDate,
      );

      // Load categories for mapping
      final categories = await _dataService.getCategories();

      setState(() {
        _salesSummary = summary;
        _topProducts = products;
        _hourlySales = hourly;
        _previousHourlySales = previousHourly;
        _categorySales = categorySales;
        _paymentMethods = paymentData;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load report data: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to transaction changes for live report updates
    _dataService.subscribeToTransactionChanges((response) {
      print('🔄 Reports: Received transaction update');
      // Reload report data when new transactions come in
      _loadReportData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return HorizonLayout(
        breadcrumbs: const ['Reports', 'Analytics'],
        currentRoute: '/reports',
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading reports...'),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_hasError) {
      return HorizonLayout(
        breadcrumbs: const ['Reports', 'Analytics'],
        currentRoute: '/reports',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: HorizonColors.rose),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 24),
              HorizonButton(
                text: 'Retry',
                type: HorizonButtonType.primary,
                icon: Icons.refresh,
                onPressed: _loadReportData,
              ),
            ],
          ),
        ),
      );
    }

    return const ComingSoonPlaceholder(
      title: 'Horizon Reports',
      subtitle: 'Cloud analytics reports are coming soon.',
    );
    return HorizonLayout(
      breadcrumbs: const ['Reports', 'Analytics'],
      currentRoute: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & Analytics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: HorizonColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detailed business insights and performance metrics',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HorizonColors.textSecondary,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  HorizonButton(
                    text: 'Export CSV',
                    type: HorizonButtonType.secondary,
                    icon: Icons.download,
                    onPressed: _exportReportToCSV,
                  ),
                  const SizedBox(width: 12),
                  HorizonButton(
                    text: 'Print Report',
                    type: HorizonButtonType.primary,
                    icon: Icons.print,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date Range Selector
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: HorizonColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HorizonColors.border, width: 1),
                ),
                child: GestureDetector(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (range != null) {
                      setState(() {
                        _dateRange = range;
                      });
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_dateRange?.start.toString().split(' ')[0]} to ${_dateRange?.end.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildReportTypeChip('Daily'),
              const SizedBox(width: 8),
              _buildReportTypeChip('Weekly'),
              const SizedBox(width: 8),
              _buildReportTypeChip('Monthly'),
            ],
          ),

          const SizedBox(height: 32),

          // Sales Comparison Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: HorizonLineChart(
                title: 'Sales Performance',
                currentData: _hourlySales.entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList()
                    ..sort((a, b) => a.x.compareTo(b.x)),
                previousData: _previousHourlySales.entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList()
                    ..sort((a, b) => a.x.compareTo(b.x)),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Top Products
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Selling Products',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HorizonColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ..._buildTopProductsList(),
                ],
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Performance
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Performance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: HorizonColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 20),
                        ..._buildCategoryRows(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Payment Methods
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: HorizonColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 20),
                        ..._buildPaymentRows(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Summary Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Period Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HorizonColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Sales',
                          'RM ${_salesSummary['total_sales']?.toStringAsFixed(2) ?? '0.00'}',
                          '+15.2%', // TODO: Calculate from previous period
                          HorizonColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Transactions',
                          '${_salesSummary['transaction_count'] ?? 0}',
                          '+8.4%', // TODO: Calculate from previous period
                          HorizonColors.electricIndigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Average Order',
                          'RM ${_salesSummary['average_order_value']?.toStringAsFixed(2) ?? '0.00'}',
                          '-1.2%', // TODO: Calculate from previous period
                          HorizonColors.amber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Conversion Rate',
                          '3.42%', // TODO: Implement conversion rate calculation
                          '+0.5%',
                          HorizonColors.rose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows() {
    if (_categorySales.isEmpty) {
      return [
        const Text('No category data available'),
      ];
    }

    // Get category name map
    final categoryNames = <String, String>{};
    for (final cat in _categories) {
      final id = cat['id'] as String?;
      final name = cat['name'] as String? ?? 'Unknown';
      if (id != null) {
        categoryNames[id] = name;
      }
    }

    // Calculate total sales
    final totalSales = _categorySales.values.fold(0.0, (sum, sales) => sum + sales);

    // Sort categories by sales
    final sortedCategories = _categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 4
    final topCategories = sortedCategories.take(4).toList();

    final widgets = <Widget>[];
    for (int i = 0; i < topCategories.length; i++) {
      final entry = topCategories[i];
      final categoryName = categoryNames[entry.key] ?? 'Unknown';
      final sales = entry.value;
      final percent = totalSales > 0 ? (sales / totalSales * 100).round() : 0;

      // For units, we don't have that data, so use sales as proxy
      final units = (sales / 10).round(); // Rough estimate

      widgets.add(_buildCategoryRow(categoryName, 'RM ${sales.toStringAsFixed(2)}', units, percent));
      if (i < topCategories.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  List<Widget> _buildPaymentRows() {
    if (_paymentMethods.isEmpty) {
      return [
        const Text('No payment data available'),
      ];
    }

    // Calculate total
    final total = _paymentMethods.values.fold(0.0, (sum, amount) => sum + amount);

    // Sort by amount
    final sortedPayments = _paymentMethods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final widgets = <Widget>[];
    for (int i = 0; i < sortedPayments.length && i < 3; i++) {
      final entry = sortedPayments[i];
      final method = entry.key;
      final amount = entry.value;
      final percent = total > 0 ? (amount / total * 100).round() : 0;

      widgets.add(_buildPaymentRow(method, 'RM ${amount.toStringAsFixed(2)}', percent));
      if (i < sortedPayments.length - 1 && i < 2) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  List<Widget> _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return [
        const Text('No product sales data available'),
      ];
    }

    final widgets = <Widget>[];
    for (int i = 0; i < _topProducts.length && i < 5; i++) {
      final product = _topProducts[i];
      final name = product['name'] as String? ?? 'Unknown Product';
      final quantity = product['totalQuantity'] as int? ?? 0;
      final revenue = product['totalRevenue'] as double? ?? 0.0;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${i + 1}. $name',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HorizonColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$quantity sold • RM ${revenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: HorizonColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  void _exportReportToCSV() {
    try {
      // Create CSV header
      final csvHeader = [
        'Metric',
        'Value',
        'Change',
      ].join(',');

      // Create CSV rows for summary data
      final List<String> csvRows = [csvHeader];
      
      // Summary metrics
      csvRows.add([
        'Total Sales',
        'RM ${_salesSummary['total_sales']?.toStringAsFixed(2) ?? '0.00'}',
        '+15.2%', // TODO: Calculate from previous period
      ].map((cell) => '"$cell"').join(','));
      
      csvRows.add([
        'Transactions',
        '${_salesSummary['transaction_count'] ?? 0}',
        '+8.4%', // TODO: Calculate from previous period
      ].map((cell) => '"$cell"').join(','));
      
      csvRows.add([
        'Average Order',
        'RM ${_salesSummary['average_order_value']?.toStringAsFixed(2) ?? '0.00'}',
        '-1.2%', // TODO: Calculate from previous period
      ].map((cell) => '"$cell"').join(','));
      
      // Category data
      csvRows.add(['', '', ''].map((cell) => '"$cell"').join(',')); // Empty row
      csvRows.add(['Category Performance', '', ''].map((cell) => '"$cell"').join(','));
      
      final categoryNames = <String, String>{};
      for (final cat in _categories) {
        final id = cat['id'] as String?;
        final name = cat['name'] as String? ?? 'Unknown';
        if (id != null) {
          categoryNames[id] = name;
        }
      }
      
      final totalSales = _categorySales.values.fold(0.0, (sum, sales) => sum + sales);
      final sortedCategories = _categorySales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories.take(4)) {
        final categoryName = categoryNames[entry.key] ?? 'Unknown';
        final sales = entry.value;
        final percent = totalSales > 0 ? (sales / totalSales * 100).round() : 0;
        
        csvRows.add([
          categoryName,
          'RM ${sales.toStringAsFixed(2)}',
          '$percent%',
        ].map((cell) => '"$cell"').join(','));
      }
      
      // Top products
      csvRows.add(['', '', ''].map((cell) => '"$cell"').join(',')); // Empty row
      csvRows.add(['Top Products', '', ''].map((cell) => '"$cell"').join(','));
      
      for (int i = 0; i < _topProducts.length && i < 5; i++) {
        final product = _topProducts[i];
        final name = product['name'] as String? ?? 'Unknown Product';
        final quantity = product['totalQuantity'] as int? ?? 0;
        final revenue = product['totalRevenue'] as double? ?? 0.0;
        
        csvRows.add([
          name,
          '$quantity units',
          'RM ${revenue.toStringAsFixed(2)}',
        ].map((cell) => '"$cell"').join(','));
      }

      final csvData = csvRows.join('\n');
      
      // Log CSV data and show success
      print('📊 Report CSV Export Generated');
      print('📄 Data:\n$csvData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report CSV generated! Check console for data.'),
          backgroundColor: HorizonColors.emerald,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: HorizonColors.rose,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildReportTypeChip(String label) {
    final isSelected = _reportType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reportType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HorizonColors.electricIndigo : HorizonColors.surfaceGrey,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? HorizonColors.electricIndigo : HorizonColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : HorizonColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String name, String revenue, int units, int percent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
            Text(
              revenue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: percent / 100,
            backgroundColor: HorizonColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(
              HorizonColors.electricIndigo,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$units units • $percent%',
            style: const TextStyle(
              fontSize: 11,
              color: HorizonColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String method, String amount, int percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HorizonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percent% of total',
                style: const TextStyle(
                  fontSize: 11,
                  color: HorizonColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HorizonColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String change, Color color) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HorizonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
