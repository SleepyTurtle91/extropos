import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/reports_service.dart';
import 'package:flutter/material.dart';

class PaymentBreakdownScreen extends StatefulWidget {
  const PaymentBreakdownScreen({super.key});

  @override
  State<PaymentBreakdownScreen> createState() => _PaymentBreakdownScreenState();
}

class _PaymentBreakdownScreenState extends State<PaymentBreakdownScreen> {
  late SalesReport? currentReport;
  late bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() => isLoading = true);
      final report = await ReportsService().generateMonthlyReport(DateTime.now());
      setState(() {
        currentReport = report;
        isLoading = false;
      });
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
        title: const Text('Payment Breakdown'),
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
                      const Icon(Icons.payment, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No data available', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _loadReport,
                        child: const Text('Retry'),
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
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1e40af)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Revenue',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RM ${currentReport!.netSales.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryInfo(
                                    'Payment Methods',
                                    '${currentReport!.paymentMethods.length}',
                                  ),
                                  _buildSummaryInfo(
                                    'Total Transactions',
                                    '${currentReport!.transactionCount}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Payment Methods List
                        const Text(
                          'Payment Methods',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (currentReport!.paymentMethods.isEmpty)
                          const Center(child: Text('No payment data'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentReport!.paymentMethods.length,
                            itemBuilder: (context, index) {
                              final entries = currentReport!.paymentMethods.entries.toList();
                              entries.sort((a, b) => b.value.compareTo(a.value));
                              final entry = entries[index];
                              final percentage = (entry.value / currentReport!.netSales) * 100;

                              return _buildPaymentMethodCard(
                                entry.key,
                                entry.value,
                                percentage,
                                index,
                              );
                            },
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadReport,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSummaryInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method, double amount, double percentage, int index) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    method,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount:'),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
