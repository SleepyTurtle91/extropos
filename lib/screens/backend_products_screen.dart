import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

part 'backend_products_screen_dialog.dart';
part 'backend_products_screen_ui.dart';

class BackendProductsScreen extends StatefulWidget {
  const BackendProductsScreen({super.key});

  @override
  State<BackendProductsScreen> createState() => _BackendProductsScreenState();
}

class _BackendProductsScreenState extends State<BackendProductsScreen> {
  final BackendProductServiceAppwrite _productService =
      BackendProductServiceAppwrite();
  final BackendCategoryServiceAppwrite _categoryService =
      BackendCategoryServiceAppwrite();

  final Set<String> _selectedProductIds = {};

  List<BackendProductModel> _allProducts = [];
  List<BackendProductModel> _filteredProducts = [];
  List<BackendCategoryModel> _categories = [];

  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  bool _isLoading = false;
  String? _errorMessage;

  static const int _pageSize = 12;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productService.fetchProducts(forceRefresh: true),
        _categoryService.fetchCategories(forceRefresh: true),
      ]);

      setState(() {
        _allProducts = results[0] as List<BackendProductModel>;
        _categories = results[1] as List<BackendCategoryModel>;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
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
    List<BackendProductModel> filtered = _allProducts;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(query) ||
                (product.sku?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    if (_selectedCategoryId != 'all') {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
      _currentPage = 0;
      _selectedProductIds.clear();
    });
  }

  List<BackendProductModel> _getPagedProducts() {
    final start = _currentPage * _pageSize;
    if (start >= _filteredProducts.length) return [];
    final end = (start + _pageSize).clamp(0, _filteredProducts.length);
    return _filteredProducts.sublist(start, end);
  }

  int get _totalPages {
    if (_filteredProducts.isEmpty) return 1;
    return (_filteredProducts.length / _pageSize).ceil();
  }

  Future<void> _confirmDelete(BackendProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Delete "${product.name}"? This will deactivate it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || product.id == null) return;
    setState(() => _isLoading = true);
    try {
      await _productService.deleteProduct(product.id!);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyBulkDeactivate() async {
    final targets = _allProducts
        .where((p) => p.id != null && _selectedProductIds.contains(p.id))
        .toList();

    if (targets.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      for (final product in targets) {
        await _productService.updateProduct(product.copyWith(isActive: false));
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bulk update failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Backend Products',
      subtitle: 'Cloud product management is coming soon.',
    );
    final currency = BusinessInfo.instance.currencySymbol;
    final pagedProducts = _getPagedProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _showProductDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedProductIds.isNotEmpty) _buildBulkActionsBar(),
          Padding(padding: const EdgeInsets.all(16), child: _buildFilters()),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : pagedProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 4;
                      if (constraints.maxWidth < 600) {
                        columns = 1;
                      } else if (constraints.maxWidth < 900) {
                        columns = 2;
                      } else if (constraints.maxWidth < 1200) {
                        columns = 3;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.35,
                        ),
                        itemCount: pagedProducts.length,
                        itemBuilder: (context, index) {
                          final product = pagedProducts[index];
                          return _buildProductCard(product, currency);
                        },
                      );
                    },
                  ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }
}
