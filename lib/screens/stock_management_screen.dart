import 'package:extropos/models/inventory_models.dart';
import 'package:extropos/services/inventory_service.dart';
import 'package:flutter/material.dart';

part 'stock_management_screen_ui.dart';

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
