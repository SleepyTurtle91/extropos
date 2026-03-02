// Part of advanced_reports_screen.dart
// Auto-extracted Large widgets (>100L)

part of 'advanced_reports_screen.dart';

extension AdvancedReportsLargeWidgets on _AdvancedReportsScreenState {
  Widget _buildPaymentMethodContent() {
    if (_paymentMethodReport == null) {
      return const Center(child: Text('No data available'));
    }

    final report = _paymentMethodReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Processed',
              'RM${report.paymentBreakdown.entries.where(_matchesPaymentMethodFilter).fold<double>(0.0, (sum, e) => sum + e.value.totalAmount).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Most Used',
              (report.paymentBreakdown.entries
                      .where(_matchesPaymentMethodFilter)
                      .isEmpty
                  ? report.mostUsedMethod
                  : report.paymentBreakdown.entries
                        .where(_matchesPaymentMethodFilter)
                        .reduce(
                          (a, b) =>
                              a.value.transactionCount >
                                  b.value.transactionCount
                              ? a
                              : b,
                        )
                        .key),
              Icons.payment,
            ),
            _buildMetricCard(
              'Highest Revenue',
              (report.paymentBreakdown.entries
                      .where(_matchesPaymentMethodFilter)
                      .isEmpty
                  ? report.highestRevenueMethod
                  : report.paymentBreakdown.entries
                        .where(_matchesPaymentMethodFilter)
                        .reduce(
                          (a, b) =>
                              a.value.totalAmount > b.value.totalAmount ? a : b,
                        )
                        .key),
              Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Payment Method Breakdown
        const Text(
          'Payment Method Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.paymentBreakdown.entries
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
                      ok = ok && entry.value.totalAmount >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && entry.value.totalAmount <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .map((entry) {
                    final data = entry.value;
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        '${data.transactionCount} transactions  ${data.percentageOfTotal.toStringAsFixed(1)}%',
                      ),
                      trailing: Text(
                        'RM${data.totalAmount.toStringAsFixed(2)}',
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

  Widget _buildDayClosingContent() {
    if (_dayClosingReport == null) {
      return const Center(child: Text('No data available'));
    }

    final report = _dayClosingReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMetricCard(
                      'Total Sales',
                      FormattingService.currency(report.totalSales),
                      Icons.attach_money,
                    ),
                    _buildMetricCard(
                      'Net Sales',
                      FormattingService.currency(report.netSales),
                      Icons.trending_up,
                    ),
                    _buildMetricCard(
                      'Cash Expected',
                      FormattingService.currency(report.cashExpected),
                      Icons.account_balance_wallet,
                    ),
                    _buildMetricCard(
                      'Cash Variance',
                      FormattingService.currency(report.cashVariance),
                      report.cashVariance >= 0
                          ? Icons.check_circle
                          : Icons.warning,
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
                  report.cashReconciliation.openingFloat,
                ),
                _buildReconciliationRow(
                  'Cash Sales',
                  report.cashReconciliation.cashSales,
                ),
                _buildReconciliationRow(
                  'Cash Refunds',
                  -report.cashReconciliation.cashRefunds,
                ),
                _buildReconciliationRow(
                  'Paid Outs',
                  -report.cashReconciliation.paidOuts,
                ),
                _buildReconciliationRow(
                  'Paid Ins',
                  report.cashReconciliation.paidIns,
                ),
                const Divider(),
                _buildReconciliationRow(
                  'Expected Cash',
                  report.cashReconciliation.expectedCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Actual Cash',
                  report.cashReconciliation.actualCash,
                  isTotal: true,
                ),
                _buildReconciliationRow(
                  'Variance',
                  report.cashReconciliation.variance,
                  isTotal: true,
                  isVariance: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Shift Summaries
        if (report.shiftSummaries.isNotEmpty)
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
                  ...report.shiftSummaries.map(
                    (shift) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(shift.employeeName ?? 'Unknown')),
                          Expanded(
                            child: Text(_formatDuration(
                              shift.shiftDuration ?? Duration.zero,
                            )),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(
                                shift.salesDuringShift ?? 0.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              FormattingService.currency(shift.cashHandled ?? 0.0),
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
    if (_dailyStaffPerformanceReport == null ||
        _dailyStaffPerformanceReport!['error'] != null) {
      return const Center(child: Text('No data available'));
    }

    return DailyStaffPerformanceContent(
      reportData: _dailyStaffPerformanceReport!,
    );
  }

  pw.Widget _buildDailyStaffPerformancePDF() {
    if (_dailyStaffPerformanceReport == null)
      return pw.Text('No data available');

    final data = _dailyStaffPerformanceReport!;
    final staffData = data['staffData'] as List<dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;
    final businessDate = DateTime.parse(data['businessDate'] as String);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Staff Performance Report',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Business Date: ${FormattingService.formatDate(businessDate.toIso8601String())}',
        ),
        pw.Text('Tax Entity: ${BusinessInfo.instance.businessName}'),
        pw.SizedBox(height: 16),
        // Sales Performance Summary
        pw.Text(
          '1. Sales Performance Summary',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'Login',
            'Logout',
            'Gross Sales',
            'Discounts',
            'Net Sales',
            'Transactions',
          ],
          data: [
            ...staffData.map(
              (staff) => [
                staff['userName'] as String,
                _formatTime(staff['loginTime'] as String?),
                _formatTime(staff['logoutTime'] as String?),
                FormattingService.currency(staff['grossSales'] as double),
                FormattingService.currency(staff['discounts'] as double),
                FormattingService.currency(staff['netSales'] as double),
                (staff['transactionCount'] as int).toString(),
              ],
            ),
            [
              'TOTAL',
              '',
              '',
              FormattingService.currency(summary['totalGrossSales'] as double),
              FormattingService.currency(summary['totalDiscounts'] as double),
              FormattingService.currency(summary['totalNetSales'] as double),
              (summary['totalTransactions'] as int).toString(),
            ],
          ],
        ),
        pw.SizedBox(height: 16),
        // SST & Tax Breakdown
        pw.Text(
          '2. SST & Tax Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'SST 6% (F&B)',
            'SST 8% (Other)',
            'Tax-Exempt',
            'Total SST',
          ],
          data: [
            ...staffData.map((staff) {
              final taxBreakdown =
                  staff['taxBreakdown'] as Map<String, dynamic>;
              final totalTax = taxBreakdown.values.fold<double>(
                0,
                (sum, amount) => sum + (amount as double),
              );
              return [
                staff['userName'] as String,
                FormattingService.currency(taxBreakdown['0.06'] ?? 0),
                FormattingService.currency(taxBreakdown['0.08'] ?? 0),
                '0.00',
                FormattingService.currency(totalTax),
              ];
            }),
            [
              'TOTAL',
              FormattingService.currency(
                (summary['taxBreakdown'] as Map)['0.06'] ?? 0,
              ),
              FormattingService.currency(
                (summary['taxBreakdown'] as Map)['0.08'] ?? 0,
              ),
              '0.00',
              FormattingService.currency(
                (summary['taxBreakdown'] as Map).values.fold<double>(
                  0,
                  (sum, amount) => sum + (amount as double),
                ),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 16),
        // Payment Method Audit
        pw.Text(
          '3. Payment Method Audit',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [
            'Staff Name',
            'Cash',
            'Credit Card',
            'TNG/GrabPay',
            'ShopeePay',
          ],
          data: [
            ...staffData.map((staff) {
              final paymentMethods =
                  staff['paymentMethods'] as Map<String, dynamic>;
              return [
                staff['userName'] as String,
                FormattingService.currency(paymentMethods['Cash'] ?? 0),
                FormattingService.currency(paymentMethods['Credit Card'] ?? 0),
                FormattingService.currency(
                  paymentMethods['TNG / GrabPay'] ?? 0,
                ),
                FormattingService.currency(paymentMethods['ShopeePay'] ?? 0),
              ];
            }),
            [
              'TOTAL',
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['Cash'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['Credit Card'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['TNG / GrabPay'] ?? 0,
              ),
              FormattingService.currency(
                (summary['paymentMethodTotals'] as Map)['ShopeePay'] ?? 0,
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 16),
        // Error & Security Log
        pw.Text(
          '4. Error & Security Log',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['Staff Name', 'Voids', 'Overrides', 'Refunds'],
          data: [
            ...staffData.map(
              (staff) => [
                staff['userName'] as String,
                (staff['voids'] as int).toString(),
                (staff['overrides'] as int).toString(),
                FormattingService.currency(staff['refunds'] as double),
              ],
            ),
            [
              'TOTAL',
              (summary['totalVoids'] as int).toString(),
              (summary['totalOverrides'] as int).toString(),
              FormattingService.currency(summary['totalRefunds'] as double),
            ],
          ],
        ),
      ],
    );
  }
}
