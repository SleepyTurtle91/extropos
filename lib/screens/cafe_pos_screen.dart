import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/shift/end_shift_dialog.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/user_activity_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/payment_result_parser.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/cart_item_widget.dart';
import 'package:extropos/widgets/customer_info_widget.dart';
import 'package:extropos/widgets/modifier_selection_dialog.dart';
import 'package:extropos/widgets/product_card.dart';
import 'package:extropos/widgets/responsive_layout.dart';
import 'package:extropos/widgets/split_bill_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CafePOSScreen extends StatefulWidget {
  /// Optional test seams: provide initial cart items and skip DB/shift checks.
  final List<CartItem> initialCartItems;
  final bool skipDbLoad;
  final bool skipShiftCheck;

  const CafePOSScreen({
    super.key,
    this.initialCartItems = const [],
    this.skipDbLoad = false,
    this.skipShiftCheck = false,
  });

  @override
  State<CafePOSScreen> createState() => _CafePOSScreenState();
}

class CafeOrder {
  final int number;
  final List<CartItem> items;
  final DateTime createdAt;
  bool called;
  bool completed;

  CafeOrder({
    required this.number,
    required this.items,
    required this.createdAt,
    this.called = false,
    this.completed = false,
  });

  double get subtotal => items.fold(0.0, (s, c) => s + c.totalPrice);
}

class _CafePOSScreenState extends State<CafePOSScreen> {
  late List<CartItem> cartItems;
  final List<CafeOrder> activeOrders = [];
  int nextOrderNumber = 1;
  final Map<String, List<Product>> _productFilterCache = {};
  Timer? _categoryDebounceTimer;
  int _gridItemBuildLogCounter = 0;

  String selectedCategory = 'All';
  // Start empty by default — no fallback mock products or categories on first load
  List<String> categories = ['All'];

  List<Product> products = [];
  String selectedMerchant = 'none';

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: 'cash', name: 'Cash', isDefault: true),
    PaymentMethod(id: 'card', name: 'Card'),
    PaymentMethod(id: 'ewallet', name: 'E-Wallet'),
  ];

  // Customer information for current order
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? specialInstructions;

  @override
  void initState() {
    super.initState();
    // Listen to BusinessInfo changes for real-time tax/service charge updates
    BusinessInfo.instance.addListener(_onBusinessInfoChanged);
    cartItems = List<CartItem>.from(widget.initialCartItems);
    try {
      if (!widget.skipDbLoad) {
        _loadFromDatabase();
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load categories/items from DB: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
    if (!widget.skipShiftCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkShiftStatus();
      });
    }
  }

  Future<void> _checkShiftStatus() async {
    try {
      final user = LockManager.instance.currentUser;
      if (user == null) return;

      await ShiftService().initialize(user.id);

      // Safe shift check with null coalescing
      final hasShift = ShiftService().hasActiveShift;
      if (!hasShift && mounted) {
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
    } catch (e, stackTrace) {
      developer.log('Error in _checkShiftStatus: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastHelper.showToast(context, 'Error checking shift status. Please try again.');
      }
    }
  }

  Future<void> _manageShift() async {
    try {
      final shift = ShiftService().currentShift;
      if (shift == null) {
        _checkShiftStatus();
        return;
      }

      if (!mounted) return;

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
    } catch (e, stackTrace) {
      developer.log('Error in _manageShift: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        ToastHelper.showToast(context, 'Error managing shift. Please try again.');
      }
    }
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    if (!mounted) return;
    if (kDebugMode) {
      developer.log(
        'CAFE POS: category selected $category (debounced)',
        name: 'cafe_pos_perf',
      );
      developer.log('CAFE POS: category selected (debounced) $category');
    }
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        selectedCategory = category;
      });
      // No-op here; we'll update display in addToCart after state changes
    });
  }

  // Cart ops
  Future<void> addToCart(Product p) async {
    try {
      // Find the Item by name to get categoryId for modifiers
      final items = await DatabaseService.instance.getItems();
      final item = items.firstWhere(
        (it) => it.name == p.name,
        orElse: () => Item(
          id: '',
          name: p.name,
          description: '',
          price: p.price,
          categoryId: '',
          icon: p.icon,
          color: Colors.blue,
        ),
      );

      List<ModifierItem> selectedModifiers = [];
      double priceAdjustment = 0.0;

      // Show modifier dialog if item has a category
      if (item.categoryId.isNotEmpty) {
        if (!mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) =>
              ModifierSelectionDialog(item: item, categoryId: item.categoryId),
        );

        if (!mounted) return;
        if (result == null) return; // User cancelled

        selectedModifiers = result['modifiers'] as List<ModifierItem>;
        priceAdjustment = result['priceAdjustment'] as double;
      }

      // Apply merchant override
      if (selectedMerchant != 'none' && selectedMerchant != 'takeaway') {
        final mprice = item.merchantPrices[selectedMerchant];
        if (mprice != null) {
          priceAdjustment += (mprice - item.price);
        }
      }

      // Apply happy hour discount if enabled
      if (BusinessInfo.instance.isInHappyHourNow()) {
        final appliedBase =
            item.price + priceAdjustment; // include merchant override
        final hh = appliedBase * BusinessInfo.instance.happyHourDiscountPercent;
        priceAdjustment -= hh;
      }

      // Update cart after dialog is closed
      if (!mounted) return;

      setState(() {
        final index = cartItems.indexWhere(
          (c) => c.hasSameConfigurationWithDiscount(
            p,
            selectedModifiers,
            0.0,
            otherPriceAdjustment: priceAdjustment,
            otherSeatNumber: null,
          ),
        );
        if (index != -1) {
          cartItems[index].quantity++;
        } else {
          cartItems.add(
            CartItem(
              p,
              1,
              modifiers: selectedModifiers,
              priceAdjustment: priceAdjustment,
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
              ? "${last.quantity} x ${last.product.name}\nSubtotal: RM ${getSubtotal().toStringAsFixed(2)}"
              : "Subtotal: RM ${getSubtotal().toStringAsFixed(2)}";
          await CustomerDisplayService().showText(display, displayText);
        }
      } catch (e) {
        developer.log('CustomerDisplay update failed: $e');
      }
      */
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add item to cart: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ToastHelper.showToast(context, 'Failed to add item: $e');
    }
  }

  /// Update dual display with current cart state
  Future<void> _updateDualDisplay() async {
    try {
      await DualDisplayService().showCartItemsFromObjects(
        cartItems,
        BusinessInfo.instance.currencySymbol,
      );
    } catch (e) {
      developer.log('DualDisplay cart update failed: $e');
    }
  }

  Future<void> removeFromCart(int index) async {
    try {
      setState(() {
        if (cartItems[index].quantity > 1) {
          cartItems[index].quantity--;
        } else {
          cartItems.removeAt(index);
        }
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to remove item from cart: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Update dual display with the new cart state
    await _updateDualDisplay();
  }

  void clearCart() {
    try {
      setState(() {
        cartItems.clear();
        customerName = null;
        customerPhone = null;
        customerEmail = null;
        specialInstructions = null;
      });

      // Update dual display to show empty cart
      _updateDualDisplay();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to clear cart: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Totals with BusinessInfo pattern
  double getSubtotal() => Pricing.subtotal(cartItems);
  double billDiscount = 0.0;

  double getTaxAmount() =>
      Pricing.taxAmountWithDiscount(cartItems, billDiscount);

  double getServiceChargeAmount() =>
      Pricing.serviceChargeAmountWithDiscount(cartItems, billDiscount);

  double getTotal() => Pricing.totalWithDiscount(cartItems, billDiscount);

  void _onBusinessInfoChanged() {
    // Trigger UI rebuild when tax/service charge settings change
    setState(() {});
  }

  @override
  void dispose() {
    _categoryDebounceTimer?.cancel();
    // Remove BusinessInfo listener
    BusinessInfo.instance.removeListener(_onBusinessInfoChanged);
    super.dispose();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final List<Category> dbCategories = await DatabaseService.instance
          .getCategories();
      final List<Item> dbItems = await DatabaseService.instance.getItems();

      if (dbCategories.isNotEmpty) {
        final List<String> newCategories = [
          'All',
          ...dbCategories.map((c) => c.name),
        ];
        if (mounted) {
          setState(() {
            categories = newCategories;
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }
          });
        }
      }

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
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load categories/items from DB: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<Product> _getFilteredProductsSync(String category) {
    if (_productFilterCache.containsKey(category)) {
      if (kDebugMode) {
        developer.log(
          'CAFE POS: cache hit for $category',
          name: 'cafe_pos_perf',
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
        'CAFE POS: computed filter for $category count=${res.length} elapsed=${sw.elapsedMilliseconds}ms',
        name: 'cafe_pos_perf',
      );
    }
    _productFilterCache[category] = res;
    return res;
  }

  Future<void> _onCheckoutPressed() async {
    developer.log('╔════════════════════════════════════════════════════════╗');
    developer.log('║ CAFE: _onCheckoutPressed() CALLED                      ║');
    developer.log(
      '║ Cart items: ${cartItems.length}                                 ║',
    );
    developer.log('╚════════════════════════════════════════════════════════╝');

    if (cartItems.isEmpty) {
      developer.log('CAFE: Cart is empty, returning');
      return;
    }

    // Show order total on customer display when checkout starts
    await DualDisplayService().showOrderTotal(
      getTotal(),
      BusinessInfo.instance.currencySymbol,
    );
    if (!mounted) return;

    final parentNav = Navigator.of(context);
    final result = await parentNav.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: getTotal(),
          availablePaymentMethods: paymentMethods,
          cartItems: cartItems,
          merchantId: selectedMerchant,
          orderType: 'cafe',
          cafeOrderNumber: nextOrderNumber,
          initialCustomerName: customerName,
          initialCustomerPhone: customerPhone,
          initialCustomerEmail: customerEmail,
        ),
      ),
    );

    developer.log('========================================');
    developer.log('CAFE CHECKOUT: Payment screen returned');
    developer.log('CAFE CHECKOUT: result = $result');
    developer.log('========================================');

    final parsedResult = PaymentResultParser.parse(
      result,
      fallbackAmount: getTotal(),
      fallbackPaymentMethod: paymentMethods.first,
    );

    if (parsedResult != null) {
      developer.log('CAFE CHECKOUT: Payment SUCCESS - processing order...');
      final paymentMethod = parsedResult.paymentMethod;
      final change = parsedResult.change;
      final amountPaid = parsedResult.amountPaid;

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

      final myOrderNumber = nextOrderNumber++;

      // Save completed sale to database with customer information
      String? savedOrderNumber;
      if (TrainingModeService.instance.isTrainingMode) {
        savedOrderNumber = 'TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        TrainingModeService.instance.addTrainingTransaction({
          'orderNumber': savedOrderNumber,
          'cartItems': itemsSnapshot.map((c) => c.toJson()).toList(),
          'subtotal': getSubtotal(),
          'tax': getTaxAmount(),
          'serviceCharge': getServiceChargeAmount(),
          'total': getTotal(),
          'paymentMethod': paymentMethod.name,
          'amountPaid': amountPaid,
          'change': change,
          'orderType': 'cafe',
          'cafeOrderNumber': myOrderNumber,
          'merchantId': selectedMerchant,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'specialInstructions': specialInstructions,
        });
      } else {
        savedOrderNumber = await DatabaseService.instance.saveCompletedSale(
          cartItems: itemsSnapshot,
          subtotal: getSubtotal(),
          tax: getTaxAmount(),
          serviceCharge: getServiceChargeAmount(),
          total: getTotal(),
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          change: change,
          orderType: 'cafe',
          cafeOrderNumber: myOrderNumber,
          discount: billDiscount,
          merchantId: selectedMerchant,
          customerName: customerName,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
          specialInstructions: specialInstructions,
          status: 'preparing', // Set status to 'preparing' for cafe order queue
        );
      }

      // Log the saved order number for debugging
      developer.log('Cafe sale completed with order number: $savedOrderNumber');

      // Log transaction activity for user tracking
      final currentUser = UserSessionService().currentActiveUser;
      if (currentUser != null && savedOrderNumber != null) {
        await UserActivityService.instance.logTransaction(
          currentUser.id,
          savedOrderNumber,
          getTotal(),
        );
      }

      // Print kitchen order (fire and forget)
      PrinterService().printKitchenOrder({
        'order_number': myOrderNumber.toString(),
        'order_type': 'cafe',
        'merchant': selectedMerchant,
        'items': itemsSnapshot
            .map(
              (ci) => {
                'name': ci.product.name,
                'quantity': ci.quantity,
                'category': ci.product.category,
                'printer_override': ci.product.printerOverride,
                'modifiers': ci.modifiers.map((m) => m.name).join(', '),
              },
            )
            .toList(),
        'customer_name': customerName,
        'special_instructions': specialInstructions,
        'timestamp': DateTime.now().toIso8601String(),
      }).catchError((e) {
        developer.log('KITCHEN PRINT ERROR: $e');
        return false;
      });

      // Push order to active orders (calling system)
      setState(() {
        activeOrders.add(
          CafeOrder(
            number: myOrderNumber,
            items: itemsSnapshot,
            createdAt: DateTime.now(),
          ),
        );
      });

      // Auto print with order number
      developer.log('🔥🔥🔥 RIGHT BEFORE TRY-CATCH BLOCK 🔥🔥🔥');

      // Auto-print will be attempted after receipt preview

      try {
        developer.log('🚀🚀🚀 ENTERING TRY BLOCK 🚀🚀🚀');
        await _tryAutoPrint(
          orderNumber: myOrderNumber,
          items: itemsSnapshot,
          subtotal: getSubtotal(),
          tax: getTaxAmount(),
          serviceCharge: getServiceChargeAmount(),
          total: getTotal(),
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          change: change,
        );
        developer.log('✅✅✅ TRY BLOCK COMPLETED SUCCESSFULLY ✅✅✅');
      } catch (e, stackTrace) {
        developer.log('🚨🚨🚨 AUTO-PRINT FAILED: $e 🚨🚨🚨');
        developer.log('Stack trace: $stackTrace');
        // Show error to user
        if (mounted) ToastHelper.showToast(context, 'Auto-print failed: $e');
      }
      developer.log('🎯🎯🎯 AFTER TRY-CATCH BLOCK 🎯🎯🎯');

      // Show a brief confirmation and clear cart
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        'Order #$myOrderNumber created. Payment successful.',
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

  // Auto-print receipt with prominent calling number
  Future<void> _tryAutoPrint({
    required int orderNumber,
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    bool allowFallback = false,
  }) async {
    // Using `context` directly here; we'll check `mounted` before UI operations.
    developer.log(
      '🎯🎯🎯 _tryAutoPrint METHOD ENTERED - Order #$orderNumber 🎯🎯🎯',
    );
    developer.log('🚨🚨🚨 AUTO-PRINT STARTED - Order #$orderNumber 🚨🚨🚨');
    try {
      developer.log('========================================');
      developer.log('AUTO-PRINT (Cafe): METHOD CALLED for Order #$orderNumber');
      developer.log('AUTO-PRINT (Cafe): Items count: ${items.length}');
      developer.log('AUTO-PRINT (Cafe): Total: $total');
      developer.log('========================================');

      developer.log('AUTO-PRINT (Cafe): Checking settings...');
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log(
        'AUTO-PRINT (Cafe): autoPrint=${settings.autoPrint}, paperWidth=${settings.paperWidth}',
      );

      // Auto-print setting checked

      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT (Cafe): Auto-print is DISABLED, skipping');
        return;
      }

      // Prepare receipt data early (needed for both printer paths)
      final info = BusinessInfo.instance;
      final currency = info.currencySymbol;
      final now = DateTime.now();

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
        'customer':
            'Order #${orderNumber.toString().padLeft(3, '0')}', // Cafe mode shows order number as customer
        'bill_no': orderNumber.toString().padLeft(3, '0'),
        'payment_mode': paymentMethod.name,
        'dr_ref': '', // Not used in cafe mode
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
        'change': change,
      };

      // Load printers from database
      developer.log('AUTO-PRINT (Cafe): Loading printers from database...');
      final allPrinters = await DatabaseService.instance.getPrinters();
      developer.log(
        'AUTO-PRINT (Cafe): Found ${allPrinters.length} saved printers',
      );

      // Filter for RECEIPT printers only (not kitchen/bar printers)
      final printers =
          allPrinters.where((p) => p.type == PrinterType.receipt).toList();
      developer.log(
        'AUTO-PRINT (Cafe): Found ${printers.length} receipt printers',
      );

      if (printers.isEmpty) {
        developer.log(
          'AUTO-PRINT (Cafe): No receipt printers configured, skipping',
        );
        return;
      }

      // Find default receipt printer, or just first receipt printer
      final printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );
      developer.log(
        'AUTO-PRINT (Cafe): Using printer ${printer.name} (${printer.type.name}, isDefault=${printer.isDefault}, status=${printer.status.name})',
      );

      // Using selected printer for auto-print

      // Send structured receipt data directly to printer (Android native code will format it)
      developer.log('AUTO-PRINT (Cafe): Sending structured data to printer...');
      // Show a quick visual confirmation so operator knows printing started
      try {
        if (!mounted) return;
        ToastHelper.showToast(context, 'Auto-printing receipt...');
      } catch (e) {
        if (!mounted) return;
        ToastHelper.showToast(context, 'Failed to add item: $e');
      }
      final printerService = PrinterService();
      // Small delay before printing to avoid concurrent native plugin calls
      await Future.delayed(const Duration(milliseconds: 250));
      // Validate printer config before attempting to print
      final validationMsg = printerService.validatePrinterConfig(printer);
      if (validationMsg != null) {
        developer.log(
          'AUTO-PRINT (Cafe): Printer validation failed: $validationMsg',
        );
        if (mounted) {
          ToastHelper.showToast(context, 'Auto-print failed: $validationMsg');
        }
        return;
      }
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
                      // Re-run preflight and if OK, retry printing
                      final postflight =
                          await PrinterService().preflightPrinterCheck(updated);
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
        // Do not attempt printing now - user should fix printer settings first
        return;
      }

      final printResult = await printerService.printReceipt(
        printer,
        receiptData,
      );
      developer.log('AUTO-PRINT (Cafe): Print result = $printResult');

      // If structured print failed, do not auto trigger a test print (it prints a test page).
      // Instead notify user with a toast and attempt to print via external service fallback.
      if (!printResult) {
        developer.log(
          'AUTO-PRINT (Cafe): printReceipt failed — not automatically triggering external fallback for auto-print',
        );
        if (mounted) {
          ToastHelper.showToast(
            context,
            'Auto-print failed — please check printer connection in Settings > Printers',
          );
          // Also show validation details and connection info if available
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
          // plugin message already included in details above, no additional action.
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
        if (allowFallback) {
          try {
            final fallbackOk = await printerService.printViaExternalService(
              receiptData,
              paperSize: printer.paperSize,
            );
            developer.log(
              'AUTO-PRINT (Cafe): printViaExternalService fallback = $fallbackOk',
            );
            if (mounted && fallbackOk) {
              ToastHelper.showToast(context, 'Auto-print fallback successful.');
            }
          } catch (e) {
            developer.log(
              'AUTO-PRINT (Cafe): printViaExternalService fallback failed: $e',
            );
          }
        }
      }

      // DEBUG: Show print result
      if (mounted) {
        final message = printResult
            ? '🖨️ Print result: success'
            : '🖨️ Print result: failed';
        ToastHelper.showToast(context, message);
      }
    } catch (e) {
      developer.log('AUTO-PRINT (Cafe) ERROR: $e');
    }
  }

  void _showActiveOrders() {
    developer.log(
      'CAFE POS: opening Active Orders modal',
      name: 'cafe_pos_perf',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () async {
                                final parentNavigator = Navigator.of(context);
                                final result = await showDialog<List<CartItem>>(
                                  context: context,
                                  builder: (context) => SplitBillDialog(
                                    cartItems: cartItems,
                                    tableCapacity: 0,
                                  ),
                                );
                                if (result != null && result.isNotEmpty) {
                                  setState(() {
                                    for (final s in result) {
                                      final idx = cartItems.indexWhere(
                                        (ci) =>
                                            ci.hasSameConfigurationWithDiscount(
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
                                          cartItems[idx].quantity = remaining;
                                        }
                                      }
                                    }
                                  });
                                  await parentNavigator.push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        totalAmount: Pricing.total(result),
                                        availablePaymentMethods: paymentMethods,
                                        cartItems: result,
                                        billDiscount: 0.0,
                                        merchantId: selectedMerchant,
                                        orderType: 'cafe',
                                        cafeOrderNumber: nextOrderNumber,
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Split Bill'),
                      ),
                    ),
                    const Text(
                      'Active Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use maxCrossAxisExtent for adaptive columns (min tile width)
                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: activeOrders.length,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: AppTokens.productTileMinWidth + 40,
                        crossAxisSpacing: AppSpacing.m,
                        mainAxisSpacing: AppSpacing.m,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (context, index) {
                        final o = activeOrders[index];
                        final total = o.subtotal +
                            (BusinessInfo.instance.isTaxEnabled
                                ? o.subtotal * BusinessInfo.instance.taxRate
                                : 0.0) +
                            (BusinessInfo.instance.isServiceChargeEnabled
                                ? o.subtotal *
                                    BusinessInfo.instance.serviceChargeRate
                                : 0.0);
                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${o.number}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!o.completed)
                                      Icon(
                                        o.called
                                            ? Icons.campaign
                                            : Icons.hourglass_bottom,
                                        color: o.called
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${o.items.length} item(s)  •  ${BusinessInfo.instance.currencySymbol} ${total.toStringAsFixed(2)}',
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!o.called && !o.completed)
                                      Flexible(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              setState(() => o.called = true),
                                          icon: const Icon(
                                            Icons.campaign,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Call',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    if (!o.completed)
                                      Flexible(
                                        child: ElevatedButton.icon(
                                          onPressed: () => setState(
                                            () => o.completed = true,
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Done',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Public wrapper so parent (UnifiedPOSScreen) can open the active orders sheet
  Future<void> showActiveOrders() async {
    _showActiveOrders();
  }

  @override
  Widget build(BuildContext context) {
    final buildSw = Stopwatch()..start();
    try {
      final filterSw = Stopwatch()..start();
      final filteredProducts = _getFilteredProductsSync(selectedCategory);
      filterSw.stop();
      if (kDebugMode) {
        developer.log(
          'CAFE POS: filtered ${filteredProducts.length} products in ${filterSw.elapsedMilliseconds}ms for category=$selectedCategory',
          name: 'cafe_pos_perf',
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        buildSw.stop();
        if (kDebugMode) {
          developer.log(
            'CAFE POS: build finished in ${buildSw.elapsedMilliseconds}ms (category=$selectedCategory)',
            name: 'cafe_pos_perf',
          );
        }
      });

      return Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            children: [
              ResponsiveLayout(
                builder: (context, constraints, info) {
                  if (info.width < 600) {
                    return _buildPhoneLayout(filteredProducts);
                  } else if (info.width < 900) {
                    return _buildTabletLayout(filteredProducts);
                  } else {
                    return _buildDesktopLayout(filteredProducts);
                  }
                },
              ),
              // Active Orders are now in the app bar in UnifiedPOSScreen (avoid duplicate FAB)
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Cafe POS Screen build error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'An error occurred while loading the Cafe POS screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPhoneLayout(List<Product> filteredProducts) {
    final mediaH = MediaQuery.of(context).size.height;
    if (mediaH < 500) {
      // Very short screens: use flex layout so product grid and cart share height
      return Column(
        children: [
          Flexible(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: SizedBox(
                          height: mediaH < 500 ? 44 : 56,
                          child: mediaH < 500
                              ? Row(
                                  children: [
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: selectedCategory,
                                        items: categories
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(c),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) _onCategorySelected(v);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final c = categories[index];
                                    final isSelected = c == selectedCategory;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      child: FilterChip(
                                        label: Text(c),
                                        selected: isSelected,
                                        onSelected: (_) =>
                                            _onCategorySelected(c),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? SingleChildScrollView(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 56,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No items available.\nOpen Settings → Database Test to restore demo data.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.all(mediaH < 500 ? 8 : 12),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      AppTokens.productTileMinWidth + 40,
                                  childAspectRatio: mediaH < 500 ? 0.6 : 0.85,
                                  crossAxisSpacing: mediaH < 500
                                      ? AppSpacing.s
                                      : AppSpacing.m,
                                  mainAxisSpacing: mediaH < 500
                                      ? AppSpacing.s
                                      : AppSpacing.m,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ProductCard(
                                    product: filteredProducts[index],
                                    onTap: () =>
                                        addToCart(filteredProducts[index]),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: _buildCartPanel()),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: SizedBox(
                  height: mediaH < 500 ? 44 : 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final c = categories[index];
                      final isSelected = c == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: FilterChip(
                          label: Text(c),
                          selected: isSelected,
                          onSelected: (_) {
                            final tapSw = Stopwatch()..start();
                            developer.log(
                              'CATEGORY: Selected $c in CafePOS - start',
                              name: 'cafe_pos',
                            );
                            _onCategorySelected(c);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              tapSw.stop();
                              developer.log(
                                'CATEGORY: Selected $c in CafePOS - frame done: ${tapSw.elapsedMilliseconds}ms',
                                name: 'cafe_pos_perf',
                              );
                            });
                          },
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: mediaH < 500 ? 40 : 56,
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              AppTokens.productTileMinWidth + 40,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          if (_gridItemBuildLogCounter < 20 && kDebugMode) {
                            _gridItemBuildLogCounter++;
                            developer.log(
                              'CAFE POS: Grid build index=$index product=${filteredProducts[index].name}',
                              name: 'cafe_pos_grid',
                            );
                          }
                          return ProductCard(
                            product: filteredProducts[index],
                            onTap: () => addToCart(filteredProducts[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Constrain the cart panel height on narrow screens so internal
        // Expanded/ListView inside it has a bounded height to layout into.
        SizedBox(
          height: MediaQuery.of(context).size.height < 480
              ? MediaQuery.of(context).size.height * 0.30
              : MediaQuery.of(context).size.height < 600
                  ? MediaQuery.of(context).size.height * 0.45
                  : 350.0,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(List<Product> filteredProducts) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: SizedBox(
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
                          vertical: 8,
                        ),
                        child: FilterChip(
                          label: Text(c),
                          selected: isSelected,
                          onSelected: (_) => _onCategorySelected(c),
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              AppTokens.productTileMinWidth + 40,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) => ProductCard(
                          product: filteredProducts[index],
                          onTap: () => addToCart(filteredProducts[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
        // Constrain the cart panel height on narrow screens so internal
        // Expanded/ListView inside it has a bounded height to layout into.
        SizedBox(
          height: MediaQuery.of(context).size.height < 500
              ? MediaQuery.of(context).size.height * 0.32
              : MediaQuery.of(context).size.height < 700
                  ? MediaQuery.of(context).size.height * 0.45
                  : 400.0,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(List<Product> filteredProducts) {
    if (kDebugMode) {
      developer.log(
        'CAFE POS: _buildDesktopLayout products=${filteredProducts.length}',
      );
    }
    return ResponsiveLayout(
      builder: (context, constraints, info) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: SizedBox(
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
                              vertical: 8,
                            ),
                            child: FilterChip(
                              label: Text(c),
                              selected: isSelected,
                              onSelected: (_) => _onCategorySelected(c),
                              selectedColor: const Color(0xFF2563EB),
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // LayoutBuilder retained for responsive sizing but we use
                        // maxCrossAxisExtent for adaptive product tile sizing.
                        if (filteredProducts.isEmpty) {
                          return Center(
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
                                    'Use the menu button (☺) at the top to access Settings.',
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
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                AppTokens.productTileMinWidth + 40,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: AppSpacing.m,
                            mainAxisSpacing: AppSpacing.m,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            if (_gridItemBuildLogCounter < 20 && kDebugMode) {
                              _gridItemBuildLogCounter++;
                              developer.log(
                                'CAFE POS: Grid build index=$index product=${filteredProducts[index].name}',
                                name: 'cafe_pos_grid',
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
            SizedBox(
              width: info.width < 900
                  ? info.width * 0.35
                  : info.width < 1200
                      ? info.width * 0.3
                      : info.width < 1600
                          ? 420
                          : info.width < 2560
                              ? 450
                              : 480,
              child: _buildCartPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Current Order',
                        style: TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      tooltip: 'Shift Management',
                      onPressed: _manageShift,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEXT #$nextOrderNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (cartItems.isEmpty)
                        SizedBox(
                          height: math.min(200, maxH * 0.5),
                          child: Center(
                            child: Text(
                              'Cart is empty',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                      if (cartItems.isNotEmpty)
                        CustomerInfoWidget(
                          customerName: customerName,
                          customerPhone: customerPhone,
                          customerEmail: customerEmail,
                          specialInstructions: specialInstructions,
                          onEdit: () async {
                            final customerInfo =
                                await showDialog<Map<String, String?>>(
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
                      const SizedBox(height: 8),
                      // Footer (merchant/discounts/buttons)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 340;
                                final merchantDropdown = Material(
                                  color: Colors.transparent,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedMerchant,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'none',
                                        child: Text('On-site'),
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
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Merchant:'),
                                      const SizedBox(height: 6),
                                      merchantDropdown,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    const Text('Merchant:'),
                                    const SizedBox(width: 12),
                                    Expanded(child: merchantDropdown),
                                  ],
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(FormattingService.currency(getSubtotal())),
                              ],
                            ),
                            if (BusinessInfo.instance.isTaxEnabled) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Tax (${BusinessInfo.instance.taxRatePercentage})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    FormattingService.currency(getTaxAmount()),
                                  ),
                                ],
                              ),
                            ],
                            if (BusinessInfo
                                .instance.isServiceChargeEnabled) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            if (billDiscount > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount'),
                                  Text(
                                    FormattingService.currency(billDiscount),
                                  ),
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        cartItems.isEmpty ? null : clearCart,
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
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: cartItems.isEmpty
                                      ? null
                                      : () async {
                                          final controller =
                                              TextEditingController(
                                            text:
                                                billDiscount.toStringAsFixed(2),
                                          );
                                          final res = await showDialog<double?>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Apply discount (RM)',
                                              ),
                                              content: TextField(
                                                controller: controller,
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0.00',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    final v = double.tryParse(
                                                          controller.text,
                                                        ) ??
                                                        0.0;
                                                    Navigator.of(
                                                      context,
                                                    ).pop(v);
                                                  },
                                                  child: const Text('Apply'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (res != null) {
                                            setState(() => billDiscount = res);
                                          }
                                        },
                                  icon: const Icon(Icons.local_offer_outlined),
                                  tooltip: 'Apply discount',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
