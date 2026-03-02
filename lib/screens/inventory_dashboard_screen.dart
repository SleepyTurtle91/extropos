import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter/material.dart';

part 'inventory_dashboard_ui.dart';

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
}
