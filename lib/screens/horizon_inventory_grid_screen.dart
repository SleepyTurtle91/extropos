import 'dart:async';
import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/appwrite_service.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:extropos/widgets/horizon_button.dart';
import 'package:extropos/widgets/horizon_data_table.dart';
import 'package:extropos/widgets/horizon_layout.dart';
import 'package:flutter/material.dart';

/// Horizon Admin - Inventory Grid Screen
/// Advanced product inventory management with sorting, filtering, and quick edit
class HorizonInventoryGridScreen extends StatefulWidget {
  const HorizonInventoryGridScreen({super.key});

  @override
  State<HorizonInventoryGridScreen> createState() =>
      _HorizonInventoryGridScreenState();
}

class _HorizonInventoryGridScreenState
    extends State<HorizonInventoryGridScreen> {
  final HorizonDataService _dataService = HorizonDataService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRealtimeConnected = false;

  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'All';
  
  // Bulk selection state
  final Set<String> _selectedProductIds = {};
  bool _selectAll = false;
  
  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 50;
  int _totalProducts = 0;
  bool _hasMorePages = true;
  
  // Search debouncing
  Timer? _searchDebounceTimer;

  List<String> categories = ['All'];
  final stockLevels = ['All', 'In Stock', 'Low Stock', 'Out of Stock'];

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> allCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // Initialize Appwrite client
      final appwriteService = AppwriteService.instance;
      if (!appwriteService.isInitialized) {
        await appwriteService.initialize();
      }

      // Initialize data service
      if (appwriteService.client != null) {
        await _dataService.initialize(appwriteService.client!);
      } else {
        throw Exception('Appwrite client is null');
      }

      // Load products
      await _loadProducts();
      
      // Load categories for filter dropdown
      await _loadCategories();
      
      // Subscribe to real-time product updates
      _subscribeToProductUpdates();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get products based on filters
      String? categoryId;
      if (_categoryFilter != 'All') {
        // Map category name to ID
        final selectedCategory = allCategories.firstWhere(
          (cat) => cat['name'] == _categoryFilter,
          orElse: () => <String, dynamic>{},
        );
        categoryId = selectedCategory['\$id'] as String?;
      }

      String? stockStatus;
      if (_stockFilter != 'All') {
        stockStatus = _stockFilter;
      }

      // Load products from Appwrite
      List<Map<String, dynamic>> loadedProducts;
      if (stockStatus != null) {
        loadedProducts = await _dataService.getInventory(stockStatus: stockStatus);
      } else {
        loadedProducts = await _dataService.getProducts(
          categoryId: categoryId,
          searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        );
      }

      setState(() {
        products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await _dataService.getCategories();
      setState(() {
        allCategories = loadedCategories;
        categories = ['All'] + loadedCategories.map((c) => (c['name'] ?? '').toString()).toList();
      });
    } catch (e) {
      print('Failed to load categories: $e');
      // Keep default categories if loading fails
    }
  }

  void _subscribeToProductUpdates() {
    // Subscribe to product changes for live inventory updates
    _dataService.subscribeToProductChanges((response) {
      print('🔄 Inventory: Received product update');
      // Reload products when changes detected
      _loadProducts();
    });
    
    setState(() {
      _isRealtimeConnected = true;
    });
  }

  @override
  void dispose() {
    // Cancel search debounce timer
    _searchDebounceTimer?.cancel();
    // Unsubscribe from real-time updates
    _dataService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComingSoonPlaceholder(
      title: 'Inventory Grid',
      subtitle: 'Cloud inventory management coming soon',
    );
    if (_isLoading) {
      return HorizonLayout(
        breadcrumbs: const ['Inventory'],
        currentRoute: '/inventory',
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading inventory...'),
            ],
          ),
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
                onPressed: _loadProducts,
              ),
            ],
          ),
        ),
      );
    }

    final allFilteredProducts = products.where((p) {
      final name = (p['name'] ?? '').toString();
      final id = (p['id'] ?? '').toString();
      final categoryId = (p['category_id'] ?? '').toString();
      final status = (p['status'] ?? '').toString();
      
      final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery);
      
      // Match category by finding the category name from ID
      final matchesCategory = _categoryFilter == 'All' || 
          allCategories.any((cat) => 
            cat['\$id'] == categoryId && cat['name'] == _categoryFilter
          );
      
      final matchesStock = _stockFilter == 'All' || status == _stockFilter;

      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    // Update total count
    _totalProducts = allFilteredProducts.length;

    // Apply pagination
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    final filteredProducts = allFilteredProducts.sublist(
      startIndex,
      endIndex > allFilteredProducts.length ? allFilteredProducts.length : endIndex,
    );

    // Check if there are more pages
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
                      // Real-time connection indicator
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
              HorizonButton(
                text: 'Add Product',
                type: HorizonButtonType.primary,
                icon: Icons.add,
                onPressed: _showAddProductDialog,
              ),
              if (_selectedProductIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                HorizonButton(
                  text: 'Delete Selected (${_selectedProductIds.length})',
                  type: HorizonButtonType.secondary,
                  icon: Icons.delete,
                  onPressed: _showBulkDeleteConfirmation,
                ),
                const SizedBox(width: 8),
                HorizonButton(
                  text: 'Export to CSV',
                  type: HorizonButtonType.secondary,
                  icon: Icons.download,
                  onPressed: () => _exportToCSV(_getSelectedProducts()),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: HorizonColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HorizonColors.border,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0; // Reset pagination on search
                      });
                      // Debounce search - wait 500ms before loading
                      _searchDebounceTimer?.cancel();
                      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                        _loadProducts();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Category Filter
              _buildFilterDropdown('Category', _categoryFilter, categories, (value) {
                setState(() {
                  _categoryFilter = value;
                  _currentPage = 0; // Reset pagination on filter change
                });
                _loadProducts(); // Reload with new filter
              }),

              const SizedBox(width: 12),

              // Stock Status Filter
              _buildFilterDropdown('Stock Status', _stockFilter, stockLevels, (value) {
                setState(() {
                  _stockFilter = value;
                  _currentPage = 0; // Reset pagination on filter change
                });
                _loadProducts(); // Reload with new filter
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Data Table
          HorizonDataTable(
            title: 'Products (${filteredProducts.length})',
            columns: [
              DataColumn(
                label: SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: _selectAll,
                    onChanged: (value) {
                      setState(() {
                        _selectAll = value ?? false;
                        if (_selectAll) {
                          _selectedProductIds.addAll(
                            filteredProducts.map((p) => (p['\$id'] ?? p['id']).toString())
                          );
                        } else {
                          _selectedProductIds.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              const DataColumn(
                label: HorizonTableCell('SKU'),
              ),
              const DataColumn(
                label: HorizonTableCell('Product Name'),
              ),
              const DataColumn(
                label: HorizonTableCell('Category'),
              ),
              const DataColumn(
                label: HorizonTableCell('Price', isNumeric: true),
              ),
              const DataColumn(
                label: HorizonTableCell('Quantity', isNumeric: true),
              ),
              const DataColumn(
                label: HorizonTableCell('Min Stock', isNumeric: true),
              ),
              const DataColumn(
                label: HorizonTableCell('Status'),
              ),
              const DataColumn(
                label: HorizonTableCell('Actions'),
              ),
            ],
            rows: filteredProducts.map((product) {
              final id = (product['\$id'] ?? product['id'] ?? '').toString();
              final name = (product['name'] ?? '').toString();
              final category = (product['category'] ?? '').toString();
              final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
              final status = (product['status'] ?? '').toString();
              final minStockStr = (product['minStock'] ?? '0').toString();
              
              final quantity = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
              final minStock = int.tryParse(minStockStr) ?? 0;
              final stockPercent = minStock > 0 ? (quantity / minStock * 100).clamp(0, 100) : 100;

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 24,
                      child: Checkbox(
                        value: _selectedProductIds.contains(id),
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedProductIds.add(id);
                            } else {
                              _selectedProductIds.remove(id);
                              _selectAll = false;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  DataCell(HorizonTableCell(id)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: HorizonColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: HorizonColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        HorizonTableCell(name),
                      ],
                    ),
                  ),
                  DataCell(HorizonTableCell(category)),
                  DataCell(HorizonTableCell('RM ${price.toStringAsFixed(2)}', isNumeric: true)),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HorizonTableCell(
                          quantity.toString(),
                          isNumeric: true,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: 60,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: stockPercent / 100,
                              backgroundColor: HorizonColors.border,
                              valueColor: AlwaysStoppedAnimation(
                                stockPercent > 50 ? HorizonColors.emerald : 
                                stockPercent > 25 ? HorizonColors.amber :
                                HorizonColors.rose,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(HorizonTableCell(minStockStr, isNumeric: true)),
                  DataCell(HorizonStatusCell(status)),
                  // Actions column
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quick edit button
                        Tooltip(
                          message: 'Quick Edit',
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: HorizonColors.electricIndigo,
                            onPressed: () => _showQuickEditDialog(product),
                            splashRadius: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: HorizonColors.rose,
                            onPressed: () => _showDeleteConfirmation(product),
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Pagination Controls
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalProducts / _pageSize).ceil();
    final startItem = _currentPage * _pageSize + 1;
    final endItem = (_currentPage + 1) * _pageSize;
    final actualEnd = endItem > _totalProducts ? _totalProducts : endItem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem to $actualEnd of $_totalProducts products',
          style: const TextStyle(
            fontSize: 13,
            color: HorizonColors.textSecondary,
          ),
        ),
        Row(
          children: [
            HorizonButton(
              text: 'Previous',
              type: HorizonButtonType.secondary,
              onPressed: _currentPage > 0 ? () {
                setState(() {
                  _currentPage--;
                });
                _loadProducts();
              } : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HorizonColors.surfaceGrey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            HorizonButton(
              text: 'Next',
              type: HorizonButtonType.secondary,
              onPressed: _hasMorePages ? () {
                setState(() {
                  _currentPage++;
                });
                _loadProducts();
              } : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HorizonColors.surfaceGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HorizonColors.border, width: 1),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }

  void _showQuickEditDialog(Map<String, dynamic> product) {
    final productId = product['\$id'] ?? product['id'];
    final currentPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    final currentQty = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

    // Create local controllers for this dialog
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
    final qtyController = TextEditingController(text: currentQty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: HorizonColors.electricIndigo),
            const SizedBox(width: 8),
            Expanded(child: Text('Edit: ${product['name'] ?? 'Product'}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Price (RM)', priceController, 'Enter price'),
              const SizedBox(height: 16),
              _buildEditField('Quantity', qtyController, 'Enter quantity'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              priceController.dispose();
              qtyController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              final newQty = int.tryParse(qtyController.text);

              if (newPrice == null || newQty == null) {
                _showErrorToast('Invalid input. Please check your entries.');
                return;
              }

              // Update product
              final success = await _dataService.updateProduct(productId, {
                'price': newPrice,
                'quantity': newQty,
              });

              priceController.dispose();
              qtyController.dispose();

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                _showSuccessToast('Product updated successfully!');
                _loadProducts(); // Refresh list
              } else {
                _showErrorToast('Failed to update product. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    final productId = product['\$id'] ?? product['id'];
    final productName = product['name'] ?? 'Product';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: HorizonColors.rose),
            const SizedBox(width: 8),
            const Text('Delete Product'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$productName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HorizonColors.rose,
            ),
            onPressed: () async {
              final success = await _dataService.deleteProduct(productId);

              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                _showSuccessToast('Product deleted successfully!');
                _loadProducts(); // Refresh list
              } else {
                _showErrorToast('Failed to delete product. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    String selectedCategory = 'Beverages';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: HorizonColors.emerald),
            const SizedBox(width: 8),
            const Text('Add New Product'),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField('Product Name', nameController, 'Enter product name'),
                const SizedBox(height: 16),
                _buildEditField('Price (RM)', priceController, 'Enter price'),
                const SizedBox(height: 16),
                _buildEditField('Initial Quantity', qtyController, 'Enter quantity'),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: HorizonColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: HorizonColors.border, width: 1),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: categories
                          .where((c) => c != 'All')
                          .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nameController.dispose();
              priceController.dispose();
              qtyController.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HorizonColors.emerald,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final qty = int.tryParse(qtyController.text);

              if (name.isEmpty || price == null || qty == null) {
                _showErrorToast('Please fill in all fields with valid data.');
                return;
              }

              // Create new product using Appwrite API
              try {
                final success = await _dataService.createProduct({
                  'name': name,
                  'category': selectedCategory,
                  'price': price,
                  'quantity': qty,
                  'minStock': 5, // Default min stock
                  'status': 'Active',
                });

                if (!mounted) return;

                if (success) {
                  Navigator.pop(context);
                  nameController.dispose();
                  priceController.dispose();
                  qtyController.dispose();

                  _showSuccessToast('Product "$name" created successfully!');
                  _loadProducts(); // Refresh list
                } else {
                  _showErrorToast('Failed to create product. Please try again.');
                }
              } catch (e) {
                if (!mounted) return;
                _showErrorToast('Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          keyboardType: label.contains('Price') || label.contains('Quantity')
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
        ),
      ],
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HorizonColors.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HorizonColors.rose,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BULK OPERATIONS ====================

  List<Map<String, dynamic>> _getSelectedProducts() {
    return products.where((p) {
      final id = (p['\$id'] ?? p['id']).toString();
      return _selectedProductIds.contains(id);
    }).toList();
  }

  void _showBulkDeleteConfirmation() {
    final selectedCount = _selectedProductIds.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: HorizonColors.rose),
            const SizedBox(width: 8),
            const Text('Delete Selected Products'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $selectedCount product(s)?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: Text('Delete $selectedCount Product(s)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HorizonColors.rose,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                int deleted = 0;
                for (final productId in _selectedProductIds) {
                  final success = await _dataService.deleteProduct(productId);
                  if (success) deleted++;
                }

                setState(() {
                  _selectedProductIds.clear();
                  _selectAll = false;
                });

                _showSuccessToast('$deleted product(s) deleted successfully!');
                _loadProducts();
              } catch (e) {
                _showErrorToast('Error deleting products: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _exportToCSV(List<Map<String, dynamic>> selectedProducts) {
    try {
      // Create CSV header
      final csvHeader = [
        'ID',
        'Product Name',
        'Category',
        'Price (RM)',
        'Quantity',
        'Min Stock',
        'Status',
      ].join(',');

      // Create CSV rows
      final List<String> csvRows = [csvHeader];
      for (final product in selectedProducts) {
        final row = [
          (product['\$id'] ?? product['id'] ?? '').toString(),
          (product['name'] ?? '').toString(),
          (product['category'] ?? '').toString(),
          (product['price'] ?? '0').toString(),
          (product['quantity'] ?? '0').toString(),
          (product['minStock'] ?? '0').toString(),
          (product['status'] ?? '').toString(),
        ].map((cell) => '"$cell"').join(',');
        
        csvRows.add(row);
      }

      final csvData = csvRows.join('\n');
      
      // Log CSV data and show success
      print('📊 CSV Export Generated: ${csvData.split('\n').length} rows');
      print('📄 Data:\n$csvData');
      
      _showSuccessToast('CSV data generated! (${selectedProducts.length} products - check console)');
    } catch (e) {
      _showErrorToast('Error exporting CSV: $e');
    }
  }
}
