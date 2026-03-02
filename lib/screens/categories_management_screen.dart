import 'dart:developer' as developer;

import 'package:extropos/models/category_model.dart';
import 'package:extropos/services/category_repository.dart';
import 'package:extropos/services/guide_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/guide_widgets.dart';
import 'package:flutter/material.dart';

part 'categories_management_screen_dialogs.dart';

class CategoriesManagementScreen extends StatefulWidget {
  /// Optional repository for categories. If omitted, the default
  /// [DatabaseCategoryRepository] will be used.
  final CategoryRepository? repository;

  const CategoriesManagementScreen({super.key, this.repository});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  final List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    developer.log('CategoriesManagementScreen: initState called');
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    final sw = Stopwatch()..start();
    try {
      final categories =
          await (widget.repository ?? DatabaseCategoryRepository())
              .getCategories();
      sw.stop();
      developer.log(
        'CategoriesManagementScreen: _loadCategories returned ${categories.length} categories in ${sw.elapsedMilliseconds}ms',
      );
      if (!mounted) return;
      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _filteredCategories = List.from(_categories);
      });
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error loading categories: $e');

      // Fall back to sample data if database fails
      setState(() {
        _categories.addAll([
          Category(
            id: '1',
            name: 'Beverages',
            description: 'Hot and cold drinks',
            icon: Icons.local_cafe,
            color: Colors.brown,
            sortOrder: 1,
          ),
          Category(
            id: '2',
            name: 'Food',
            description: 'Main dishes and snacks',
            icon: Icons.restaurant,
            color: Colors.orange,
            sortOrder: 2,
          ),
          Category(
            id: '3',
            name: 'Desserts',
            description: 'Sweet treats',
            icon: Icons.cake,
            color: Colors.pink,
            sortOrder: 3,
          ),
        ]);
        _filteredCategories = List.from(_categories);
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories = _categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query) ||
                  category.description.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _addCategory() {
    _showCategoryDialog();
  }

  void _editCategory(Category category) {
    _showCategoryDialog(category: category);
  }

  void _deleteCategory(Category category) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await (widget.repository ?? DatabaseCategoryRepository())
                    .deleteCategory(category.id);
                setState(() {
                  _categories.remove(category);
                  _filterCategories();
                });
                if (!mounted) return;
                Navigator.pop(context);
                ToastHelper.showToast(context, '${category.name} deleted');
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ToastHelper.showToast(context, 'Error deleting category: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      'CategoriesManagementScreen: build start, _filteredCategories=${_filteredCategories.length}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search categories',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No categories yet'
                              : 'No categories found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Tap + to add your first category'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories.length,
                    onReorder: (oldIndex, newIndex) {
                      _handleReorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return Card(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category.color.withAlpha(
                                (0.2 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category.isActive
                                          ? Color.fromRGBO(76, 175, 80, 0.1)
                                          : Color.fromRGBO(158, 158, 158, 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: category.isActive
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order: ${category.sortOrder}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCategory(category),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        heroTag: 'add_category',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FloatingGuideButton(
              heroTag: null,
              onPressed: () async {
                final steps = PredefinedGuides.getGuideSteps(
                  'categories_setup',
                );
                if (steps.isNotEmpty) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => InteractiveGuideOverlay(
                      guideName: 'Categories Setup Guide',
                      steps: steps,
                      onComplete: () {
                        GuideService.instance.markGuideCompleted(
                          'categories_setup',
                        );
                        Navigator.of(context).pop();
                      },
                      onSkip: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }
              },
              tooltip: 'Show Categories Guide',
            ),
          ],
        ),
      ),
    );
  }

  /// Handles reordering of categories. Extracted into a method to allow
  /// tests to call the same logic directly (test seam).
  @visibleForTesting
  Future<void> testReorder(int oldIndex, int newIndex) async {
    _handleReorder(oldIndex, newIndex);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex--;
      }
      final category = _filteredCategories.removeAt(oldIndex);
      _filteredCategories.insert(newIndex, category);

      // Update sort orders
      for (int i = 0; i < _filteredCategories.length; i++) {
        final index = _categories.indexWhere(
          (c) => c.id == _filteredCategories[i].id,
        );
        if (index != -1) {
          _categories[index] = _categories[index].copyWith(sortOrder: i + 1);
        }
      }
    });

    // Persist updated sort orders to local DB
    try {
      for (final cat in _categories) {
        (widget.repository ?? DatabaseCategoryRepository()).updateCategory(cat);
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Error saving category order: $e');
    }
  }
}
