import 'dart:async';
import 'dart:developer' as developer;

// guide_service and guide_widgets not used in this screen (kept in other POS screens)
// reports_screen is not used here; remove unused imports to silence warnings.
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/receipt_preview_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/services/app_settings.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/services/reset_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/user_activity_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/payment_result_parser.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/cart_item_widget.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:extropos/widgets/modifier_selection_dialog.dart';
import 'package:extropos/widgets/product_card.dart';
import 'package:extropos/widgets/responsive_layout.dart';
import 'package:extropos/widgets/split_bill_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class POSOrderScreen extends StatefulWidget {
  final RestaurantTable table;

  /// Optional test seam: provide initial cart items and skip DB load.
  final List<CartItem> initialCartItems;
  final bool skipDbLoad;

  const POSOrderScreen({
    super.key,
    required this.table,
    this.initialCartItems = const [],
    this.skipDbLoad = false,
  });

  @override
  State<POSOrderScreen> createState() => _POSOrderScreenState();
}

class _POSOrderScreenState extends State<POSOrderScreen> {
  String selectedCategory = 'All';
  final Map<String, List<Product>> _productFilterCache = {};
  Timer? _categoryDebounceTimer;
  late List<CartItem> cartItems;
  String selectedMerchant = 'none';

  // Start empty by default — no fallback mock products or categories on first load
  List<String> categories = ['All'];

  List<Product> products = [];

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
  ];

  @override
  void initState() {
    super.initState();
    cartItems = widget.initialCartItems.isNotEmpty
        ? List<CartItem>.from(widget.initialCartItems)
        : List<CartItem>.from(widget.table.orders);
    if (!widget.skipDbLoad) {
      _loadFromDatabase();
    }
    // Listen for global reset events
    ResetService.instance.addListener(_handleReset);
    // Listen for BusinessInfo changes
    BusinessInfo.instance.addListener(_onBusinessInfoChanged);
  }

  @override
  void dispose() {
    ResetService.instance.removeListener(_handleReset);
    // Remove BusinessInfo listener
    BusinessInfo.instance.removeListener(_onBusinessInfoChanged);
    _categoryDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleReset() {
    if (!mounted) return;
    setState(() {
      cartItems.clear();
    });
  }

  Future<void> _loadFromDatabase() async {
    try {
      final List<Category> dbCategories =
          await DatabaseService.instance.getCategories();
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
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }
            _productFilterCache.clear();
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
      // Leave categories/products empty (no fallback mock data)
    }
  }

  List<Product> _getFilteredProductsSync(String category) {
    if (_productFilterCache.containsKey(category)) {
      if (!mounted) return <Product>[];
      if (kDebugMode) {
        developer.log(
          'RESTAURANT POS: cache hit for $category',
          name: 'restaurant_pos_perf',
        );
        developer.log(
          'RESTAURANT POS: cache hit for $category',
          name: 'restaurant_pos_perf',
        );
      }
      return _productFilterCache[category]!;
    }
    final sw = Stopwatch()..start();
    final res = category == 'All'
        ? List<Product>.from(products)
        : products.where((p) => p.category == category).toList();
    sw.stop();
    if (!mounted) return <Product>[];
    if (kDebugMode) {
      developer.log(
        'RESTAURANT POS: computed filter for $category count=${res.length} elapsed=${sw.elapsedMilliseconds}ms',
        name: 'restaurant_pos_perf',
      );
    }
    _productFilterCache[category] = res;
    return res;
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    if (!mounted) return;
    if (kDebugMode) {
      developer.log(
        'RESTAURANT POS: category selected $category (debounced)',
        name: 'restaurant_pos_perf',
      );
      developer.log(
        'RESTAURANT POS: category selected (debounced) $category',
        name: 'restaurant_pos_perf',
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

  Future<void> addToCart(Product product) async {
    try {
      final items = await DatabaseService.instance.getItems();
      final item = items.firstWhere(
        (it) => it.name == product.name,
        orElse: () => Item(
          id: '',
          name: product.name,
          price: product.price,
          categoryId: '',
          description: '',
          icon: Icons.fastfood,
          color: Colors.blue,
        ),
      );

      String categoryId = item.categoryId;
      if (categoryId.isEmpty) {
        final categories = await DatabaseService.instance.getCategories();
        final category = categories.firstWhere(
          (c) => c.name == product.category,
          orElse: () => Category(
            id: '',
            name: '',
            description: '',
            icon: Icons.category,
            color: Colors.grey,
            sortOrder: 0,
          ),
        );
        categoryId = category.id;
      }

      List<ModifierItem> selectedModifiers = [];
      double priceAdjustment = 0.0;

      if (categoryId.isNotEmpty) {
        if (!mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) =>
              ModifierSelectionDialog(item: item, categoryId: categoryId),
        );

        if (!mounted) return;
        if (result == null) return;

        selectedModifiers = result['modifiers'] as List<ModifierItem>;
        priceAdjustment = result['priceAdjustment'] as double;
      }

      // Determine merchant price override if merchant selected
      if (selectedMerchant != 'none' && selectedMerchant != 'takeaway') {
        final mprice = item.merchantPrices[selectedMerchant];
        if (mprice != null) {
          // priceAdjustment is the difference from base item price
          priceAdjustment += (mprice - item.price);
        }
      }

      // Apply happy hour discount if enabled
      if (BusinessInfo.instance.isInHappyHourNow()) {
        final appliedBase = item.price +
            priceAdjustment; // includes merchant/modifier adjustments
        final hh = appliedBase * BusinessInfo.instance.happyHourDiscountPercent;
        priceAdjustment -= hh; // negative adjustment to reduce price
      }

      setState(() {
        final existingIndex = cartItems.indexWhere(
          (ci) => ci.hasSameConfigurationWithDiscount(
            product,
            selectedModifiers,
            0.0,
            otherPriceAdjustment: priceAdjustment,
            otherSeatNumber: null,
          ),
        );

        if (existingIndex != -1) {
          cartItems[existingIndex].quantity++;
        } else {
          cartItems.add(
            CartItem(
              product,
              1,
              modifiers: selectedModifiers,
              priceAdjustment: priceAdjustment,
            ),
          );
        }
      });

      // Update dual display (Imin back screen) with cart items
      await _updateDualDisplay();

      if (mounted) {
        ToastHelper.showToast(context, 'Added ${product.name}');
      }
    } catch (e) {
      if (AppSettings.instance.requireDbProducts) {
        if (!mounted) return;
        final parentNavigator = Navigator.of(context);
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Product not in database'),
            content: const Text(
              'This product is not available in the database. Please add it in Items Management before selling.',
            ),
            actions: [
              TextButton(
                onPressed: () => parentNavigator.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  parentNavigator.pop();
                  parentNavigator.push(
                    MaterialPageRoute(
                      builder: (_) => const ItemsManagementScreen(),
                    ),
                  );
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        final existingIndex = cartItems.indexWhere(
          (item) => item.product.name == product.name,
        );
        if (existingIndex != -1) {
          cartItems[existingIndex].quantity++;
        } else {
          cartItems.add(CartItem(product, 1));
        }
      });
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

  void clearCart() {
    setState(() {
      cartItems.clear();
    });
    _updateDualDisplay();
  }

  double getSubtotal() {
    return Pricing.subtotal(cartItems);
  }

  double billDiscount = 0.0;

  double getTaxAmount() {
    return Pricing.taxAmountWithDiscount(cartItems, billDiscount);
  }

  double getServiceChargeAmount() {
    return Pricing.serviceChargeAmountWithDiscount(cartItems, billDiscount);
  }

  double getTotal() {
    return Pricing.totalWithDiscount(cartItems, billDiscount);
  }

  void _onBusinessInfoChanged() {
    // Trigger UI rebuild when tax/service charge settings change
    setState(() {});
  }

  void _saveAndReturn() async {
    // Update the table with current cart items
    widget.table.orders.clear();
    widget.table.orders.addAll(cartItems);

    // Update table status based on orders
    if (cartItems.isNotEmpty) {
      widget.table.status = TableStatus.occupied;
      widget.table.occupiedSince ??= DateTime.now();
    } else {
      widget.table.status = TableStatus.available;
      widget.table.occupiedSince = null;
      widget.table.customerName = null;
    }

    // Save the updated table to database
    try {
      await DatabaseService.instance.updateTable(widget.table);
    } catch (e) {
      // If database save fails, still return but log the error
      developer.log(
        'Failed to save table ${widget.table.name}: $e',
        name: 'restaurant_pos',
      );
    }

    // Print kitchen order for restaurant mode (fire and forget)
    if (cartItems.isNotEmpty) {
      try {
        // Generate a temporary order number based on table name and timestamp
        final tempOrderNumber =
            '${widget.table.name}-${DateTime.now().millisecondsSinceEpoch % 10000}';

        await PrinterService().printKitchenOrder({
          'order_number': tempOrderNumber,
          'order_type': 'restaurant',
          'table': widget.table.name,
          'merchant': selectedMerchant,
          'items': cartItems
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
          'customer_name': widget.table.customerName,
          'timestamp': DateTime.now().toIso8601String(),
        });

        developer.log(
          'Kitchen order printed for table ${widget.table.name}',
          name: 'restaurant_pos',
        );
      } catch (e) {
        developer.log(
          'KITCHEN PRINT ERROR on Save & Return: $e',
          name: 'restaurant_pos',
        );
        // Don't block the save operation if printing fails
      }
    }

    Navigator.pop(context, cartItems);
  }

  Future<void> _sendToKitchen() async {
    if (cartItems.isEmpty) return;

    try {
      // Save order with sent_to_kitchen status (will be updated on payment)
      final orderNumber = await DatabaseService.instance.saveCompletedSale(
        cartItems: cartItems,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod:
            paymentMethods.first, // Placeholder, will be updated on payment
        amountPaid: 0, // Not paid yet
        change: 0,
        orderType: 'restaurant',
        tableId: widget.table.id,
        discount: billDiscount,
        merchantId: selectedMerchant,
        specialInstructions: widget.table.customerName,
      );

      if (orderNumber != null) {
        // Update order status to sent_to_kitchen
        await DatabaseService.instance.updateOrderStatus(
          orderNumber,
          OrderStatus.sentToKitchen,
          notes: 'Order sent to kitchen from ${widget.table.name}',
        );

        // Print kitchen order
        await PrinterService().printKitchenOrder({
          'order_number': orderNumber,
          'order_type': 'restaurant',
          'table': widget.table.name,
          'merchant': selectedMerchant,
          'items': cartItems
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
          'customer_name': widget.table.customerName,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ToastHelper.showToast(
            context,
            'Order $orderNumber sent to kitchen for ${widget.table.name}',
          );

          // Clear cart after sending to kitchen
          setState(() {
            cartItems.clear();
          });

          // Update table status
          widget.table.orders.clear();
          widget.table.status =
              TableStatus.occupied; // Keep occupied until paid
          await DatabaseService.instance.updateTable(widget.table);
        }
      }
    } catch (e) {
      developer.log('Failed to send order to kitchen: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to send order to kitchen: $e');
      }
    }
  }

  void _checkout() async {
    await DualDisplayService().showOrderTotal(
      getTotal(),
      BusinessInfo.instance.currencySymbol,
    );

    final parentNavigator = Navigator.of(context);
    final result = await parentNavigator.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: getTotal(),
          cartItems: cartItems,
          availablePaymentMethods: paymentMethods,
          billDiscount: billDiscount,
          merchantId: selectedMerchant,
          orderType: 'restaurant',
          tableId: widget.table.id,
          initialCustomerName: widget.table.customerName,
        ),
      ),
    );

    if (!mounted) return;

    final parsedResult = PaymentResultParser.parse(
      result,
      fallbackAmount: getTotal(),
      fallbackPaymentMethod: paymentMethods.first,
    );

    if (parsedResult != null) {
      final paymentMethod = parsedResult.paymentMethod;
      final change = parsedResult.change;
      final amountPaid = parsedResult.amountPaid;

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

      String? orderNumber;
      try {
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
            'orderType': 'restaurant',
            'tableId': widget.table.id,
            'discount': billDiscount,
            'merchantId': selectedMerchant,
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
            orderType: 'restaurant',
            tableId: widget.table.id,
            discount: billDiscount,
            merchantId: selectedMerchant,
          );
        }
      } catch (_) {}

      if (!mounted) return;

      // Log transaction activity for user tracking
      final currentUser = UserSessionService().currentActiveUser;
      if (currentUser != null && orderNumber != null) {
        await UserActivityService.instance.logTransaction(
          currentUser.id,
          orderNumber,
          getTotal(),
        );
      }

      // Print kitchen order (fire and forget)
      if (orderNumber != null) {
        final kitchenOrderData = {
          'order_number': orderNumber,
          'order_type': 'restaurant',
          'table': widget.table.name,
          'merchant': selectedMerchant,
          'timestamp': DateTime.now().toIso8601String(),
        };
        PrinterService().printKitchenOrder(kitchenOrderData).catchError((e) {
          developer.log('KITCHEN PRINT ERROR: $e');
          return false;
        });
      }

      final tableName = widget.table.name;
      final paymentName = paymentMethod.name;
      final savedOrderNote =
          orderNumber != null ? ' (Saved as $orderNumber)' : '';

      _tryAutoPrint(
        items: itemsSnapshot,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
        merchantId: selectedMerchant,
      ).catchError((_) {});

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
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        'Order completed for $tableName! Payment: $paymentName${change > 0 ? ', Change: ${FormattingService.currency(change)}' : ''}$savedOrderNote',
      );

      if (change > 0) {
        await DualDisplayService().showChange(
          change,
          BusinessInfo.instance.currencySymbol,
        );
      }

      await DualDisplayService().showThankYou();

      if (!mounted) return;

      // Clear the table after successful checkout
      widget.table.clearOrders();
      try {
        await DatabaseService.instance.updateTable(widget.table);
      } catch (e) {
        developer.log(
          'Failed to clear table ${widget.table.name} after checkout: $e',
          name: 'restaurant_pos',
        );
      }

      parentNavigator.pop(<CartItem>[]);
    }
  }

  Future<void> _tryAutoPrint({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    String? merchantId,
  }) async {
    try {
      developer.log('AUTO-PRINT (Restaurant): Checking settings...');
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log('AUTO-PRINT (Restaurant): autoPrint=${settings.autoPrint}');

      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT (Restaurant): Disabled in settings');
        return;
      }

      final printerService = PrinterService();
      // Load printers from database
      developer.log(
        'AUTO-PRINT (Restaurant): Loading printers from database...',
      );
      final allPrinters = await DatabaseService.instance.getPrinters();
      developer.log(
        'AUTO-PRINT (Restaurant): Found ${allPrinters.length} saved printers',
      );

      // Filter for RECEIPT printers only (not kitchen/bar printers)
      final printers =
          allPrinters.where((p) => p.type == PrinterType.receipt).toList();
      developer.log(
        'AUTO-PRINT (Restaurant): Found ${printers.length} receipt printers',
      );

      if (printers.isEmpty) {
        developer.log(
          'AUTO-PRINT (Restaurant): No receipt printers configured, skipping',
        );
        return;
      }

      // Find default receipt printer, or just first receipt printer
      final printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      developer.log(
        'AUTO-PRINT (Restaurant): Using printer ${printer.name} (${printer.type.name}, isDefault=${printer.isDefault}, status=${printer.status.name})',
      );

      // Build receipt content matching PDF template format
      final buffer = StringBuffer();
      final info = BusinessInfo.instance;
      final currency = info.currencySymbol;
      final now = DateTime.now();

      // Header (matching PDF)
      buffer.writeln(info.businessName);
      buffer.writeln(info.fullAddress);
      if (info.taxNumber != null && info.taxNumber!.isNotEmpty) {
        buffer.writeln('Tax No: ${info.taxNumber}');
      }
      buffer.writeln('');
      buffer.writeln('Table: ${widget.table.name}');
      if (merchantId != null && merchantId.isNotEmpty && merchantId != 'none') {
        buffer.writeln('Merchant: $merchantId');
      }
      buffer.writeln(now.toIso8601String());
      buffer.writeln('');

      // Items (matching PDF format)
      for (var item in items) {
        final seatLabel =
            item.seatNumber != null ? ' (Seat ${item.seatNumber})' : '';
        final itemLine = '${item.product.name}$seatLabel x${item.quantity}';
        final priceLine = '$currency ${item.totalPrice.toStringAsFixed(2)}';
        // Right-align price (matching PDF)
        final maxWidth = 42; // 80mm paper width
        final spaces = maxWidth - itemLine.length - priceLine.length;
        final paddedSpaces = spaces > 0 ? ''.padLeft(spaces) : ' ';
        buffer.writeln('$itemLine$paddedSpaces$priceLine');

        if (item.modifiers.isNotEmpty) {
          final modsText = item.modifiers
              .map(
                (m) => m.priceAdjustment == 0
                    ? m.name
                    : '${m.name} (${m.getPriceAdjustmentDisplay()})',
              )
              .join(', ');
          buffer.writeln('  $modsText');
        }
      }

      buffer.writeln('');
      // Totals (matching PDF format)
      final subtotalLine =
          'Subtotal${''.padLeft(42 - 'Subtotal'.length - '$currency ${subtotal.toStringAsFixed(2)}'.length)}$currency ${subtotal.toStringAsFixed(2)}';
      buffer.writeln(subtotalLine);

      if (tax > 0) {
        final taxLine =
            'Tax${''.padLeft(42 - 'Tax'.length - '$currency ${tax.toStringAsFixed(2)}'.length)}$currency ${tax.toStringAsFixed(2)}';
        buffer.writeln(taxLine);
      }

      if (serviceCharge > 0) {
        final serviceLine =
            'Service${''.padLeft(42 - 'Service'.length - '$currency ${serviceCharge.toStringAsFixed(2)}'.length)}$currency ${serviceCharge.toStringAsFixed(2)}';
        buffer.writeln(serviceLine);
      }

      buffer.writeln('');
      final totalLine =
          'Total${''.padLeft(42 - 'Total'.length - '$currency ${total.toStringAsFixed(2)}'.length)}$currency ${total.toStringAsFixed(2)}';
      buffer.writeln(totalLine);

      buffer.writeln('');
      buffer.writeln('Payment: ${paymentMethod.name}');
      buffer.writeln('Paid: $currency ${amountPaid.toStringAsFixed(2)}');
      if (change > 0) {
        buffer.writeln('Change: $currency ${change.toStringAsFixed(2)}');
      }
      buffer.writeln('');
      buffer.writeln('Thank you!');

      final receiptData = {
        'store_name': BusinessInfo.instance.businessName,
        'address': [
          BusinessInfo.instance.fullAddress,
          if (BusinessInfo.instance.taxNumber != null &&
              BusinessInfo.instance.taxNumber!.isNotEmpty)
            'Tax No: ${BusinessInfo.instance.taxNumber}',
        ],
        'title': 'RECEIPT',
        'date':
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
        'customer':
            'Table ${widget.table.name}', // Restaurant mode shows table name
        'bill_no': '', // Could add bill number here
        'payment_mode': paymentMethod.name,
        'dr_ref': '', // Not used in restaurant mode
        'currency': currency,
        'items': items
            .map(
              (ci) => {
                'name': ci.product.name,
                'qty': ci.quantity,
                'amt': ci.totalPrice,
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
        return;
      }
      final printResult = await printerService.printReceipt(
        printer,
        receiptData,
      );
      developer.log('AUTO-PRINT (Restaurant): Print result = $printResult');

      if (!printResult) {
        developer.log(
          'AUTO-PRINT (Restaurant): printReceipt failed — not auto-running external print chooser to avoid false success. Please check printer or run a manual test print.',
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
                          content: ConstrainedDialog(
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
      developer.log('AUTO-PRINT failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Table: ${widget.table.name}'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: ResponsiveLayout(
          builder: (context, constraints, info) {
            final isNarrow = info.width < 900;
            final filteredProducts = _getFilteredProductsSync(selectedCategory);
            if (kDebugMode) {
              developer.log(
                'RESTAURANT POS: filtered ${filteredProducts.length} products for category=$selectedCategory',
                name: 'restaurant_pos_perf',
              );
            }

            Widget cartPanel() {
              final isNarrowLocal = isNarrow;
              return Container(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: isNarrowLocal
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Cart',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Material(
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
                                          onChanged: (v) => setState(
                                            () =>
                                                selectedMerchant = v ?? 'none',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              cartItems.isEmpty
                                  ? const Center(child: Text('Cart is empty'))
                                  : ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.only(bottom: 8),
                                      itemCount: cartItems.length,
                                      itemBuilder: (_, idx) {
                                        final ci = cartItems[idx];
                                        return CartItemWidget(
                                          item: ci,
                                          tableCapacity: widget.table.capacity,
                                          onRemove: () => removeFromCart(idx),
                                          onAdd: () =>
                                              setState(() => ci.quantity++),
                                          onEdit: () =>
                                              editCartItemModifiers(idx),
                                          onSetDiscount: (v) => setState(
                                            () => ci.discountPerUnit = v,
                                          ),
                                          onSetSeat: (seat) => setState(
                                            () => ci.seatNumber = seat,
                                          ),
                                          onSetNotes: (notes) =>
                                              setState(() => ci.notes = notes),
                                        );
                                      },
                                    ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text(
                                    '${BusinessInfo.instance.currencySymbol}${getSubtotal().toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              if (BusinessInfo.instance.isTaxEnabled) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tax (${(BusinessInfo.instance.taxRate * 100).toStringAsFixed(0)}%)',
                                    ),
                                    Text(
                                      '${BusinessInfo.instance.currencySymbol}${getTaxAmount().toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              ],
                              if (BusinessInfo
                                  .instance.isServiceChargeEnabled) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Service'),
                                    Text(
                                      '${BusinessInfo.instance.currencySymbol}${getServiceChargeAmount().toStringAsFixed(2)}',
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
                                      '${BusinessInfo.instance.currencySymbol}${billDiscount.toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${BusinessInfo.instance.currencySymbol}${getTotal().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          cartItems.isEmpty ? null : _checkout,
                                      child: const Text('Checkout'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: cartItems.isEmpty
                                          ? null
                                          : () async {
                                              final parentNavigator =
                                                  Navigator.of(context);
                                              final result = await showDialog<
                                                  List<CartItem>>(
                                                context: context,
                                                builder: (context) =>
                                                    SplitBillDialog(
                                                  cartItems: cartItems,
                                                  tableCapacity:
                                                      widget.table.capacity,
                                                ),
                                              );
                                              if (result != null &&
                                                  result.isNotEmpty) {
                                                // Apply split: subtract quantities from main cart
                                                setState(() {
                                                  for (final s in result) {
                                                    final idx =
                                                        cartItems.indexWhere(
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
                                                      final orig =
                                                          cartItems[idx];
                                                      final remaining =
                                                          orig.quantity -
                                                              s.quantity;
                                                      if (remaining <= 0) {
                                                        cartItems.removeAt(idx);
                                                      } else {
                                                        cartItems[idx]
                                                                .quantity =
                                                            remaining;
                                                      }
                                                    }
                                                  }
                                                });
                                                // Launch checkout flow for the split items
                                                final paymentResult =
                                                    await parentNavigator.push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PaymentScreen(
                                                      totalAmount:
                                                          Pricing.total(result),
                                                      availablePaymentMethods:
                                                          paymentMethods,
                                                      cartItems: result,
                                                      billDiscount: 0.0,
                                                      merchantId:
                                                          selectedMerchant,
                                                      orderType: 'restaurant',
                                                      tableId: widget.table.id,
                                                      initialCustomerName:
                                                          widget.table
                                                              .customerName,
                                                    ),
                                                  ),
                                                );
                                                final parsedPaymentResult =
                                                    PaymentResultParser.parse(
                                                  paymentResult,
                                                  fallbackAmount:
                                                      Pricing.total(result),
                                                  fallbackPaymentMethod:
                                                      paymentMethods.first,
                                                );
                                                if (parsedPaymentResult !=
                                                    null) {
                                                  // No-op: Payment screen handles saving
                                                }
                                              }
                                            },
                                      child: const Text('Split Bill'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Cart',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Material(
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
                                        onChanged: (v) => setState(
                                          () => selectedMerchant = v ?? 'none',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: cartItems.isEmpty
                                  ? const Center(child: Text('Cart is empty'))
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      itemCount: cartItems.length,
                                      itemBuilder: (_, idx) {
                                        final ci = cartItems[idx];
                                        return CartItemWidget(
                                          item: ci,
                                          tableCapacity: widget.table.capacity,
                                          onRemove: () => removeFromCart(idx),
                                          onAdd: () =>
                                              setState(() => ci.quantity++),
                                          onEdit: () =>
                                              editCartItemModifiers(idx),
                                          onSetDiscount: (v) => setState(
                                            () => ci.discountPerUnit = v,
                                          ),
                                          onSetSeat: (seat) => setState(
                                            () => ci.seatNumber = seat,
                                          ),
                                          onSetNotes: (notes) =>
                                              setState(() => ci.notes = notes),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(
                                  '${BusinessInfo.instance.currencySymbol}${getSubtotal().toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            if (BusinessInfo.instance.isTaxEnabled) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tax (${(BusinessInfo.instance.taxRate * 100).toStringAsFixed(0)}%)',
                                  ),
                                  Text(
                                    '${BusinessInfo.instance.currencySymbol}${getTaxAmount().toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],
                            if (BusinessInfo
                                .instance.isServiceChargeEnabled) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Service'),
                                  Text(
                                    '${BusinessInfo.instance.currencySymbol}${getServiceChargeAmount().toStringAsFixed(2)}',
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
                                    '${BusinessInfo.instance.currencySymbol}${billDiscount.toStringAsFixed(2)}',
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${BusinessInfo.instance.currencySymbol}${getTotal().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCartNarrow = constraints.maxWidth < 400;
                                return isCartNarrow
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ElevatedButton(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : _checkout,
                                            child: const Text('Checkout'),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : () async {
                                                    final result =
                                                        await showDialog<
                                                            List<CartItem>>(
                                                      context: context,
                                                      builder: (context) =>
                                                          SplitBillDialog(
                                                        cartItems: cartItems,
                                                        tableCapacity: widget
                                                            .table.capacity,
                                                      ),
                                                    );
                                                    if (result != null &&
                                                        result.isNotEmpty) {
                                                      // Apply split: subtract quantities from main cart
                                                      setState(() {
                                                        for (final s
                                                            in result) {
                                                          final idx = cartItems
                                                              .indexWhere(
                                                            (
                                                              ci,
                                                            ) =>
                                                                ci.hasSameConfigurationWithDiscount(
                                                              s.product,
                                                              s.modifiers,
                                                              s.discountPerUnit,
                                                              otherPriceAdjustment:
                                                                  s.priceAdjustment,
                                                            ),
                                                          );
                                                          if (idx != -1) {
                                                            final orig =
                                                                cartItems[idx];
                                                            final remaining =
                                                                orig.quantity -
                                                                    s.quantity;
                                                            if (remaining <=
                                                                0) {
                                                              cartItems
                                                                  .removeAt(
                                                                idx,
                                                              );
                                                            } else {
                                                              cartItems[idx]
                                                                      .quantity =
                                                                  remaining;
                                                            }
                                                          }
                                                        }
                                                      });
                                                      // Launch checkout flow for the split items
                                                      final parentNavigator =
                                                          Navigator.of(context);
                                                      final paymentResult =
                                                          await parentNavigator
                                                              .push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              PaymentScreen(
                                                            totalAmount:
                                                                Pricing.total(
                                                                    result),
                                                            availablePaymentMethods:
                                                                paymentMethods,
                                                            cartItems: result,
                                                            billDiscount: 0.0,
                                                            merchantId:
                                                                selectedMerchant,
                                                            orderType:
                                                                'restaurant',
                                                            tableId:
                                                                widget.table.id,
                                                            initialCustomerName:
                                                                widget.table
                                                                    .customerName,
                                                          ),
                                                        ),
                                                      );
                                                      final parsedPaymentResult =
                                                          PaymentResultParser
                                                              .parse(
                                                        paymentResult,
                                                        fallbackAmount:
                                                            Pricing.total(
                                                          result,
                                                        ),
                                                        fallbackPaymentMethod:
                                                            paymentMethods
                                                                .first,
                                                      );
                                                      if (parsedPaymentResult !=
                                                          null) {
                                                        // No-op: Payment screen handles saving
                                                      }
                                                    }
                                                  },
                                            child: const Text('Split Bill'),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : _sendToKitchen,
                                            icon: const Icon(Icons.restaurant),
                                            label: const Text(
                                              'Send to Kitchen',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF2196F3,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : _saveAndReturn,
                                            child: const Text('Save & Return'),
                                          ),
                                          const SizedBox(height: 8),
                                          IconButton(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : () async {
                                                    final controller =
                                                        TextEditingController(
                                                      text: billDiscount
                                                          .toStringAsFixed(
                                                        2,
                                                      ),
                                                    );
                                                    final res =
                                                        await showDialog<
                                                            double?>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                          'Apply discount (RM)',
                                                        ),
                                                        content: TextField(
                                                          controller:
                                                              controller,
                                                          keyboardType:
                                                              TextInputType
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
                                                            onPressed: () =>
                                                                Navigator.of(
                                                              context,
                                                            ).pop(),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              final v = double
                                                                      .tryParse(
                                                                    controller
                                                                        .text,
                                                                  ) ??
                                                                  0.0;
                                                              Navigator.of(
                                                                context,
                                                              ).pop(v);
                                                            },
                                                            child: const Text(
                                                              'Apply',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (res != null) {
                                                      setState(
                                                        () =>
                                                            billDiscount = res,
                                                      );
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.local_offer_outlined,
                                            ),
                                            tooltip: 'Apply discount',
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: cartItems.isEmpty
                                                  ? null
                                                  : _checkout,
                                              child: const Text('Checkout'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: cartItems.isEmpty
                                                  ? null
                                                  : () async {
                                                      final result =
                                                          await showDialog<
                                                              List<CartItem>>(
                                                        context: context,
                                                        builder: (context) =>
                                                            SplitBillDialog(
                                                          cartItems: cartItems,
                                                          tableCapacity: widget
                                                              .table.capacity,
                                                        ),
                                                      );
                                                      if (result != null &&
                                                          result.isNotEmpty) {
                                                        // Apply split: subtract quantities from main cart
                                                        setState(() {
                                                          for (final s
                                                              in result) {
                                                            final idx =
                                                                cartItems
                                                                    .indexWhere(
                                                              (
                                                                ci,
                                                              ) =>
                                                                  ci.hasSameConfigurationWithDiscount(
                                                                s.product,
                                                                s.modifiers,
                                                                s.discountPerUnit,
                                                                otherPriceAdjustment:
                                                                    s.priceAdjustment,
                                                              ),
                                                            );
                                                            if (idx != -1) {
                                                              final orig =
                                                                  cartItems[
                                                                      idx];
                                                              final remaining =
                                                                  orig.quantity -
                                                                      s.quantity;
                                                              if (remaining <=
                                                                  0) {
                                                                cartItems
                                                                    .removeAt(
                                                                  idx,
                                                                );
                                                              } else {
                                                                cartItems[idx]
                                                                        .quantity =
                                                                    remaining;
                                                              }
                                                            }
                                                          }
                                                        });
                                                        // Launch checkout flow for the split items
                                                        final parentNavigator =
                                                            Navigator.of(
                                                          context,
                                                        );
                                                        final paymentResult =
                                                            await parentNavigator
                                                                .push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                PaymentScreen(
                                                              totalAmount:
                                                                  Pricing.total(
                                                                result,
                                                              ),
                                                              availablePaymentMethods:
                                                                  paymentMethods,
                                                              cartItems: result,
                                                              billDiscount: 0.0,
                                                              merchantId:
                                                                  selectedMerchant,
                                                              orderType:
                                                                  'restaurant',
                                                              tableId: widget
                                                                  .table.id,
                                                              initialCustomerName:
                                                                  widget.table
                                                                      .customerName,
                                                            ),
                                                          ),
                                                        );
                                                        final parsedPaymentResult =
                                                            PaymentResultParser
                                                                .parse(
                                                          paymentResult,
                                                          fallbackAmount:
                                                              Pricing.total(
                                                            result,
                                                          ),
                                                          fallbackPaymentMethod:
                                                              paymentMethods
                                                                  .first,
                                                        );
                                                        if (parsedPaymentResult !=
                                                            null) {
                                                          // No-op: Payment screen handles saving
                                                        }
                                                      }
                                                    },
                                              child: const Text('Split Bill'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: cartItems.isEmpty
                                                  ? null
                                                  : _saveAndReturn,
                                              child: const Text(
                                                'Save & Return',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: cartItems.isEmpty
                                                ? null
                                                : () async {
                                                    final controller =
                                                        TextEditingController(
                                                      text: billDiscount
                                                          .toStringAsFixed(
                                                        2,
                                                      ),
                                                    );
                                                    final res =
                                                        await showDialog<
                                                            double?>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                          'Apply discount (RM)',
                                                        ),
                                                        content: TextField(
                                                          controller:
                                                              controller,
                                                          keyboardType:
                                                              TextInputType
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
                                                            onPressed: () =>
                                                                Navigator.of(
                                                              context,
                                                            ).pop(),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              final v = double
                                                                      .tryParse(
                                                                    controller
                                                                        .text,
                                                                  ) ??
                                                                  0.0;
                                                              Navigator.of(
                                                                context,
                                                              ).pop(v);
                                                            },
                                                            child: const Text(
                                                              'Apply',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (res != null) {
                                                      setState(
                                                        () =>
                                                            billDiscount = res,
                                                      );
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.local_offer_outlined,
                                            ),
                                            tooltip: 'Apply discount',
                                          ),
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                ),
              );
            }

            Widget productPane(List<Product> filteredProducts) {
              return Column(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((c) {
                          final isSelected = c == selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: FilterChip(
                              label: Text(c),
                              selected: isSelected,
                              onSelected: (_) => _onCategorySelected(c),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.grey[100],
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              AppTokens.productTileMinWidth + 80,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, idx) {
                          final prod = filteredProducts[idx];
                          return ProductCard(
                            product: prod,
                            onTap: () => addToCart(prod),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            if (isNarrow) {
              final mediaH = MediaQuery.of(context).size.height;
              // For very short screens use 3:1 split; otherwise allow the cart to take smaller portion
              final cartFlex = mediaH < 500 ? 1 : 1;
              return Column(
                children: [
                  Expanded(flex: 3, child: productPane(filteredProducts)),
                  Expanded(flex: cartFlex, child: cartPanel()),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: productPane(filteredProducts)),
                Expanded(child: cartPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> editCartItemModifiers(int index) async {
    final ci = cartItems[index];
    try {
      final items = await DatabaseService.instance.getItems();
      final item = items.firstWhere(
        (it) => it.name == ci.product.name,
        orElse: () => Item(
          id: '',
          name: ci.product.name,
          price: ci.product.price,
          categoryId: '',
          description: '',
          icon: ci.product.icon,
          color: Colors.blue,
        ),
      );

      String categoryId = item.categoryId;
      if (categoryId.isEmpty) {
        final categories = await DatabaseService.instance.getCategories();
        final category = categories.firstWhere(
          (c) => c.name == ci.product.category,
          orElse: () => Category(
            id: '',
            name: '',
            description: '',
            icon: Icons.category,
            color: Colors.grey,
            sortOrder: 0,
          ),
        );
        categoryId = category.id;
      }

      if (!mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => ModifierSelectionDialog(
          item: item,
          categoryId: categoryId,
          initialSelectedItemIds: ci.modifiers.isNotEmpty
              ? ci.modifiers.map((m) => m.id).toSet()
              : null,
        ),
      );

      if (!mounted) return;
      if (result == null) return;

      final selectedModifiers = result['modifiers'] as List<ModifierItem>;
      final priceAdjustment = result['priceAdjustment'] as double;

      setState(() {
        final q = cartItems[index].quantity;
        final updated = CartItem(
          cartItems[index].product,
          q,
          modifiers: selectedModifiers,
          priceAdjustment: priceAdjustment,
          discountPerUnit: cartItems[index].discountPerUnit,
        );

        // Try to merge with an existing cart item if the configuration matches
        final existingIndex = cartItems.indexWhere(
          (ci) =>
              ci.hasSameConfigurationWithDiscount(
                updated.product,
                updated.modifiers,
                updated.discountPerUnit,
                otherPriceAdjustment: updated.priceAdjustment,
              ) &&
              cartItems.indexOf(ci) != index,
        );
        if (existingIndex != -1) {
          cartItems[existingIndex].quantity += updated.quantity;
          cartItems.removeAt(index);
        } else {
          cartItems[index] = updated;
        }
      });
    } catch (e) {
      developer.log('Error editing modifiers: $e');
      if (!mounted) return;
      ToastHelper.showToast(context, 'Error editing modifiers');
    }
  }
}
