import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter/material.dart';

/// Inventory Dashboard Screen
/// Shows overview of inventory status with key metrics and alerts
class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  late InventoryService _inventoryService;
  List<InventoryItem> _allInventory = [];
  List<InventoryItem> _lowStockItems = [];
  List<InventoryItem> _outOfStockItems = [];

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService();
    _loadInventoryData();
  }

  void _loadInventoryData() {
    setState(() {
      _allInventory = _inventoryService.getAllInventory();
      _lowStockItems = _inventoryService.getLowStockItems();
      _outOfStockItems = _inventoryService.getOutOfStockItems();
    });
  }

  double _calculateTotalValue() {
    return _allInventory.fold(0.0, (sum, item) => sum + item.inventoryValue);
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _calculateTotalValue();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventoryData,
            tooltip: 'Refresh Inventory',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards Row
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
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildKPICard(
                      title: 'Total Items',
                      value: _allInventory.length.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _buildKPICard(
                      title: 'Low Stock',
                      value: _lowStockItems.length.toString(),
                      icon: Icons.warning_amber,
                      color: Colors.orange,
                    ),
                    _buildKPICard(
                      title: 'Out of Stock',
                      value: _outOfStockItems.length.toString(),
                      icon: Icons.error,
                      color: Colors.red,
                    ),
                    _buildKPICard(
                      title: 'Total Value',
                      value: 'RM ${totalValue.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Alert Section
            if (_lowStockItems.isNotEmpty || _outOfStockItems.isNotEmpty) ...[
              Text(
                'Alerts & Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildAlertCard(),
              const SizedBox(height: 24),
            ],

            // Stock Status Distribution
            Text(
              'Stock Status Distribution',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildStatusDistribution(),
            const SizedBox(height: 24),

            // Low Stock Items Table
            Text(
              'Low Stock Items',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildLowStockTable(),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
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
                fontSize: 28,
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

  Widget _buildAlertCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_outOfStockItems.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '${_outOfStockItems.length} Items Out of Stock',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _outOfStockItems.take(3).map((item) {
                  return Chip(
                    label: Text(item.productName),
                    backgroundColor: Colors.red[100],
                  );
                }).toList(),
              ),
              if (_outOfStockItems.length > 3)
                Text(
                  '+ ${_outOfStockItems.length - 3} more',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 16),
            ],
            if (_lowStockItems.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${_lowStockItems.length} Items Low on Stock',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _lowStockItems.take(3).map((item) {
                  return Chip(
                    label: Text('${item.productName} (${item.currentQuantity} ${item.unit})'),
                    backgroundColor: Colors.orange[100],
                  );
                }).toList(),
              ),
              if (_lowStockItems.length > 3)
                Text(
                  '+ ${_lowStockItems.length - 3} more',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final outOfStock = _allInventory.where((i) => i.isOutOfStock).length;
    final lowStock = _allInventory.where((i) => i.isLowStock).length;
    final normal = _allInventory.where((i) => i.status == StockStatus.normal).length;
    final overstock = _allInventory.where((i) => i.status == StockStatus.overstock).length;

    final total = _allInventory.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusRow('Out of Stock', outOfStock, total, Colors.red),
            _buildStatusRow('Low Stock', lowStock, total, Colors.orange),
            _buildStatusRow('Normal', normal, total, Colors.green),
            _buildStatusRow('Overstock', overstock, total, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color) {
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
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

  Widget _buildLowStockTable() {
    if (_lowStockItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No low stock items',
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
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Current')),
            DataColumn(label: Text('Min Level')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: _lowStockItems.take(10).map((item) {
            return DataRow(cells: [
              DataCell(Text(item.productName)),
              DataCell(Text('${item.currentQuantity} ${item.unit}')),
              DataCell(Text('${item.minStockLevel} ${item.unit}')),
              DataCell(
                Chip(
                  label: Text(item.statusDisplay),
                  backgroundColor: item.isOutOfStock
                      ? Colors.red[100]
                      : Colors.orange[100],
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Stock',
                      onPressed: () => _showAddStockDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      tooltip: 'Create PO',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Create PO feature coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.inventory_2,
          label: 'Manage Stock',
          onTap: () {
            Navigator.of(context).pushNamed('/inventory/stock-management');
          },
        ),
        _buildActionButton(
          icon: Icons.shopping_cart,
          label: 'Purchase Orders',
          onTap: () {
            Navigator.of(context).pushNamed('/inventory/purchase-orders');
          },
        ),
        _buildActionButton(
          icon: Icons.history,
          label: 'Stock Movements',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock movements history coming soon')),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.assessment,
          label: 'Inventory Report',
          onTap: () {
            Navigator.of(context).pushNamed('/inventory/reports');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStockDialog(InventoryItem item) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController(text: 'Stock replenishment');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock - ${item.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${item.currentQuantity} ${item.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }

              // Add stock via service
              _inventoryService.addStock(
                item.productId,
                quantity,
                reason: reasonController.text,
              ).then((_) {
                Navigator.pop(context);
                _loadInventoryData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $quantity ${item.unit} to ${item.productName}')),
                );
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}
