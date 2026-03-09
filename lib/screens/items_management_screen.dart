import 'package:extropos/dialogs/item_form_dialog.dart';
import 'package:extropos/dialogs/item_import_dialog.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'items_management_screen_ui.dart';

class ItemsManagementScreen extends StatefulWidget {
  const ItemsManagementScreen({super.key});

  @override
  State<ItemsManagementScreen> createState() => _ItemsManagementScreenState();
}

class _ItemsManagementScreenState extends State<ItemsManagementScreen> {
  final List<Item> _items = [];
  final List<Category> _categories = [];
  List<Item> _filteredItems = [];
  final _searchController = TextEditingController();
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return _buildItemsManagementScreen(context);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      // Load categories from database
      final categories = await DatabaseService.instance.getCategories();
      // Load items from database
      final items = await DatabaseService.instance.getItems();
      if (!mounted) return;

      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _items.clear();
        _items.addAll(items);
        _filteredItems = List.from(_items);
      });

      // Check for low stock items and show warnings
      _checkLowStockAlerts(items);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error loading data: $e');
      // Fall back to sample data if database fails
      setState(() {
        _categories.addAll([
          Category(
            id: '1',
            name: 'Beverages',
            description: 'Hot and cold drinks',
            icon: Icons.local_cafe,
            color: Colors.brown,
          ),
          Category(
            id: '2',
            name: 'Food',
            description: 'Main dishes',
            icon: Icons.restaurant,
            color: Colors.orange,
          ),
        ]);

        _items.addAll([
          Item(
            id: '1',
            name: 'Espresso',
            description: 'Strong black coffee',
            price: 3.50,
            categoryId: '1',
            icon: Icons.local_cafe,
            color: Colors.brown,
            stock: 100,
            trackStock: false,
          ),
          Item(
            id: '2',
            name: 'Cappuccino',
            description: 'Espresso with steamed milk',
            price: 4.50,
            categoryId: '1',
            icon: Icons.coffee,
            color: Colors.brown,
            stock: 100,
            trackStock: false,
          ),
        ]);

        _filteredItems = List.from(_items);
      });
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesSearch =
            query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.sku?.toLowerCase().contains(query) == true;

        final matchesCategory =
            _selectedCategoryFilter == null ||
            item.categoryId == _selectedCategoryFilter;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addItem() {
    if (_categories.isEmpty) {
      ToastHelper.showToast(context, 'Please create a category first');
      return;
    }
    _showItemDialog();
  }

  void _editItem(Item item) {
    _showItemDialog(item: item);
  }

  void _deleteItem(Item item) async {
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Use outer currentContext instead of dialog's context across async gaps
              // dialog's context (the builder's `context`) should not be held across async
              try {
                await DatabaseService.instance.deleteItem(item.id);
                setState(() {
                  _items.remove(item);
                  _filterItems();
                });
                if (!mounted) return;
                parentNavigator.pop();
                ToastHelper.showToast(context, '${item.name} deleted');
              } catch (e) {
                if (!mounted) return;
                parentNavigator.pop();
                ToastHelper.showToast(context, 'Error deleting item: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({Item? item}) {
    showDialog(
      context: context,
      builder: (context) => ItemFormDialog(
        item: item,
        categories: _categories,
        onItemSave: (newItem) async {
          if (item == null) {
            // Adding new item
            await DatabaseService.instance.insertItem(newItem);
          } else {
            // Updating existing item
            await DatabaseService.instance.updateItem(newItem);
          }
          if (mounted) _loadData();
        },
      ),
    );
  }
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ItemImportDialog(
        onImportComplete: _loadData,
      ),
    );
  }


  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _checkLowStockAlerts(List<Item> items) {
    final lowStockItems = items
        .where(
          (item) =>
              item.trackStock &&
              item.stock <= item.lowStockThreshold &&
              item.stock > 0,
        )
        .toList();

    if (lowStockItems.isNotEmpty) {
      final itemNames = lowStockItems
          .map((item) => '${item.name} (${item.stock})')
          .join(', ');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Low stock alert: $itemNames'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Could navigate to a low stock screen or filter the list
              setState(() {
                _filteredItems = lowStockItems;
                _selectedCategoryFilter = null;
                _searchController.clear();
              });
            },
          ),
        ),
      );
    }

    final outOfStockItems = items
        .where((item) => item.trackStock && item.stock == 0)
        .toList();

    if (outOfStockItems.isNotEmpty) {
      final itemNames = outOfStockItems.map((item) => item.name).join(', ');
      if (mounted) ToastHelper.showToast(context, 'Out of stock: $itemNames');
    }
  }
}
