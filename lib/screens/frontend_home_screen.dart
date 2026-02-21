import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/order_status_screen.dart';
import 'package:extropos/screens/product_detail_screen.dart';
import 'package:extropos/screens/start_screen.dart';
import 'package:extropos/services/appwrite_backend_service.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:extropos/widgets/cart_item_widget.dart';
import 'package:extropos/widgets/product_card.dart';
import 'package:flutter/material.dart';

class FrontendHomeScreen extends StatefulWidget {
  final OrderType orderType;
  final String? tableNumber;

  const FrontendHomeScreen({
    super.key,
    required this.orderType,
    this.tableNumber,
  });

  @override
  State<FrontendHomeScreen> createState() => _FrontendHomeScreenState();
}

class _FrontendHomeScreenState extends State<FrontendHomeScreen> {
  final AppwriteBackendService _backendService =
      AppwriteBackendService.instance;
  List<Category> _categories = [];
  List<Item> _items = [];
  final List<CartItem> _cartItems = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);

      // Initialize Appwrite service
      await _backendService.initialize();

      // Load categories
      final categories = await _backendService.getCategories();
      setState(() => _categories = categories);

      // Load all items initially
      await _loadItems();
    } catch (e) {
      developer.log('Frontend: Failed to initialize: $e');
      setState(() {
        _errorMessage = 'Failed to load menu. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadItems({String? categoryId}) async {
    try {
      final items = await _backendService.getItems();
      setState(() {
        _items = categoryId != null
            ? items.where((item) => item.categoryId == categoryId).toList()
            : items;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Frontend: Failed to load items: $e');
      setState(() {
        _errorMessage = 'Failed to load items. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    _loadItems(categoryId: category.id);
  }

  void _onCategoryCleared() {
    setState(() {
      _selectedCategory = null;
      _isLoading = true;
    });
    _loadItems();
  }

  void _navigateToProductDetail(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailScreen(item: item, onAddToCart: _addToCart),
      ),
    );
  }

  void _addToCart(CartItem cartItem) {
    setState(() {
      // For now, we'll add each item as a separate cart entry
      // In a more advanced implementation, we could group identical items
      _cartItems.add(cartItem);
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cartItem.product.name} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _getSubtotal() => Pricing.subtotal(_cartItems);

  double _getTaxAmount() => Pricing.taxAmount(_cartItems);

  double _getServiceChargeAmount() => Pricing.serviceChargeAmount(_cartItems);

  double _getTotal() => Pricing.total(_cartItems);

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory?.name ?? 'Menu'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _onCategoryCleared,
              tooltip: 'Show all categories',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _showCart,
                tooltip: 'View cart',
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _selectedCategory == null
          ? _buildCategoriesView()
          : _buildItemsView(),
    );
  }

  Widget _buildCategoriesView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () => _onCategorySelected(category),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category.icon, size: 48, color: category.color),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items available in this category',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return ProductCard(
              product: Product(
                item.name,
                item.price,
                _selectedCategory?.name ?? 'Unknown',
                item.icon,
                imagePath: item.imageUrl,
              ),
              onTap: () => _navigateToProductDetail(item),
            );
          },
        );
      },
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Your Order',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cartItems[index];
                          return CartItemWidget(
                            item: cartItem,
                            onRemove: () {
                              setState(() {
                                if (cartItem.quantity > 1) {
                                  _cartItems[index] = CartItem(
                                    cartItem.product,
                                    cartItem.quantity - 1,
                                  );
                                } else {
                                  _cartItems.removeAt(index);
                                }
                              });
                            },
                            onAdd: () {
                              setState(() {
                                _cartItems[index] = CartItem(
                                  cartItem.product,
                                  cartItem.quantity + 1,
                                );
                              });
                            },
                          );
                        },
                      ),
              ),
              if (_cartItems.isNotEmpty) ...[
                const Divider(),
                _buildOrderSummary(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Place Order'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final info = BusinessInfo.instance;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal'),
            Text('${info.currencySymbol}${_getSubtotal().toStringAsFixed(2)}'),
          ],
        ),
        if (info.isTaxEnabled) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (${info.taxRatePercentage})'),
              Text(
                '${info.currencySymbol}${_getTaxAmount().toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
        if (info.isServiceChargeEnabled) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Charge (${info.serviceChargeRatePercentage})'),
              Text(
                '${info.currencySymbol}${_getServiceChargeAmount().toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${info.currencySymbol}${_getTotal().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _checkout() {
    // Generate order number
    final orderNumber =
        'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Navigate to order status screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderStatusScreen(
          orderItems: List.from(_cartItems),
          orderNumber: orderNumber,
          orderType: widget.orderType,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }
}
