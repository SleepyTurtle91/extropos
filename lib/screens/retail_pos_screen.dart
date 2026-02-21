import 'dart:async';
import 'dart:developer' as developer;
// ignore: unused_import
import 'dart:math' as math;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_variant.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/variant_selection_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

class RetailPOSScreen extends StatefulWidget {
  const RetailPOSScreen({super.key});

  @override
  State<RetailPOSScreen> createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  String selectedCategory = 'All';
  final List<CartItem> cartItems = [];
  final Map<String, List<Product>> _productFilterCache = {};
  Timer? _categoryDebounceTimer;

  // Start empty by default — no fallback mock products or categories on first load
  List<String> categories = ['All'];
  List<Category> _categoryObjects = [];

  List<Product> products = [];
  String selectedMerchant = 'none';

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
  ];

  // Customer information
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? specialInstructions;
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
    // Listen to BusinessInfo changes for real-time tax/service charge updates
    BusinessInfo.instance.addListener(_onBusinessInfoChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  Future<void> _checkShiftStatus() async {
    final user = LockManager.instance.currentUser;
    if (user == null) return;

    await ShiftService().initialize(user.id);

    if (!ShiftService().hasActiveShift && mounted) {
      // Prompt to start shift
      final started = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StartShiftDialog(userId: user.id),
      );

      if (started != true && mounted) {
        ToastHelper.showToast(
          context,
          'You must start a shift to process orders',
        );
      }
    }
  }

  Future<void> _loadFromDatabase() async {
    try {
      final List<Category> dbCategories = await DatabaseService.instance
          .getCategories();
      final List<Item> dbItems = await DatabaseService.instance.getItems();

      // Update categories if any exist in DB
      if (dbCategories.isNotEmpty) {
        final List<String> newCategories = [
          'All',
          ...dbCategories.map((c) => c.name),
        ];
        if (mounted) {
          setState(() {
            categories = newCategories;
            _categoryObjects = dbCategories;
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }
          });
        }
      }

      // Update products if any exist in DB
      if (dbItems.isNotEmpty) {
        final Map<String, Category> catById = {
          for (final c in dbCategories) c.id: c,
        };
        final List<Product> newProducts = dbItems.map((it) {
          final catName = catById[it.categoryId]?.name ?? 'Uncategorized';
          return Product(
            it.name,
            it.price,
            catName,
            it.icon,
            imagePath: it.imageUrl,
            printerOverride: it.printerOverride,
          );
        }).toList();
        if (mounted) {
          setState(() {
            products = newProducts;
            _productFilterCache.clear();
          });
        }
      }
    } catch (e) {
      developer.log('Failed to load categories/items from DB: $e');
      // Ensure sample data exists in database for transaction saving
      await _ensureSampleDataInDatabase();
      // Load sample products for display
      if (mounted) {
        setState(() {
          categories = ['All', 'Food', 'Drinks', 'Desserts'];
          products = _getSampleProducts();
        });
      }
    }

    // If no products loaded from DB, ensure sample data and load products
    if (products.isEmpty && mounted) {
      await _ensureSampleDataInDatabase();
      setState(() {
        categories = ['All', 'Food', 'Drinks', 'Desserts'];
        products = _getSampleProducts();
      });
    }
  }

  List<Product> _getSampleProducts() {
    return [
      // Products with variants
      Product(
        'Pizza',
        15.00,
        'Food',
        Icons.local_pizza,
        variants: [
          ProductVariant(
            id: 'pizza_small',
            name: 'Small (8")',
            priceModifier: -5.00,
          ),
          ProductVariant(
            id: 'pizza_medium',
            name: 'Medium (12")',
            priceModifier: 0.00,
          ),
          ProductVariant(
            id: 'pizza_large',
            name: 'Large (16")',
            priceModifier: 8.00,
          ),
        ],
      ),
      Product(
        'Burger',
        12.00,
        'Food',
        Icons.lunch_dining,
        variants: [
          ProductVariant(
            id: 'burger_single',
            name: 'Single Patty',
            priceModifier: 0.00,
          ),
          ProductVariant(
            id: 'burger_double',
            name: 'Double Patty',
            priceModifier: 5.00,
          ),
        ],
      ),
      Product(
        'Coffee',
        5.00,
        'Drinks',
        Icons.local_cafe,
        variants: [
          ProductVariant(
            id: 'coffee_small',
            name: 'Small',
            priceModifier: -1.00,
          ),
          ProductVariant(
            id: 'coffee_medium',
            name: 'Medium',
            priceModifier: 0.00,
          ),
          ProductVariant(
            id: 'coffee_large',
            name: 'Large',
            priceModifier: 1.00,
          ),
        ],
      ),
      // Regular products without variants
      Product('Pasta', 18.00, 'Food', Icons.restaurant),
      Product('Salad', 10.00, 'Food', Icons.grass),
      Product('Soda', 3.00, 'Drinks', Icons.local_drink),
      Product('Ice Cream', 6.00, 'Desserts', Icons.icecream),
      Product('Cake', 8.00, 'Desserts', Icons.cake),
    ];
  }

  Future<void> _ensureSampleDataInDatabase() async {
    try {
      // Check if sample categories already exist
      final existingCategories = await DatabaseService.instance.getCategories();
      if (existingCategories.isEmpty) {
        // Create sample categories
        final sampleCategories = [
          Category(
            id: 'sample_cat_food',
            name: 'Food',
            description: 'Meals and main dishes',
            icon: Icons.restaurant,
            color: Colors.orange,
            sortOrder: 1,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_drinks',
            name: 'Drinks',
            description: 'Beverages and drinks',
            icon: Icons.local_cafe,
            color: Colors.blue,
            sortOrder: 2,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_desserts',
            name: 'Desserts',
            description: 'Sweet treats and desserts',
            icon: Icons.cake,
            color: Colors.pink,
            sortOrder: 3,
            isActive: true,
          ),
        ];

        for (final category in sampleCategories) {
          try {
            await DatabaseService.instance.insertCategory(category);
          } catch (e) {
            developer.log(
              'Failed to insert sample category ${category.name}: $e',
            );
          }
        }
      }

      // Check if sample items already exist
      final existingItems = await DatabaseService.instance.getItems();
      if (existingItems.isEmpty) {
        // Get categories for item creation
        final categories = await DatabaseService.instance.getCategories();
        final categoryMap = {for (final cat in categories) cat.name: cat};

        // Create sample items
        final sampleItems = [
          Item(
            id: 'sample_item_pizza',
            name: 'Pizza',
            description: 'Delicious pizza with various toppings',
            price: 15.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.local_pizza,
            color: Colors.orange,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 1,
          ),
          Item(
            id: 'sample_item_burger',
            name: 'Burger',
            description: 'Juicy burger with fresh ingredients',
            price: 12.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.lunch_dining,
            color: Colors.brown,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 2,
          ),
          Item(
            id: 'sample_item_coffee',
            name: 'Coffee',
            description: 'Freshly brewed coffee',
            price: 5.00,
            categoryId: categoryMap['Drinks']?.id ?? 'sample_cat_drinks',
            icon: Icons.local_cafe,
            color: Colors.brown,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 3,
          ),
          Item(
            id: 'sample_item_pasta',
            name: 'Pasta',
            description: 'Authentic pasta dish',
            price: 18.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.restaurant,
            color: Colors.red,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 4,
          ),
          Item(
            id: 'sample_item_salad',
            name: 'Salad',
            description: 'Fresh garden salad',
            price: 10.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.grass,
            color: Colors.green,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 5,
          ),
          Item(
            id: 'sample_item_soda',
            name: 'Soda',
            description: 'Refreshing carbonated drink',
            price: 3.00,
            categoryId: categoryMap['Drinks']?.id ?? 'sample_cat_drinks',
            icon: Icons.local_drink,
            color: Colors.blue,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 6,
          ),
          Item(
            id: 'sample_item_ice_cream',
            name: 'Ice Cream',
            description: 'Creamy ice cream dessert',
            price: 6.00,
            categoryId: categoryMap['Desserts']?.id ?? 'sample_cat_desserts',
            icon: Icons.icecream,
            color: Colors.pink,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 7,
          ),
          Item(
            id: 'sample_item_cake',
            name: 'Cake',
            description: 'Delicious cake slice',
            price: 8.00,
            categoryId: categoryMap['Desserts']?.id ?? 'sample_cat_desserts',
            icon: Icons.cake,
            color: Colors.purple,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 8,
          ),
        ];

        for (final item in sampleItems) {
          try {
            await DatabaseService.instance.insertItem(item);
          } catch (e) {
            developer.log('Failed to insert sample item ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      developer.log('Failed to ensure sample data in database: $e');
    }
  }

  Future<void> addToCart(Product p) async {
    // If product has variants, show variant selection dialog first
    if (p.hasVariants) {
      final selectedVariant = await showDialog<ProductVariant>(
        context: context,
        builder: (context) => VariantSelectionDialog(product: p),
      );

      if (selectedVariant == null) return; // User cancelled

      await _addProductWithVariantToCart(p, selectedVariant);
      return;
    }

    // No variants, add directly
    await _addProductToCart(p);
  }

  Future<void> _addProductToCart(Product p, {ProductVariant? variant}) async {
    // Determine merchant price override if merchant selected
    double priceAdjustment = 0.0;
    if (selectedMerchant != 'none' && selectedMerchant != 'takeaway') {
      final items = await DatabaseService.instance.getItems();
      final match = items.firstWhere(
        (it) => it.name == p.name,
        orElse: () => Item(
          id: '',
          name: '',
          description: '',
          price: p.price,
          categoryId: '',
          icon: p.icon,
          color: Colors.blue,
        ),
      );
      if (match.id.isNotEmpty) {
        final mprice = match.merchantPrices[selectedMerchant];
        if (mprice != null) {
          priceAdjustment = mprice - p.price;
        }
      }
    }

    // Apply happy hour discount if enabled
    if (BusinessInfo.instance.isInHappyHourNow()) {
      final appliedBase =
          p.price + priceAdjustment; // include merchant override
      final hh = appliedBase * BusinessInfo.instance.happyHourDiscountPercent;
      priceAdjustment -= hh;
    }

    setState(() {
      // Check for existing cart item with same configuration
      final index = cartItems.indexWhere(
        (c) => c.hasSameConfigurationWithDiscount(
          p,
          [],
          0.0,
          otherPriceAdjustment: priceAdjustment,
          otherSeatNumber: null,
          otherVariant: variant,
        ),
      );
      if (index != -1) {
        cartItems[index].quantity++;
      } else {
        cartItems.add(
          CartItem(
            p,
            1,
            priceAdjustment: priceAdjustment,
            selectedVariant: variant,
          ),
        );
      }
    });

    // Update dual display (Imin back screen) with cart items
    await _updateDualDisplay();

    // Update customer display (external displays)
    // DISABLED: This conflicts with the built-in DualDisplayService on iMin devices
    // causing the screen to revert to legacy LCD mode.
    /*
    try {
      final display = await CustomerDisplayService().getDefaultDisplay();
      if (display != null) {
        final last = cartItems.isNotEmpty ? cartItems.last : null;
        final displayText = last != null
            ? "${last.quantity} x ${last.getFullDisplayName()}\nSubtotal: RM ${getSubtotal().toStringAsFixed(2)}"
            : "Subtotal: RM ${getSubtotal().toStringAsFixed(2)}";
        await CustomerDisplayService().showText(display, displayText);
      }
    } catch (e) {
      developer.log('CustomerDisplay update failed: $e');
    }
    */
  }

  Future<void> _addProductWithVariantToCart(
    Product p,
    ProductVariant variant,
  ) async {
    await _addProductToCart(p, variant: variant);
  }

  Future<void> removeFromCart(int index) async {
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        cartItems.removeAt(index);
      }
    });

    // Update dual display with the new cart state
    await _updateDualDisplay();
  }

  @override
  void dispose() {
    _categoryDebounceTimer?.cancel();
    // Remove BusinessInfo listener
    BusinessInfo.instance.removeListener(_onBusinessInfoChanged);
    super.dispose();
  }

  void _onBusinessInfoChanged() {
    // Trigger UI rebuild when tax/service charge settings change
    setState(() {});
  }

  List<Product> _getFilteredProductsSync(String category) {
    if (_productFilterCache.containsKey(category)) {
      if (kDebugMode) {
        developer.log(
          'RETAIL POS: cache hit for $category',
          name: 'retail_pos_perf',
        );
        developer.log(
          'RETAIL POS: cache hit for $category',
          name: 'retail_pos_perf',
        );
      }
      return _productFilterCache[category]!;
    }
    final sw = Stopwatch()..start();
    final res = category == 'All'
        ? List<Product>.from(products)
        : products.where((p) => p.category == category).toList();
    sw.stop();
    if (kDebugMode) {
      developer.log(
        'RETAIL POS: computed filter for $category count=${res.length} elapsed=${sw.elapsedMilliseconds}ms',
        name: 'retail_pos_perf',
      );
    }
    _productFilterCache[category] = res;
    return res;
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    if (kDebugMode) {
      developer.log(
        'RETAIL POS: category selected $category (debounced)',
        name: 'retail_pos_perf',
      );
      developer.log(
        'RETAIL POS: category selected (debounced) $category',
        name: 'retail_pos_perf',
      );
    }
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        selectedCategory = category;
      });
    });
  }

  /// Update dual display with current cart state
  Future<void> _updateDualDisplay() async {
    developer.log(
      'POS: _updateDualDisplay() called with ${cartItems.length} items',
    );
    try {
      await DualDisplayService().showCartItemsFromObjects(
        cartItems,
        BusinessInfo.instance.currencySymbol,
      );
      developer.log('POS: Dual display update completed successfully');
    } catch (e) {
      developer.log('POS: ERROR - Dual display update failed: $e', error: e);
    }
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
      customerName = null;
      customerPhone = null;
      customerEmail = null;
      specialInstructions = null;
      selectedCustomer = null;
    });

    // Update dual display to show empty cart
    _updateDualDisplay();
  }

  double getSubtotal() => cartItems.fold(0.0, (s, c) => s + c.totalPrice);
  double billDiscount = 0.0;

  double getTaxAmount() {
    final info = BusinessInfo.instance;
    if (!info.isTaxEnabled) return 0.0;

    final afterDiscount = (getSubtotal() - billDiscount) < 0
        ? 0.0
        : (getSubtotal() - billDiscount);

    // Calculate tax per item based on category tax rates
    double totalTax = 0.0;
    for (final cartItem in cartItems) {
      final category = _categoryObjects.firstWhere(
        (cat) => cat.name == cartItem.product.category,
        orElse: () => Category(
          id: '',
          name: cartItem.product.category,
          description: '',
          icon: Icons.category,
          color: Colors.grey,
          taxRate: BusinessInfo
              .instance
              .taxRate, // Fallback to global rate if category not found
        ),
      );

      // Use category-specific tax rate, fallback to global rate
      final taxRate = category.taxRate > 0 ? category.taxRate : info.taxRate;
      final itemSubtotal =
          cartItem.totalPrice * (afterDiscount / getSubtotal());
      totalTax += itemSubtotal * taxRate;
    }

    return totalTax;
  }

  double getServiceChargeAmount() {
    final info = BusinessInfo.instance;
    final afterDiscount = (getSubtotal() - billDiscount) < 0
        ? 0.0
        : (getSubtotal() - billDiscount);
    return info.isServiceChargeEnabled
        ? afterDiscount * info.serviceChargeRate
        : 0.0;
  }

  double getTotal() =>
      (getSubtotal() - billDiscount < 0 ? 0.0 : getSubtotal() - billDiscount) +
      getTaxAmount() +
      getServiceChargeAmount();

  /// Calculate loyalty points that will be earned from this purchase
  int getLoyaltyPointsEarned() {
    if (selectedCustomer == null) return 0;

    // Simple loyalty calculation: 1 point per RM10 spent
    final pointsEarned = (getTotal() / 10).floor();

    // VIP customers get double points
    if (selectedCustomer!.customerTier == 'VIP') {
      return pointsEarned * 2;
    }

    return pointsEarned;
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (item) => item.product.name == product.name,
      );
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity += 1;
      } else {
        cartItems.add(CartItem(product, 1));
      }
    });
  }

  void _updateQuantity(CartItem item, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        cartItems.remove(item);
      } else {
        item.quantity = newQuantity;
      }
    });
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) return;

    // Implement checkout logic
    // This is a placeholder
    // Process payment, create transaction, etc.
    setState(() {
      cartItems.clear();
    });
  }

  Widget _buildProductGrid(List<Product> filteredProducts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive columns based on screen width
        int crossAxisCount = 4; // default
        if (constraints.maxWidth < 600)
          crossAxisCount = 1;
        else if (constraints.maxWidth < 900)
          crossAxisCount = 2;
        else if (constraints.maxWidth < 1200)
          crossAxisCount = 3;

        if (filteredProducts.isEmpty) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items available.\nOpen Settings → Database Test to restore demo data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use the menu button (☰) at the top to access Settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: () => _addToCart(product),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(product.icon, size: 32, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
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

  Widget _buildCartPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Text(
              'Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Cart items
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('No items in cart'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                          'RM ${item.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  _updateQuantity(item, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _updateQuantity(item, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Cart total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('RM ${getSubtotal().toStringAsFixed(2)}'),
                  ],
                ),
                if (BusinessInfo.instance.isTaxEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (${BusinessInfo.instance.taxRatePercentage}):'),
                      Text('RM ${getTaxAmount().toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage}):',
                      ),
                      Text('RM ${getServiceChargeAmount().toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RM ${getTotal().toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : _checkout,
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProductsSync(selectedCategory);
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Category filter
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCategory,
                              items: categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _onCategorySelected(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 140,
                          child: Material(
                            color: Colors.transparent,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedMerchant,
                              items: const [
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text('Dine-In'),
                                ),
                                DropdownMenuItem(
                                  value: 'takeaway',
                                  child: Text('Takeaway'),
                                ),
                                DropdownMenuItem(
                                  value: 'grabfood',
                                  child: Text('GrabFood'),
                                ),
                                DropdownMenuItem(
                                  value: 'shopeefood',
                                  child: Text('ShopeeFood'),
                                ),
                                DropdownMenuItem(
                                  value: 'foodpanda',
                                  child: Text('FoodPanda'),
                                ),
                              ],
                              onChanged: (v) => setState(
                                () => selectedMerchant = v ?? 'none',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Products grid
                  Expanded(child: _buildProductGrid(filteredProducts)),
                ],
              ),
            ),
            SizedBox(width: 350, child: _buildCartPanel()),
          ],
        ),
      ),
    );
  }
}

class _ParkSaleDialog extends StatefulWidget {
  const _ParkSaleDialog();

  @override
  State<_ParkSaleDialog> createState() => _ParkSaleDialogState();
}

class _ParkSaleDialogState extends State<_ParkSaleDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Park Sale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add optional notes for this parked sale:'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'e.g., Customer will return later',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(_notesController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Park Sale'),
        ),
      ],
    );
  }
}
