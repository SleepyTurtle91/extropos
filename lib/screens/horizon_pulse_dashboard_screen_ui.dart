part of 'horizon_pulse_dashboard_screen.dart';

/// UI extension for HorizonPulseDashboardScreen
extension HorizonPulseDashboardScreenUI on _HorizonPulseDashboardScreenState {
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
  }
}
