import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';
import 'package:extropos/widgets/coming_soon_placeholder.dart';
import 'package:flutter/material.dart';

class BackendCategoriesScreen extends StatefulWidget {
  const BackendCategoriesScreen({super.key});

  @override
  State<BackendCategoriesScreen> createState() =>
      _BackendCategoriesScreenState();
}

class _BackendCategoriesScreenState extends State<BackendCategoriesScreen> {
  final BackendCategoryServiceAppwrite _categoryService =
      BackendCategoryServiceAppwrite();
  final BackendProductServiceAppwrite _productService =
      BackendProductServiceAppwrite();

  List<BackendCategoryModel> _categories = [];
  List<BackendProductModel> _products = [];
  String _searchQuery = '';
  bool _showInactive = false;

  bool _isLoading = false;
  String? _errorMessage;

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
        _categoryService.fetchCategories(forceRefresh: true),
        _productService.fetchProducts(forceRefresh: true),
      ]);
      setState(() {
        _categories = results[0] as List<BackendCategoryModel>;
        _products = results[1] as List<BackendProductModel>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<BackendCategoryModel> _filteredCategories() {
    var items = _categories;
    if (!_showInactive) {
      items = items.where((c) => c.isActive).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((c) => c.name.toLowerCase().contains(query)).toList();
    }
    return items;
  }

  Map<String, int> _buildProductCounts() {
    final counts = <String, int>{};
    for (final product in _products) {
      counts[product.categoryId] = (counts[product.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _showCategoryDialog({BackendCategoryModel? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final sortOrderController = TextEditingController(
      text: category?.sortOrder.toString() ?? '0',
    );
    final colorController = TextEditingController(
      text: category?.colorHex ?? '',
    );
    final taxRateController = TextEditingController(
      text: category?.defaultTaxRate?.toString() ?? '',
    );

    bool isActive = category?.isActive ?? true;
    String? parentCategoryId = category?.parentCategoryId;
    String? iconName = category?.iconName;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<BackendCategoryModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
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
                        labelText: 'Category Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Category name is required';
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
                    DropdownButtonFormField<String>(
                      value: parentCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Category',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None (Root)'),
                        ),
                        ..._categories
                            .where((c) => c.id != category?.id)
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ),
                            ),
                      ],
                      onChanged: (value) => parentCategoryId = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sortOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: iconName,
                      decoration: const InputDecoration(labelText: 'Icon'),
                      items: _iconOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => iconName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color Hex',
                        hintText: '#FF5733',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Default Tax Rate',
                        hintText: '0.10 = 10%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      title: const Text('Active'),
                      onChanged: (value) => isActive = value,
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
                final parsedOrder =
                    int.tryParse(sortOrderController.text.trim()) ?? 0;
                final parsedTax = double.tryParse(
                  taxRateController.text.trim(),
                );

                final newCategory = BackendCategoryModel(
                  id: category?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  parentCategoryId: parentCategoryId,
                  sortOrder: parsedOrder,
                  isActive: isActive,
                  iconName: iconName,
                  colorHex: colorController.text.trim().isEmpty
                      ? null
                      : colorController.text.trim(),
                  defaultTaxRate: parsedTax,
                  createdAt: category?.createdAt ?? now,
                  updatedAt: now,
                );

                Navigator.pop(context, newCategory);
              },
              child: Text(category == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    setState(() => _isLoading = true);

    try {
      if (category == null) {
        await _categoryService.createCategory(result);
      } else {
        await _categoryService.updateCategory(result);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save category: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(BackendCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${category.name}"? This will deactivate it.'),
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

    if (confirmed != true || category.id == null) return;
    setState(() => _isLoading = true);
    try {
      await _categoryService.deleteCategory(category.id!);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete category: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adjustSortOrder(
    BackendCategoryModel category,
    int delta,
  ) async {
    if (category.id == null) return;
    setState(() => _isLoading = true);
    try {
      await _categoryService.updateCategory(
        category.copyWith(sortOrder: category.sortOrder + delta),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reorder category: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(
      title: 'Backend Categories',
      subtitle: 'Cloud category management is coming soon.',
    );
    final filtered = _filteredCategories();
    final productCounts = _buildProductCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: _buildFilters()),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _buildCategoryTree(filtered, productCounts),
          ),
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
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SwitchListTile(
              value: _showInactive,
              title: const Text('Show inactive'),
              onChanged: (value) {
                setState(() => _showInactive = value);
              },
            ),
          ),
        ];

        return isNarrow
            ? Column(
                children: [children[0], const SizedBox(height: 8), children[2]],
              )
            : Row(children: children);
      },
    );
  }

  Widget _buildCategoryTree(
    List<BackendCategoryModel> categories,
    Map<String, int> productCounts,
  ) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    final rootCategories = categories.where((c) => c.isRootCategory).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        final root = rootCategories[index];
        final children =
            categories.where((c) => c.parentCategoryId == root.id).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return Card(
          child: ExpansionTile(
            title: _buildCategoryRow(root, productCounts),
            children: [
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 12),
                  child: Text('No subcategories'),
                )
              else
                ...children.map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildCategoryRow(child, productCounts),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(
    BackendCategoryModel category,
    Map<String, int> productCounts,
  ) {
    final count = productCounts[category.id] ?? 0;

    return ListTile(
      title: Text(category.name),
      subtitle: Text(
        'Order: ${category.sortOrder} • Products: $count',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: _isLoading ? null : () => _adjustSortOrder(category, -1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: _isLoading ? null : () => _adjustSortOrder(category, 1),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: _isLoading
                ? null
                : () => _showCategoryDialog(category: category),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: _isLoading ? null : () => _confirmDelete(category),
          ),
        ],
      ),
      leading: _buildIconPreview(category),
    );
  }

  Widget _buildIconPreview(BackendCategoryModel category) {
    final color = _parseColor(category.colorHex);
    return CircleAvatar(
      backgroundColor: color ?? Colors.blueGrey.shade100,
      child: Icon(
        _iconMap[category.iconName] ?? Icons.category,
        color: color != null ? Colors.white : Colors.blueGrey,
        size: 18,
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

const List<String> _iconOptions = [
  'category',
  'restaurant',
  'local_cafe',
  'lunch_dining',
  'bakery_dining',
  'fastfood',
  'local_bar',
  'local_pizza',
  'icecream',
];

const Map<String, IconData> _iconMap = {
  'category': Icons.category,
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'lunch_dining': Icons.lunch_dining,
  'bakery_dining': Icons.bakery_dining,
  'fastfood': Icons.fastfood,
  'local_bar': Icons.local_bar,
  'local_pizza': Icons.local_pizza,
  'icecream': Icons.icecream,
};
