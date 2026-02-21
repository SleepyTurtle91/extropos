import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

/// Advanced Analytics Dashboard with charts and detailed reports
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _analyticsService = AnalyticsService.instance;

  // Date range selection
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  // Data
  SalesSummary? _summary;
  List<CategoryPerformance> _categories = [];
  List<ProductPerformance> _topProducts = [];
  List<PaymentMethodStats> _paymentMethods = [];
  List<DailySales> _dailySales = [];
  Map<String, double> _orderTypeDistribution = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
          limit: 10,
        ),
        _analyticsService.getTopProducts(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
          limit: 10,
        ),
        _analyticsService.getPaymentMethodStats(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        ),
        _analyticsService.getDailySales(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        ),
        _analyticsService.getOrderTypeDistribution(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        ),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as SalesSummary;
          _categories = results[1] as List<CategoryPerformance>;
          _topProducts = results[2] as List<ProductPerformance>;
          _paymentMethods = results[3] as List<PaymentMethodStats>;
          _dailySales = results[4] as List<DailySales>;
          _orderTypeDistribution = results[5] as Map<String, double>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: const Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _loadData();
    }
  }

  Future<void> _exportCsv() async {
    try {
      final csv = await _analyticsService.exportAnalyticsCsv(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Save to downloads
        final directory = await getExternalStorageDirectory();
        final fileName =
            'analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final file = File('${directory!.path}/$fileName');
        await file.writeAsString(csv);

        if (mounted) {
          ToastHelper.showToast(context, 'Exported to ${file.path}');
        }
      } else {
        // Desktop: Show save dialog
        final fileName =
            'analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final file = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'CSV Files', extensions: ['csv']),
          ],
        );

        if (file != null) {
          await File(file.path).writeAsString(csv);
          if (mounted) {
            ToastHelper.showToast(context, 'Analytics exported successfully');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _isLoading ? null : _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading analytics: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range display
          _buildDateRangeCard(),
          const SizedBox(height: 16),

          // Summary cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Daily sales trend chart
          _buildDailySalesChart(),
          const SizedBox(height: 24),

          // Two-column layout for charts
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCategoryChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPaymentMethodChart()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCategoryChart(),
                    const SizedBox(height: 24),
                    _buildPaymentMethodChart(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Top products table
          _buildTopProductsTable(),
          const SizedBox(height: 24),

          // Order type distribution
          _buildOrderTypeChart(),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reporting Period',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.edit),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) return const SizedBox.shrink();

    final currency = BusinessInfo.instance.currencySymbol;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 2;
        } else if (constraints.maxWidth < 900) {
          columns = 3;
        }

        final cards = [
          _SummaryCard(
            title: 'Total Revenue',
            value: '$currency ${_summary!.totalRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          _SummaryCard(
            title: 'Orders',
            value: _summary!.orderCount.toString(),
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
          _SummaryCard(
            title: 'Items Sold',
            value: _summary!.itemsSold.toString(),
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),
          _SummaryCard(
            title: 'Avg Order Value',
            value:
                '$currency ${_summary!.averageOrderValue.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            return SizedBox(
              width: (constraints.maxWidth - ((columns - 1) * 12)) / columns,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDailySalesChart() {
    if (_dailySales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text('No sales data available for this period'),
          ),
        ),
      );
    }

    final maxRevenue = _dailySales
        .map((s) => s.revenue)
        .reduce((a, b) => a > b ? a : b);
    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sales Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxRevenue / 5,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '$currency${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _dailySales.length) {
                            return Text(
                              _dailySales[index].dateLabel,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailySales.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.revenue);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxRevenue * 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No category data available')),
        ),
      );
    }

    final total = _categories.fold<double>(0, (sum, cat) => sum + cat.revenue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _categories.map((cat) {
                    final percentage = (cat.revenue / total) * 100;
                    return PieChartSectionData(
                      value: cat.revenue,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_categories.length, (index) {
              final cat = _categories[index];
              final percentage = (cat.revenue / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    if (_paymentMethods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No payment data available')),
        ),
      );
    }

    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '$currency${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _paymentMethods.length) {
                            return Text(
                              _paymentMethods[index].paymentMethodName,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _paymentMethods.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalAmount,
                          color: const Color(0xFF2563EB),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsTable() {
    if (_topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: const Center(child: Text('No product data available')),
        ),
      );
    }

    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 10 Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Revenue')),
                  DataColumn(label: Text('Qty Sold')),
                  DataColumn(label: Text('Orders')),
                ],
                rows: List.generate(_topProducts.length, (index) {
                  final product = _topProducts[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('#${index + 1}')),
                      DataCell(Text(product.itemName)),
                      DataCell(Text(product.categoryName)),
                      DataCell(
                        Text('$currency${product.revenue.toStringAsFixed(2)}'),
                      ),
                      DataCell(Text(product.quantitySold.toString())),
                      DataCell(Text(product.orderCount.toString())),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeChart() {
    if (_orderTypeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _orderTypeDistribution.values.fold<double>(
      0,
      (sum, val) => sum + val,
    );
    final currency = BusinessInfo.instance.currencySymbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Mode Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._orderTypeDistribution.entries.map((entry) {
              final percentage = (entry.value / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
