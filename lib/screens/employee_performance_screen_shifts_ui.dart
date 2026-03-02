part of 'employee_performance_screen.dart';

extension _EmployeePerformanceShiftsUIBuilders
    on _EmployeePerformanceScreenState {
  Widget buildShiftReportsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _performances.map((perf) {
                  return ChoiceChip(
                    label: Text(perf.userName),
                    selected: _selectedUserId == perf.userId,
                    onSelected: (selected) {
                      if (selected) {
                        _loadShiftReport(perf.userId);
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        Expanded(
          child: _selectedShiftReport == null
              ? const Center(
                  child: Text('Select an employee to view shift reports'),
                )
              : buildShiftReportDetails(_selectedShiftReport!),
        ),
      ],
    );
  }

  Widget buildShiftReportDetails(ShiftReport report) {
    final formatter = DateFormat('MMM dd, hh:mm a');
    final duration = report.shiftEnd.difference(report.shiftStart);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shift Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatter.format(report.shiftStart)} - ${formatter.format(report.shiftEnd)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${hours}h ${minutes}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildShiftCard(
                  'Orders',
                  report.orderCount.toString(),
                  Icons.shopping_cart,
                  const Color(0xFF2563EB),
                ),
                buildShiftCard(
                  'Total Sales',
                  '${BusinessInfo.instance.currencySymbol}${report.totalSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  const Color(0xFF10B981),
                ),
                buildShiftCard(
                  'Commission',
                  '${BusinessInfo.instance.currencySymbol}${0.0.toStringAsFixed(2)}',
                  Icons.payments,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  buildPaymentRow('Cash Sales', report.cashSales),
                  buildPaymentRow('Card Sales', report.cardSales),
                  buildPaymentRow('Other Payments', report.otherSales),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShiftCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPaymentRow(String method, double amount) {
    final total =
        _selectedShiftReport!.cashSales +
        _selectedShiftReport!.cardSales +
        _selectedShiftReport!.otherSales;
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(method),
              Text(
                '${BusinessInfo.instance.currencySymbol}${amount.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
