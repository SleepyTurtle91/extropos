import 'dart:async';

// Services
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/horizon/dialogs/inventory_add_product_dialog.dart';
import 'package:extropos/widgets/horizon/dialogs/inventory_delete_dialog.dart';
// Dialogs
import 'package:extropos/widgets/horizon/dialogs/inventory_quick_edit_dialog.dart';
import 'package:extropos/widgets/horizon/horizon_button.dart';
import 'package:extropos/widgets/horizon/horizon_colors.dart';
import 'package:extropos/widgets/horizon/horizon_data_table.dart';
// Horizon UI Imports
import 'package:extropos/widgets/horizon/horizon_layout.dart';
import 'package:extropos/widgets/horizon/horizon_status_cell.dart';
import 'package:extropos/widgets/horizon/horizon_table_cell.dart';
import 'package:flutter/material.dart';

part 'horizon_inventory_dialogs.dart';
part 'horizon_inventory_filters.dart';
part 'horizon_inventory_notifications.dart';
// Extensions (part files)
part 'horizon_inventory_operations.dart';
part 'horizon_inventory_pagination.dart';
part 'horizon_inventory_table.dart';

/// Horizon Inventory Grid Screen
/// 
/// Cloud-synced product inventory management with real-time updates.
class HorizonInventoryGridScreen extends StatefulWidget {
  const HorizonInventoryGridScreen({super.key});

  @override
  State<HorizonInventoryGridScreen> createState() => _HorizonInventoryGridScreenState();
}

class _HorizonInventoryGridScreenState extends State<HorizonInventoryGridScreen> {
  // Services
  late HorizonDataService _dataService;

  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRealtimeConnected = false;

  // Filter state
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'All';

  // Selection state
  final Set<String> _selectedProductIds = {};
  bool _selectAll = false;

  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalProducts = 0;
  bool _hasMorePages = false;

  // Search debounce
  Timer? _searchDebounceTimer;

  // Data
  List<String> categories = ['All'];
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> products = [];

  // Stock levels for filter
  final List<String> stockLevels = ['All', 'In Stock', 'Low Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    initializeAndLoadData();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _dataService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return HorizonLayout(
        breadcrumbs: const ['Inventory'],
        currentRoute: '/inventory',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return HorizonLayout(
        breadcrumbs: const ['Inventory'],
        currentRoute: '/inventory',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: HorizonColors.rose),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 24),
              HorizonButton(
                text: 'Retry',
                type: HorizonButtonType.primary,
                icon: Icons.refresh,
                onPressed: loadProducts,
              ),
            ],
          ),
        ),
      );
    }

    // Apply filters (client-side)
    final allFilteredProducts = products.where((p) {
      final name = (p['name'] ?? '').toString();
      final id = (p['id'] ?? '').toString();
      final categoryId = (p['category_id'] ?? '').toString();
      final status = (p['status'] ?? '').toString();
      
      final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery);
      
      final matchesCategory = _categoryFilter == 'All' || 
          allCategories.any((cat) => 
            cat['\$id'] == categoryId && cat['name'] == _categoryFilter
          );
      
      final matchesStock = _stockFilter == 'All' || status == _stockFilter;

      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    _totalProducts = allFilteredProducts.length;

    // Apply pagination
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    final filteredProducts = allFilteredProducts.sublist(
      startIndex,
      endIndex > allFilteredProducts.length ? allFilteredProducts.length : endIndex,
    );

    _hasMorePages = endIndex < allFilteredProducts.length;

    return HorizonLayout(
      breadcrumbs: const ['Inventory', 'Products'],
      currentRoute: '/inventory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title with real-time indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Inventory Management',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: HorizonColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isRealtimeConnected 
                              ? HorizonColors.electricIndigo.withOpacity(0.1)
                              : HorizonColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isRealtimeConnected 
                                ? HorizonColors.electricIndigo 
                                : HorizonColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isRealtimeConnected 
                                    ? HorizonColors.electricIndigo 
                                    : HorizonColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isRealtimeConnected 
                                    ? HorizonColors.electricIndigo 
                                    : HorizonColors.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your product stock and inventory levels',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HorizonColors.textSecondary,
                        ),
                  ),
                ],
              ),
              // Action buttons
              Row(
                children: [
                  HorizonButton(
                    text: 'Add Product',
                    type: HorizonButtonType.primary,
                    icon: Icons.add,
                    onPressed: showAddProductDialog,
                  ),
                  if (_selectedProductIds.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    HorizonButton(
                      text: 'Delete Selected (${_selectedProductIds.length})',
                      type: HorizonButtonType.secondary,
                      icon: Icons.delete,
                      onPressed: showBulkDeleteConfirmation,
                    ),
                    const SizedBox(width: 8),
                    HorizonButton(
                      text: 'Export to CSV',
                      type: HorizonButtonType.secondary,
                      icon: Icons.download,
                      onPressed: () => exportToCSV(getSelectedProducts()),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Filters (from extension)
          buildFiltersSection(),

          const SizedBox(height: 24),

          // Data Table (from extension)
          buildInventoryTable(filteredProducts),

          const SizedBox(height: 24),

          // Pagination (from extension)
          buildPaginationControls(),
        ],
      ),
    );
  }
}
