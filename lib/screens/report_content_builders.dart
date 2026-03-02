import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/screens/_report_demand_content.dart';
import 'package:extropos/screens/_report_inventory_content.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:flutter/material.dart';

/// Additional report content builders for the reports screen
/// These are separated from the main reports_screen.dart to improve maintainability
/// This main file handles financial reports (P&L, CashFlow, Tax).
/// Inventory and ABC analysis reports are in _report_inventory_content.dart
/// Demand, menu engineering, and table performance reports are in _report_demand_content.dart

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

  /// ========== Inventory and ABC Analysis Reports ==========
  /// Delegated to _ReportInventoryContent for code organization
  static Widget buildInventoryValuationContent(
    InventoryValuationReport? report,
  ) =>
      ReportInventoryContent.buildInventoryValuationContent(report);

  static Widget buildABCAnalysisContent(ABCAnalysisReport? report) =>
      ReportInventoryContent.buildABCAnalysisContent(report);

  /// ========== Demand Forecasting, Menu Engineering, and Table Performance ==========
  /// Delegated to _ReportDemandContent for code organization
  static Widget buildDemandForecastingContent(DemandForecastingReport? report) =>
      ReportDemandContent.buildDemandForecastingContent(report);

  static Widget buildMenuEngineeringContent(MenuEngineeringReport? report) =>
      ReportDemandContent.buildMenuEngineeringContent(report);

  static Widget buildTablePerformanceContent(TablePerformanceReport? report) =>
      ReportDemandContent.buildTablePerformanceContent(report);
}
