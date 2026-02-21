import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/table_management_service.dart';
import 'package:flutter/material.dart';

class TableReportsScreen extends StatefulWidget {
  const TableReportsScreen({super.key});

  @override
  State<TableReportsScreen> createState() => _TableReportsScreenState();
}

class _TableReportsScreenState extends State<TableReportsScreen> {
  late TableManagementService _tableService;

  @override
  void initState() {
    super.initState();
    _tableService = TableManagementService();
    _initializeTables();
  }

  Future<void> _initializeTables() async {
    await _tableService.loadTablesFromDatabase();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = _tableService.getTableStatistics();
    final avgDuration = _tableService.getAverageTableDuration();
    final total = stats['total'] ?? 0;
    final available = stats['available'] ?? 0;
    final occupied = stats['occupied'] ?? 0;
    final reserved = stats['reserved'] ?? 0;
    final cleaning = stats['cleaning'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Table Reports'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // KPI Cards Section
            _buildKPISection(
              total: total,
              available: available,
              occupied: occupied,
              reserved: reserved,
              cleaning: cleaning,
              avgDuration: avgDuration,
            ),
            const SizedBox(height: 24),

            // Occupancy Analysis
            _buildSectionTitle('Occupancy Analysis'),
            const SizedBox(height: 12),
            _buildOccupancyAnalysis(total, available, occupied),
            const SizedBox(height: 24),

            // Table Status Distribution
            _buildSectionTitle('Table Status Distribution'),
            const SizedBox(height: 12),
            _buildStatusDistribution(
              available: available,
              occupied: occupied,
              reserved: reserved,
              cleaning: cleaning,
            ),
            const SizedBox(height: 24),

            // Table Details List
            _buildSectionTitle('Table Details'),
            const SizedBox(height: 12),
            _buildTableDetailsList(),
            const SizedBox(height: 24),

            // Performance Metrics
            _buildSectionTitle('Performance Metrics'),
            const SizedBox(height: 12),
            _buildPerformanceMetrics(
              avgDuration: avgDuration,
              total: total,
              occupied: occupied,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection({
    required int total,
    required int available,
    required int occupied,
    required int reserved,
    required int cleaning,
    required double avgDuration,
  }) {
    final occupancyRate = total > 0 ? ((occupied / total) * 100).toStringAsFixed(1) : '0.0';
    final utilizationRate =
        total > 0 ? (((occupied + reserved) / total) * 100).toStringAsFixed(1) : '0.0';

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth > 1200) {
          columns = 4;
        } else if (constraints.maxWidth > 800) {
          columns = 3;
        }

        final cards = [
          _buildKPICard(
            title: 'Total Tables',
            value: total.toString(),
            unit: '',
            icon: Icons.table_restaurant,
            color: Colors.blue,
          ),
          _buildKPICard(
            title: 'Occupancy Rate',
            value: occupancyRate,
            unit: '%',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
          _buildKPICard(
            title: 'Utilization Rate',
            value: utilizationRate,
            unit: '%',
            icon: Icons.show_chart,
            color: Colors.green,
          ),
          _buildKPICard(
            title: 'Avg Duration',
            value: avgDuration.toStringAsFixed(1),
            unit: 'min',
            icon: Icons.schedule,
            color: Colors.purple,
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 1.2,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          children: cards,
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 28, color: color),
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyAnalysis(int total, int available, int occupied) {
    if (total == 0) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No tables configured'),
        ),
      );
    }

    final occupancyPercent = (occupied / total) * 100;
    final availablePercent = (available / total) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Occupied Tables'),
              Text(
                '$occupied / $total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancyPercent / 100,
                  minHeight: 24,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange[400]!,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${occupancyPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Tables'),
              Text(
                '$available / $total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: availablePercent / 100,
                  minHeight: 24,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green[400]!,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${availablePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution({
    required int available,
    required int occupied,
    required int reserved,
    required int cleaning,
  }) {
    final total = available + occupied + reserved + cleaning;

    if (total == 0) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No tables with status data'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Available',
            available,
            total,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Occupied',
            occupied,
            total,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Reserved',
            reserved,
            total,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Cleaning',
            cleaning,
            total,
            Colors.brown,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percent = (count / total) * 100;

    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label),
                  Text(
                    '$count (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableDetailsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _tableService.tables.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No tables configured'),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Table')),
                  DataColumn(label: Text('Capacity')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Duration')),
                ],
                rows: _tableService.tables
                    .map(
                      (table) => DataRow(
                        cells: [
                          DataCell(Text(table.name)),
                          DataCell(Text('${table.capacity}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(table.status)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                table.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(table.status),
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                            table.customerName ?? '-',
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(
                            Text(
                              table.isOccupied
                                  ? '${table.occupiedDurationMinutes} min'
                                  : '-',
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildPerformanceMetrics({
    required double avgDuration,
    required int total,
    required int occupied,
  }) {
    final occupancyRate = total > 0 ? (occupied / total) * 100 : 0.0;
    final estimatedRevenue = (avgDuration / 60) * 50; // Estimate 50 per hour

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildMetricRow(
            'Average Table Duration',
            '${avgDuration.toStringAsFixed(1)} minutes',
            Icons.schedule,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Current Occupancy Rate',
            '${occupancyRate.toStringAsFixed(1)}%',
            Icons.trending_up,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Est. Revenue/Table/Hour',
            'RM ${estimatedRevenue.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Tables Available',
            '${(total - occupied)} of $total',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue[500],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.orange;
      case TableStatus.reserved:
        return Colors.blue;
      case TableStatus.merged:
        return Colors.purple;
      case TableStatus.cleaning:
        return Colors.brown;
    }
  }
}
