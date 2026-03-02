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

part 'retail_pos_screen_modern_futures.dart';
part 'retail_pos_screen_modern_operations.dart';
part 'retail_pos_screen_modern_operations_part2.dart';
part 'retail_pos_screen_modern_operations_part3.dart';
part 'retail_pos_screen_modern_medium_widgets.dart';
part 'retail_pos_screen_modern_small_widgets.dart';
part 'retail_pos_screen_modern_large_widgets.dart';

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
  final List<Category> _categoryObjects = [];

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
  final String _searchQuery = '';
  final Set<String> _favoriteProductIds = {}; // Quick add favorites

  // Cart animation feedback
  late AnimationController _cartAddAnimController;

  // Number pad for quantity input
  final String _quantityInput = '1';
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


  }


  }

  }






  }



  }

  }
  }
  }
  }
  }

  }


  }


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
  }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            Expanded(
                              child: Text(
                                _selectedProductForQuantity != null
                                    ? _selectedProductForQuantity!.name
                                    : 'Quantity',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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







  // Payment processing methods
  // ignore: unused_element

  // ignore: unused_element


    void try {
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
    } void catch (e) {
      developer.log('AUTO-PRINT (Retail): Exception - $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }
}
