part of 'horizon_inventory_grid_screen.dart';

/// Extension containing dialog operations
extension HorizonInventoryDialogs on _HorizonInventoryGridScreenState {
  /// Show quick edit dialog for product
  void showQuickEditDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => InventoryQuickEditDialog(
        product: product,
        dataService: _dataService,
        onSuccess: () {
          showSuccessToast('Product updated successfully!');
          loadProducts();
        },
        onError: (message) {
          showErrorToast(message);
        },
      ),
    );
  }

  /// Show delete confirmation dialog
  void showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => InventoryDeleteDialog(
        product: product,
        dataService: _dataService,
        onSuccess: () {
          showSuccessToast('Product deleted successfully!');
          loadProducts();
        },
        onError: (message) {
          showErrorToast(message);
        },
      ),
    );
  }

  /// Show add product dialog
  void showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => InventoryAddProductDialog(
        categories: categories,
        dataService: _dataService,
        onSuccess: () {
          showSuccessToast('Product created successfully!');
          loadProducts();
        },
        onError: (message) {
          showErrorToast(message);
        },
      ),
    );
  }
}
