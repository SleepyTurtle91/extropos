part of 'analytics_dashboard_screen.dart';

/// Chart builder methods for AnalyticsDashboardScreen
extension AnalyticsDashboardCharts on _AnalyticsDashboardScreenState {
  /// Build the dashboard grid layout with all charts
  Widget buildDashboardLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDateRangeCard(),
          const SizedBox(height: 16),
          buildSummaryCards(),
          const SizedBox(height: 24),
          buildDailySalesChart(),
          const SizedBox(height: 24),
          // Two-column layout for charts
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildCategoryChart()),
                    const SizedBox(width: 16),
                    Expanded(child: buildPaymentMethodChart()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    buildCategoryChart(),
                    const SizedBox(height: 24),
                    buildPaymentMethodChart(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          buildTopProductsTable(),
          const SizedBox(height: 24),
          buildOrderTypeChart(),
        ],
      ),
    );
  }

  /// Build date range selection card
  Widget buildDateRangeCard() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reporting Period',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.edit),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary cards grid
  Widget buildSummaryCards() {
    if (_summary == null) return const SizedBox.shrink();

    final currency = BusinessInfo.instance.currencySymbol;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 2;
        } else if (constraints.maxWidth < 900) {
          columns = 3;
        }

        final cards = [
          _SummaryCard(
            title: 'Total Revenue',
            value: '$currency ${_summary!.totalRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          _SummaryCard(
            title: 'Orders',
            value: _summary!.orderCount.toString(),
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
          _SummaryCard(
            title: 'Items Sold',
            value: _summary!.itemsSold.toString(),
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),
          _SummaryCard(
            title: 'Avg Order Value',
            value:
                '$currency ${_summary!.averageOrderValue.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            return SizedBox(
              width: (constraints.maxWidth - ((columns - 1) * 12)) / columns,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  /// Build daily sales trend line chart
  Widget buildDailySalesChart() {
    if (_dailySales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text('No sales data available for this period'),
          ),
        ),
      );
    }

    final maxRevenue = _dailySales
        .map((s) => s.revenue)
        .reduce((a, b) => a > b ? a : b);
    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sales Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxRevenue / 5,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '$currency${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _dailySales.length) {
                            return Text(
                              _dailySales[index].dateLabel,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
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
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxRevenue * 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category performance pie chart
  Widget buildCategoryChart() {
    if (_categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No category data available')),
        ),
      );
    }

    final total = _categories.fold<double>(0, (sum, cat) => sum + cat.revenue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _categories.map((cat) {
                    final percentage = (cat.revenue / total) * 100;
                    return PieChartSectionData(
                      value: cat.revenue,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_categories.length, (index) {
              final cat = _categories[index];
              final percentage = (cat.revenue / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build payment methods bar chart
  Widget buildPaymentMethodChart() {
    if (_paymentMethods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No payment data available')),
        ),
      );
    }

    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '$currency${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _paymentMethods.length) {
                            return Text(
                              _paymentMethods[index].paymentMethodName,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _paymentMethods.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalAmount,
                          color: const Color(0xFF2563EB),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build business mode distribution chart
  Widget buildOrderTypeChart() {
    if (_orderTypeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _orderTypeDistribution.values.fold<double>(
      0,
      (sum, val) => sum + val,
    );
    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Mode Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._orderTypeDistribution.entries.map((entry) {
              final percentage = (entry.value / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
