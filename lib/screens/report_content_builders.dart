import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:flutter/material.dart';

/// Additional report content builders for the reports screen
/// These are separated from the main reports_screen.dart to improve maintainability

class ReportContentBuilders {
  // Summary card widget
  static Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // P&L row builder
  static Widget buildPLRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            FormattingService.currency(amount.abs()),
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProfitLossContent(ProfitLossReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Total Revenue',
                value: FormattingService.currency(report.totalRevenue),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Net Profit',
                value: FormattingService.currency(report.netProfit),
                icon: Icons.account_balance_wallet,
                color: report.netProfit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Gross Profit',
                value: FormattingService.currency(report.grossProfit),
                icon: Icons.business,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Profit Margin',
                value: '${report.profitMargin.toStringAsFixed(1)}%',
                icon: Icons.percent,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profit & Loss Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                buildPLRow('Revenue', report.totalRevenue, Colors.green),
                buildPLRow(
                  'Cost of Goods Sold',
                  -report.costOfGoodsSold,
                  Colors.red,
                ),
                const Divider(),
                buildPLRow('Gross Profit', report.grossProfit, Colors.blue),
                buildPLRow(
                  'Operating Expenses',
                  -report.operatingExpenses,
                  Colors.red,
                ),
                const Divider(),
                buildPLRow(
                  'Net Profit',
                  report.netProfit,
                  report.netProfit >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildCashFlowContent(CashFlowReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Opening Cash',
                value: FormattingService.currency(report.openingCash),
                icon: Icons.account_balance,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Closing Cash',
                value: FormattingService.currency(report.closingCash),
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Cash Inflows',
                value: FormattingService.currency(report.cashInflows),
                icon: Icons.arrow_upward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Net Cash Flow',
                value: FormattingService.currency(report.netCashFlow),
                icon: Icons.swap_horiz,
                color: report.netCashFlow >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash Flow Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...report.inflowBreakdown.entries.map(
                  (entry) => buildPLRow(
                    'Inflow: ${entry.key}',
                    entry.value,
                    Colors.green,
                  ),
                ),
                ...report.outflowBreakdown.entries.map(
                  (entry) => buildPLRow(
                    'Outflow: ${entry.key}',
                    -entry.value,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildTaxSummaryContent(TaxSummaryReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Tax Collected',
                value: FormattingService.currency(report.totalTaxCollected),
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Tax Liability',
                value: FormattingService.currency(report.taxLiability),
                icon: Icons.account_balance,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tax Breakdown by Rate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...report.taxBreakdown.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('${entry.key} Tax Rate')),
                        Text(
                          FormattingService.currency(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildInventoryValuationContent(
    InventoryValuationReport? report,
  ) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Total Value',
                value: FormattingService.currency(report.totalInventoryValue),
                icon: Icons.inventory,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Turnover Ratio',
                value: report.inventoryTurnoverRatio.toStringAsFixed(2),
                icon: Icons.refresh,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Cost Value',
                value: FormattingService.currency(report.totalCostValue),
                icon: Icons.attach_money,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Retail Value',
                value: FormattingService.currency(report.totalRetailValue),
                icon: Icons.store,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Inventory Items by Value',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...report.valuationItems
                    .take(10)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.itemName)),
                            Text(
                              FormattingService.currency(item.totalRetailValue),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildABCAnalysisContent(ABCAnalysisReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'A Category',
                value: FormattingService.currency(report.aCategoryRevenue),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'B Category',
                value: FormattingService.currency(report.bCategoryRevenue),
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'C Category',
                value: FormattingService.currency(report.cCategoryRevenue),
                icon: Icons.trending_down,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Total Revenue',
                value: FormattingService.currency(report.totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABC Analysis (Pareto Principle)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A items (80% of revenue): High priority\nB items (15% of revenue): Medium priority\nC items (5% of revenue): Low priority',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...report.abcItems
                    .take(10)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.category == 'A'
                                    ? Colors.amber
                                    : item.category == 'B'
                                    ? Colors.blue
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.itemName)),
                            Text(
                              '${item.percentageOfTotal.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildDemandForecastingContent(DemandForecastingReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Demand Forecasting - ${report.forecastingMethod}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Forecast Accuracy: ${(report.forecastAccuracy * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...report.forecastItems
                    .take(5)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Historical: ${item.historicalSales.last.toStringAsFixed(0)} units',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Forecast: ${item.forecastedSales.last.toStringAsFixed(0)} units',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            LinearProgressIndicator(
                              value: item.confidenceLevel,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.confidenceLevel > 0.8
                                    ? Colors.green
                                    : item.confidenceLevel > 0.6
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              'Confidence: ${(item.confidenceLevel * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMenuEngineeringContent(MenuEngineeringReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Stars',
                value: report.starsCount.toString(),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Plowhorses',
                value: report.plowhorsesCount.toString(),
                icon: Icons.work,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Puzzles',
                value: report.puzzlesCount.toString(),
                icon: Icons.help,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Dogs',
                value: report.dogsCount.toString(),
                icon: Icons.pets,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Engineering Matrix',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stars: High popularity, high profit - Focus on promotion\nPlowhorses: High popularity, low profit - Review pricing/costs\nPuzzles: Low popularity, high profit - Improve marketing\nDogs: Low popularity, low profit - Consider removal',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...report.menuItems
                    .take(10)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.category == 'star'
                                    ? Colors.amber
                                    : item.category == 'plowhorse'
                                    ? Colors.blue
                                    : item.category == 'puzzle'
                                    ? Colors.orange
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  item.category[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.itemName)),
                            Text(
                              '${item.popularity.toStringAsFixed(1)}% / ${item.profitability.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildTablePerformanceContent(TablePerformanceReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Total Tables',
                value: report.totalTables.toString(),
                icon: Icons.table_restaurant,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Occupied Tables',
                value: report.occupiedTables.toString(),
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                title: 'Avg Turnover',
                value: report.averageTableTurnover.toStringAsFixed(1),
                icon: Icons.refresh,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSummaryCard(
                title: 'Avg Revenue/Table',
                value: FormattingService.currency(
                  report.averageRevenuePerTable,
                ),
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Table Performance Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...report.tableData
                    .take(10)
                    .map(
                      (table) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${table.tableName} (Capacity: ${table.capacity})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Revenue: ${FormattingService.currency(table.totalRevenue)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Orders: ${table.totalOrders}',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Avg Occupancy: ${table.averageOccupancyTime.inHours}h ${table.averageOccupancyTime.inMinutes % 60}m',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Revenue/Hour: ${FormattingService.currency(table.revenuePerHour)}',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
