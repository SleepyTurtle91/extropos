part of 'horizon_inventory_grid_screen.dart';

/// Extension containing data operations for horizon inventory
extension HorizonInventoryOperations on _HorizonInventoryGridScreenState {
  /// Initialize Appwrite and load data
  Future<void> initializeAndLoadData() async {
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
      await loadProducts();
      
      // Load categories for filter dropdown
      await loadCategories();
      
      // Subscribe to real-time product updates
      subscribeToProductUpdates();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  /// Load products from Appwrite with current filters
  Future<void> loadProducts() async {
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

  /// Load categories for filter dropdown
  Future<void> loadCategories() async {
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

  /// Subscribe to real-time product updates
  void subscribeToProductUpdates() {
    // Subscribe to product changes for live inventory updates
    _dataService.subscribeToProductChanges((response) {
      print('🔄 Inventory: Received product update');
      // Reload products when changes detected
      loadProducts();
    });
    
    setState(() {
      _isRealtimeConnected = true;
    });
  }

  /// Get selected products
  List<Map<String, dynamic>> getSelectedProducts() {
    return products.where((p) {
      final id = (p['\$id'] ?? p['id']).toString();
      return _selectedProductIds.contains(id);
    }).toList();
  }

  /// Perform bulk delete operation
  void showBulkDeleteConfirmation() {
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

                showSuccessToast('$deleted product(s) deleted successfully!');
                loadProducts();
              } catch (e) {
                showErrorToast('Error deleting products: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  /// Export selected products to CSV
  void exportToCSV(List<Map<String, dynamic>> selectedProducts) {
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
      
      showSuccessToast('CSV exported to console (${csvRows.length - 1} products)');
    } catch (e) {
      showErrorToast('Failed to export CSV: $e');
    }
  }
}
