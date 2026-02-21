import 'package:extropos/models/advanced_reporting_features.dart';
import 'package:extropos/models/sales_report.dart' show ReportPeriod;
import 'package:extropos/services/advanced_reporting_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparative Analysis'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showPeriodSelector,
            tooltip: 'Change Periods',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateComparison,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analysis == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          _buildMetricsOverview(),
          const SizedBox(height: 24),
          _buildDetailedComparisons(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile: Vertical layout
            return Column(
              children: [
                _buildPeriodCard(
                  'Current Period',
                  _currentPeriod.label,
                  const Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                const SizedBox(height: 12),
                _buildPeriodCard(
                  'Comparison Period',
                  _comparisonPeriod.label,
                  Colors.grey[600]!,
                ),
              ],
            );
          } else {
            // Desktop: Horizontal layout
            return Row(
              children: [
                Expanded(
                  child: _buildPeriodCard(
                    'Current Period',
                    _currentPeriod.label,
                    const Color(0xFF2563EB),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Icon(
                    Icons.compare_arrows,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildPeriodCard(
                    'Comparison Period',
                    _comparisonPeriod.label,
                    Colors.grey[600]!,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPeriodCard(String title, String period, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              period,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview() {
    if (_analysis == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use maxCrossAxisExtent for cards so layout stays balanced across sizes

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
            crossAxisSpacing: AppSpacing.m,
            mainAxisSpacing: AppSpacing.m,
            childAspectRatio: 1.3,
          ),
          itemCount: _analysis!.metrics.length,
          itemBuilder: (context, index) {
            final metric = _analysis!.metrics.values.elementAt(index);
            return _buildMetricCard(metric);
          },
        );
      },
    );
  }

  Widget _buildMetricCard(PeriodComparison comparison) {
    final isPositive = comparison.isImprovement;
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMetricName(comparison.metricName),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(trendIcon, color: trendColor, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              _formatCurrency(comparison.currentValue),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'vs ${_formatCurrency(comparison.previousValue)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${comparison.changePercentage >= 0 ? '+' : ''}${comparison.changePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedComparisons() {
    if (_analysis == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Detailed Comparison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  // Mobile: List view
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _analysis!.metrics.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final metric = _analysis!.metrics.values.elementAt(index);
                      return _buildDetailedRow(metric);
                    },
                  );
                } else {
                  // Desktop: Table view
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Metric')),
                        DataColumn(label: Text('Current')),
                        DataColumn(label: Text('Previous')),
                        DataColumn(label: Text('Difference')),
                        DataColumn(label: Text('Change %')),
                        DataColumn(label: Text('Trend')),
                      ],
                      rows: _analysis!.metrics.values.map((metric) {
                        final isPositive = metric.isImprovement;
                        final trendColor = isPositive
                            ? Colors.green
                            : Colors.red;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(_formatMetricName(metric.metricName)),
                            ),
                            DataCell(
                              Text(_formatCurrency(metric.currentValue)),
                            ),
                            DataCell(
                              Text(_formatCurrency(metric.previousValue)),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(metric.difference),
                                style: TextStyle(color: trendColor),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${metric.changePercentage >= 0 ? '+' : ''}${metric.changePercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: trendColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Icon(
                                isPositive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: trendColor,
                                size: 20,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRow(PeriodComparison metric) {
    final isPositive = metric.isImprovement;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return ListTile(
      title: Text(_formatMetricName(metric.metricName)),
      subtitle: Text(
        'Current: ${_formatCurrency(metric.currentValue)} | Previous: ${_formatCurrency(metric.previousValue)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${metric.changePercentage >= 0 ? '+' : ''}${metric.changePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: trendColor,
            size: 20,
          ),
        ],
      ),
    );
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

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Comparison Periods'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Period',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPeriodButtons(isCurrentPeriod: true),
                const SizedBox(height: 24),
                const Text(
                  'Comparison Period',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPeriodButtons(isCurrentPeriod: false),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateComparison();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButtons({required bool isCurrentPeriod}) {
    final periods = [
      ('Today', ReportPeriod.today()),
      ('Yesterday', ReportPeriod.yesterday()),
      ('This Week', ReportPeriod.thisWeek()),
      ('Last Week', ReportPeriod.lastWeek()),
      ('This Month', ReportPeriod.thisMonth()),
      ('Last Month', ReportPeriod.lastMonth()),
      ('This Year', ReportPeriod.thisYear()),
      ('Last Year', ReportPeriod.lastYear()),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periods.map((period) {
        final isSelected = isCurrentPeriod
            ? _currentPeriod.label == period.$2.label
            : _comparisonPeriod.label == period.$2.label;

        return ChoiceChip(
          label: Text(period.$1),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (isCurrentPeriod) {
                _currentPeriod = period.$2;
              } else {
                _comparisonPeriod = period.$2;
              }
            });
          },
        );
      }).toList(),
    );
  }
}
