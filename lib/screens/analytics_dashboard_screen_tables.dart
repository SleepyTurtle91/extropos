part of 'analytics_dashboard_screen.dart';

/// Table and distribution builders for AnalyticsDashboardScreen
extension AnalyticsDashboardTables on _AnalyticsDashboardScreenState {
  /// Build top products data table
  Widget buildTopProductsTable() {
    if (_topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No product data available')),
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
              'Top 10 Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Revenue')),
                  DataColumn(label: Text('Qty Sold')),
                  DataColumn(label: Text('Orders')),
                ],
                rows: List.generate(_topProducts.length, (index) {
                  final product = _topProducts[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('#${index + 1}')),
                      DataCell(Text(product.itemName)),
                      DataCell(Text(product.categoryName)),
                      DataCell(
                        Text('$currency${product.revenue.toStringAsFixed(2)}'),
                      ),
                      DataCell(Text(product.quantitySold.toString())),
                      DataCell(Text(product.orderCount.toString())),
                    ],
                  );
                }),
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
