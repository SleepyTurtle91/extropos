// Part of advanced_reports_screen.dart
// Auto-extracted Medium widgets (50-100L)

part of 'advanced_reports_screen.dart';

extension AdvancedReportsMediumWidgets on _AdvancedReportsScreenState {
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

        pw.Text(
          'Business Session Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Total Sales: ${FormattingService.currency(report.totalSales)}'),
        pw.Text('Net Sales: ${FormattingService.currency(report.netSales)}'),
        pw.Text(
          'Cash Expected: ${FormattingService.currency(report.cashExpected)}',
        ),
        pw.Text('Cash Actual: ${FormattingService.currency(report.cashActual)}'),
        pw.Text(
          'Cash Variance: ${FormattingService.currency(report.cashVariance)}',
        ),
        pw.SizedBox(height: 20),

        pw.Text(
          'Cash Reconciliation',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Opening Float: ${FormattingService.currency(report.cashReconciliation.openingFloat)}',
        ),
        pw.Text(
          'Cash Sales: ${FormattingService.currency(report.cashReconciliation.cashSales)}',
        ),
        pw.Text(
          'Cash Refunds: ${FormattingService.currency(report.cashReconciliation.cashRefunds)}',
        ),
        pw.Text(
          'Paid Outs: ${FormattingService.currency(report.cashReconciliation.paidOuts)}',
        ),
        pw.Text(
          'Paid Ins: ${FormattingService.currency(report.cashReconciliation.paidIns)}',
        ),
        pw.Text(
          'Expected Cash: ${FormattingService.currency(report.cashReconciliation.expectedCash)}',
        ),
        pw.Text(
          'Actual Cash: ${FormattingService.currency(report.cashReconciliation.actualCash)}',
        ),
        pw.Text(
          'Variance: ${FormattingService.currency(report.cashReconciliation.variance)}',
        ),
        pw.SizedBox(height: 20),

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

  Widget _buildReportContent() {
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
        return AdvancedReportsMediumWidgetsPart2(
          this,
        )._buildEmployeePerformanceContent();
      case ReportType.inventory:
        return AdvancedReportsMediumWidgetsPart2(this)._buildInventoryContent();
      case ReportType.shrinkage:
        return AdvancedReportsMediumWidgetsPart2(this)._buildShrinkageContent();
      case ReportType.laborCost:
        return AdvancedReportsMediumWidgetsPart2(this)._buildLaborCostContent();
      case ReportType.customerAnalysis:
        return AdvancedReportsMediumWidgetsPart3(
          this,
        )._buildCustomerAnalysisContent();
      case ReportType.basketAnalysis:
        return AdvancedReportsMediumWidgetsPart3(
          this,
        )._buildBasketAnalysisContent();
      case ReportType.loyaltyProgram:
        return AdvancedReportsMediumWidgetsPart3(
          this,
        )._buildLoyaltyProgramContent();
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
        return ReportContentBuilders.buildABCAnalysisContent(_abcAnalysisReport);
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
    if (_salesSummaryReport == null) return const SizedBox.shrink();

    final report = _salesSummaryReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Gross Sales',
              'RM${report.grossSales.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Net Sales',
              'RM${report.netSales.toStringAsFixed(2)}',
              Icons.trending_up,
            ),
            _buildMetricCard(
              'Total Transactions',
              report.totalTransactions.toString(),
              Icons.receipt,
            ),
            _buildMetricCard(
              'Avg Transaction',
              'RM${report.averageTransactionValue.toStringAsFixed(2)}',
              Icons.analytics,
            ),
            _buildMetricCard(
              'Tax Collected',
              'RM${report.taxCollected.toStringAsFixed(2)}',
              Icons.account_balance,
            ),
            _buildMetricCard(
              'Total Discounts',
              'RM${report.totalDiscounts.toStringAsFixed(2)}',
              Icons.discount,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Sales by Hour',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(24, (hour) {
                return BarChartGroupData(
                  x: hour,
                  barRods: [
                    BarChartRodData(
                      toY: report.hourlySales[hour.toString()] ?? 0,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}:00'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSalesContent() {
    if (_productSalesReport == null) return const SizedBox.shrink();

    final report = _productSalesReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Products',
              report.productSales
                  .where(_matchesProductFilter)
                  .length
                  .toString(),
              Icons.inventory,
            ),
            _buildMetricCard(
              'Total Units Sold',
              report.productSales
                  .where(_matchesProductFilter)
                  .fold<int>(0, (sum, p) => sum + p.unitsSold)
                  .toString(),
              Icons.shopping_cart,
            ),
            _buildMetricCard(
              'Total Revenue',
              'RM${report.productSales.where(_matchesProductFilter).fold<double>(0, (sum, p) => sum + p.totalRevenue).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Top Selling Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.productSales
                  .where((product) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok =
                          product.productName.toLowerCase().contains(
                            f.searchText!.toLowerCase(),
                          ) ||
                          product.category.toLowerCase().contains(
                            f.searchText!.toLowerCase(),
                          );
                    }
                    if (f.minAmount != null) {
                      ok = ok && product.totalRevenue >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && product.totalRevenue <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .take(10)
                  .map((product) {
                    return ListTile(
                      title: Text(product.productName),
                      subtitle: Text(
                        '${product.category} � ${product.unitsSold} units',
                      ),
                      trailing: Text(
                        'RM${product.totalRevenue.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySalesContent() {
    if (_categorySalesReport == null) return const SizedBox.shrink();

    final report = _categorySalesReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Categories',
              report.categorySales.entries
                  .where(_matchesCategoryFilter)
                  .length
                  .toString(),
              Icons.category,
            ),
            _buildMetricCard(
              'Top Category',
              (report.categorySales.entries.where(_matchesCategoryFilter).isEmpty
                  ? report.topPerformingCategory
                  : report.categorySales.entries
                        .where(_matchesCategoryFilter)
                        .reduce(
                          (a, b) => a.value.revenue > b.value.revenue ? a : b,
                        )
                        .key),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Category Performance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.categorySales.entries
                  .where((entry) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = entry.key.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && entry.value.revenue >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && entry.value.revenue <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((entry) {
                    final data = entry.value;
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${data.transactionCount} transactions'),
                      trailing: Text('RM${data.revenue.toStringAsFixed(2)}'),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
