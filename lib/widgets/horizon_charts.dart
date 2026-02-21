import 'package:extropos/design_system/horizon_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Sparkline Chart Component
/// Mini inline chart for metric cards showing trend
class HorizonSparkline extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final bool isPositiveTrend;

  const HorizonSparkline({
    super.key,
    required this.values,
    this.lineColor = HorizonColors.electricIndigo,
    this.fillColor = HorizonColors.electricIndigo,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final spots = List<FlSpot>.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [lineColor, lineColor.withOpacity(0.5)],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  fillColor.withOpacity(0.15),
                  fillColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: values.reduce((a, b) => a > b ? a : b),
      ),
    );
  }
}

/// Horizon Design System - Bar Chart Component
/// Hourly/Daily sales velocity chart
class HorizonBarChart extends StatelessWidget {
  final List<BarChartGroupData> groups;
  final String title;

  const HorizonBarChart({
    super.key,
    required this.groups,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HorizonColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
        ],
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 250,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => HorizonColors.deepMidnight,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'RM ${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'RM ${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HorizonColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final hours = ['12am', '4am', '8am', '12pm', '4pm', '8pm', '12am'];
                    final index = value.toInt();
                    if (index < hours.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          hours[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: HorizonColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: HorizonColors.border),
                bottom: BorderSide(color: HorizonColors.border),
              ),
            ),
            gridData: const FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
            ),
            barGroups: groups,
          ),
        ),
      ],
    );
  }
}

/// Horizon Design System - Line Chart Component
/// Sales trend over time
class HorizonLineChart extends StatelessWidget {
  final List<FlSpot> currentData;
  final List<FlSpot>? previousData;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;

  const HorizonLineChart({
    super.key,
    required this.currentData,
    this.previousData,
    this.title = '',
    this.xAxisLabel = '',
    this.yAxisLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HorizonColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  _buildLegend('Current Period', HorizonColors.electricIndigo),
                  const SizedBox(width: 16),
                  if (previousData != null)
                    _buildLegend('Previous Period', HorizonColors.textTertiary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        LineChart(
          LineChartData(
            gridData: const FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'RM ${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HorizonColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final index = value.toInt();
                    if (index < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: HorizonColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: HorizonColors.border),
                bottom: BorderSide(color: HorizonColors.border),
              ),
            ),
            lineBarsData: [
              // Current data
              LineChartBarData(
                spots: currentData,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [HorizonColors.electricIndigo, HorizonColors.electricIndigoLight],
                ),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      HorizonColors.electricIndigo.withOpacity(0.1),
                      HorizonColors.electricIndigo.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Previous data (dashed line)
              if (previousData != null)
                LineChartBarData(
                  spots: previousData!,
                  isCurved: true,
                  color: HorizonColors.textTertiary,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: HorizonColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
