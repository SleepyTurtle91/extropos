import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/screens/backend/dialogs/stock_adjustment_dialog.dart';
import 'package:extropos/screens/backend/dialogs/stock_take_dialog.dart';
import 'package:extropos/screens/backend/widgets/inventory_card_widget.dart';
import 'package:extropos/screens/backend/widgets/low_stock_alert_widget.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/phase1_inventory_service.dart';
import 'package:flutter/material.dart';

/// Inventory Dashboard Screen for Backend Flavor
///
/// Displays inventory status, stock levels, and provides stock management tools.
/// Features quick adjustments, stock takes, and low stock alerts.
///
/// Permission Requirements:
/// - VIEW_INVENTORY (to see inventory)
/// - ADJUST_INVENTORY (to adjust stock)
/// - VIEW_STOCK_MOVEMENTS (to see movements)
class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreenState> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  late Phase1InventoryService _inventoryService;
  late AccessControlService _accessControl;

  List<InventoryModel> _allInventory = [];
  List<InventoryModel> _filteredInventory = [];

  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all', 'normal', 'low', 'out', 'overstock'

  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  static const int _pageSize = 15;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _inventoryService = Phase1InventoryService.instance;
    _accessControl = AccessControlService.instance;

    // Listen for inventory changes
    _inventoryService.addListener(_onInventoryChanged);

    // Load initial data
    _loadInventory();
  }

  @override
  void dispose() {
    _inventoryService.removeListener(_onInventoryChanged);
    super.dispose();
  }

  void _onInventoryChanged() {
    if (mounted) {
      _loadInventory();
    }
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inventory = await _inventoryService.getAllInventory();
      setState(() {
        _allInventory = inventory;
        _applyFilters();
      });
    } catch (e) {
      print('❌ Error loading inventory: $e');
      setState(() {
        _errorMessage = 'Failed to load inventory: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<InventoryModel> filtered = _allInventory;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((item) =>
              item.productName.toLowerCase().contains(query) ||
              (item.sku?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Status filter
    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((item) {
        final status = _getInventoryStatus(item);
        return status == _selectedStatusFilter;
      }).toList();
    }

    setState(() {
      _filteredInventory = filtered;
      _currentPage = 0;
    });
  }

  String _getInventoryStatus(InventoryModel item) {
    if (item.isOutOfStock()) return 'out';
    if (item.isLowStock()) return 'low';
    if (item.isOverstock()) return 'overstock';
    return 'normal';
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatusFilter = value ?? 'all';
    });
    _applyFilters();
  }

  Future<void> _showStockAdjustmentDialog(InventoryModel inventory) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StockAdjustmentDialog(inventory: inventory),
    );

    if (result == true) {
      await _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Stock adjusted successfully')),
        );
      }
    }
  }

  Future<void> _showStockTakeDialog(InventoryModel inventory) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StockTakeDialog(inventory: inventory),
    );

    if (result == true) {
      await _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Stock take completed')),
        );
      }
    }
  }

  // Get paginated inventory
  List<InventoryModel> get _paginatedInventory {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    if (start >= _filteredInventory.length) return [];
    return _filteredInventory.sublist(start, min(end, _filteredInventory.length));
  }

  int get _totalPages => (_filteredInventory.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final lowStockItems = _allInventory.where((i) => i.isLowStock()).toList();
    final outOfStockItems = _allInventory.where((i) => i.isOutOfStock()).toList();
    final totalValue = _inventoryService.getTotalInventoryValue(_allInventory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Total Items',
                  value: _allInventory.length.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  title: 'Low Stock',
                  value: lowStockItems.length.toString(),
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  title: 'Out of Stock',
                  value: outOfStockItems.length.toString(),
                  icon: Icons.error,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  title: 'Total Value',
                  value: 'RM ${totalValue.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          // Low Stock Alerts (if any)
          if (lowStockItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${lowStockItems.length} items low on stock',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: lowStockItems.take(5).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: LowStockAlertWidget(inventory: item),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Search & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by product name or SKU...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _selectedStatusFilter,
                  isExpanded: true,
                  onChanged: _onStatusFilterChanged,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal Stock')),
                    DropdownMenuItem(value: 'low', child: Text('Low Stock')),
                    DropdownMenuItem(value: 'out', child: Text('Out of Stock')),
                    DropdownMenuItem(value: 'overstock', child: Text('Overstock')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Inventory List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInventory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredInventory.isEmpty
                        ? const Center(child: Text('No inventory items found'))
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                    ),
                                    itemCount: _paginatedInventory.length,
                                    itemBuilder: (context, index) {
                                      final item = _paginatedInventory[index];
                                      return InventoryCardWidget(
                                        inventory: item,
                                        onAdjustStock: (canAdjust) async {
                                          if (canAdjust) {
                                            await _showStockAdjustmentDialog(item);
                                          }
                                        },
                                        onStockTake: (canAdjust) async {
                                          if (canAdjust) {
                                            await _showStockTakeDialog(item);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                                // Pagination
                                if (_totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: _currentPage > 0
                                              ? () {
                                                  setState(() => _currentPage--);
                                                }
                                              : null,
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        Text(
                                          'Page ${_currentPage + 1} of $_totalPages',
                                        ),
                                        IconButton(
                                          onPressed:
                                              _currentPage < _totalPages - 1
                                                  ? () {
                                                      setState(() => _currentPage++);
                                                    }
                                                  : null,
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;
