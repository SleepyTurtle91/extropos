part of 'reports_screen.dart';

extension ReportsScreenContentPart1 on _ReportsScreenState {
  String _generateReportCsv() {
    if (_currentReport == null) return '';

    final buffer = StringBuffer();

    // Header
    buffer.writeln('Sales Report');
    buffer.writeln(
      'Period: ${_selectedPeriod.startDate.toString().split(' ')[0]} to ${_selectedPeriod.endDate.toString().split(' ')[0]}',
    );
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Sales,${_currentReport!.grossSales}');
    buffer.writeln('Total Orders,${_currentReport!.transactionCount}');
    buffer.writeln('Average Order Value,${_currentReport!.averageTicket}');
    buffer.writeln('');

    // Payment Methods
    buffer.writeln('PAYMENT METHODS');
    buffer.writeln('Method,Amount,Percentage');
    final totalSales = _currentReport!.grossSales;
    for (final entry in _currentReport!.paymentMethods.entries) {
      final percentage = totalSales > 0
          ? (entry.value / totalSales * 100)
          : 0.0;
      buffer.writeln(
        '${entry.key},${entry.value.toStringAsFixed(2)},${percentage.toStringAsFixed(1)}%',
      );
    }
    buffer.writeln('');

    // Top Items
    buffer.writeln('TOP CATEGORIES');
    buffer.writeln('Category,Revenue');
    for (final entry in _currentReport!.topCategories.entries) {
      buffer.writeln('${entry.key},${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    // Note about hourly sales
    buffer.writeln('Note: Hourly sales data requires enhanced reporting.');

    return buffer.toString();
  }

  String _generateAdvancedCSVData() {
    final buffer = StringBuffer();
    final reportTitle = _getReportTypeLabel(_selectedReportType);

    buffer.writeln(reportTitle);
    buffer.writeln('Period: ${_selectedPeriod.label}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    switch (_selectedReportType) {
      case ReportType.salesSummary:
        if (_salesSummaryReport != null) {
          final netProfit =
              _salesSummaryReport!.netSales -
              _salesSummaryReport!.totalDiscounts;
          buffer.writeln('Gross Sales,${_salesSummaryReport!.grossSales}');
          buffer.writeln(
            'Total Transactions,${_salesSummaryReport!.totalTransactions}',
          );
          buffer.writeln('Net Sales,${_salesSummaryReport!.netSales}');
          buffer.writeln('Net Profit,$netProfit');
        }
        break;
      case ReportType.productSales:
        if (_productSalesReport != null) {
          buffer.writeln('Product,Quantity Sold,Revenue');
          for (final product in _productSalesReport!.productSales) {
            buffer.writeln(
              '${product.productName},${product.unitsSold},${product.totalRevenue}',
            );
          }
        }
        break;
      case ReportType.dayClosing:
        if (_dayClosingReport != null) {
          buffer.writeln('Business Session Summary');
          buffer.writeln('Total Sales,${_dayClosingReport!.totalSales}');
          buffer.writeln('Net Sales,${_dayClosingReport!.netSales}');
          buffer.writeln('Cash Expected,${_dayClosingReport!.cashExpected}');
          buffer.writeln('Cash Actual,${_dayClosingReport!.cashActual}');
          buffer.writeln('Cash Variance,${_dayClosingReport!.cashVariance}');
          buffer.writeln('');
          buffer.writeln('Cash Reconciliation Details');
          buffer.writeln(
            'Opening Float,${_dayClosingReport!.cashReconciliation.openingFloat}',
          );
          buffer.writeln(
            'Cash Sales,${_dayClosingReport!.cashReconciliation.cashSales}',
          );
          buffer.writeln(
            'Cash Refunds,${_dayClosingReport!.cashReconciliation.cashRefunds}',
          );
          buffer.writeln(
            'Paid Outs,${_dayClosingReport!.cashReconciliation.paidOuts}',
          );
          buffer.writeln(
            'Paid Ins,${_dayClosingReport!.cashReconciliation.paidIns}',
          );
          buffer.writeln('');
          buffer.writeln('Shift Summaries');
          buffer.writeln(
            'Employee,Shift Start,Shift End,Sales,Cash Handled,Duration',
          );
          for (final shift in _dayClosingReport!.shiftSummaries) {
            final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
            buffer.writeln(
              '${shift.employeeName},${shift.shiftStart.toIso8601String()},$endTime,${shift.salesDuringShift},${shift.cashHandled},${shift.shiftDuration.inHours}h ${shift.shiftDuration.inMinutes % 60}m',
            );
          }
        }
        break;
      // Add other report types as needed
      default:
        buffer.writeln('Report data not available for CSV export');
    }

    return buffer.toString();
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.salesSummary:
        return 'Sales Summary Report';
      case ReportType.productSales:
        return 'Product Sales Report';
      case ReportType.categorySales:
        return 'Category Sales Report';
      case ReportType.paymentMethod:
        return 'Payment Method Report';
      case ReportType.employeePerformance:
        return 'Employee Performance Report';
      case ReportType.inventory:
        return 'Inventory Report';
      case ReportType.shrinkage:
        return 'Shrinkage Report';
      case ReportType.laborCost:
        return 'Labor Cost Report';
      case ReportType.customerAnalysis:
        return 'Customer Analysis Report';
      case ReportType.basketAnalysis:
        return 'Basket Analysis Report';
      case ReportType.loyaltyProgram:
        return 'Loyalty Program Report';
      case ReportType.dayClosing:
        return 'Day Closing Report';
      case ReportType.profitLoss:
        return 'Profit & Loss Report';
      case ReportType.cashFlow:
        return 'Cash Flow Report';
      case ReportType.taxSummary:
        return 'Tax Summary Report';
      case ReportType.inventoryValuation:
        return 'Inventory Valuation Report';
      case ReportType.abcAnalysis:
        return 'ABC Analysis Report';
      case ReportType.demandForecasting:
        return 'Demand Forecasting Report';
      case ReportType.menuEngineering:
        return 'Menu Engineering Report';
      case ReportType.tablePerformance:
        return 'Table Performance Report';
      case ReportType.dailyStaffPerformance:
        return 'Daily Staff Performance Report';
    }
  }

  Widget _buildAdvancedReportContent() {
    switch (_selectedReportType) {
      case ReportType.salesSummary:
        return _buildSalesSummaryContent();
      case ReportType.productSales:
        return _buildProductSalesContent();
      case ReportType.categorySales:
        return _buildCategorySalesContent();
      case ReportType.paymentMethod:
        return _buildPaymentMethodContent();
      case ReportType.employeePerformance:
        return _buildEmployeePerformanceContent();
      case ReportType.inventory:
        return _buildInventoryContent();
      case ReportType.shrinkage:
        return _buildShrinkageContent();
      case ReportType.laborCost:
        return _buildLaborCostContent();
      case ReportType.customerAnalysis:
        return _buildCustomerContent();
      case ReportType.basketAnalysis:
        return _buildBasketAnalysisContent();
      case ReportType.loyaltyProgram:
        return _buildLoyaltyProgramContent();
      case ReportType.dayClosing:
        return _buildDayClosingContent();
      case ReportType.profitLoss:
        return ReportContentBuilders.buildProfitLossContent(_profitLossReport);
      case ReportType.cashFlow:
        return ReportContentBuilders.buildCashFlowContent(_cashFlowReport);
      case ReportType.taxSummary:
        return ReportContentBuilders.buildTaxSummaryContent(_taxSummaryReport);
      case ReportType.inventoryValuation:
        return ReportContentBuilders.buildInventoryValuationContent(
          _inventoryValuationReport,
        );
      case ReportType.abcAnalysis:
        return ReportContentBuilders.buildABCAnalysisContent(
          _abcAnalysisReport,
        );
      case ReportType.demandForecasting:
        return ReportContentBuilders.buildDemandForecastingContent(
          _demandForecastingReport,
        );
      case ReportType.menuEngineering:
        return ReportContentBuilders.buildMenuEngineeringContent(
          _menuEngineeringReport,
        );
      case ReportType.tablePerformance:
        return ReportContentBuilders.buildTablePerformanceContent(
          _tablePerformanceReport,
        );
      case ReportType.dailyStaffPerformance:
        return _buildDailyStaffPerformanceContent();
    }
  }

  Widget _buildSalesSummaryContent() {
    if (_salesSummaryReport == null)
      return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Gross Sales',
                value: FormattingService.currency(
                  _salesSummaryReport!.grossSales,
                ),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: 'Total Transactions',
                value: _salesSummaryReport!.totalTransactions.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Net Sales',
                value: FormattingService.currency(
                  _salesSummaryReport!.netSales,
                ),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: 'Avg Transaction',
                value: FormattingService.currency(
                  _salesSummaryReport!.averageTransactionValue,
                ),
                icon: Icons.analytics,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductSalesContent() {
    if (_productSalesReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._productSalesReport!.productSales
                .take(20)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(product.productName)),
                        Text('${product.unitsSold} sold'),
                        const SizedBox(width: 16),
                        Text(FormattingService.currency(product.totalRevenue)),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySalesContent() {
    if (_categorySalesReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._categorySalesReport!.categorySales.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.categoryName)),
                    Text('${entry.value.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(entry.value.revenue)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent() {
    if (_paymentMethodReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._paymentMethodReport!.paymentBreakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value.methodName)),
                    Text('${entry.value.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(entry.value.totalAmount)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceContent() {
    if (_employeePerformanceReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._employeePerformanceReport!.employeePerformance.map(
              (employee) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(employee.employeeName)),
                    Text('${employee.transactionCount} transactions'),
                    const SizedBox(width: 16),
                    Text(FormattingService.currency(employee.totalSales)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
