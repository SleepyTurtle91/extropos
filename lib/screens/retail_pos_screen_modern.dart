// MODERN RETAIL POS SCREEN - Layer C (Assembler)
// Orchestrates services (Layer A) and widgets (Layer B)
// Manages navigation and screen state

import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/product_service.dart';
import 'package:extropos/services/receipt_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/number_pad_widget.dart';
import 'package:extropos/widgets/product_grid_widget.dart';
import 'package:flutter/material.dart';

class RetailPOSScreenModern extends StatefulWidget {
  final bool embedded;

  const RetailPOSScreenModern({super.key, this.embedded = false});

  @override
  State<RetailPOSScreenModern> createState() => _RetailPOSScreenModernState();
}

class _RetailPOSScreenModernState extends State<RetailPOSScreenModern>
    with TickerProviderStateMixin {
  // Layer A: Services
  late final CartService cartService;

  // Screen state
  String selectedCategory = 'All';
  List<String> categories = ['All'];
  final List<Category> _categoryObjects = [];
  List<Product> products = [];

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
    PaymentMethod(id: 'ewallet', name: 'E-Wallet'),
  ];

  String selectedMerchant = 'none';
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? specialInstructions;
  Customer? selectedCustomer;
  double billDiscount = 0.0;
  final List<Customer> customers = [];

  // Number pad state
  String quantityInput = '1';
  Product? selectedProductForQuantity;

  // Colors
  static const Color darkNavy = Color(0xFF1E2A3A);
  static const Color darkNavyLight = Color(0xFF2C3E50);
  static const Color accentGreen = Color(0xFF00D9A5);
  static const Color accentBlue = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    cartService = CartService.instance;
    _loadData();
  }

  Future<void> _loadData() async {
    // Load categories and products from database
    final loadedCategories = await DatabaseService.instance.getCategories();
    final loadedProducts = await ProductService().getProducts();

    setState(() {
      categories = ['All', ...loadedCategories.map((c) => c.name)];
      _categoryObjects.addAll(loadedCategories);
      products = loadedProducts;
    });
  }

  void _onProductSelected(Product product) {
    // Add to cart using Layer A service
    cartService.addProduct(product, quantity: int.tryParse(quantityInput) ?? 1);
    setState(() {});
    ToastHelper.showToast(context, '${product.name} added to cart');
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (quantityInput == '0') {
        quantityInput = number;
      } else {
        quantityInput += number;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      quantityInput = '1';
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (quantityInput.length > 1) {
        quantityInput = quantityInput.substring(0, quantityInput.length - 1);
      } else {
        quantityInput = '1';
      }
    });
  }

  Future<void> _printReceipt(List<CartItem> items, double subtotal, double tax,
      double serviceCharge, double total, PaymentResult paymentResult) async {
    try {
      final receiptData = await ReceiptService.prepareReceiptData(
        items,
        subtotal,
        tax,
        serviceCharge,
        total,
        paymentResult,
      );
      await ReceiptService.printReceipt(receiptData);
      developer.log('AUTO-PRINT (Retail): Receipt printed successfully');
    } catch (e) {
      developer.log('AUTO-PRINT (Retail): Exception - $e');
      if (mounted) {
        ToastHelper.showToast(context, 'Print error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = cartService.items;
    final subtotal = CartCalculationService.calculateSubtotal(cartItems);
    final tax = CartCalculationService.calculateTax(subtotal, BusinessInfo.instance);
    final serviceCharge = CartCalculationService.calculateServiceCharge(subtotal, BusinessInfo.instance);
    final total = CartCalculationService.calculateTotalWithDiscount(cartItems, BusinessInfo.instance, billDiscount, 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail POS'),
        backgroundColor: darkNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              // Navigate to cart/payment screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    cartItems: cartItems,
                    total: total,
                    discount: billDiscount,
                    onPaymentComplete: () {
                      // Refresh the screen after payment
                      setState(() {});
                      ToastHelper.showToast(context, 'Payment completed successfully');
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive layout: Row on large screens, Column on small screens
          final isLargeScreen = constraints.maxWidth >= 900;
          
          if (isLargeScreen) {
            return Row(
              children: [
                // Left panel: Categories and Products
                Expanded(
                  flex: 2,
                  child: _buildLeftPanel(),
                ),
                // Right panel: Number pad and Cart
                Expanded(
                  flex: 1,
                  child: _buildRightPanel(cartItems, subtotal, tax, serviceCharge, total),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                // Top panel: Categories and Products
                Expanded(
                  flex: 3,
                  child: _buildLeftPanel(),
                ),
                // Bottom panel: Number pad and Cart
                Expanded(
                  flex: 2,
                  child: _buildRightPanel(cartItems, subtotal, tax, serviceCharge, total),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        // Category selector
        Container(
          height: 60,
          color: darkNavyLight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? accentGreen : Colors.white,
                    foregroundColor: isSelected ? Colors.white : darkNavy,
                  ),
                  child: Text(category),
                ),
              );
            },
          ),
        ),
        // Products grid - Layer B widget
        Expanded(
          child: ProductGridWidget(
            products: _getFilteredProducts(),
            onProductSelected: _onProductSelected,
            backgroundColor: Colors.grey.shade50,
            cardColor: Colors.white,
            textColor: darkNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(List<CartItem> cartItems, double subtotal, double tax, double serviceCharge, double total) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Number pad - Layer B widget
          NumberPadWidget(
            currentValue: quantityInput,
            onNumberPressed: _onNumberPressed,
            onClearPressed: _onClearPressed,
            onBackspacePressed: _onBackspacePressed,
            backgroundColor: Colors.white,
            buttonColor: accentBlue,
            textColor: Colors.white,
          ),
          // Cart summary
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cart Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('Qty: ${item.quantity}'),
                          trailing: Text('\$${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  _buildTotalRow('Subtotal', subtotal),
                  if (billDiscount > 0) _buildTotalRow('Discount', -billDiscount),
                  _buildTotalRow('Tax', tax),
                  _buildTotalRow('Service', serviceCharge),
                  _buildTotalRow('Total', total, isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts() {
    if (selectedCategory == 'All') {
      return products;
    }
    return products.where((p) => p.category == selectedCategory).toList();
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: darkNavy,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}