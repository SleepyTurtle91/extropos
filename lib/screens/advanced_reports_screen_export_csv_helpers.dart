// Part of advanced_reports_screen.dart
// CSV helpers for advanced report types

part of 'advanced_reports_screen.dart';

extension AdvancedReportsExportCsvHelpers on _AdvancedReportsScreenState {
  void _appendDayClosingCsv(List<List<String>> csvData) {
    if (_dayClosingReport == null) return;

    csvData.add(['Metric', 'Value']);
    csvData.add(['Total Sales', _dayClosingReport!.totalSales.toStringAsFixed(2)]);
    csvData.add(['Net Sales', _dayClosingReport!.netSales.toStringAsFixed(2)]);
    csvData.add(['Cash Expected', _dayClosingReport!.cashExpected.toStringAsFixed(2)]);
    csvData.add(['Cash Actual', _dayClosingReport!.cashActual.toStringAsFixed(2)]);
    csvData.add(['Cash Variance', _dayClosingReport!.cashVariance.toStringAsFixed(2)]);
    csvData.add(['', '']);
    csvData.add(['Cash Reconciliation Details', '']);
    csvData.add([
      'Opening Float',
      _dayClosingReport!.cashReconciliation.openingFloat.toStringAsFixed(2),
    ]);
    csvData.add([
      'Cash Sales',
      _dayClosingReport!.cashReconciliation.cashSales.toStringAsFixed(2),
    ]);
    csvData.add([
      'Cash Refunds',
      _dayClosingReport!.cashReconciliation.cashRefunds.toStringAsFixed(2),
    ]);
    csvData.add([
      'Paid Outs',
      _dayClosingReport!.cashReconciliation.paidOuts.toStringAsFixed(2),
    ]);
    csvData.add([
      'Paid Ins',
      _dayClosingReport!.cashReconciliation.paidIns.toStringAsFixed(2),
    ]);
    csvData.add(['', '']);
    csvData.add([
      'Employee',
      'Shift Start',
      'Shift End',
      'Sales',
      'Cash Handled',
      'Duration',
    ]);
    for (final shift in _dayClosingReport!.shiftSummaries) {
      final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
      csvData.add([
        shift.employeeName,
        shift.shiftStart.toIso8601String(),
        endTime,
        shift.salesDuringShift.toStringAsFixed(2),
        shift.cashHandled.toStringAsFixed(2),
        '${shift.shiftDuration.inHours}h ${shift.shiftDuration.inMinutes % 60}m',
      ]);
    }
  }

  void _appendProfitLossCsv(List<List<String>> csvData) {
    if (_profitLossReport == null) return;

    csvData.add(['Metric', 'Value']);
    csvData.add(['Total Revenue', _profitLossReport!.totalRevenue.toStringAsFixed(2)]);
    csvData.add([
      'Cost of Goods Sold',
      _profitLossReport!.costOfGoodsSold.toStringAsFixed(2),
    ]);
    csvData.add(['Gross Profit', _profitLossReport!.grossProfit.toStringAsFixed(2)]);
    csvData.add([
      'Operating Expenses',
      _profitLossReport!.operatingExpenses.toStringAsFixed(2),
    ]);
    csvData.add(['Net Profit', _profitLossReport!.netProfit.toStringAsFixed(2)]);
    csvData.add([
      'Profit Margin',
      '${_profitLossReport!.profitMargin.toStringAsFixed(1)}%',
    ]);
  }

  void _appendCashFlowCsv(List<List<String>> csvData) {
    if (_cashFlowReport == null) return;

    csvData.add(['Cash Flow Type', 'Amount']);
    csvData.add(['Opening Cash', _cashFlowReport!.openingCash.toStringAsFixed(2)]);
    csvData.add(['Closing Cash', _cashFlowReport!.closingCash.toStringAsFixed(2)]);
    csvData.add(['Net Cash Flow', _cashFlowReport!.netCashFlow.toStringAsFixed(2)]);
    csvData.add(['', '']);
    csvData.add(['Inflows', '']);
    for (final entry in _cashFlowReport!.inflowBreakdown.entries) {
      final key = entry.key;
      final value = entry.value;
      csvData.add([key, value.toStringAsFixed(2)]);
    }
    csvData.add(['', '']);
    csvData.add(['Outflows', '']);
    for (final entry in _cashFlowReport!.outflowBreakdown.entries) {
      final key = entry.key;
      final value = entry.value;
      csvData.add([key, (-value).toStringAsFixed(2)]);
    }
  }

  void _appendTaxSummaryCsv(List<List<String>> csvData) {
    if (_taxSummaryReport == null) return;

    csvData.add(['Tax Rate', 'Amount Collected']);
    csvData.add([
      'Total Tax Collected',
      _taxSummaryReport!.totalTaxCollected.toStringAsFixed(2),
    ]);
    csvData.add(['Tax Liability', _taxSummaryReport!.taxLiability.toStringAsFixed(2)]);
    csvData.add(['', '']);
    for (final entry in _taxSummaryReport!.taxBreakdown.entries) {
      final rate = entry.key;
      final amount = entry.value;
      csvData.add([rate, amount.toStringAsFixed(2)]);
    }
  }

  void _appendInventoryValuationCsv(List<List<String>> csvData) {
    if (_inventoryValuationReport == null) return;

    csvData.add(['Item', 'Cost Value', 'Retail Value', 'Units']);
    for (final item in _inventoryValuationReport!.valuationItems) {
      csvData.add([
        item.itemName,
        item.totalCostValue.toStringAsFixed(2),
        item.totalRetailValue.toStringAsFixed(2),
        item.quantity.toString(),
      ]);
    }
  }

  void _appendAbcAnalysisCsv(List<List<String>> csvData) {
    if (_abcAnalysisReport == null) return;

    csvData.add(['Item', 'Category', 'Revenue', 'Percentage']);
    for (final item in _abcAnalysisReport!.abcItems) {
      csvData.add([
        item.itemName,
        item.category,
        item.revenue.toStringAsFixed(2),
        '${item.percentageOfTotal.toStringAsFixed(1)}%',
      ]);
    }
  }

  void _appendDemandForecastingCsv(List<List<String>> csvData) {
    if (_demandForecastingReport == null) return;

    csvData.add(['Item', 'Historical Sales', 'Forecasted Sales', 'Confidence']);
    for (final item in _demandForecastingReport!.forecastItems) {
      csvData.add([
        item.itemName,
        item.historicalSales.last.toStringAsFixed(0),
        item.forecastedSales.last.toStringAsFixed(0),
        '${(item.confidenceLevel * 100).toStringAsFixed(0)}%',
      ]);
    }
  }

  void _appendMenuEngineeringCsv(List<List<String>> csvData) {
    if (_menuEngineeringReport == null) return;

    csvData.add(['Item', 'Category', 'Popularity %', 'Profitability %']);
    for (final item in _menuEngineeringReport!.menuItems) {
      csvData.add([
        item.itemName,
        item.category,
        item.popularity.toStringAsFixed(1),
        item.profitability.toStringAsFixed(1),
      ]);
    }
  }

  void _appendTablePerformanceCsv(List<List<String>> csvData) {
    if (_tablePerformanceReport == null) return;

    csvData.add(['Table', 'Revenue', 'Orders', 'Avg Occupancy', 'Revenue/Hour']);
    for (final table in _tablePerformanceReport!.tableData) {
      csvData.add([
        table.tableName,
        table.totalRevenue.toStringAsFixed(2),
        table.totalOrders.toString(),
        '${table.averageOccupancyTime.inHours}h ${table.averageOccupancyTime.inMinutes % 60}m',
        table.revenuePerHour.toStringAsFixed(2),
      ]);
    }
  }

  void _appendDailyStaffPerformanceCsv(List<List<String>> csvData) {
    if (_dailyStaffPerformanceReport == null) return;

    final data = _dailyStaffPerformanceReport!;
    final staffData = data['staffData'] as List<dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;

    csvData.add([
      'Staff Name',
      'Login Time',
      'Logout Time',
      'Gross Sales',
      'Discounts',
      'Net Sales',
      'Transactions',
      'SST 6%',
      'SST 8%',
      'Total SST',
      'Cash',
      'Credit Card',
      'TNG/GrabPay',
      'ShopeePay',
      'Voids',
      'Overrides',
      'Refunds',
    ]);

    for (final staff in staffData) {
      final taxBreakdown = staff['taxBreakdown'] as Map<String, dynamic>;
      final paymentMethods = staff['paymentMethods'] as Map<String, dynamic>;
      final totalTax = taxBreakdown.values.fold<double>(
        0,
        (sum, amount) => sum + (amount as double),
      );

      csvData.add([
        staff['userName'] as String,
        _formatTime(staff['loginTime'] as String?),
        _formatTime(staff['logoutTime'] as String?),
        (staff['grossSales'] as double).toStringAsFixed(2),
        (staff['discounts'] as double).toStringAsFixed(2),
        (staff['netSales'] as double).toStringAsFixed(2),
        (staff['transactionCount'] as int).toString(),
        (taxBreakdown['0.06'] ?? 0).toStringAsFixed(2),
        (taxBreakdown['0.08'] ?? 0).toStringAsFixed(2),
        totalTax.toStringAsFixed(2),
        (paymentMethods['Cash'] ?? 0).toStringAsFixed(2),
        (paymentMethods['Credit Card'] ?? 0).toStringAsFixed(2),
        (paymentMethods['TNG / GrabPay'] ?? 0).toStringAsFixed(2),
        (paymentMethods['ShopeePay'] ?? 0).toStringAsFixed(2),
        (staff['voids'] as int).toString(),
        (staff['overrides'] as int).toString(),
        (staff['refunds'] as double).toStringAsFixed(2),
      ]);
    }

    // Add totals row
    final totalTax = (summary['taxBreakdown'] as Map).values.fold<double>(
      0,
      (sum, amount) => sum + (amount as double),
    );
    csvData.add([
      'TOTAL',
      '',
      '',
      (summary['totalGrossSales'] as double).toStringAsFixed(2),
      (summary['totalDiscounts'] as double).toStringAsFixed(2),
      (summary['totalNetSales'] as double).toStringAsFixed(2),
      (summary['totalTransactions'] as int).toString(),
      ((summary['taxBreakdown'] as Map)['0.06'] ?? 0).toStringAsFixed(2),
      ((summary['taxBreakdown'] as Map)['0.08'] ?? 0).toStringAsFixed(2),
      totalTax.toStringAsFixed(2),
      ((summary['paymentMethodTotals'] as Map)['Cash'] ?? 0).toStringAsFixed(2),
      ((summary['paymentMethodTotals'] as Map)['Credit Card'] ?? 0).toStringAsFixed(2),
      ((summary['paymentMethodTotals'] as Map)['TNG / GrabPay'] ?? 0).toStringAsFixed(2),
      ((summary['paymentMethodTotals'] as Map)['ShopeePay'] ?? 0).toStringAsFixed(2),
      (summary['totalVoids'] as int).toString(),
      (summary['totalOverrides'] as int).toString(),
      (summary['totalRefunds'] as double).toStringAsFixed(2),
    ]);
  }
}
