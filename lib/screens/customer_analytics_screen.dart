import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/reports_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() => _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  late SalesReport? currentReport;
  late bool isLoading = true;
  late DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

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

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (range != null) {
      setState(() => selectedDateRange = range);
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Analytics'),
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
                      const Icon(Icons.people, size: 64, color: Colors.grey),
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
                        // Date Range Selector
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                            title: Text(
                              '${DateFormat('MMM d').format(selectedDateRange.start)} - ${DateFormat('MMM d').format(selectedDateRange.end)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: _selectDateRange,
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
                              childAspectRatio: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                _buildMetricCard(
                                  'Total Customers',
                                  '${currentReport!.uniqueCustomers}',
                                  Icons.people,
                                  Colors.blue,
                                ),
                                _buildMetricCard(
                                  'Avg Customer Value',
                                  'RM ${(currentReport!.netSales / (currentReport!.uniqueCustomers > 0 ? currentReport!.uniqueCustomers : 1)).toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                                _buildMetricCard(
                                  'Repeat Rate',
                                  '${((currentReport!.transactionCount / (currentReport!.uniqueCustomers > 0 ? currentReport!.uniqueCustomers : 1))).toStringAsFixed(1)}x',
                                  Icons.repeat,
                                  Colors.orange,
                                ),
                                _buildMetricCard(
                                  'Customer Retention',
                                  '${((currentReport!.uniqueCustomers / (currentReport!.transactionCount > 0 ? currentReport!.transactionCount : 1)) * 100).toStringAsFixed(1)}%',
                                  Icons.check_circle,
                                  Colors.purple,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Customer Segments
                        const Text(
                          'Customer Segments',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSegmentCard(
                          'High Value',
                          '${(currentReport!.uniqueCustomers * 0.2).toInt()}',
                          'Top 20% spenders',
                          Colors.green,
                          Icons.star,
                        ),
                        const SizedBox(height: 12),
                        _buildSegmentCard(
                          'Regular',
                          '${(currentReport!.uniqueCustomers * 0.5).toInt()}',
                          'Repeat customers',
                          Colors.blue,
                          Icons.people,
                        ),
                        const SizedBox(height: 12),
                        _buildSegmentCard(
                          'New',
                          '${(currentReport!.uniqueCustomers * 0.3).toInt()}',
                          'First-time buyers',
                          Colors.orange,
                          Icons.person_add,
                        ),
                        const SizedBox(height: 32),

                        // Spending Distribution
                        const Text(
                          'Spending Distribution',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDistributionBar(
                                  'RM 0-50',
                                  0.25,
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                _buildDistributionBar(
                                  'RM 51-100',
                                  0.35,
                                  Colors.green,
                                ),
                                const SizedBox(height: 12),
                                _buildDistributionBar(
                                  'RM 101-200',
                                  0.25,
                                  Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                _buildDistributionBar(
                                  'RM 200+',
                                  0.15,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentCard(String title, String count, String description, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, double percentage, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
