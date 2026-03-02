part of 'modern_reports_dashboard.dart';

extension ModernReportsDashboardHelpers on _ModernReportsDashboardState {
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

}
