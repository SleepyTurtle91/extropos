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

part 'analytics_dashboard_screen_charts.dart';
part 'analytics_dashboard_screen_tables.dart';

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
    return buildDashboardLayout();
  }

  // All chart builder methods moved to AnalyticsDashboardCharts extension
  // in analytics_dashboard_screen_charts.dart
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
