// Part of advanced_reports_screen.dart

part of 'advanced_reports_screen.dart';

extension AdvancedReportsPdfPart1 on _AdvancedReportsScreenState {
  pw.Widget _buildSalesSummaryPDF() {
    if (_salesSummaryReport == null) return pw.Text('No data available');

    final report = _salesSummaryReport!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Gross Sales', 'RM${report.grossSales.toStringAsFixed(2)}'],
            ['Net Sales', 'RM${report.netSales.toStringAsFixed(2)}'],
            ['Total Transactions', report.totalTransactions.toString()],
            [
              'Average Transaction',
              'RM${report.averageTransactionValue.toStringAsFixed(2)}',
            ],
            ['Tax Collected', 'RM${report.taxCollected.toStringAsFixed(2)}'],
            [
              'Total Discounts',
              'RM${report.totalDiscounts.toStringAsFixed(2)}',
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildProductSalesPDF() {
    if (_productSalesReport == null) return pw.Text('No data available');

    final report = _productSalesReport!;
    final filteredProducts = report.productSales
        .where((p) => _matchesProductFilter(p))
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Products: ${filteredProducts.length}'),
        pw.Text(
          'Total Units Sold: ${filteredProducts.fold<int>(0, (s, p) => s + p.unitsSold)}',
        ),
        pw.Text(
          'Total Revenue: RM${filteredProducts.fold<double>(0, (s, p) => s + p.totalRevenue).toStringAsFixed(2)}',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Top Products',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
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
    final filteredEntries = report.categorySales.entries
        .where(_matchesCategoryFilter)
        .toList();
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
          headers: [
            'Method',
            'Amount',
            'Transactions',
            'Average',
            'Percentage',
          ],
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
    final filteredEmployees = report.employeePerformance
        .where(_matchesEmployeeFilter)
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Performance',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: [
            'Employee',
            'Sales',
            'Transactions',
            'Avg Transaction',
            'Discounts',
          ],
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
        pw.Text(
          'Total Value: RM${report.totalInventoryValue.toStringAsFixed(2)}',
        ),
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
        pw.Text(
          'Total Shrinkage Value: RM${report.totalShrinkageValue.toStringAsFixed(2)}',
        ),
        pw.Text(
          'Shrinkage Percentage: ${report.totalShrinkagePercentage.toStringAsFixed(1)}%',
        ),
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
        pw.Text(
          'Total Labor Cost: RM${report.totalLaborCost.toStringAsFixed(2)}',
        ),
        pw.Text(
          'Labor Cost Percentage: ${report.laborCostPercentage.toStringAsFixed(1)}%',
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Cost by Department',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Department', 'Labor Cost'],
          data: report.laborCostByDepartment.entries
              .map(
                (entry) => [entry.key, 'RM${entry.value.toStringAsFixed(2)}'],
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAnalysisPDF() {
    if (_customerReport == null) return pw.Text('No data available');

    final report = _customerReport!;
    final filteredCustomers = report.topCustomers
        .where(_matchesCustomerFilter)
        .toList();
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
        pw.Text(
          'Top Customers',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
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
        pw.Text(
          'Product Affinities: ${report.productAffinityScores.length} scores calculated',
        ),
        pw.Text(
          'Recommended Bundles: ${report.recommendedBundles.length} suggestions',
        ),
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
        pw.Text(
          'Points Issued: ${report.totalPointsIssued.toStringAsFixed(0)}',
        ),
        pw.Text(
          'Points Redeemed: ${report.totalPointsRedeemed.toStringAsFixed(0)}',
        ),
        pw.Text(
          'Redemption Rate: ${report.redemptionRate.toStringAsFixed(1)}%',
        ),
        pw.Text(
          'Revenue from Loyalty Members: RM${report.revenueFromLoyaltyMembers.toStringAsFixed(2)}',
        ),
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
        pw.Text(
          'Total Revenue: ${FormattingService.currency(_profitLossReport!.totalRevenue)}',
        ),
        pw.Text(
          'Cost of Goods Sold: ${FormattingService.currency(_profitLossReport!.costOfGoodsSold)}',
        ),
        pw.Text(
          'Gross Profit: ${FormattingService.currency(_profitLossReport!.grossProfit)}',
        ),
        pw.Text(
          'Operating Expenses: ${FormattingService.currency(_profitLossReport!.operatingExpenses)}',
        ),
        pw.Text(
          'Net Profit: ${FormattingService.currency(_profitLossReport!.netProfit)}',
        ),
        pw.Text(
          'Profit Margin: ${_profitLossReport!.profitMargin.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

}
