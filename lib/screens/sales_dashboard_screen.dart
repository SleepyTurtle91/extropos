import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/reports_service.dart';
import 'package:flutter/material.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  late SalesReport? currentReport;
  late bool isLoading = true;
  late String selectedPeriod = 'Today';
  late DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReport('Today');
  }

  Future<void> _loadReport(String period) async {
    try {
      setState(() => isLoading = true);

      SalesReport report;
      switch (period) {
        case 'Yesterday':
          report = await ReportsService().generateDailyReport(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          break;
        case 'This Week':
          report = await ReportsService().generateWeeklyReport(DateTime.now());
          break;
        case 'Last Week':
          final lastWeek = DateTime.now().subtract(const Duration(days: 7));
          report = await ReportsService().generateWeeklyReport(lastWeek);
          break;
        case 'This Month':
          report = await ReportsService().generateMonthlyReport(DateTime.now());
          break;
        case 'Last Month':
          final lastMonth = DateTime.now().subtract(const Duration(days: 30));
          report = await ReportsService().generateMonthlyReport(lastMonth);
          break;
        default: // Today
          report = await ReportsService().generateDailyReport(DateTime.now());
      }

      setState(() {
        currentReport = report;
        selectedPeriod = period;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Report loaded for $period')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentReport == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.show_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No data available', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => _loadReport('Today'),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period selector
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'Today',
                              'Yesterday',
                              'This Week',
                              'Last Week',
                              'This Month',
                              'Last Month',
                            ]
                                .map((period) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(period),
                                        selected: selectedPeriod == period,
                                        onSelected: (_) => _loadReport(period),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // KPI Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int columns = constraints.maxWidth < 600 ? 1 : 2;
                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 2.2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                _buildKPICard(
                                  title: 'Gross Sales',
                                  value: 'RM ${currentReport!.grossSales.toStringAsFixed(2)}',
                                  icon: Icons.trending_up,
                                  color: Colors.blue,
                                ),
                                _buildKPICard(
                                  title: 'Net Sales',
                                  value: 'RM ${currentReport!.netSales.toStringAsFixed(2)}',
                                  icon: Icons.assessment,
                                  color: Colors.green,
                                ),
                                _buildKPICard(
                                  title: 'Transactions',
                                  value: '${currentReport!.transactionCount}',
                                  icon: Icons.receipt,
                                  color: Colors.orange,
                                ),
                                _buildKPICard(
                                  title: 'Avg Ticket',
                                  value: 'RM ${currentReport!.averageTicket.toStringAsFixed(2)}',
                                  icon: Icons.shopping_cart,
                                  color: Colors.purple,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tax & Service Charge Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Charges & Deductions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildChargeLine(
                                'Tax Collected',
                                'RM ${currentReport!.taxAmount.toStringAsFixed(2)}',
                                '${currentReport!.taxPercentage.toStringAsFixed(1)}%',
                                Colors.red,
                              ),
                              const SizedBox(height: 8),
                              _buildChargeLine(
                                'Service Charge',
                                'RM ${currentReport!.serviceChargeAmount.toStringAsFixed(2)}',
                                '${currentReport!.serviceChargePercentage.toStringAsFixed(1)}%',
                                Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              _buildChargeLine(
                                'Total Deductions',
                                'RM ${currentReport!.totalDeductions.toStringAsFixed(2)}',
                                '${currentReport!.discountPercentage.toStringAsFixed(1)}%',
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Methods
                        _buildSectionHeader('Payment Methods', Icons.payment),
                        const SizedBox(height: 12),
                        if (currentReport!.paymentMethods.isEmpty)
                          const Text('No payment data available')
                        else
                          Column(
                            children: currentReport!.paymentMethods.entries
                                .map((entry) => _buildPaymentMethodRow(
                                      entry.key,
                                      entry.value,
                                      currentReport!.netSales,
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 24),

                        // Top Categories
                        _buildSectionHeader('Top Categories', Icons.category),
                        const SizedBox(height: 12),
                        if (currentReport!.topCategories.isEmpty)
                          const Text('No category data available')
                        else
                          Column(
                            children: currentReport!.topCategories.entries
                                .map((entry) => _buildCategoryRow(
                                      entry.key,
                                      entry.value,
                                      currentReport!.netSales,
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargeLine(String label, String amount, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(String method, double amount, double total) {
    final percentage = total > 0 ? (amount / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double total) {
    final percentage = total > 0 ? (amount / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
