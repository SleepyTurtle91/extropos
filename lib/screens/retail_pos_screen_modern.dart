// MODERN RETAIL POS SCREEN - EXACT MATCH TO REFERENCE IMAGES
// Portrait and Landscape modes with dark navy theme
// Colors: Dark Navy (#1E2A3A), Accent Green (#00D9A5)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/payment_split_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/e_wallet_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/printer_service.dart';
import 'package:extropos/services/receipt_generator.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/utils/payment_result_parser.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class RetailPOSScreenModern extends StatefulWidget {
  final bool embedded;

  const RetailPOSScreenModern({super.key, this.embedded = false});

  @override
  State<RetailPOSScreenModern> createState() => _RetailPOSScreenModernState();
}

class _RetailPOSScreenModernState extends State<RetailPOSScreenModern>
    with TickerProviderStateMixin {
  String selectedCategory = 'All';

  // Enhanced cart management with CartService
  late final CartService cartService;

  // Categories loaded from database
  List<String> categories = ['All'];
  List<Category> _categoryObjects = [];

  // Sample products matching reference images
  List<Product> products = [];
  final Map<String, List<Product>> _productFilterCache = {};

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
    PaymentMethod(id: 'ewallet', name: 'E-Wallet'),
  ];

  PaymentMethod? _selectedPaymentMethod;

  String selectedMerchant = 'none';
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? specialInstructions;
  Customer? selectedCustomer;
  double billDiscount = 0.0;
  final List<Customer> customers = [];

  // Search & Barcode Scanning
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _favoriteProductIds = {}; // Quick add favorites

  // Cart animation feedback
  late AnimationController _cartAddAnimController;

  // Number pad for quantity input
  String _quantityInput = '1';
  Product? _selectedProductForQuantity;

  // Color scheme from reference images
  static const Color darkNavy = Color(0xFF1E2A3A);
  static const Color darkNavyLight = Color(0xFF2C3E50);
  static const Color accentGreen = Color(0xFF00D9A5);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentPurple = Color(0xFFB74FE5);

  @override
  void initState() {
    super.initState();
    cartService = CartService();
    cartService.addListener(_onCartChanged);
    _searchController.addListener(_onSearchChanged);
    _cartAddAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _selectedPaymentMethod = paymentMethods.firstWhere(
      (method) => method.isDefault,
      orElse: () => paymentMethods.first,
    );
    _loadData();
  }

  @override
  void dispose() {
    cartService.removeListener(_onCartChanged);
    _searchController.dispose();
    _cartAddAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _productFilterCache.clear(); // Clear cache when search changes
    });
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
      _updateDualDisplay();
    }
  }

  void _loadData() async {
    try {
      // Load categories from database
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
          categories = ['All', 'Apparel', 'Footwear', 'Accessories'];
          products = _getSampleProducts();
          _productFilterCache.clear();
        });
      }
    }

    // If no products loaded from DB, ensure sample data and load products
    if (products.isEmpty && mounted) {
      await _ensureSampleDataInDatabase();
      setState(() {
        categories = ['All', 'Apparel', 'Footwear', 'Accessories'];
        products = _getSampleProducts();
        _productFilterCache.clear();
      });
    }
  }

  List<Product> _getFilteredProductsSync(String category) {
    if (_productFilterCache.containsKey(category)) {
      return _productFilterCache[category]!;
    }
    final res = category == 'All'
        ? List<Product>.from(products)
        : products.where((p) => p.category == category).toList();
    _productFilterCache[category] = res;
    return res;
  }

  List<Product> _getSampleProducts() {
    return [
      Product(
        'Premium Solved Denim - Size 32',
        68.00,
        'Apparel',
        Icons.checkroom,
      ),
      Product(
        'Distressed Fossil Extra-Blue',
        149.00,
        'Apparel',
        Icons.checkroom,
      ),
      Product('Denim el Plum - Allieneso', 54.00, 'Apparel', Icons.checkroom),
      Product('Casual Sneakers', 89.00, 'Footwear', Icons.shopping_bag),
      Product('Leather Boots', 159.00, 'Footwear', Icons.shopping_bag),
      Product('Belt - Black', 35.00, 'Accessories', Icons.style),
      Product('Wallet', 45.00, 'Accessories', Icons.account_balance_wallet),
      Product('Sunglasses', 120.00, 'Accessories', Icons.visibility),
    ];
  }

  Future<void> _ensureSampleDataInDatabase() async {
    try {
      // Check if sample categories already exist
      final existingCategories = await DatabaseService.instance.getCategories();
      if (existingCategories.isEmpty) {
        // Create sample categories matching modern theme
        final sampleCategories = [
          Category(
            id: 'sample_cat_apparel',
            name: 'Apparel',
            description: 'Clothing and fashion items',
            icon: Icons.checkroom,
            color: Colors.blue,
            sortOrder: 1,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_footwear',
            name: 'Footwear',
            description: 'Shoes and footwear',
            icon: Icons.shopping_bag,
            color: Colors.green,
            sortOrder: 2,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_accessories',
            name: 'Accessories',
            description: 'Fashion accessories and add-ons',
            icon: Icons.style,
            color: Colors.purple,
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

        // Create sample items matching modern theme
        final sampleItems = [
          Item(
            id: 'sample_item_denim_32',
            name: 'Premium Solved Denim - Size 32',
            description: 'High-quality denim jeans',
            price: 68.00,
            categoryId: categoryMap['Apparel']?.id ?? 'sample_cat_apparel',
            icon: Icons.checkroom,
            color: Colors.blue,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 1,
          ),
          Item(
            id: 'sample_item_fossil_blue',
            name: 'Distressed Fossil Extra-Blue',
            description: 'Stylish distressed jeans',
            price: 149.00,
            categoryId: categoryMap['Apparel']?.id ?? 'sample_cat_apparel',
            icon: Icons.checkroom,
            color: Colors.indigo,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 2,
          ),
          Item(
            id: 'sample_item_denim_plum',
            name: 'Denim el Plum - Allieneso',
            description: 'Unique plum-colored denim',
            price: 54.00,
            categoryId: categoryMap['Apparel']?.id ?? 'sample_cat_apparel',
            icon: Icons.checkroom,
            color: Colors.deepPurple,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 3,
          ),
          Item(
            id: 'sample_item_sneakers',
            name: 'Casual Sneakers',
            description: 'Comfortable casual sneakers',
            price: 89.00,
            categoryId: categoryMap['Footwear']?.id ?? 'sample_cat_footwear',
            icon: Icons.shopping_bag,
            color: Colors.green,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 4,
          ),
          Item(
            id: 'sample_item_boots',
            name: 'Leather Boots',
            description: 'Premium leather boots',
            price: 159.00,
            categoryId: categoryMap['Footwear']?.id ?? 'sample_cat_footwear',
            icon: Icons.shopping_bag,
            color: Colors.brown,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 5,
          ),
          Item(
            id: 'sample_item_belt',
            name: 'Belt - Black',
            description: 'Classic black leather belt',
            price: 35.00,
            categoryId:
                categoryMap['Accessories']?.id ?? 'sample_cat_accessories',
            icon: Icons.style,
            color: Colors.black,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 6,
          ),
          Item(
            id: 'sample_item_wallet',
            name: 'Wallet',
            description: 'Genuine leather wallet',
            price: 45.00,
            categoryId:
                categoryMap['Accessories']?.id ?? 'sample_cat_accessories',
            icon: Icons.account_balance_wallet,
            color: Colors.grey,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 7,
          ),
          Item(
            id: 'sample_item_sunglasses',
            name: 'Sunglasses',
            description: 'Stylish UV protection sunglasses',
            price: 120.00,
            categoryId:
                categoryMap['Accessories']?.id ?? 'sample_cat_accessories',
            icon: Icons.visibility,
            color: Colors.black,
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
    final success = cartService.addProduct(p);
    if (!success) {
      ToastHelper.showToast(context, 'Failed to add product to cart');
    }
  }

  Future<void> removeFromCart(int index) async {
    final success = cartService.removeItem(index);
    if (!success) {
      ToastHelper.showToast(context, 'Failed to remove item from cart');
    }
  }

  Future<void> updateCartQuantity(int index, int newQuantity) async {
    final success = cartService.updateQuantity(index, newQuantity);
    if (!success) {
      ToastHelper.showToast(context, 'Failed to update quantity');
    }
  }

  Future<void> incrementCartQuantity(int index) async {
    final success = cartService.incrementQuantity(index);
    if (!success) {
      ToastHelper.showToast(context, 'Cannot increase quantity further');
    }
  }

  Future<void> decrementCartQuantity(int index) async {
    final success = cartService.decrementQuantity(index);
    if (!success) {
      ToastHelper.showToast(context, 'Cannot decrease quantity further');
    }
  }

  Future<void> _updateDualDisplay() async {
    try {
      await DualDisplayService().showCartItemsFromObjects(
        cartService.items,
        BusinessInfo.instance.currencySymbol,
      );
    } catch (e) {
      developer.log('Dual display update error: $e');
    }
  }

  double getSubtotal() {
    return Pricing.subtotal(cartService.items);
  }

  double getTaxAmount() {
    return Pricing.taxAmountWithDiscount(cartService.items, billDiscount);
  }

  double getServiceChargeAmount() {
    return Pricing.serviceChargeAmountWithDiscount(
      cartService.items,
      billDiscount,
    );
  }

  double getTotal() {
    return Pricing.totalWithDiscount(cartService.items, billDiscount);
  }

  void _clearCart() {
    cartService.clearCart();
    billDiscount = 0.0;
    ToastHelper.showToast(context, 'New sale started');
  }

  void _addToCart(Product product) {
    final success = cartService.addProduct(product);
    if (!success) {
      ToastHelper.showToast(context, 'Failed to add product to cart');
    } else {
      // Trigger cart add animation
      _cartAddAnimController.forward(from: 0.0).then((_) {
        if (mounted) {
          _cartAddAnimController.reverse();
        }
      });

      // Show brief success feedback
      ToastHelper.showToast(context, '${product.name} added');
    }
  }

  Future<void> _completeSale() async {
    if (cartService.isEmpty) {
      ToastHelper.showToast(context, 'Cart is empty');
      return;
    }

    if (_selectedPaymentMethod == null) {
      ToastHelper.showToast(context, 'Please select a payment method');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: getTotal(),
          availablePaymentMethods: paymentMethods,
          preSelectedPaymentMethod: _selectedPaymentMethod,
          cartItems: cartService.items,
          billDiscount: billDiscount,
          orderType: 'retail',
        ),
      ),
    );

    final parsedResult = PaymentResultParser.parse(
      result,
      fallbackAmount: getTotal(),
      fallbackPaymentMethod: paymentMethods.first,
    );
    if (parsedResult != null && mounted) {
      final normalizedSplits = parsedResult.paymentSplits.isNotEmpty
          ? parsedResult.paymentSplits
          : <PaymentSplit>[
              PaymentSplit(
                paymentMethod: parsedResult.paymentMethod,
                amount: parsedResult.amountPaid,
              ),
            ];

      final normalizedResult = PaymentResult(
        success: true,
        transactionId: parsedResult.transactionId,
        receiptNumber: parsedResult.receiptNumber,
        amountPaid: parsedResult.amountPaid,
        change: parsedResult.change,
        paymentSplits: normalizedSplits,
      );

      await _tryAutoPrintWithPaymentResult(
        items: cartService.items,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentResult: normalizedResult,
      );

      if (parsedResult.change > 0) {
        await DualDisplayService().showChange(
          parsedResult.change,
          BusinessInfo.instance.currencySymbol,
        );
      }
      await DualDisplayService().showThankYou();

      _clearCart();
      return;
    }

    if (result == true && mounted) {
      _clearCart();
      setState(() {
        _selectedPaymentMethod = paymentMethods.firstWhere(
          (method) => method.isDefault,
          orElse: () => paymentMethods.first,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: darkNavy,
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout();
          } else {
            return _buildLandscapeLayout();
          }
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(backgroundColor: darkNavy, body: content);
  }

  Future<void> _showCategoryProductsPopup(String categoryName) async {
    final categoryProducts = _getFilteredProductsSync(categoryName);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with category name and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Products grid
                Expanded(
                  child: categoryProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products in this category',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent:
                                    AppTokens.productTileMinWidth + 40,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: categoryProducts.length,
                          itemBuilder: (context, index) {
                            final product = categoryProducts[index];
                            return _buildProductCardForPopup(product);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCardForPopup(Product product) {
    return InkWell(
      onTap: () {
        addToCart(product);
        Navigator.of(context).pop(); // Close popup after adding to cart
        ToastHelper.showToast(context, '${product.name} added to cart');
      },
      child: Container(
        decoration: BoxDecoration(
          color: darkNavyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Product icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(product.icon, color: accentGreen, size: 30),
            ),
            const SizedBox(height: 8),
            // Product name
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Product price
            Text(
              '${BusinessInfo.instance.currencySymbol}${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: accentGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Product Grid - takes most of the space
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: _buildProductGrid(),
                      ),
                      const SizedBox(height: 12),
                      // Current Order - smaller section
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: _buildCurrentOrderSection(),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 8),
                      _buildPaymentMethodsRow(),
                      const SizedBox(height: 8),
                      _buildCategoriesRow(),
                      const SizedBox(height: 8),
                      SizedBox(height: 320, child: _buildNumberPad()),
                      const SizedBox(height: 8),
                      _buildBottomActions(),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    // Responsive left panel width: 35-40% of screen, max 420px
    // For 8" tablets (1280px): ~320-380px, for larger: up to 420px
    final leftPanelWidth = (screenWidth * 0.35).clamp(300.0, 420.0);
    
    // Responsive number pad height: Scale based on available height
    // Minimum 240px for basic functionality, max 300px
    final numberPadHeight = (screenHeight * 0.3).clamp(240.0, 300.0);
    
    // For very narrow landscapes (8" tablets), use compact layout
    final isNarrowLandscape = screenWidth < 900;
    
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          // Left Panel - Current Order (responsive width)
          Container(
            width: leftPanelWidth,
            color: darkNavy,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCurrentOrderSection(),
                  ),
                ),
                _buildBottomActions(),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
          // Right Panel - Centered content with responsive layout
          Expanded(
            child: Container(
              color: darkNavyLight,
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 600),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 12.0,
                        bottom: bottomPadding + 12.0,
                      ),
                      child: Column(
                        children: [
                          // Product Grid - flexible height
                          SizedBox(
                            height: (screenHeight - numberPadHeight - 180).clamp(200, 400),
                            child: _buildProductGrid(),
                          ),
                          const SizedBox(height: 12),
                          // Bottom controls: Compact layout for narrow screens
                          if (isNarrowLandscape)
                            // Vertical stack for 8" tablets (more readable)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCategoriesRow(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(flex: 2, child: _buildQuickActionsGrid()),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 1, child: _buildPaymentStack()),
                                  ],
                                ),
                              ],
                            )
                          else
                            // Horizontal layout for wider screens
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildCategoriesRow()),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: _buildQuickActionsGrid()),
                                const SizedBox(width: 12),
                                Expanded(flex: 1, child: _buildPaymentStack()),
                              ],
                            ),
                          const SizedBox(height: 12),
                          // Number pad - responsive height
                          SizedBox(
                            height: numberPadHeight,
                            child: _buildNumberPad(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick actions arranged as a 2x2 grid to match reference
  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionButton(
          'New Sale',
          Icons.add_circle_outline,
          accentBlue,
          _clearCart,
        ),
        _buildActionButton(
          'Customers',
          Icons.people_outline,
          accentGreen,
          () => ToastHelper.showToast(context, 'Customers (Coming Soon)'),
        ),
        _buildActionButton(
          'Orders',
          Icons.receipt_long_outlined,
          accentOrange,
          () => ToastHelper.showToast(context, 'Orders (Coming Soon)'),
        ),
        _buildActionButton(
          'Reports',
          Icons.bar_chart_outlined,
          accentOrange,
          () => ToastHelper.showToast(context, 'Reports (Coming Soon)'),
        ),
      ],
    );
  }

  // Payment buttons removed - using new _buildPaymentMethodsRow() instead
  Widget _buildPaymentStack() {
    return const SizedBox.shrink(); // Placeholder, payment methods moved to main UI
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: darkNavyLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products or scan barcode',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Barcode Scanner Button
              Container(
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_2, color: Colors.white),
                  onPressed: () => _openBarcodeScannerOrInput(),
                  tooltip: 'Scan Barcode',
                ),
              ),
              const SizedBox(width: 8),
              // Favorites Button
              Container(
                decoration: BoxDecoration(
                  color: _favoriteProductIds.isNotEmpty
                      ? accentPurple
                      : darkNavyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  onPressed: () => _showFavoritesMenu(),
                  tooltip: 'Quick Add Favorites',
                ),
              ),
            ],
          ),
          // Customer info section (if customer selected)
          if (selectedCustomer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.15),
                border: Border.all(color: accentBlue, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer: ${selectedCustomer!.name}',
                        style: TextStyle(
                          color: accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        selectedCustomer!.phone ?? 'No phone',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => selectedCustomer = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCustomerLookup(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add/Select Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomerLookup() {
    final searchController = TextEditingController();
    List<Customer> filteredCustomers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select or Add Customer'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer by name or phone',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredCustomers = customers
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ) ||
                                (c.phone?.contains(value) ?? false),
                          )
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Customer list
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text('No customers found'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _showAddCustomerDialog(
                                  searchController.text,
                                ),
                                child: const Text('Create New Customer'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(customer.name),
                              subtitle: Text(customer.phone ?? 'No phone'),
                              onTap: () {
                                selectedCustomer = customer;
                                setState(() {});
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddCustomerDialog('');
              },
              icon: const Icon(Icons.add),
              label: const Text('New Customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(String initialName) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'Enter customer name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                }
                return;
              }

              final now = DateTime.now();
              final newCustomer = Customer(
                id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                phone: phoneController.text,
                email: emailController.text,
                createdAt: now,
                updatedAt: now,
              );

              setState(() {
                customers.add(newCustomer);
                selectedCustomer = newCustomer;
              });

              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer added successfully')),
                );
              }
            },
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  void _openBarcodeScannerOrInput() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode/Product Code'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Scan or type product code',
            prefixIcon: Icon(Icons.qr_code_2),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _searchByBarcode(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _searchByBarcode(String barcode) {
    if (barcode.isEmpty) return;

    // Search by barcode or product code (SKU)
    _searchController.text = barcode;
    _onSearchChanged();

    // Try to auto-add if only one product matches
    final filteredProducts = _getFilteredProductsSync(selectedCategory);
    if (filteredProducts.length == 1) {
      _addToCart(filteredProducts.first);
      _searchController.clear();
      _onSearchChanged();
      ToastHelper.showToast(context, 'Added to cart');
    } else if (filteredProducts.isEmpty) {
      ToastHelper.showToast(context, 'Product not found');
    }
  }

  void _showFavoritesMenu() {
    if (_favoriteProductIds.isEmpty) {
      ToastHelper.showToast(
        context,
        'No favorites yet. Tap ♥ on products to add.',
      );
      return;
    }

    final favorites = products
        .where((p) => _favoriteProductIds.contains(p.name))
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Add Favorites',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: AppTokens.productTileMinWidth + 40,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final product = favorites[index];
                  return _buildFavoriteProductTile(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteProductTile(Product product) {
    return InkWell(
      onTap: () {
        _addToCart(product);
        Navigator.pop(context);
        _cartAddAnimController.forward().then(
          (_) => _cartAddAnimController.reverse(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentGreen),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(product.icon, size: 32, color: accentGreen),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '${BusinessInfo.instance.currencySymbol}${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentOrderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart header with animated add indicator
          Row(
            children: [
              const Text(
                'Current Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (cartService.items.isNotEmpty)
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(
                      parent: _cartAddAnimController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cartService.items.length} item${cartService.items.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: darkNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Cart Items
          ...cartService.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildCartItem(item, index);
          }),
          if (cartService.items.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'No items in cart',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          const SizedBox(height: 16),
          // Totals
          _buildTotalsSection(),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final filteredProducts = _getFilteredProductsSync(selectedCategory);

    if (filteredProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No products in ${selectedCategory == 'All' ? 'inventory' : selectedCategory.toLowerCase()}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppTokens.productTileMinWidth + 40,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: filteredProducts.length,
      addAutomaticKeepAlives: true, // Improve performance with keep alive
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        // Use RepaintBoundary to isolate rebuilds
        return RepaintBoundary(
          key: ValueKey(product.name),
          child: _buildProductCardWithFavorite(product),
        );
      },
    );
  }

  Widget _buildProductCardWithFavorite(Product product) {
    final isFavorite = _favoriteProductIds.contains(product.name);

    return Stack(
      children: [
        // Main product card
        InkWell(
          onLongPress: () => _showProductOptions(product),
          onTap: () => _addToCart(product),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkNavyLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Product image or icon (with caching)
                _buildProductImage(product),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Variant indicator
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.variants.length} variants',
                      style: const TextStyle(color: accentBlue, fontSize: 9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Favorite button (top-right corner)
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isFavorite) {
                  _favoriteProductIds.remove(product.name);
                } else {
                  _favoriteProductIds.add(product.name);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? accentPurple : Colors.white70,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(product.imagePath!),
            fit: BoxFit.cover,
            cacheWidth: 120,
            cacheHeight: 120,
            errorBuilder: (context, error, stackTrace) =>
                Icon(product.icon, color: accentGreen, size: 32),
          ),
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(product.icon, color: accentGreen, size: 32),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkNavyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: darkNavy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.product.icon, color: Colors.white70, size: 28),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'x${item.quantity}  ${BusinessInfo.instance.currencySymbol} ${item.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Price & Remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${BusinessInfo.instance.currencySymbol} ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => removeFromCart(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final info = BusinessInfo.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkNavyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', getSubtotal()),
          if (info.isTaxEnabled) _buildTotalRow('Tax', getTaxAmount()),
          if (info.isServiceChargeEnabled)
            _buildTotalRow('Service', getServiceChargeAmount()),
          if (billDiscount > 0) _buildTotalRow('Discount', -billDiscount),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${BusinessInfo.instance.currencySymbol} ${getTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: accentGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            '${BusinessInfo.instance.currencySymbol} ${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'New Sale',
              Icons.add_circle_outline,
              accentBlue,
              _clearCart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Customers',
              Icons.people_outline,
              accentGreen,
              () => ToastHelper.showToast(context, 'Customers (Coming Soon)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Orders',
              Icons.receipt_long_outlined,
              accentOrange,
              () => ToastHelper.showToast(context, 'Orders (Coming Soon)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Reports',
              Icons.bar_chart_outlined,
              accentOrange,
              () => ToastHelper.showToast(context, 'Reports (Coming Soon)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentMethodChip(
                paymentMethods[0],
                Icons.money,
                accentGreen,
              ),
              _buildPaymentMethodChip(
                paymentMethods[1],
                Icons.credit_card,
                accentBlue,
              ),
              _buildPaymentMethodChip(
                paymentMethods[3],
                Icons.wallet_membership,
                accentPurple,
              ),
              _buildPaymentMethodChip(
                PaymentMethod(id: 'cheque', name: 'Cheque'),
                Icons.receipt_long,
                accentOrange,
              ),
              _buildPaymentMethodChip(
                PaymentMethod(id: 'split', name: 'Split'),
                Icons.call_split,
                const Color(0xFF6C63FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
    ToastHelper.showToast(context, '${method.name} selected');
  }

  Widget _buildPaymentMethodChip(
    PaymentMethod method,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    return InkWell(
      onTap: () => _selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? Colors.white : color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              method.name,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: 'Enter card number',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: 'XXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ToastHelper.showToast(context, 'Card payment processed');
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _showEWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-Wallet Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEWalletOption('GCash', Icons.phone_android, accentBlue),
            const SizedBox(height: 12),
            _buildEWalletOption('Grab Pay', Icons.local_taxi, accentOrange),
            const SizedBox(height: 12),
            _buildEWalletOption(
              'TNG',
              Icons.credit_card,
              const Color(0xFF00BFB3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletOption(String name, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ToastHelper.showToast(context, '$name payment initiated');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showChequeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cheque Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Cheque Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cheque Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ToastHelper.showToast(context, 'Cheque recorded');
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showSplitPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Divide payment between multiple methods'),
              const SizedBox(height: 16),
              _buildSplitPaymentInput('Cash', accentGreen),
              const SizedBox(height: 12),
              _buildSplitPaymentInput('Card', accentBlue),
              const SizedBox(height: 12),
              _buildSplitPaymentInput('E-Wallet', accentPurple),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ToastHelper.showToast(context, 'Split payment configured');
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPaymentInput(String method, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            method,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: 'RM ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    // Filter out 'All' category and get actual categories
    final displayCategories = categories.where((cat) => cat != 'All').toList();

    // If no categories loaded yet, show loading or default
    if (displayCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _buildCategoryButton('Apparel', Icons.checkroom)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCategoryButton('Footwear', Icons.shopping_bag),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryButton('Accessories', Icons.style)),
          ],
        ),
      );
    }

    // Show all categories (no limit)
    final categoriesToShow = displayCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categoriesToShow.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            return SizedBox(
              width: 200,
              child: _buildCategoryButtonFromCategory(
                _categoryObjects.firstWhere(
                  (cat) => cat.name == categoriesToShow[i],
                  orElse: () => Category(
                    id: 'default_$i',
                    name: categoriesToShow[i],
                    description: '',
                    icon: _getDefaultIconForCategory(categoriesToShow[i]),
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getDefaultIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'apparel':
      case 'clothing':
        return Icons.checkroom;
      case 'footwear':
      case 'shoes':
        return Icons.shopping_bag;
      case 'accessories':
        return Icons.style;
      case 'food':
        return Icons.restaurant;
      case 'drinks':
      case 'beverages':
        return Icons.local_cafe;
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoryButton(String label, IconData icon) {
    return InkWell(
      onTap: () => _showCategoryProductsPopup(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedCategory == label ? accentGreen : darkNavyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedCategory == label ? accentGreen : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButtonFromCategory(Category category) {
    return InkWell(
      onTap: () => _showCategoryProductsPopup(category.name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedCategory == category.name
              ? accentGreen
              : darkNavyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedCategory == category.name
                ? accentGreen
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Container(
          decoration: BoxDecoration(
            color: darkNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Quantity input display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: darkNavyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedProductForQuantity != null
                          ? _selectedProductForQuantity!.name
                          : 'Quantity',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _quantityInput,
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Number pad buttons
              Row(
                children: [
                  Expanded(child: _buildNumberButton('1')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('2')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('3')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildNumberButton('4')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('5')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('6')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildNumberButton('7')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('8')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('9')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildNumberButton('0')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberButton(
                      '0',
                      label: '.',
                      hideNumber: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberButton(
                      'C',
                      isAction: true,
                      label: 'Clear',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNumberButton(
                      'Back',
                      isAction: true,
                      label: 'Delete',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildNumberButton(
                      'OK',
                      isAction: true,
                      color: accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(
    String number, {
    bool isAction = false,
    String? label,
    Color? color,
    bool hideNumber = false,
  }) {
    return InkWell(
      onTap: () => _handleNumberPadInput(number),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isAction
              ? (color ?? accentOrange.withOpacity(0.2))
              : const Color(0xFF3A4A5C),
          border: isAction
              ? Border.all(color: color ?? accentOrange, width: 2)
              : Border.all(color: Colors.white12, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label ?? (hideNumber ? '.' : number),
            style: TextStyle(
              color: isAction ? (color ?? accentOrange) : Colors.white,
              fontSize: isAction ? 14 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _handleNumberPadInput(String input) {
    setState(() {
      if (input == 'C') {
        // Clear
        _quantityInput = '1';
      } else if (input == 'Back') {
        // Delete last character
        if (_quantityInput.length > 1) {
          _quantityInput = _quantityInput.substring(
            0,
            _quantityInput.length - 1,
          );
        } else {
          _quantityInput = '1';
        }
      } else if (input == 'OK') {
        // Add to cart with specified quantity
        if (_selectedProductForQuantity != null && _quantityInput.isNotEmpty) {
          final quantity = int.tryParse(_quantityInput) ?? 1;
          if (quantity > 0) {
            for (int i = 0; i < quantity; i++) {
              _addToCart(_selectedProductForQuantity!);
            }
            _quantityInput = '1';
            _selectedProductForQuantity = null;
            ToastHelper.showToast(
              context,
              'Added $quantity item${quantity > 1 ? 's' : ''} to cart',
            );
          }
        }
      } else if (input == '0' && _quantityInput == '0') {
        // Prevent leading zeros
        return;
      } else {
        // Append number
        if (_quantityInput == '1' && input != '0') {
          _quantityInput = input;
        } else if (_quantityInput != '0') {
          _quantityInput += input;
        } else {
          _quantityInput = input;
        }
      }
    });
  }

  void _setProductForQuantityInput(Product product) {
    setState(() {
      _selectedProductForQuantity = product;
      _quantityInput = '1';
    });
  }

  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Quick add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addToCart(product);
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Quick Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Add with quantity button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _setProductForQuantityInput(product);
                },
                icon: const Icon(Icons.exposure),
                label: const Text('Add with Quantity'),
              ),
            ),
            const SizedBox(height: 8),
            // Variants button (if product has variants)
            if (product.variants.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showVariantSelection(product);
                  },
                  icon: const Icon(Icons.tune),
                  label: Text('Variants (${product.variants.length})'),
                ),
              ),
            const SizedBox(height: 8),
            // Toggle favorite button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    if (_favoriteProductIds.contains(product.name)) {
                      _favoriteProductIds.remove(product.name);
                      ToastHelper.showToast(context, 'Removed from favorites');
                    } else {
                      _favoriteProductIds.add(product.name);
                      ToastHelper.showToast(context, 'Added to favorites');
                    }
                  });
                },
                icon: Icon(
                  _favoriteProductIds.contains(product.name)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                label: Text(
                  _favoriteProductIds.contains(product.name)
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariantSelection(Product product) {
    if (product.variants.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No variants available')));
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.name} - Select Variant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: product.variants.asMap().entries.map((entry) {
              final index = entry.key;
              final variant = entry.value as Map<String, dynamic>;

              return ListTile(
                title: Text(variant['name'] ?? 'Variant ${index + 1}'),
                subtitle: variant['price'] != null
                    ? Text('RM ${(variant['price'] as num).toStringAsFixed(2)}')
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  // Add product with selected variant
                  _addToCart(product);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added: ${product.name} - ${variant['name'] ?? ''}',
                        ),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final subtotal = getSubtotal();
    final discountAmount = billDiscount;
    final tax = getTaxAmount();
    final serviceCharge = getServiceChargeAmount();
    final total = getTotal();

    return Column(
      children: [
        // Discount section
        if (billDiscount > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.15),
              border: Border.all(color: accentOrange, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount Applied',
                      style: TextStyle(
                        color: accentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${discountAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => billDiscount = 0.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Summary and actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Price summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkNavyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'RM ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (billDiscount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discount',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '-RM ${discountAmount.toStringAsFixed(2)}',
                            style: TextStyle(color: accentOrange),
                          ),
                        ],
                      ),
                    ],
                    if (BusinessInfo.instance.isTaxEnabled) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tax',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'RM ${tax.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                    if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service Charge',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'RM ${serviceCharge.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                    const Divider(color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  // Discount button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDiscountDialog(),
                      icon: const Icon(Icons.local_offer),
                      label: const Text('Discount'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Complete sale button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _completeSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Complete Sale',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Print receipt button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ToastHelper.showToast(context, 'Print Receipt'),
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5C6E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDiscountDialog() {
    final discountController = TextEditingController(
      text: billDiscount > 0 ? billDiscount.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter discount amount (RM):'),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefix: const Text('RM '),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0.0;
              if (discount >= 0) {
                final clampedDiscount = discount > getSubtotal()
                    ? getSubtotal()
                    : discount;
                setState(() => billDiscount = clampedDiscount);
                Navigator.pop(context);
                ToastHelper.showToast(
                  context,
                  'Discount applied: RM ${clampedDiscount.toStringAsFixed(2)}',
                );
              } else {
                ToastHelper.showToast(
                  context,
                  'Please enter a valid discount amount',
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // Payment processing methods
  // ignore: unused_element
  Future<void> _processCashPayment() async {
    if (cartService.items.isEmpty) {
      ToastHelper.showToast(context, 'Cart is empty');
      return;
    }

    final total = getTotal();
    final result = await PaymentService.instance.processCashPayment(
      totalAmount: total,
      amountPaid: total, // Assume exact payment for now
      cartItems: cartService.items,
      billDiscount: 0.0,
      orderType: 'retail',
    );

    if (result.success) {
      await _handlePaymentSuccess(result);
    } else {
      if (mounted) {
        developer.log('\u274c Cash payment failed: ${result.errorMessage}');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment Failed'),
            content: Text(
              result.errorMessage ?? 'Payment failed for unknown reason',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _processCardPayment() async {
    if (cartService.items.isEmpty) {
      ToastHelper.showToast(context, 'Cart is empty');
      return;
    }

    final total = getTotal();
    final result = await PaymentService.instance.processCardPayment(
      totalAmount: total,
      paymentMethod: PaymentMethod(id: 'card', name: 'Card'),
      cartItems: cartService.items,
      billDiscount: 0.0,
      orderType: 'retail',
    );

    if (result.success) {
      await _handlePaymentSuccess(result);
    } else {
      if (mounted) {
        developer.log('\u274c Card payment failed: ${result.errorMessage}');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment Failed'),
            content: Text(
              result.errorMessage ?? 'Payment failed for unknown reason',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentResult result) async {
    try {
      // Auto-print receipt with split payment support
      await _tryAutoPrintWithPaymentResult(
        items: cartService.items,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentResult: result,
      );

      // Show success message
      if (mounted) {
        ToastHelper.showToast(context, 'Payment successful!');
      }

      // Update customer display
      if (result.change > 0) {
        await DualDisplayService().showChange(
          result.change,
          BusinessInfo.instance.currencySymbol,
        );
      }
      await DualDisplayService().showThankYou();

      // Clear cart
      _clearCart();
    } catch (e) {
      developer.log('Error handling payment success: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Error after payment: $e');
      }
    }
  }

  Future<void> _tryAutoPrintWithPaymentResult({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentResult paymentResult,
  }) async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT (Retail): Auto-print is DISABLED, skipping');
        return;
      }

      // Prepare receipt data with split payment support
      final info = BusinessInfo.instance;
      final currency = info.currencySymbol;
      final now = DateTime.now();

      // Handle payment mode display for split payments
      String paymentMode;
      if (paymentResult.paymentSplits.length == 1) {
        paymentMode = paymentResult.paymentSplits.first.paymentMethod.name;
      } else {
        // Multiple payment methods - show summary
        final methods = paymentResult.paymentSplits
            .map((split) => split.paymentMethod.name)
            .toSet() // Remove duplicates
            .join('/');
        paymentMode = 'Split ($methods)';
      }

      final receiptNumber =
          paymentResult.receiptNumber ??
          now.millisecondsSinceEpoch.toString().substring(7);

      // E-Wallet metadata (if any split uses e-wallet)
      String? ewalletProvider;
      String? ewalletMerchantId;
      String? ewalletQR;
      if (paymentResult.paymentSplits.any(
        (s) =>
            s.paymentMethod.id == 'ewallet' ||
            s.paymentMethod.name.toLowerCase().contains('wallet'),
      )) {
        final settings = await EWalletService.instance.getSettings();
        ewalletProvider = (settings['provider'] as String?) ?? 'duitnow';
        ewalletMerchantId = (settings['merchant_id'] as String?) ?? '';
        ewalletQR = EWalletService.instance.buildDuitNowQR(
          amount: total,
          referenceId: receiptNumber,
          merchantId: ewalletMerchantId,
        );
      }

      final receiptData = {
        'store_name': info.businessName,
        'address': [
          info.fullAddress,
          if (info.taxNumber != null && info.taxNumber!.isNotEmpty)
            'Tax No: ${info.taxNumber}',
        ],
        'title': 'RECEIPT',
        'date':
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
        'customer': 'Walk-in Customer',
        'bill_no': receiptNumber,
        'payment_mode': paymentMode,
        'dr_ref': '',
        'currency': currency,
        if (ewalletProvider != null) 'ewallet_provider': ewalletProvider,
        if (ewalletMerchantId != null) 'ewallet_merchant_id': ewalletMerchantId,
        if (ewalletQR != null) 'ewallet_qr': ewalletQR,
        if (ewalletQR != null) 'ewallet_reference': receiptNumber,
        'items': items
            .map(
              (item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'amt': item.totalPrice,
              },
            )
            .toList(),
        'sub_total_qty': items.fold(0, (sum, item) => sum + item.quantity),
        'sub_total_amt': subtotal,
        'discount': 0.0,
        'taxes': tax > 0
            ? [
                {'name': 'Tax', 'amt': tax},
              ]
            : [],
        'service_charge': serviceCharge,
        'total': total,
        'amount_paid': paymentResult.amountPaid,
        'change': paymentResult.change,
        'payment_splits': paymentResult.paymentSplits
            .map(
              (split) => {
                'method': split.paymentMethod.name,
                'amount': split.amount,
                'reference': split.reference ?? '',
              },
            )
            .toList(),
      };

      // Load printers from database
      final allPrinters = await DatabaseService.instance.getPrinters();
      final printers = allPrinters
          .where((p) => p.type == PrinterType.receipt)
          .toList();

      if (printers.isEmpty) {
        developer.log('AUTO-PRINT (Retail): No receipt printers configured');
        return;
      }

      // Find default receipt printer
      final printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      // Show printing toast
      if (mounted) {
        ToastHelper.showToast(context, 'Printing receipt...');
      }

      // Print both customer and merchant receipts
      final printerService = PrinterService();
      await Future.delayed(const Duration(milliseconds: 250));

      // Validate printer config
      final validationMsg = printerService.validatePrinterConfig(printer);
      if (validationMsg != null) {
        developer.log(
          'AUTO-PRINT (Retail): Printer validation failed: $validationMsg',
        );
        if (mounted) {
          ToastHelper.showToast(context, 'Print failed: $validationMsg');
        }
        return;
      }

      // Print customer receipt first
      if (mounted) {
        ToastHelper.showToast(context, 'Printing customer receipt...');
      }

      final customerPrintResult = await printerService.printReceipt(
        printer,
        receiptData,
        receiptType: ReceiptType.customer,
      );

      if (!customerPrintResult) {
        developer.log('AUTO-PRINT (Retail): Customer receipt print failed');
        if (mounted) {
          ToastHelper.showToast(context, 'Customer receipt print failed');
        }
        return;
      }

      // Wait a moment before printing merchant copy
      await Future.delayed(const Duration(milliseconds: 500));

      // Print merchant receipt
      if (mounted) {
        ToastHelper.showToast(context, 'Printing merchant receipt...');
      }

      final merchantPrintResult = await printerService.printReceipt(
        printer,
        receiptData,
        receiptType: ReceiptType.merchant,
      );

      if (!merchantPrintResult) {
        developer.log('AUTO-PRINT (Retail): Merchant receipt print failed');
        if (mounted) {
          ToastHelper.showToast(context, 'Merchant receipt print failed');
        }
        return;
      }

      developer.log('AUTO-PRINT (Retail): Both receipts printed successfully');
    } catch (e) {
      developer.log('AUTO-PRINT (Retail): Exception - $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }
}
