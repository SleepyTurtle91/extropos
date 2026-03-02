import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:flutter/material.dart';

/// Inventory and ABC analysis report content builders
class ReportInventoryContent {
  static Widget buildInventoryValuationContent(
    InventoryValuationReport? report,
  ) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportContentHelpers.buildSummaryCard(
                title: 'Total Value',
                value: FormattingService.currency(report.totalInventoryValue),
                icon: Icons.inventory,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportContentHelpers.buildSummaryCard(
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
              child: _ReportContentHelpers.buildSummaryCard(
                title: 'Cost Value',
                value: FormattingService.currency(report.totalCostValue),
                icon: Icons.attach_money,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportContentHelpers.buildSummaryCard(
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
              child: _ReportContentHelpers.buildSummaryCard(
                title: 'A Category',
                value: FormattingService.currency(report.aCategoryRevenue),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportContentHelpers.buildSummaryCard(
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
              child: _ReportContentHelpers.buildSummaryCard(
                title: 'C Category',
                value: FormattingService.currency(report.cCategoryRevenue),
                icon: Icons.trending_down,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportContentHelpers.buildSummaryCard(
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
}

/// Helper class for shared report content building utilities
class _ReportContentHelpers {
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
}
