part of 'reports_screen.dart';

extension _ReportsScreenWidgets on _ReportsScreenState {
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
                    onChanged: onCategoryChanged,
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
                    onChanged: onStaffChanged,
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
                    onPeriodChanged: onPeriodChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Comparison'),
                    subtitle: const Text('Compare with previous period'),
                    value: _showComparison,
                    onChanged: toggleComparison,
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
}
