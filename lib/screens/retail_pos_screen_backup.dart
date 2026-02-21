import 'dart:async';
import 'dart:developer' as developer;
// ignore: unused_import
import 'dart:math' as math;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/parked_sale_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_variant.dart';
import 'package:extropos/screens/barcode_scanner_screen.dart';
import 'package:extropos/screens/parked_sales_screen.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/receipt_preview_screen.dart';
import 'package:extropos/screens/shift/end_shift_dialog.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/parked_sale_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/user_activity_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/cart_item_widget.dart';
import 'package:extropos/widgets/customer_info_widget.dart';
import 'package:extropos/widgets/product_card.dart';
import 'package:extropos/widgets/responsive_layout.dart';
import 'package:extropos/widgets/split_bill_dialog.dart';
import 'package:extropos/widgets/variant_selection_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetailPOSScreen extends StatefulWidget {
  const RetailPOSScreen({super.key});

  @override
  State<RetailPOSScreen> createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  int _gridItemBuildLogCounter = 0;
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

  Future<void> _manageShift() async {
    final shift = ShiftService().currentShift;
    if (shift == null) {
      _checkShiftStatus();
      return;
    }

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shift Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Started: ${shift.startTime.toString().substring(0, 16)}'),
            Text('Opening Float: RM ${shift.openingCash.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'End Shift',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      await showDialog(
        context: context,
        builder: (context) => EndShiftDialog(shift: shift),
      );
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
    super.dispose();
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

  Future<void> _onCheckoutPressed() async {
    developer.log('CHECKOUT: Button pressed, starting checkout flow');

    // Show order total on customer display when checkout starts
    await DualDisplayService().showOrderTotal(
      getTotal(),
      BusinessInfo.instance.currencySymbol,
    );

    developer.log('CHECKOUT: Navigating to payment screen');
    final currentContext = context; // capture for async usage
    final parentNavigator = Navigator.of(currentContext);

    final result = await parentNavigator.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: getTotal(),
          availablePaymentMethods: paymentMethods,
          cartItems: cartItems,
          billDiscount: billDiscount,
          merchantId: selectedMerchant,
          orderType: 'retail',
          selectedCustomer: selectedCustomer,
          initialCustomerName: customerName,
          initialCustomerPhone: customerPhone,
          initialCustomerEmail: customerEmail,
        ),
      ),
    );

    developer.log('CHECKOUT: Returned from payment screen, result=$result');

    if (!mounted) {
      developer.log('CHECKOUT: Widget not mounted, aborting');
      return;
    }
    if (result != null && result['success'] == true) {
      developer.log('CHECKOUT: Payment successful, processing sale');

      final paymentMethod = result['paymentMethod'] as PaymentMethod;
      final change = result['change'] as double;
      final amountPaid = (result['amountPaid'] as double?) ?? getTotal();

      // Show payment amount on customer display
      await DualDisplayService().showPaymentAmount(
        amountPaid,
        BusinessInfo.instance.currencySymbol,
      );

      final itemsSnapshot = cartItems
          .map(
            (ci) => CartItem(
              ci.product,
              ci.quantity,
              modifiers: ci.modifiers,
              priceAdjustment: ci.priceAdjustment,
              discountPerUnit: ci.discountPerUnit,
            ),
          )
          .toList();

      // Save completed sale to database with customer information
      String? orderNumber;
      if (TrainingModeService.instance.isTrainingMode) {
        orderNumber = 'TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        TrainingModeService.instance.addTrainingTransaction({
          'orderNumber': orderNumber,
          'cartItems': itemsSnapshot.map((c) => c.toJson()).toList(),
          'subtotal': getSubtotal(),
          'tax': getTaxAmount(),
          'serviceCharge': getServiceChargeAmount(),
          'total': getTotal(),
          'paymentMethod': paymentMethod.name,
          'amountPaid': amountPaid,
          'change': change,
          'orderType': 'retail',
          'merchantId': selectedMerchant,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'specialInstructions': specialInstructions,
        });
      } else {
        orderNumber = await DatabaseService.instance.saveCompletedSale(
          cartItems: itemsSnapshot,
          subtotal: getSubtotal(),
          tax: getTaxAmount(),
          serviceCharge: getServiceChargeAmount(),
          total: getTotal(),
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          change: change,
          orderType: 'retail',
          merchantId: selectedMerchant,
          customerName: customerName,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
          specialInstructions: specialInstructions,
        );
      }

      // Log the order number for debugging
      developer.log('Sale completed with order number: $orderNumber');

      // Log transaction activity for user tracking
      final currentUser = UserSessionService().currentActiveUser;
      if (currentUser != null) {
        await UserActivityService.instance.logTransaction(
          currentUser.id,
          orderNumber,
          getTotal(),
          paymentMethod: paymentMethod.name,
          discountAmount: billDiscount,
          taxAmount: getTaxAmount(),
          taxRate:
              0.0, // Category-based tax rates are already calculated in taxAmount
        );
      }

      // Retail mode doesn't need kitchen orders - skip kitchen printing
      // (Only restaurant and cafe modes need kitchen orders)

      // Auto-print if enabled in settings (fire and forget, don't block UI)
      developer.log('Calling _tryAutoPrint...');
      _tryAutoPrint(
        items: itemsSnapshot,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
      ).catchError((e) {
        developer.log('AUTO-PRINT ERROR (catchError): $e');
      });

      final currentContext = context;
      await parentNavigator.push(
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(
            items: itemsSnapshot,
            subtotal: getSubtotal(),
            tax: getTaxAmount(),
            serviceCharge: getServiceChargeAmount(),
            total: getTotal(),
            paymentMethod: paymentMethod,
            amountPaid: amountPaid,
            change: change,
            merchantId: selectedMerchant,
          ),
        ),
      );

      ToastHelper.showToast(
        currentContext,
        'Payment successful! Method: ${paymentMethod.name}',
      );

      // Show change amount on customer display
      if (change > 0) {
        await DualDisplayService().showChange(
          change,
          BusinessInfo.instance.currencySymbol,
        );
      }

      // Show thank you message on customer display
      await DualDisplayService().showThankYou();

      clearCart();
    }
  }

  // Auto-print receipt if enabled in settings
  Future<void> _tryAutoPrint({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
  }) async {
    try {
      // Load receipt settings to check if auto-print is enabled
      final settings = await DatabaseService.instance.getReceiptSettings();

      developer.log(
        'AUTO-PRINT: Settings loaded, autoPrint=${settings.autoPrint}',
      );

      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT: Disabled in settings');
        return; // Auto-print is disabled
      }

      // Get printer service
      final printerService = PrinterService();

      // Check if there's a printer available - prefer default, then active, then first
      developer.log('AUTO-PRINT: Loading printers from database...');
      final allPrinters = await DatabaseService.instance.getPrinters();
      developer.log('AUTO-PRINT: Found ${allPrinters.length} saved printers');

      // Filter for RECEIPT printers only (not kitchen/bar printers)
      final printers = allPrinters
          .where((p) => p.type == PrinterType.receipt)
          .toList();
      developer.log('AUTO-PRINT: Found ${printers.length} receipt printers');

      if (printers.isEmpty) {
        developer.log('AUTO-PRINT: No receipt printers configured, skipping');
        return; // No printer found, skip auto-print
      }

      // Find default receipt printer, or just first receipt printer
      Printer printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      developer.log(
        'AUTO-PRINT: Using printer: ${printer.name} (${printer.type.name}, isDefault=${printer.isDefault}, status=${printer.status.name})',
      );

      // Build receipt content using settings
      final info = BusinessInfo.instance;
      final currency = info.currencySymbol;
      final now = DateTime.now();

      // Prepare receipt data in the format expected by the generator
      // NOTE: Remove 'items' array to force Android native code to use formatted 'content' only
      // This prevents duplicate printing (structured items + formatted content)
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
        'customer': '', // No customer info in retail mode
        'bill_no': '', // Could add order number here
        'payment_mode': paymentMethod.name,
        'dr_ref': '', // Not used in retail
        'currency': currency,
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
        'discount': 0.0, // No discount in current implementation
        'taxes': tax > 0
            ? [
                {'name': 'Tax', 'amt': tax},
              ]
            : [],
        'service_charge': serviceCharge,
        'total': total,
        'cash': amountPaid,
        'cash_tendered': amountPaid,
        'change': change, // Add change amount to receipt data
      };

      // Try to print silently (don't show errors to user, this is background)
      developer.log('AUTO-PRINT: Sending to printer...');
      await Future.delayed(const Duration(milliseconds: 250));
      final preflightMsg = await printerService.preflightPrinterCheck(printer);
      if (preflightMsg != null) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Printer Preflight Check'),
              content: SingleChildScrollView(
                child: SelectableText(preflightMsg),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final updated =
                        await PrintersManagementScreen.openPrinterEditor(
                          context,
                          printer,
                        );
                    if (!mounted) return;
                    if (updated != null) {
                      final postflight = await PrinterService()
                          .preflightPrinterCheck(updated);
                      if (postflight == null) {
                        final ok = await PrinterService().printReceipt(
                          updated,
                          receiptData,
                        );
                        if (ok) {
                          if (mounted) {
                            ToastHelper.showToast(
                              context,
                              'Print succeeded after fixing printer.',
                            );
                          }
                        } else {
                          final logs = PrinterService().getRecentPrinterLogs(
                            count: 50,
                          );
                          if (mounted) {
                            await showDialog<void>(
                              context: context,
                              builder: (ctx2) => AlertDialog(
                                title: const Text('Print Retry Failed'),
                                content: SingleChildScrollView(
                                  child: SelectableText(logs.join('\n')),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx2),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      } else {
                        if (mounted) {
                          await showDialog<void>(
                            context: context,
                            builder: (ctx3) => AlertDialog(
                              title: const Text('Preflight still failing'),
                              content: SingleChildScrollView(
                                child: SelectableText(postflight),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx3),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Fix now & Retry'),
                ),
              ],
            ),
          );
        }
        return;
      }
      final printResult = await printerService.printReceipt(
        printer,
        receiptData,
      );
      developer.log('AUTO-PRINT: Print result = $printResult');
      if (!printResult) {
        developer.log(
          'AUTO-PRINT: printReceipt failed — not auto-running external print chooser to avoid false success. Please check printer or run a manual test print.',
        );
        if (mounted) {
          ToastHelper.showToast(
            context,
            'Auto-print failed — not falling back to external printing. Please test the printer from Settings > Printers.',
          );
          final validationMsg = PrinterService().validatePrinterConfig(printer);
          final pluginMsg = PrinterService().getLastPluginMessage();
          final details = StringBuffer();
          if (validationMsg != null && validationMsg.isNotEmpty) {
            details.writeln('Validation issue: $validationMsg');
          }
          details.writeln(
            'Connection details: IP=${printer.ipAddress ?? '<none>'}, USB=${printer.usbDeviceId ?? '<none>'}, BT=${printer.bluetoothAddress ?? '<none>'}',
          );
          if (pluginMsg != null && pluginMsg.isNotEmpty) {
            details.writeln('\nPlugin message: $pluginMsg');
          }
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Printer Issue'),
              content: SingleChildScrollView(
                child: SelectableText(details.toString()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrintersManagementScreen(openPrinterId: printer.id),
                      ),
                    );
                  },
                  child: const Text('Fix now'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final logs = PrinterService().getRecentPrinterLogs(
                      count: 50,
                    );
                    await Clipboard.setData(
                      ClipboardData(text: logs.join('\n')),
                    );
                    if (mounted) {
                      ToastHelper.showToast(
                        context,
                        'Logs copied to clipboard',
                      );
                    }
                  },
                  child: const Text('Copy Logs'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          final testOk = await PrinterService().testPrint(printer);
          if (AppSettings.instance.autoDebugPrintOnSampleFailure && testOk) {
            ToastHelper.showToast(
              context,
              'Auto-running native debug print...',
            );
            final debugOkAuto = await PrinterService().debugForcePrint(
              printer,
              receiptData,
            );
            final dlAuto = PrinterService().getRecentPrinterLogs(count: 50);
            if (!mounted) return;
            await showDialog<void>(
              context: context,
              builder: (ctxAuto) => AlertDialog(
                title: Text(
                  debugOkAuto
                      ? 'Auto Debug Print Succeeded'
                      : 'Auto Debug Print Failed',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: SelectableText(dlAuto.join('\n')),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctxAuto),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
          if (kDebugMode) {
            // Offer debug force print to diagnose native plugin issues
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Auto-print failed'),
                content: const Text(
                  'Auto-print failed. Would you like to run a native debug print (bypasses validation) to help diagnose the issue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await PrinterService().debugForcePrint(
                        printer,
                        receiptData,
                      );
                      final logs = PrinterService().getRecentPrinterLogs(
                        count: 50,
                      );
                      if (!mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          title: Text(
                            ok ? 'Debug Print Success' : 'Debug Print Failed',
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: SelectableText(logs.join('\n')),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx2),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Run Debug Print'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      // Silently fail - auto-print is a convenience feature, not critical
      developer.log('AUTO-PRINT ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildSw = Stopwatch()..start();
    final filterSw = Stopwatch()..start();
    final filteredProducts = _getFilteredProductsSync(selectedCategory);
    filterSw.stop();
    if (kDebugMode) {
      developer.log(
        'RETAIL POS: filtered ${filteredProducts.length} products in ${filterSw.elapsedMilliseconds}ms for category=$selectedCategory',
        name: 'retail_pos_perf',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      buildSw.stop();
      if (kDebugMode) {
        developer.log(
          'RETAIL POS: build finished in ${buildSw.elapsedMilliseconds}ms (category=$selectedCategory)',
        );
      }
    });

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: ResponsiveLayout(
          builder: (context, constraints, info) {
            // Check orientation first - portrait always uses top-bottom layout
            if (info.isPortrait) {
              return _buildPhoneLayout(filteredProducts, info);
            }

            // Landscape orientation - use width-based breakpoints
            final isPhone = info.width < 600;
            final isTablet = info.width >= 600 && info.width < 900;

            // Use different layouts based on screen size
            if (isPhone) {
              return _buildPhoneLayout(filteredProducts, info);
            } else if (isTablet) {
              return _buildTabletLayout(filteredProducts, info);
            } else {
              return _buildDesktopLayout(filteredProducts, info);
            }
          },
        ),
      ),
    );
  }

  // Phone layout (stacked, optimized for small screens)
  Widget _buildPhoneLayout(
    List<Product> filteredProducts,
    ResponsiveInfo info,
  ) {
    return Column(
      children: [
        // TOP HALF: Categories and Products
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Category filter + merchant selection
              Container(
                padding: const EdgeInsets.all(8),
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
                    const SizedBox(width: 8),
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
                          onChanged: (v) =>
                              setState(() => selectedMerchant = v ?? 'none'),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _manageShift,
                      tooltip: 'Shift Management',
                    ),
                  ],
                ),
              ),
              // Products grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? SingleChildScrollView(
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
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
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
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Use adaptive maxCrossAxisExtent for responsive columns
                          return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      AppTokens.productTileMinWidth + 40,
                                  childAspectRatio: 0.9,
                                  crossAxisSpacing: AppSpacing.s,
                                  mainAxisSpacing: AppSpacing.s,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              if (_gridItemBuildLogCounter < 20 && kDebugMode) {
                                _gridItemBuildLogCounter++;
                                developer.log(
                                  'RETAIL POS: Grid build index=$index product=${filteredProducts[index].name}',
                                  name: 'retail_pos_grid',
                                );
                              }
                              return ProductCard(
                                product: filteredProducts[index],
                                onTap: () => addToCart(filteredProducts[index]),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // BOTTOM HALF: Cart items and checkout
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Cart header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cart (${cartItems.length} items)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (cartItems.isNotEmpty)
                            TextButton.icon(
                              onPressed: clearCart,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Action buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final scannedProduct =
                                    await Navigator.push<Product>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BarcodeScannerScreen(),
                                      ),
                                    );
                                if (scannedProduct != null) {
                                  addToCart(scannedProduct);
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('Scan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: cartItems.isEmpty
                                  ? null
                                  : () async {
                                      final notes = await showDialog<String>(
                                        context: context,
                                        builder: (context) => _ParkSaleDialog(),
                                      );

                                      if (notes != null) {
                                        final sale = ParkedSale.fromCart(
                                          cartItems: cartItems,
                                          subtotal: getSubtotal(),
                                          taxAmount: getTaxAmount(),
                                          serviceChargeAmount:
                                              getServiceChargeAmount(),
                                          total: getTotal(),
                                          customerName: customerName,
                                          customerPhone: customerPhone,
                                          customerEmail: customerEmail,
                                          specialInstructions:
                                              specialInstructions,
                                          notes: notes,
                                        );

                                        try {
                                          await ParkedSaleService.instance
                                              .saveParkedSale(sale);
                                          clearCart();
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Sale parked successfully',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error parking sale: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.local_parking, size: 18),
                              label: const Text('Park'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final resumedSale =
                                    await Navigator.push<ParkedSale>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ParkedSalesScreen(),
                                      ),
                                    );

                                if (resumedSale != null) {
                                  // Clear current cart and load parked sale
                                  setState(() {
                                    cartItems.clear();
                                    cartItems.addAll(resumedSale.cartItems);
                                    customerName = resumedSale.customerName;
                                    customerPhone = resumedSale.customerPhone;
                                    customerEmail = resumedSale.customerEmail;
                                    specialInstructions =
                                        resumedSale.specialInstructions;
                                  });

                                  // Delete the resumed sale
                                  await ParkedSaleService.instance
                                      .deleteParkedSale(resumedSale.id);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sale resumed successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: const Text('Resume'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Customer information widget - make flexible to prevent overflow
                Flexible(
                  flex: 0,
                  child: CustomerInfoWidget(
                    customerName: selectedCustomer?.name ?? customerName,
                    customerPhone: selectedCustomer?.phone ?? customerPhone,
                    customerEmail: selectedCustomer?.email ?? customerEmail,
                    specialInstructions: specialInstructions,
                    onEdit: () async {
                      final customerInfo =
                          await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => CustomerInfoDialog(
                              initialName:
                                  selectedCustomer?.name ?? customerName,
                              initialPhone:
                                  selectedCustomer?.phone ?? customerPhone,
                              initialEmail:
                                  selectedCustomer?.email ?? customerEmail,
                              initialNotes: specialInstructions,
                            ),
                          );

                      if (customerInfo != null) {
                        setState(() {
                          customerName = customerInfo['customerName'];
                          customerPhone = customerInfo['customerPhone'];
                          customerEmail = customerInfo['customerEmail'];
                          specialInstructions =
                              customerInfo['specialInstructions'];
                          selectedCustomer = customerInfo['selectedCustomer'];
                        });
                      }
                    },
                  ),
                ),
                // Cart items list
                Expanded(
                  child: cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cart is empty',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap items above to add to cart',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) => CartItemWidget(
                            item: cartItems[index],
                            onRemove: () => removeFromCart(index),
                            onAdd: () => addToCart(cartItems[index].product),
                            onSetDiscount: (v) => setState(
                              () => cartItems[index].discountPerUnit = v,
                            ),
                            onSetNotes: (notes) =>
                                setState(() => cartItems[index].notes = notes),
                          ),
                        ),
                ),
                // Checkout section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Customer information display
                      if (selectedCustomer != null || customerName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF2563EB),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedCustomer?.name ??
                                        customerName ??
                                        'Customer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedCustomer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        selectedCustomer!.customerTier,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (selectedCustomer != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${selectedCustomer!.visitCount} visits • RM${selectedCustomer!.totalSpent.toStringAsFixed(2)} spent',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${selectedCustomer!.loyaltyPoints} pts',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Earn ${getLoyaltyPointsEarned()} points from this purchase',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            FormattingService.currency(getTotal()),
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: cartItems.isEmpty
                                  ? null
                                  : () async {
                                      final result =
                                          await showDialog<List<CartItem>>(
                                            context: context,
                                            builder: (context) =>
                                                SplitBillDialog(
                                                  cartItems: cartItems,
                                                  tableCapacity: 0,
                                                ),
                                          );
                                      if (result != null && result.isNotEmpty) {
                                        // Apply split: subtract quantities from main cart
                                        setState(() {
                                          for (final s in result) {
                                            final idx = cartItems.indexWhere(
                                              (ci) => ci
                                                  .hasSameConfigurationWithDiscount(
                                                    s.product,
                                                    s.modifiers,
                                                    s.discountPerUnit,
                                                    otherPriceAdjustment:
                                                        s.priceAdjustment,
                                                  ),
                                            );
                                            if (idx != -1) {
                                              final orig = cartItems[idx];
                                              final remaining =
                                                  orig.quantity - s.quantity;
                                              if (remaining <= 0) {
                                                cartItems.removeAt(idx);
                                              } else {
                                                cartItems[idx].quantity =
                                                    remaining;
                                              }
                                            }
                                          }
                                        });
                                        // Launch checkout flow for the split items
                                        final currentContext = context;
                                        final paymentResult =
                                            await Navigator.of(
                                              currentContext,
                                            ).push(
                                              MaterialPageRoute(
                                                builder: (_) => PaymentScreen(
                                                  totalAmount: result.fold(
                                                    0.0,
                                                    (sum, ci) =>
                                                        sum + ci.totalPrice,
                                                  ),
                                                  availablePaymentMethods:
                                                      paymentMethods,
                                                  cartItems: result,
                                                  billDiscount: 0.0,
                                                  merchantId: selectedMerchant,
                                                  orderType: 'retail',
                                                ),
                                              ),
                                            );
                                        if (paymentResult != null &&
                                            paymentResult['success'] == true) {
                                          // No-op here; PaymentScreen already handles saveCompletedSale
                                        }
                                      }
                                    },
                              child: const Text('Split Bill'),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: cartItems.isEmpty
                                  ? null
                                  : _onCheckoutPressed,
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Checkout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
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
            ),
          ),
        ),
      ],
    );
  }

  // Tablet layout (side-by-side with cart)
  Widget _buildTabletLayout(
    List<Product> filteredProducts,
    ResponsiveInfo info,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Category filter + merchant selection
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: info.isPortrait
                          ? Material(
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
                            )
                          : SizedBox(
                              height: 56,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final c = categories[index];
                                  final isSelected = c == selectedCategory;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: FilterChip(
                                      label: Text(c),
                                      selected: isSelected,
                                      onSelected: (_) => _onCategorySelected(c),
                                      selectedColor: const Color(0xFF2563EB),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  );
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
                          onChanged: (v) =>
                              setState(() => selectedMerchant = v ?? 'none'),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _manageShift,
                      tooltip: 'Shift Management',
                    ),
                  ],
                ),
              ),
              // Products grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No items available.\nOpen Settings → Database Test to restore demo data.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Use the menu button (☰) at the top to access Settings.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Grid columns are handled by maxCrossAxisExtent
                          return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      AppTokens.productTileMinWidth + 40,
                                  childAspectRatio: 0.95,
                                  crossAxisSpacing: AppSpacing.m,
                                  mainAxisSpacing: AppSpacing.m,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) => ProductCard(
                              product: filteredProducts[index],
                              onTap: () => addToCart(filteredProducts[index]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Cart sidebar
        Container(
          width: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.shopping_cart),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Current Order',
                        style: TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                        child: Text(
                          'Cart is empty',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) => CartItemWidget(
                          item: cartItems[index],
                          onRemove: () => removeFromCart(index),
                          onAdd: () => addToCart(cartItems[index].product),
                          onSetDiscount: (v) => setState(
                            () => cartItems[index].discountPerUnit = v,
                          ),
                          onSetNotes: (notes) =>
                              setState(() => cartItems[index].notes = notes),
                        ),
                      ),
              ),
              // Totals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(FormattingService.currency(getSubtotal())),
                      ],
                    ),
                    if (BusinessInfo.instance.isTaxEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (${BusinessInfo.instance.taxRatePercentage})',
                          ),
                          Text(FormattingService.currency(getTaxAmount())),
                        ],
                      ),
                    ],
                    if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage})',
                          ),
                          Text(
                            FormattingService.currency(
                              getServiceChargeAmount(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (billDiscount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount'),
                          Text(FormattingService.currency(billDiscount)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormattingService.currency(getTotal()),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: cartItems.isEmpty ? null : clearCart,
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: cartItems.isEmpty
                              ? null
                              : () async {
                                  final controller = TextEditingController(
                                    text: billDiscount.toStringAsFixed(2),
                                  );
                                  final res = await showDialog<double?>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Apply discount (RM)'),
                                      content: TextField(
                                        controller: controller,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          hintText: '0.00',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final v =
                                                double.tryParse(
                                                  controller.text,
                                                ) ??
                                                0.0;
                                            Navigator.of(context).pop(v);
                                          },
                                          child: const Text('Apply'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (res != null) {
                                    setState(() => billDiscount = res);
                                    _updateDualDisplay(); // Update display after discount change
                                  }
                                },
                          icon: const Icon(Icons.local_offer_outlined),
                          tooltip: 'Apply discount',
                        ),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : _onCheckoutPressed,
                            child: const Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop layout (optimized for large screens and fullscreen)
  Widget _buildDesktopLayout(
    List<Product> filteredProducts,
    ResponsiveInfo info,
  ) {
    if (kDebugMode) {
      developer.log(
        'RETAIL POS: _buildDesktopLayout products=${filteredProducts.length}, columns=${info.columns}, width=${info.width}',
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Category filter
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: info.isPortrait
                    ? Material(
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
                      )
                    : SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final c = categories[index];
                            final isSelected = c == selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: FilterChip(
                                label: Text(c),
                                selected: isSelected,
                                onSelected: (_) => _onCategorySelected(c),
                                selectedColor: const Color(0xFF2563EB),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Products grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, inner) {
                    // Using adaptive tile sizes via maxCrossAxisExtent, no explicit 'cols' needed
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
                                  size: 56,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No items available.\nOpen Settings → Database Test to restore demo data.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Use the menu button (☰) at the top to access Settings.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
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
                      padding: const EdgeInsets.all(AppSpacing.m),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: AppTokens.productTileMinWidth + 40,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: AppSpacing.m,
                        mainAxisSpacing: AppSpacing.m,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) => ProductCard(
                        product: filteredProducts[index],
                        onTap: () => addToCart(filteredProducts[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Cart sidebar
        Container(
          width: info.width < 1200 ? info.width * 0.3 : 400,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_cart),
                    SizedBox(width: 12),
                    Text('Current Order', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                        child: Text(
                          'Cart is empty',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) => CartItemWidget(
                          item: cartItems[index],
                          onRemove: () => removeFromCart(index),
                          onAdd: () => addToCart(cartItems[index].product),
                          onSetDiscount: (v) => setState(
                            () => cartItems[index].discountPerUnit = v,
                          ),
                          onSetNotes: (notes) =>
                              setState(() => cartItems[index].notes = notes),
                        ),
                      ),
              ),
              // Customer Information
              if (cartItems.isNotEmpty)
                CustomerInfoWidget(
                  customerName: customerName,
                  customerPhone: customerPhone,
                  customerEmail: customerEmail,
                  specialInstructions: specialInstructions,
                  onEdit: () async {
                    final customerInfo = await showDialog<Map<String, String?>>(
                      context: context,
                      builder: (context) => CustomerInfoDialog(
                        initialName: customerName,
                        initialPhone: customerPhone,
                        initialEmail: customerEmail,
                        initialNotes: specialInstructions,
                      ),
                    );

                    if (customerInfo != null && mounted) {
                      setState(() {
                        customerName = customerInfo['customerName'];
                        customerPhone = customerInfo['customerPhone'];
                        customerEmail = customerInfo['customerEmail'];
                        specialInstructions =
                            customerInfo['specialInstructions'];
                      });
                    }
                  },
                ),
              // Totals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(FormattingService.currency(getSubtotal())),
                      ],
                    ),
                    if (BusinessInfo.instance.isTaxEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Tax (${BusinessInfo.instance.taxRatePercentage})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(FormattingService.currency(getTaxAmount())),
                        ],
                      ),
                    ],
                    if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            FormattingService.currency(
                              getServiceChargeAmount(),
                            ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormattingService.currency(getTotal()),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: cartItems.isEmpty ? null : clearCart,
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : _onCheckoutPressed,
                            child: const Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
