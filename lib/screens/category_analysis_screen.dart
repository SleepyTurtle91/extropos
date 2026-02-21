import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/reports_service.dart';
import 'package:flutter/material.dart';

class CategoryAnalysisScreen extends StatefulWidget {
  const CategoryAnalysisScreen({super.key});

  @override
  State<CategoryAnalysisScreen> createState() => _CategoryAnalysisScreenState();
}

class _CategoryAnalysisScreenState extends State<CategoryAnalysisScreen> {
  late SalesReport? currentReport;
  late bool isLoading = true;
  late String selectedSort = 'Revenue';

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

  List<MapEntry<String, double>> _getSortedCategories() {
    if (currentReport == null) return [];
    final categories = currentReport!.topCategories.entries.toList();
    categories.sort((a, b) => b.value.compareTo(a.value));
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Analysis'),
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
                      const Icon(Icons.category, size: 64, color: Colors.grey),
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
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                'Total Revenue',
                                'RM ${currentReport!.netSales.toStringAsFixed(2)}',
                                Icons.trending_up,
                              ),
                              _buildSummaryItem(
                                'Categories',
                                '${currentReport!.topCategories.length}',
                                Icons.category,
                              ),
                              _buildSummaryItem(
                                'Transactions',
                                '${currentReport!.transactionCount}',
                                Icons.receipt,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sort Option
                      Row(
                        children: [
                          const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedSort,
                            items: ['Revenue', 'Alphabetical'].map((e) {
                              return DropdownMenuItem(value: e, child: Text(e));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedSort = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category List
                      Expanded(
                        child: currentReport!.topCategories.isEmpty
                            ? const Center(child: Text('No category data'))
                            : ListView.builder(
                                itemCount: _getSortedCategories().length,
                                itemBuilder: (context, index) {
                                  final category = _getSortedCategories()[index];
                                  final percentage = (category.value / currentReport!.netSales) * 100;
                                  return _buildCategoryCard(
                                    category.key,
                                    category.value,
                                    percentage,
                                    index,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadReport,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryCard(String category, double revenue, double percentage, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Revenue: RM ${revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
