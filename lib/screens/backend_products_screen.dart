import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

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

  Future<void> _showProductDialog({BackendProductModel? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final skuController = TextEditingController(text: product?.sku ?? '');
    final basePriceController = TextEditingController(
      text: product?.basePrice.toStringAsFixed(2) ?? '',
    );
    final costPriceController = TextEditingController(
      text: product?.costPrice?.toStringAsFixed(2) ?? '',
    );
    final imageUrlController = TextEditingController(
      text: product?.imageUrl ?? '',
    );

    String selectedCategoryId =
        product?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id ?? '' : '');
    bool isActive = product?.isActive ?? true;
    bool trackInventory = product?.trackInventory ?? true;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<BackendProductModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Price *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Base price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId.isEmpty
                          ? null
                          : selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategoryId = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      title: const Text('Active'),
                      onChanged: (value) => isActive = value,
                    ),
                    SwitchListTile(
                      value: trackInventory,
                      title: const Text('Track Inventory'),
                      onChanged: (value) => trackInventory = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final now = DateTime.now().millisecondsSinceEpoch;
                final category = _categories.firstWhere(
                  (c) => c.id == selectedCategoryId,
                );

                final newProduct = BackendProductModel(
                  id: product?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  sku: skuController.text.trim().isEmpty
                      ? null
                      : skuController.text.trim(),
                  basePrice: double.parse(basePriceController.text),
                  costPrice: costPriceController.text.trim().isEmpty
                      ? null
                      : double.parse(costPriceController.text),
                  categoryId: selectedCategoryId,
                  categoryName: category.name,
                  isActive: isActive,
                  trackInventory: trackInventory,
                  imageUrl: imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                  createdAt: product?.createdAt ?? now,
                  updatedAt: now,
                );

                Navigator.pop(context, newProduct);
              },
              child: Text(product == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      if (product == null) {
        await _productService.createProduct(result);
      } else {
        await _productService.updateProduct(result);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final children = [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Categories'),
                ),
                ..._categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _selectedCategoryId = value;
                _applyFilters();
              },
            ),
          ),
        ];

        return isNarrow
            ? Column(
                children: [
                  children[0],
                  const SizedBox(height: 12),
                  children[2],
                ],
              )
            : Row(children: children);
      },
    );
  }

  Widget _buildProductCard(BackendProductModel product, String currency) {
    final margin = (product.basePrice - (product.costPrice ?? 0)).toDouble();
    final marginPct = product.basePrice == 0
        ? 0
        : (margin / product.basePrice) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Checkbox(
                  value: _selectedProductIds.contains(product.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true && product.id != null) {
                        _selectedProductIds.add(product.id!);
                      } else if (product.id != null) {
                        _selectedProductIds.remove(product.id!);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.sku ?? 'No SKU',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              product.categoryName ?? 'Uncategorized',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '$currency ${product.basePrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Margin: $currency ${margin.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(product.isActive),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _showProductDialog(product: product),
                  icon: const Icon(Icons.edit, size: 18),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => _confirmDelete(product),
                  icon: const Icon(Icons.delete, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Page ${_currentPage + 1} of $_totalPages'),
          const Spacer(),
          IconButton(
            onPressed: _currentPage == 0
                ? null
                : () => setState(() => _currentPage -= 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentPage >= _totalPages - 1
                ? null
                : () => setState(() => _currentPage += 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      width: double.infinity,
      color: Colors.blueGrey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_selectedProductIds.length} selected'),
          const Spacer(),
          TextButton.icon(
            onPressed: _isLoading ? null : _applyBulkDeactivate,
            icon: const Icon(Icons.visibility_off, size: 18),
            label: const Text('Deactivate'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() => _selectedProductIds.clear());
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
