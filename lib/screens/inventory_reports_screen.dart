import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter/material.dart';

/// Inventory Reports Screen
/// Comprehensive reporting and analysis of inventory performance
class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen> {
  late InventoryService _inventoryService;
  List<InventoryItem> _inventory = [];
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _inventory = _inventoryService.getAllInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _inventory.fold(0.0, (sum, item) => sum + item.inventoryValue);
    final avgValue = _inventory.isNotEmpty ? totalValue / _inventory.length : 0.0;
    final topValueItems = [..._inventory]
      ..sort((a, b) => b.inventoryValue.compareTo(a.inventoryValue));
    final lowStockCount = _inventory.where((i) => i.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _selectDateRange(),
                      tooltip: 'Change dates',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary KPIs
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 4;
                if (constraints.maxWidth < 600) columns = 1;
                else if (constraints.maxWidth < 900) columns = 2;
                else if (constraints.maxWidth < 1200) columns = 3;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildReportCard(
                      title: 'Total Items',
                      value: _inventory.length.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _buildReportCard(
                      title: 'Total Value',
                      value: 'RM ${totalValue.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _buildReportCard(
                      title: 'Average Value',
                      value: 'RM ${avgValue.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                    _buildReportCard(
                      title: 'Low Stock Items',
                      value: lowStockCount.toString(),
                      icon: Icons.warning_amber,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Top Value Items
            Text(
              'Top 10 High-Value Items',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildTopValueItemsTable(topValueItems),
            const SizedBox(height: 24),

            // Low Stock Items Report
            Text(
              'Low Stock Items Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildLowStockReport(),
            const SizedBox(height: 24),

            // Stock Status Summary
            Text(
              'Stock Status Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildStatusSummary(),
            const SizedBox(height: 24),

            // Movement History
            Text(
              'Recent Stock Movements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildMovementHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopValueItemsTable(List<InventoryItem> topItems) {
    if (topItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No items found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Rank')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Unit Cost')),
            DataColumn(label: Text('Total Value')),
            DataColumn(label: Text('% of Total')),
          ],
          rows: topItems.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            final totalValue =
                _inventory.fold(0.0, (sum, i) => sum + i.inventoryValue);
            final percentage = totalValue > 0 ? (item.inventoryValue / totalValue * 100) : 0.0;

            return DataRow(cells: [
              DataCell(Text(index.toString())),
              DataCell(Text(item.productName)),
              DataCell(Text('${item.currentQuantity} ${item.unit}')),
              DataCell(Text('RM ${(item.costPerUnit ?? 0).toStringAsFixed(2)}')),
              DataCell(Text('RM ${item.inventoryValue.toStringAsFixed(2)}')),
              DataCell(
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLowStockReport() {
    final lowStockItems = _inventory.where((i) => i.isLowStock).toList();

    if (lowStockItems.isEmpty) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 8),
                Text(
                  'No low stock items!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Current')),
            DataColumn(label: Text('Min Level')),
            DataColumn(label: Text('Shortage')),
            DataColumn(label: Text('Reorder Qty')),
            DataColumn(label: Text('Status')),
          ],
          rows: lowStockItems.map((item) {
            final shortage = item.minStockLevel - item.currentQuantity;

            return DataRow(cells: [
              DataCell(Text(item.productName)),
              DataCell(Text('${item.currentQuantity} ${item.unit}')),
              DataCell(Text('${item.minStockLevel} ${item.unit}')),
              DataCell(
                Text(
                  '${shortage.toStringAsFixed(1)} ${item.unit}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(Text('${item.reorderQuantity} ${item.unit}')),
              DataCell(
                Chip(
                  label: Text(item.statusDisplay),
                  backgroundColor:
                      item.isOutOfStock ? Colors.red[100] : Colors.orange[100],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    final outOfStock = _inventory.where((i) => i.isOutOfStock).length;
    final lowStock = _inventory.where((i) => i.isLowStock && !i.isOutOfStock).length;
    final normal = _inventory.where((i) => i.status == StockStatus.normal).length;
    final overstock = _inventory.where((i) => i.status == StockStatus.overstock).length;

    final total = _inventory.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Out of Stock', outOfStock, total, Colors.red),
            _buildSummaryRow('Low Stock', lowStock, total, Colors.orange),
            _buildSummaryRow('Normal', normal, total, Colors.green),
            _buildSummaryRow('Overstock', overstock, total, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$count ($percentage.toStringAsFixed(1)%)',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementHistory() {
    List<StockMovement> allMovements = [];
    for (var item in _inventory) {
      allMovements.addAll(item.movements);
    }

    // Sort by date descending
    allMovements.sort((a, b) => b.date.compareTo(a.date));

    if (allMovements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No stock movements recorded',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Reason')),
            DataColumn(label: Text('User')),
          ],
          rows: allMovements.take(20).map((movement) {
            return DataRow(cells: [
              DataCell(Text(_formatDate(movement.date))),
              DataCell(
                Chip(
                  label: Text(movement.type),
                  backgroundColor: _getMovementTypeColor(movement.type),
                ),
              ),
              DataCell(
                Text(
                  movement.quantity.toStringAsFixed(1),
                  style: TextStyle(
                    color: movement.quantity > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(Text(movement.reason)),
              DataCell(Text(movement.userId ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Color _getMovementTypeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.red[100]!;
      case 'purchase':
        return Colors.green[100]!;
      case 'adjustment':
        return Colors.blue[100]!;
      case 'damage':
        return Colors.red[100]!;
      case 'transfer':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (newRange != null) {
      setState(() {
        _dateRange = newRange;
      });
    }
  }
}
