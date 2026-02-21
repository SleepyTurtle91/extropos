import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_charts.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:extropos/widgets/horizon_metric_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Horizon Admin - Enhanced Pulse Dashboard
/// Real-time business metrics with charts and trends
class HorizonPulseDashboardScreen extends StatefulWidget {
  const HorizonPulseDashboardScreen({super.key});

  @override
  State<HorizonPulseDashboardScreen> createState() => _HorizonPulseDashboardScreenState();
}

class _HorizonPulseDashboardScreenState extends State<HorizonPulseDashboardScreen> {
  final HorizonDataService _dataService = HorizonDataService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRealtimeConnected = false;

  // Data
  Map<String, dynamic> _salesSummary = {};
  Map<int, double> _hourlySales = {};
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
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

      // Load data
      await _loadDashboardData();
      
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

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load today's sales summary
      final summary = await _dataService.getSalesSummary(
        startDate: DateTime.now().subtract(Duration(days: 1)),
        endDate: DateTime.now(),
      );

      // Load hourly sales for bar chart
      final hourly = await _dataService.getHourlySalesData(
        date: DateTime.now(),
      );

      // Load top products
      final products = await _dataService.getTopSellingProducts(
        limit: 4,
      );

      setState(() {
        _salesSummary = summary;
        _hourlySales = hourly;
        _topProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to transaction changes for live dashboard updates
    _dataService.subscribeToTransactionChanges((response) {
      print('🔄 Dashboard: Received transaction update');
      // Reload dashboard data when new transactions come in
      _loadDashboardData();
    });
    
    setState(() {
      _isRealtimeConnected = true;
    });
  }

  @override
  void dispose() {
    // Unsubscribe from all real-time updates
    _dataService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComingSoonPlaceholder(
      title: 'Pulse Dashboard',
      subtitle: 'Real-time business analytics coming soon',
    );
    if (_isLoading) {
      return HorizonLayout(
        breadcrumbs: const ['Dashboard'],
        currentRoute: '/dashboard',
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading dashboard data...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return HorizonLayout(
        breadcrumbs: const ['Dashboard'],
        currentRoute: '/dashboard',
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
                onPressed: _loadDashboardData,
              ),
            ],
          ),
        ),
      );
    }

    // Get metrics from loaded data
    final totalSales = _salesSummary['total_sales'] ?? 0.0;
    final transactionCount = _salesSummary['transaction_count'] ?? 0;
    final avgOrderValue = _salesSummary['average_order_value'] ?? 0.0;

    return HorizonLayout(
      breadcrumbs: const ['Dashboard'],
      currentRoute: '/dashboard',
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
                  Row(
                    children: [
                      Text(
                        'Pulse Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: HorizonColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 12),
                      // Real-time connection indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isRealtimeConnected 
                              ? HorizonColors.emerald.withOpacity(0.1)
                              : HorizonColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isRealtimeConnected 
                                ? HorizonColors.emerald 
                                : HorizonColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isRealtimeConnected 
                                    ? HorizonColors.emerald 
                                    : HorizonColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isRealtimeConnected 
                                    ? HorizonColors.emerald 
                                    : HorizonColors.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time business overview',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HorizonColors.textSecondary,
                        ),
                  ),
                ],
              ),
              HorizonButton(
                text: 'Refresh',
                type: HorizonButtonType.primary,
                icon: Icons.sync,
                onPressed: _loadDashboardData,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // KPI Metrics with Sparklines
          ResponsiveGrid(
            children: [
              HorizonMetricCard(
                title: 'Total Sales',
                value: 'RM ${totalSales.toStringAsFixed(2)}',
                subtitle: 'Today',
                icon: Icons.trending_up,
                iconColor: HorizonColors.emerald,
                percentageChange: 12.5,
                sparkline: HorizonSparkline(
                  values: [10, 45, 30, 70, 50, 95, 85, 100, 75, 120],
                  lineColor: HorizonColors.emerald,
                  fillColor: HorizonColors.emerald,
                ),
              ),
              HorizonMetricCard(
                title: 'Orders',
                value: '$transactionCount',
                subtitle: 'Today',
                icon: Icons.receipt_long_outlined,
                iconColor: HorizonColors.electricIndigo,
                percentageChange: 8.3,
                sparkline: HorizonSparkline(
                  values: [15, 35, 28, 55, 40, 75, 65, 85, 60, 95],
                  lineColor: HorizonColors.electricIndigo,
                  fillColor: HorizonColors.electricIndigo,
                ),
              ),
              HorizonMetricCard(
                title: 'Avg Order Value',
                value: 'RM ${avgOrderValue.toStringAsFixed(2)}',
                subtitle: 'Today',
                icon: Icons.attach_money,
                iconColor: HorizonColors.amber,
                percentageChange: -2.1,
                sparkline: HorizonSparkline(
                  values: [45, 52, 48, 55, 50, 58, 60, 55, 52, 50],
                  lineColor: HorizonColors.amber,
                  fillColor: HorizonColors.amber,
                  isPositiveTrend: false,
                ),
              ),
              HorizonMetricCard(
                title: 'Alerts',
                value: '5',
                subtitle: 'Low stock items',
                icon: Icons.warning_amber_rounded,
                iconColor: HorizonColors.rose,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Hourly Sales Velocity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: HorizonBarChart(
                title: 'Hourly Sales Velocity',
                groups: _buildHourlyBarChart(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Two Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Selling Products
              Expanded(
                flex: 2,
                child: Card(
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
                        ...(_topProducts.isEmpty
                            ? [
                                const Center(
                                  child: Text('No product data available'),
                                )
                              ]
                            : _topProducts
                                .asMap()
                                .entries
                                .expand((entry) => [
                                      if (entry.key > 0) const SizedBox(height: 16),
                                      _buildProductItem(
                                        (entry.value['name'] ?? 'Unknown').toString(),
                                        'RM ${(entry.value['price'] ?? 0.0).toStringAsFixed(2)}',
                                        (entry.value['totalQuantity'] ?? 0).toInt(),
                                        'RM ${(entry.value['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                                      ),
                                    ])
                                .toList()),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Quick Stats
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: HorizonColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow(
                          'Conversion',
                          '3.24%',
                          HorizonColors.emerald,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Avg Session',
                          '5m 24s',
                          HorizonColors.electricIndigo,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Repeat Rate',
                          '42.8%',
                          HorizonColors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    String name,
    String price,
    int units,
    String revenue,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HorizonColors.surfaceGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.coffee_outlined,
            size: 24,
            color: HorizonColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HorizonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$units units',
                style: const TextStyle(
                  fontSize: 12,
                  color: HorizonColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              revenue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                fontSize: 12,
                color: HorizonColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: HorizonColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build hourly bar chart from real data
  List<BarChartGroupData> _buildHourlyBarChart() {
    final List<BarChartGroupData> groups = [];
    final currentHour = DateTime.now().hour;

    // Show last 7 hours
    for (int i = 0; i < 7; i++) {
      final hour = (currentHour - 6 + i) % 24;
      final sales = _hourlySales[hour] ?? 0.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: HorizonColors.electricIndigo,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return groups;
  }}