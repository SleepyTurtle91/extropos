import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/printer_model.dart' as printer_model;
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/screens/advanced_reports_screen.dart';
import 'package:extropos/services/analytics_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/report_printer_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/kpi_card.dart';
import 'package:extropos/widgets/report_date_selector.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

/// Modern reports dashboard with visual analytics and quick insights
class ModernReportsDashboard extends StatefulWidget {
  final String? initialPeriod;

  const ModernReportsDashboard({super.key, this.initialPeriod});

  @override
  State<ModernReportsDashboard> createState() => _ModernReportsDashboardState();
}

class _ModernReportsDashboardState extends State<ModernReportsDashboard> {
  final _analyticsService = AnalyticsService.instance;

  // Date range selection
  late ReportPeriod _selectedPeriod;

  // Data
  SalesSummary? _summary;
  List<CategoryPerformance> _categories = [];
  List<ProductPerformance> _topProducts = [];
  List<PaymentMethodStats> _paymentMethods = [];
  List<DailySales> _dailySales = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize period based on initialPeriod parameter
    _selectedPeriod = _getInitialPeriod();
    _loadData();
  }

  ReportPeriod _getInitialPeriod() {
    switch (widget.initialPeriod) {
      case 'today':
        return ReportPeriod.today();
      case 'week':
        return ReportPeriod.thisWeek();
      case 'month':
        return ReportPeriod.thisMonth();
      case 'custom':
        final now = DateTime.now();
        return ReportPeriod(
          label: 'Custom (Last 30 Days)',
          startDate: now.subtract(const Duration(days: 30)),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      default:
        return ReportPeriod.today();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getSalesSummary(
          startDate: _selectedPeriod.startDate,
          endDate: _selectedPeriod.endDate,
        ),
        _analyticsService.getCategoryPerformance(
          startDate: _selectedPeriod.startDate,
          endDate: _selectedPeriod.endDate,
          limit: 10,
        ),
        _analyticsService.getTopProducts(
          startDate: _selectedPeriod.startDate,
          endDate: _selectedPeriod.endDate,
          limit: 10,
        ),
        _analyticsService.getPaymentMethodStats(
          startDate: _selectedPeriod.startDate,
          endDate: _selectedPeriod.endDate,
        ),
        _analyticsService.getDailySales(
          startDate: _selectedPeriod.startDate,
          endDate: _selectedPeriod.endDate,
        ),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as SalesSummary;
          _categories = results[1] as List<CategoryPerformance>;
          _topProducts = results[2] as List<ProductPerformance>;
          _paymentMethods = results[3] as List<PaymentMethodStats>;
          _dailySales = results[4] as List<DailySales>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _summary == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(onRefresh: _loadData, child: _buildDashboard()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExportOptions,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.download),
        label: const Text('Export'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading reports: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Date Selector
          ReportDateSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() => _selectedPeriod = period);
              _loadData();
            },
          ),
          const Divider(height: 1),

          // KPI Cards
          Padding(padding: const EdgeInsets.all(16), child: _buildKPICards()),

          // Sales Trend Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSalesTrendChart(),
          ),
          const SizedBox(height: 24),

          // Two-column charts (Category & Payment Methods)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDonutCharts(),
          ),
          const SizedBox(height: 24),

          // View Detailed Reports Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDetailedReportsSection(),
          ),
          const SizedBox(height: 24),

          // Top Products List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTopProductsList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final currency = BusinessInfo.instance.currencySymbol;
    final summary = _summary;

    return KPICardGrid(
      cards: [
        KPICard(
          title: 'Gross Sales',
          value:
              '$currency ${summary?.grossSales.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.trending_up,
          color: Colors.green.shade600,
          isLoading: _isLoading,
        ),
        KPICard(
          title: 'Net Sales',
          value: '$currency ${summary?.netSales.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.attach_money,
          color: const Color(0xFF2563EB),
          isLoading: _isLoading,
        ),
        KPICard(
          title: 'Transactions',
          value: '${summary?.transactionCount ?? 0}',
          icon: Icons.receipt_long,
          color: Colors.orange.shade600,
          isLoading: _isLoading,
        ),
        KPICard(
          title: 'Avg Ticket',
          value:
              '$currency ${summary?.averageTransactionValue.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.shopping_cart,
          color: Colors.purple.shade600,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildSalesTrendChart() {
    if (_dailySales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No sales data available for this period')),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            BusinessInfo.instance.currencySymbol +
                                value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _dailySales.length) {
                            final date = _dailySales[value.toInt()].date;
                            return Text(
                              DateFormat('MMM dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailySales.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.totalSales);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = _dailySales[spot.x.toInt()].date;
                          return LineTooltipItem(
                            '${DateFormat('MMM dd').format(date)}\n${BusinessInfo.instance.currencySymbol}${spot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutCharts() {
    return LayoutBuilder(
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
              const SizedBox(height: 16),
              _buildPaymentMethodChart(),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoryChart() {
    if (_categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No category data')),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _categories.take(8).toList().asMap().entries.map((
                          e,
                        ) {
                          final index = e.key;
                          final cat = e.value;
                          return PieChartSectionData(
                            value: cat.revenue,
                            title:
                                '${(cat.revenue / _summary!.grossSales * 100).toStringAsFixed(0)}%',
                            color: colors[index % colors.length],
                            radius: 60,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _categories
                          .take(5)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                            final index = e.key;
                            final cat = e.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat.categoryName,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    if (_paymentMethods.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No payment data')),
        ),
      );
    }

    final colors = [
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _paymentMethods.asMap().entries.map((e) {
                          final index = e.key;
                          final pm = e.value;
                          final total = _paymentMethods.fold<double>(
                            0,
                            (sum, p) => sum + p.totalAmount,
                          );
                          return PieChartSectionData(
                            value: pm.totalAmount,
                            title:
                                '${(pm.totalAmount / total * 100).toStringAsFixed(0)}%',
                            color: colors[index % colors.length],
                            radius: 60,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _paymentMethods.asMap().entries.map((e) {
                        final index = e.key;
                        final pm = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pm.paymentMethodName,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'View comprehensive analytics and insights',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildReportButton(
                  'Advanced Reports',
                  Icons.analytics_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdvancedReportsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No product data')),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdvancedReportsScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topProducts.take(5).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                final currency = BusinessInfo.instance.currencySymbol;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${product.unitsSold} units sold'),
                  trailing: Text(
                    '$currency ${product.revenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Export Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF2563EB)),
              title: const Text('Export as CSV'),
              subtitle: const Text('Comma-separated values'),
              onTap: () {
                Navigator.pop(context);
                _exportCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF (A4)'),
              subtitle: const Text('Printable document'),
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.green),
              title: const Text('Print (Thermal 58mm)'),
              subtitle: const Text('Receipt printer'),
              onTap: () {
                Navigator.pop(context);
                _printThermal58mm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.orange),
              title: const Text('Print (Thermal 80mm)'),
              subtitle: const Text('Wide receipt printer'),
              onTap: () {
                Navigator.pop(context);
                _printThermal80mm();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await _generateCSV();
      final fileName =
          'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Save to downloads
        final directory = await getExternalStorageDirectory();
        final downloadsPath = '${directory!.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '$downloadsPath/$fileName';
        final file = File(filePath);
        await file.writeAsString(csv);

        if (mounted) {
          ToastHelper.showToast(
            context,
            'Report saved to Downloads: $fileName',
          );
        }
      } else {
        // Desktop: Show save dialog
        final file = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'CSV Files', extensions: ['csv']),
          ],
        );

        if (file != null) {
          await File(file.path).writeAsString(csv);
          if (mounted) {
            ToastHelper.showToast(context, 'Report exported successfully');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Export failed: $e');
      }
    }
  }

  Future<String> _generateCSV() async {
    final buffer = StringBuffer();
    final currency = BusinessInfo.instance.currencySymbol;

    // Header
    buffer.writeln('Sales Report');
    buffer.writeln('Period: ${_selectedPeriod.label}');
    buffer.writeln(
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
    buffer.writeln('');

    // Summary
    buffer.writeln('Summary');
    buffer.writeln(
      'Gross Sales,$currency ${_summary?.grossSales.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln(
      'Net Sales,$currency ${_summary?.netSales.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln('Transactions,${_summary?.transactionCount ?? 0}');
    buffer.writeln(
      'Average Ticket,$currency ${_summary?.averageTransactionValue.toStringAsFixed(2) ?? '0.00'}',
    );
    buffer.writeln('');

    // Top Products
    buffer.writeln('Top Products');
    buffer.writeln('Rank,Product Name,Units Sold,Revenue');
    for (var i = 0; i < _topProducts.length; i++) {
      final product = _topProducts[i];
      buffer.writeln(
        '${i + 1},${product.productName},${product.unitsSold},$currency ${product.revenue.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Export sales report as PDF
  Future<void> _exportPDF() async {
    try {
      // Show loading
      if (mounted) {
        ToastHelper.showToast(context, 'Generating PDF...');
      }

      final reportService = ReportPrinterService.instance;

      // Generate PDF bytes
      final pdfBytes = await reportService.generateReportPDF(
        summary: _summary!,
        categories: _categories,
        topProducts: _topProducts,
        paymentMethods: _paymentMethods,
        periodLabel: _selectedPeriod.label,
      );

      if (!mounted) return;

      // Export to file
      final filePath = await reportService.exportToPDFFile(pdfBytes: pdfBytes);

      if (filePath != null && mounted) {
        ToastHelper.showToast(
          context,
          'PDF saved to: ${filePath.split('/').last}',
        );
      } else if (mounted) {
        ToastHelper.showToast(context, 'Save cancelled');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'PDF export failed: $e');
      }
    }
  }

  /// Print thermal report (58mm)
  Future<void> _printThermal58mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }

      final printer = await _getDefaultPrinter();
      if (printer == null) {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
        return;
      }

      if (mounted) {
        ToastHelper.showToast(context, 'Sending to thermal printer...');
      }

      final reportService = ReportPrinterService.instance;
      final success = await reportService.printThermalSummary(
        printer: printer,
        summary: _summary!,
        periodLabel: _selectedPeriod.label,
        categories: _categories,
        paymentMethods: _paymentMethods,
      );

      if (mounted) {
        ToastHelper.showToast(
          context,
          success ? 'Report printed successfully' : 'Print failed - check printer',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  /// Print thermal report (80mm)
  Future<void> _printThermal80mm() async {
    try {
      if (_summary == null) {
        ToastHelper.showToast(context, 'No data to print');
        return;
      }

      final printer = await _getDefaultPrinter();
      if (printer == null) {
        if (mounted) ToastHelper.showToast(context, 'No printer configured');
        return;
      }

      if (mounted) {
        ToastHelper.showToast(context, 'Sending to thermal printer...');
      }

      final reportService = ReportPrinterService.instance;
      final success = await reportService.printThermalSummary(
        printer: printer,
        summary: _summary!,
        periodLabel: _selectedPeriod.label,
        categories: _categories,
        paymentMethods: _paymentMethods,
      );

      if (mounted) {
        ToastHelper.showToast(
          context,
          success ? 'Report printed successfully' : 'Print failed - check printer',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  Future<printer_model.Printer?> _getDefaultPrinter() async {
    final printers = await DatabaseService.instance.getPrinters();
    return printers.isNotEmpty ? printers.first : null;
  }
}

