import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:flutter/material.dart';

/// Demand forecasting, menu engineering and table performance report content builders
class ReportDemandContent {
  static Widget buildDemandForecastingContent(DemandForecastingReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Demand Forecasting - ${report.forecastingMethod}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Forecast Accuracy: ${(report.forecastAccuracy * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...report.forecastItems
                    .take(5)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Historical: ${item.historicalSales.last.toStringAsFixed(0)} units',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Forecast: ${item.forecastedSales.last.toStringAsFixed(0)} units',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            LinearProgressIndicator(
                              value: item.confidenceLevel,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.confidenceLevel > 0.8
                                    ? Colors.green
                                    : item.confidenceLevel > 0.6
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              'Confidence: ${(item.confidenceLevel * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMenuEngineeringContent(MenuEngineeringReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Stars',
                value: report.starsCount.toString(),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Plowhorses',
                value: report.plowhorsesCount.toString(),
                icon: Icons.work,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Puzzles',
                value: report.puzzlesCount.toString(),
                icon: Icons.help,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Dogs',
                value: report.dogsCount.toString(),
                icon: Icons.pets,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Engineering Matrix',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stars: High popularity, high profit - Focus on promotion\nPlowhorses: High popularity, low profit - Review pricing/costs\nPuzzles: Low popularity, high profit - Improve marketing\nDogs: Low popularity, low profit - Consider removal',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...report.menuItems
                    .take(10)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.category == 'star'
                                    ? Colors.amber
                                    : item.category == 'plowhorse'
                                    ? Colors.blue
                                    : item.category == 'puzzle'
                                    ? Colors.orange
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  item.category[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.itemName)),
                            Text(
                              '${item.popularity.toStringAsFixed(1)}% / ${item.profitability.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildTablePerformanceContent(TablePerformanceReport? report) {
    if (report == null) return const Center(child: Text('No data available'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Total Tables',
                value: report.totalTables.toString(),
                icon: Icons.table_restaurant,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Occupied Tables',
                value: report.occupiedTables.toString(),
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Avg Turnover',
                value: report.averageTableTurnover.toStringAsFixed(1),
                icon: Icons.refresh,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportDemandContentHelpers.buildSummaryCard(
                title: 'Avg Revenue/Table',
                value: FormattingService.currency(
                  report.averageRevenuePerTable,
                ),
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Table Performance Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...report.tableData
                    .take(10)
                    .map(
                      (table) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${table.tableName} (Capacity: ${table.capacity})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Revenue: ${FormattingService.currency(table.totalRevenue)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Orders: ${table.totalOrders}',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Avg Occupancy: ${table.averageOccupancyTime.inHours}h ${table.averageOccupancyTime.inMinutes % 60}m',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Revenue/Hour: ${FormattingService.currency(table.revenuePerHour)}',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper class for demand analysis report content building
class _ReportDemandContentHelpers {
  static Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
