import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/advanced_reporting_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';

part 'comparative_analysis_dashboard_ui.dart';

class ComparativeAnalysisDashboard extends StatefulWidget {
  const ComparativeAnalysisDashboard({super.key});

  @override
  State<ComparativeAnalysisDashboard> createState() =>
      _ComparativeAnalysisDashboardState();
}

class _ComparativeAnalysisDashboardState
    extends State<ComparativeAnalysisDashboard> {
  ComparativeAnalysis? _analysis;
  bool _isLoading = false;

  // Period selectors
  ReportPeriod _currentPeriod = ReportPeriod.thisMonth();
  ReportPeriod _comparisonPeriod = ReportPeriod.lastMonth();

  final List<String> _metricsToCompare = [
    'gross_sales',
    'net_sales',
    'transactions',
    'average_transaction',
  ];

  @override
  void initState() {
    super.initState();
    _generateComparison();
  }

  Future<void> _generateComparison() async {
    setState(() => _isLoading = true);
    try {
      final analysis = await AdvancedReportingService.instance
          .generateComparativeAnalysis(
            currentPeriod: _currentPeriod,
            comparisonPeriod: _comparisonPeriod,
            metricsToCompare: _metricsToCompare,
          );
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating comparison: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See comparative_analysis_dashboard_ui.dart');
  }

  String _formatMetricName(String metric) {
    return metric
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'RM ${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return 'RM ${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return 'RM ${value.toStringAsFixed(2)}';
    }
  }
}
