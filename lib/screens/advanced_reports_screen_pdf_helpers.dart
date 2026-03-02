// Part of advanced_reports_screen.dart
// PDF helper methods extracted from main file

part of 'advanced_reports_screen.dart';

extension AdvancedReportsPDF on _AdvancedReportsScreenState {
  pw.Widget _buildSalesSummaryPDF() {
    if (_salesSummaryReport == null) return pw.Text('No data available');

    final report = _salesSummaryReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Key Metrics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Gross Sales', 'RM${report.grossSales.toStringAsFixed(2)}'],
            ['Net Sales', 'RM${report.netSales.toStringAsFixed(2)}'],
            ['Total Transactions', report.totalTransactions.toString()],
            ['Average Transaction', 'RM${report.averageTransactionValue.toStringAsFixed(2)}'],
            ['Tax Collected', 'RM${report.taxCollected.toStringAsFixed(2)}'],
            ['Total Discounts', 'RM${report.totalDiscounts.toStringAsFixed(2)}'],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildProductSalesPDF() {
    if (_productSalesReport == null) return pw.Text('No data available');

    final report = _productSalesReport!;
    final filteredProducts = report.productSales.where((p) => _matchesProductFilter(p)).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Total Products: ${filteredProducts.length}'),
        pw.Text('Total Units Sold: ${filteredProducts.fold<int>(0, (s, p) => s + p.unitsSold)}'),
        pw.Text(
          'Total Revenue: RM${filteredProducts.fold<double>(0, (s, p) => s + p.totalRevenue).toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text('Top Products', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Product', 'Category', 'Units Sold', 'Revenue'],
          data: filteredProducts
              .take(20)
              .map(
                (product) => [
                  product.productName,
                  product.category,
                  product.unitsSold.toString(),
                  'RM${product.totalRevenue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildCategorySalesPDF() {
    if (_categorySalesReport == null) return pw.Text('No data available');

    final report = _categorySalesReport!;
    final filteredEntries = report.categorySales.entries.where(_matchesCategoryFilter).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Performance',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Category', 'Revenue', 'Transactions', 'Avg Transaction'],
          data: filteredEntries
              .map(
                (entry) => [
                  entry.key,
                  'RM${entry.value.revenue.toStringAsFixed(2)}',
                  entry.value.transactionCount.toString(),
                  'RM${entry.value.averageTransactionValue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentMethodPDF() {
    if (_paymentMethodReport == null) return pw.Text('No data available');

    final report = _paymentMethodReport!;
    final filteredPaymentEntries = report.paymentBreakdown.entries
        .where(_matchesPaymentMethodFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Method Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Processed: RM${filteredPaymentEntries.fold<double>(0.0, (s, e) => s + e.value.totalAmount).toStringAsFixed(2)}',
        ),
        pw.Text('Most Used: ${report.mostUsedMethod}'),
        pw.Text('Highest Revenue: ${report.highestRevenueMethod}'),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Method', 'Amount', 'Transactions', 'Average', 'Percentage'],
          data: filteredPaymentEntries
              .map(
                (entry) => [
                  entry.key,
                  'RM${entry.value.totalAmount.toStringAsFixed(2)}',
                  entry.value.transactionCount.toString(),
                  'RM${entry.value.averageTransaction.toStringAsFixed(2)}',
                  '${entry.value.percentageOfTotal.toStringAsFixed(1)}%',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildEmployeePerformancePDF() {
    if (_employeePerformanceReport == null) return pw.Text('No data available');

    final report = _employeePerformanceReport!;
    final filteredEmployees = report.employeePerformance.where(_matchesEmployeeFilter).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Performance',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Employee', 'Sales', 'Transactions', 'Avg Transaction', 'Discounts'],
          data: filteredEmployees
              .map(
                (employee) => [
                  employee.employeeName,
                  'RM${employee.totalSales.toStringAsFixed(2)}',
                  employee.transactionCount.toString(),
                  'RM${employee.averageTransactionValue.toStringAsFixed(2)}',
                  'RM${employee.totalDiscountsGiven.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryPDF() {
    if (_inventoryReport == null) return pw.Text('No data available');

    final report = _inventoryReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Overview',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Items: ${report.inventoryItems.length}'),
        pw.Text('Low Stock Items: ${report.lowStockItems.length}'),
        pw.Text('Out of Stock: ${report.outOfStockItems.length}'),
        pw.Text('Total Value: RM${report.totalInventoryValue.toStringAsFixed(2)}'),
        pw.SizedBox(height: 20),
        pw.Text(
          'Inventory Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Stock', 'Reorder Point', 'Status'],
          data: report.inventoryItems
              .take(30)
              .map(
                (item) => [
                  item.itemName,
                  item.currentStock.toString(),
                  item.reorderPoint.toString(),
                  item.stockStatus,
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildShrinkagePDF() {
    if (_shrinkageReport == null) return pw.Text('No data available');

    final report = _shrinkageReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Shrinkage Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Shrinkage Items: ${report.shrinkageItems.length}'),
        pw.Text('Total Shrinkage Value: RM${report.totalShrinkageValue.toStringAsFixed(2)}'),
        pw.Text('Shrinkage Percentage: ${report.totalShrinkagePercentage.toStringAsFixed(1)}%'),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Variance', 'Value', 'Reason', 'Last Count'],
          data: report.shrinkageItems
              .take(20)
              .map(
                (item) => [
                  item.itemName,
                  item.variance.toString(),
                  'RM${item.varianceValue.toStringAsFixed(2)}',
                  item.reason,
                  item.lastCountDate.toString().substring(0, 10),
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildLaborCostPDF() {
    if (_laborCostReport == null) return pw.Text('No data available');

    final report = _laborCostReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Labor Cost Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Labor Cost: RM${report.totalLaborCost.toStringAsFixed(2)}'),
        pw.Text('Labor Cost Percentage: ${report.laborCostPercentage.toStringAsFixed(1)}%'),
        pw.SizedBox(height: 20),
        pw.Text(
          'Cost by Department',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Department', 'Labor Cost'],
          data: report.laborCostByDepartment.entries
              .map((entry) => [entry.key, 'RM${entry.value.toStringAsFixed(2)}'])
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAnalysisPDF() {
    if (_customerReport == null) return pw.Text('No data available');

    final report = _customerReport!;
    final filteredCustomers = report.topCustomers.where(_matchesCustomerFilter).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Customer Analysis',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Customers: ${report.totalActiveCustomers}'),
        pw.Text(
          'Average Lifetime Value: RM${report.averageCustomerLifetimeValue.toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text('Top Customers', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Customer', 'Total Spent', 'Visits', 'Avg Order'],
          data: filteredCustomers
              .take(15)
              .map(
                (customer) => [
                  customer.customerName,
                  'RM${customer.totalSpent.toStringAsFixed(2)}',
                  customer.visitCount.toString(),
                  'RM${customer.averageOrderValue.toStringAsFixed(2)}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildBasketAnalysisPDF() {
    if (_basketAnalysisReport == null) return pw.Text('No data available');

    final report = _basketAnalysisReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Basket Analysis Insights',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Frequently Bought Together: ${report.frequentlyBoughtTogether.length} combinations',
        ),
        pw.Text('Product Affinities: ${report.productAffinityScores.length} scores calculated'),
        pw.Text('Recommended Bundles: ${report.recommendedBundles.length} suggestions'),
      ],
    );
  }

  pw.Widget _buildLoyaltyProgramPDF() {
    if (_loyaltyProgramReport == null) return pw.Text('No data available');

    final report = _loyaltyProgramReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Loyalty Program Analytics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Members: ${report.totalMembers}'),
        pw.Text('Active Members: ${report.activeMembers}'),
        pw.Text('Points Issued: ${report.totalPointsIssued.toStringAsFixed(0)}'),
        pw.Text('Points Redeemed: ${report.totalPointsRedeemed.toStringAsFixed(0)}'),
        pw.Text('Redemption Rate: ${report.redemptionRate.toStringAsFixed(1)}%'),
        pw.Text(
          'Revenue from Loyalty Members: RM${report.revenueFromLoyaltyMembers.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  pw.Widget _buildDayClosingPDF() {
    if (_dayClosingReport == null) return pw.Text('No data available');

    final report = _dayClosingReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Day Closing Report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        // Business Session Summary
        pw.Text(
          'Business Session Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Sales: ${FormattingService.currency(report.totalSales)}'),
        pw.Text('Net Sales: ${FormattingService.currency(report.netSales)}'),
        pw.Text('Cash Expected: ${FormattingService.currency(report.cashExpected)}'),
        pw.Text('Cash Actual: ${FormattingService.currency(report.cashActual)}'),
        pw.Text('Cash Variance: ${FormattingService.currency(report.cashVariance)}'),
        pw.SizedBox(height: 20),

        // Cash Reconciliation
        pw.Text(
          'Cash Reconciliation',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Opening Float: ${FormattingService.currency(report.cashReconciliation.openingFloat)}',
        ),
        pw.Text('Cash Sales: ${FormattingService.currency(report.cashReconciliation.cashSales)}'),
        pw.Text(
          'Cash Refunds: ${FormattingService.currency(report.cashReconciliation.cashRefunds)}',
        ),
        pw.Text('Paid Outs: ${FormattingService.currency(report.cashReconciliation.paidOuts)}'),
        pw.Text('Paid Ins: ${FormattingService.currency(report.cashReconciliation.paidIns)}'),
        pw.Text(
          'Expected Cash: ${FormattingService.currency(report.cashReconciliation.expectedCash)}',
        ),
        pw.Text('Actual Cash: ${FormattingService.currency(report.cashReconciliation.actualCash)}'),
        pw.Text('Variance: ${FormattingService.currency(report.cashReconciliation.variance)}'),
        pw.SizedBox(height: 20),

        // Shift Summaries
        if (report.shiftSummaries.isNotEmpty) ...[
          pw.Text(
            'Shift Summaries',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...report.shiftSummaries.map((shift) {
            final endTime = shift.shiftEnd?.toIso8601String() ?? 'Active';
            return pw.Text(
              '${shift.employeeName}: ${shift.shiftStart.toIso8601String()} - $endTime, Sales: ${FormattingService.currency(shift.salesDuringShift)}, Cash: ${FormattingService.currency(shift.cashHandled)}, Duration: ${_formatDuration(shift.shiftDuration)}',
            );
          }),
        ],
      ],
    );
  }

  pw.Widget _buildProfitLossPDF() {
    if (_profitLossReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Profit & Loss Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Revenue: ${FormattingService.currency(_profitLossReport!.totalRevenue)}'),
        pw.Text(
          'Cost of Goods Sold: ${FormattingService.currency(_profitLossReport!.costOfGoodsSold)}',
        ),
        pw.Text('Gross Profit: ${FormattingService.currency(_profitLossReport!.grossProfit)}'),
        pw.Text(
          'Operating Expenses: ${FormattingService.currency(_profitLossReport!.operatingExpenses)}',
        ),
        pw.Text('Net Profit: ${FormattingService.currency(_profitLossReport!.netProfit)}'),
        pw.Text('Profit Margin: ${_profitLossReport!.profitMargin.toStringAsFixed(1)}%'),
      ],
    );
  }

  pw.Widget _buildCashFlowPDF() {
    if (_cashFlowReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cash Flow Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Opening Cash: ${FormattingService.currency(_cashFlowReport!.openingCash)}'),
        pw.Text('Closing Cash: ${FormattingService.currency(_cashFlowReport!.closingCash)}'),
        pw.Text('Net Cash Flow: ${FormattingService.currency(_cashFlowReport!.netCashFlow)}'),
      ],
    );
  }

  pw.Widget _buildTaxSummaryPDF() {
    if (_taxSummaryReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tax Summary Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Tax Collected: ${FormattingService.currency(_taxSummaryReport!.totalTaxCollected)}',
        ),
        pw.Text('Tax Liability: ${FormattingService.currency(_taxSummaryReport!.taxLiability)}'),
        ..._taxSummaryReport!.taxBreakdown.entries.map(
          (entry) => pw.Text('${entry.key} Tax Rate: ${FormattingService.currency(entry.value)}'),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryValuationPDF() {
    if (_inventoryValuationReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Valuation Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total Value: ${FormattingService.currency(_inventoryValuationReport!.totalInventoryValue)}',
        ),
        pw.Text(
          'Turnover Ratio: ${_inventoryValuationReport!.inventoryTurnoverRatio.toStringAsFixed(2)}',
        ),
        ..._inventoryValuationReport!.valuationItems
            .take(10)
            .map(
              (item) =>
                  pw.Text('${item.itemName}: ${FormattingService.currency(item.totalRetailValue)}'),
            ),
      ],
    );
  }

  pw.Widget _buildABCAnalysisPDF() {
    if (_abcAnalysisReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ABC Analysis Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'A Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.aCategoryRevenue)}',
        ),
        pw.Text(
          'B Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.bCategoryRevenue)}',
        ),
        pw.Text(
          'C Category Revenue: ${FormattingService.currency(_abcAnalysisReport!.cCategoryRevenue)}',
        ),
        ..._abcAnalysisReport!.abcItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.percentageOfTotal.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildDemandForecastingPDF() {
    if (_demandForecastingReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Demand Forecasting Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Forecasting Method: ${_demandForecastingReport!.forecastingMethod}'),
        pw.Text(
          'Forecast Accuracy: ${(_demandForecastingReport!.forecastAccuracy * 100).toStringAsFixed(1)}%',
        ),
        ..._demandForecastingReport!.forecastItems
            .take(5)
            .map(
              (item) => pw.Text(
                '${item.itemName}: Historical ${item.historicalSales.last.toStringAsFixed(0)}, Forecast ${item.forecastedSales.last.toStringAsFixed(0)}',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildMenuEngineeringPDF() {
    if (_menuEngineeringReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Menu Engineering Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Stars: ${_menuEngineeringReport!.starsCount}'),
        pw.Text('Plowhorses: ${_menuEngineeringReport!.plowhorsesCount}'),
        pw.Text('Puzzles: ${_menuEngineeringReport!.puzzlesCount}'),
        pw.Text('Dogs: ${_menuEngineeringReport!.dogsCount}'),
        ..._menuEngineeringReport!.menuItems
            .take(10)
            .map(
              (item) => pw.Text(
                '${item.itemName} (${item.category}): ${item.popularity.toStringAsFixed(1)}% / ${item.profitability.toStringAsFixed(1)}%',
              ),
            ),
      ],
    );
  }

  pw.Widget _buildTablePerformancePDF() {
    if (_tablePerformanceReport == null) return pw.Text('No data available');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Table Performance Report',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Tables: ${_tablePerformanceReport!.totalTables}'),
        pw.Text('Occupied Tables: ${_tablePerformanceReport!.occupiedTables}'),
        pw.Text(
          'Average Turnover: ${_tablePerformanceReport!.averageTableTurnover.toStringAsFixed(1)}',
        ),
        pw.Text(
          'Average Revenue/Table: ${FormattingService.currency(_tablePerformanceReport!.averageRevenuePerTable)}',
        ),
        ..._tablePerformanceReport!.tableData
            .take(10)
            .map(
              (table) => pw.Text(
                '${table.tableName}: ${FormattingService.currency(table.totalRevenue)}, ${table.totalOrders} orders',
              ),
            ),
      ],
    );
  }
}
