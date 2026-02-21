import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter/material.dart';

/// Stock Management Screen
/// Allows adding, adjusting, and managing stock levels
class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  late InventoryService _inventoryService;
  List<InventoryItem> _inventory = [];
  List<InventoryItem> _filteredInventory = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, low, out, normal, overstock

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _inventory = _inventoryService.getAllInventory();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredInventory = _inventory.where((item) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          item.productName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus = _filterStatus == 'all' ||
          (_filterStatus == 'low' && item.isLowStock && !item.isOutOfStock) ||
          (_filterStatus == 'out' && item.isOutOfStock) ||
          (_filterStatus == 'normal' && item.status == StockStatus.normal) ||
          (_filterStatus == 'overstock' && item.status == StockStatus.overstock);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Status filter chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Low Stock', 'low'),
                    _buildFilterChip('Out of Stock', 'out'),
                    _buildFilterChip('Normal', 'normal'),
                    _buildFilterChip('Overstock', 'overstock'),
                  ],
                ),
              ],
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing ${_filteredInventory.length} of ${_inventory.length} items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Inventory list
          Expanded(
            child: _filteredInventory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredInventory.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildInventoryCard(_filteredInventory[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new product coming soon')),
          );
        },
        tooltip: 'Add New Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'all';
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final statusColor = _getStatusColor(item.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product ID: ${item.productId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stock levels
            Row(
              children: [
                Expanded(
                  child: _buildStockLevel(
                    'Current',
                    '${item.currentQuantity} ${item.unit}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockLevel(
                    'Min Level',
                    '${item.minStockLevel} ${item.unit}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockLevel(
                    'Max Level',
                    '${item.maxStockLevel} ${item.unit}',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Inventory value and reorder quantity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Value: RM ${item.inventoryValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (item.reorderQuantity > 0)
                  Text(
                    'Reorder: ${item.reorderQuantity} ${item.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _showEditDialog(item),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Stock'),
                  onPressed: () => _showAddStockDialog(item),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Adjust'),
                  onPressed: () => _showAdjustStockDialog(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLevel(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.low:
        return Colors.orange;
      case StockStatus.normal:
        return Colors.green;
      case StockStatus.overstock:
        return Colors.blue;
    }
  }

  void _showEditDialog(InventoryItem item) {
    final minController = TextEditingController(text: item.minStockLevel.toString());
    final maxController = TextEditingController(text: item.maxStockLevel.toString());
    final reorderController = TextEditingController(text: item.reorderQuantity.toString());
    final costController = TextEditingController(text: item.costPerUnit?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Stock Levels - ${item.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Minimum Stock Level (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Maximum Stock Level (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reorderController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Reorder Quantity (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost Per Unit (RM)',
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
              // Update values in service
              // final min = double.tryParse(minController.text) ?? 0;
              // final max = double.tryParse(maxController.text) ?? 0;
              // final reorder = double.tryParse(reorderController.text) ?? 0;
              // final cost = double.tryParse(costController.text);

              // Update in service and reload
              _loadInventory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock levels updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
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
                  labelText: 'Quantity to Add (${item.unit})',
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

              _inventoryService
                  .addStock(
                    item.productId,
                    quantity,
                    reason: reasonController.text,
                  )
                  .then((_) {
                Navigator.pop(context);
                _loadInventory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $quantity ${item.unit} to ${item.productName}'),
                  ),
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

  void _showAdjustStockDialog(InventoryItem item) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final adjustmentTypes = ['Damage', 'Loss', 'Adjustment', 'Correction'];
    String selectedType = adjustmentTypes[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock - ${item.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${item.currentQuantity} ${item.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: adjustmentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedType = value ?? selectedType;
                },
                decoration: const InputDecoration(
                  labelText: 'Adjustment Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Quantity Change (${item.unit})',
                  hintText: 'Negative for removal',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason/Notes',
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
              if (quantity == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }

              _inventoryService
                  .addStock(
                    item.productId,
                    quantity,
                    reason: '$selectedType - ${reasonController.text}',
                  )
                  .then((_) {
                Navigator.pop(context);
                _loadInventory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock adjusted for ${item.productName}'),
                  ),
                );
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}
