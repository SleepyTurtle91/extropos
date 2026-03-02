part of 'reports_screen.dart';

extension ReportsScreenContentPart2 on _ReportsScreenState {
  Widget _buildInventoryContent() {
    if (_inventoryReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._inventoryReport!.inventoryItems
                .take(50)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.itemName)),
                        Text('${item.currentStock} in stock'),
                        const SizedBox(width: 16),
                        Text(
                          item.stockStatus == 'low_stock'
                              ? 'LOW STOCK'
                              : item.stockStatus == 'out_of_stock'
                              ? 'OUT OF STOCK'
                              : 'OK',
                          style: TextStyle(
                            color:
                                item.stockStatus == 'low_stock' ||
                                    item.stockStatus == 'out_of_stock'
                                ? Colors.red
                                : Colors.green,
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
    );
  }

  Widget _buildShrinkageContent() {
    if (_shrinkageReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shrinkage Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Shrinkage: ${FormattingService.currency(_shrinkageReport!.totalShrinkageValue)}',
            ),
            Text(
              'Shrinkage Percentage: ${_shrinkageReport!.totalShrinkagePercentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborCostContent() {
    if (_laborCostReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Labor Cost Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Labor Cost: ${FormattingService.currency(_laborCostReport!.totalLaborCost)}',
            ),
            Text(
              'Labor Cost Percentage: ${_laborCostReport!.laborCostPercentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerContent() {
    if (_customerReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Active Customers: ${_customerReport!.totalActiveCustomers}',
            ),
            Text(
              'Average Customer Lifetime Value: ${FormattingService.currency(_customerReport!.averageCustomerLifetimeValue)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketAnalysisContent() {
    if (_basketAnalysisReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basket Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Frequently Bought Together Items: ${_basketAnalysisReport!.frequentlyBoughtTogether.length}',
            ),
            Text(
              'Recommended Product Bundles: ${_basketAnalysisReport!.recommendedBundles.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyProgramContent() {
    if (_loyaltyProgramReport == null)
      return const Center(child: Text('No data available'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loyalty Program',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Points Issued: ${_loyaltyProgramReport!.totalPointsIssued}',
            ),
            Text(
              'Total Points Redeemed: ${_loyaltyProgramReport!.totalPointsRedeemed}',
            ),
            Text('Active Members: ${_loyaltyProgramReport!.activeMembers}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDayClosingContent() {
    if (_dayClosingReport == null)
      return const Center(child: Text('No data available'));

    return Column(
      children: [
        // Business Session Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Session Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Total Sales',
                        value: FormattingService.currency(
                          _dayClosingReport!.totalSales,
                        ),
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Net Sales',
                        value: FormattingService.currency(
                          _dayClosingReport!.netSales,
                        ),
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
                      child: SummaryCard(
                        title: 'Cash Expected',
                        value: FormattingService.currency(
                          _dayClosingReport!.cashExpected,
                        ),
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Cash Variance',
                        value: FormattingService.currency(
                          _dayClosingReport!.cashVariance,
                        ),
                        icon: _dayClosingReport!.cashVariance >= 0
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _dayClosingReport!.cashVariance >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cash Reconciliation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash Reconciliation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReconciliationRow(
                  'Opening Float',
                  _dayClosingReport!.cashReconciliation.openingFloat,
                ),
                _buildReconciliationRow(
                  'Cash Sales',
                  _dayClosingReport!.cashReconciliation.cashSales,
                ),
                _buildReconciliationRow(
                  'Cash Refunds',
                  -_dayClosingReport!.cashReconciliation.cashRefunds,
                ),
                _buildReconciliationRow(
                  'Paid Outs',
                  -_dayClosingReport!.cashReconciliation.paidOuts,
                ),
                _buildReconciliationRow(
                  'Paid Ins',
                  _dayClosingReport!.cashReconciliation.paidIns,
                ),
                const Divider(),
                _buildReconciliationRow(
                  'Expected Cash',
                  _dayClosingReport!.cashReconciliation.expectedCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Actual Cash',
                  _dayClosingReport!.cashReconciliation.actualCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Variance',
                  _dayClosingReport!.cashReconciliation.variance,
                  isTotal: true,
                  isVariance: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shift Summaries
        if (_dayClosingReport!.shiftSummaries.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shift Summaries',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._dayClosingReport!.shiftSummaries.map(
                    (shift) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(shift.employeeName)),
                          Expanded(
                            child: Text(_formatDuration(shift.shiftDuration)),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(
                                shift.salesDuringShift,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(shift.cashHandled),
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

  Widget _buildDailyStaffPerformanceContent() {
    return DailyStaffPerformanceContentScreen(
      reportData: _dailyStaffPerformanceReport ?? {},
    );
  }

}
