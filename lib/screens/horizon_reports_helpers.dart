part of 'horizon_reports_screen.dart';

/// Extension providing helper methods for data transformation and export
extension _HorizonReportsScreenHelpers on _HorizonReportsScreenState {
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
}
