import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/pos/cart_panel.dart';
import 'package:extropos/screens/pos/cash_payment_dialog.dart';
import 'package:extropos/screens/pos/product_grid.dart';
import 'package:extropos/services/audit_service_appwrite.dart';
import 'package:extropos/services/product_service.dart';
import 'package:flutter/material.dart';

class PosHome extends StatefulWidget {
  const PosHome({super.key});

  @override
  _PosHomeState createState() => _PosHomeState();
}

class _PosHomeState extends State<PosHome> {
  final ProductService _productService = ProductService();
  List<Product> products = [];
  final List<CartItem> cart = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final loadedProducts = await _productService.getProducts(limit: 200);
      if (mounted) {
        setState(() => products = loadedProducts);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load products: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addProduct(Product p) {
    setState(() {
      final existing = cart.firstWhere((c) => c.product.name == p.name, orElse: () => CartItem(product: p, quantity: 0));
      if (existing.quantity == 0) {
        cart.add(CartItem(product: p, quantity: 1));
      } else {
        existing.quantity += 1;
      }
    });
  }

  void _changeQty(CartItem item, int newQty) {
    setState(() {
      if (newQty <= 0) {
        cart.removeWhere((c) => c.product.name == item.product.name);
      } else {
        final idx = cart.indexWhere((c) => c.product.name == item.product.name);
        if (idx != -1) cart[idx].quantity = newQty;
      }
    });
  }

  void _clearCart() {
    setState(() => cart.clear());
  }

  void _checkout() async {
    final subtotal = cart.fold(0.0, (s, it) => s + it.lineTotal);
    final businessInfo = BusinessInfo.instance;
    final tax = businessInfo.isTaxEnabled ? (subtotal * businessInfo.taxRate) : 0.0;
    final serviceCharge = businessInfo.isServiceChargeEnabled
        ? (subtotal * businessInfo.serviceChargeRate)
        : 0.0;
    final total = subtotal + tax + serviceCharge;

    final method = await _showPaymentMethodDialog(total);
    if (!mounted || method == null) return;

    if (method == 'CASH') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CashPaymentDialog(
          totalAmount: total,
          onPaymentConfirmed: (tendered) => _processCashPayment(subtotal, tendered),
        ),
      );
    } else {
      await _confirmNonCashPayment(method, total);
    }
  }

  Future<String?> _showPaymentMethodDialog(double total) {
    final businessInfo = BusinessInfo.instance;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total: ${businessInfo.currencySymbol}${total.toStringAsFixed(2)}'),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('CASH'),
              child: Text('Cash'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('CARD'),
              child: Text('Card (Offline Stub)'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('EWALLET'),
              child: Text('E-Wallet (Offline Stub)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmNonCashPayment(String method, double total) async {
    final businessInfo = BusinessInfo.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${_paymentLabel(method)} Payment'),
        content: Text(
          'Confirm ${_paymentLabel(method)} payment for '
          '${businessInfo.currencySymbol}${total.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final subtotal = cart.fold(0.0, (s, it) => s + it.lineTotal);
    await _processNonCashPayment(method, subtotal, total);
  }

  Future<void> _processNonCashPayment(
    String method,
    double subtotal,
    double total,
  ) async {
    try {
      final businessInfo = BusinessInfo.instance;
      final tax = businessInfo.isTaxEnabled ? (subtotal * businessInfo.taxRate) : 0.0;
      final serviceCharge = businessInfo.isServiceChargeEnabled
          ? (subtotal * businessInfo.serviceChargeRate)
          : 0.0;

      final now = DateTime.now();
      final txnId =
          'txn_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch % 100000}';

      final txnData = {
        'id': txnId,
        'items': cart.map((ci) => {
          'name': ci.product.name,
          'qty': ci.quantity,
          'price': ci.product.price,
          'total': ci.lineTotal,
        }).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'serviceCharge': serviceCharge,
        'total': total,
        'tendered': total,
        'change': 0.0,
        'payment_method': method,
        'created_at': now.toIso8601String(),
      };

      try {
        await AuditServiceAppwrite.instance.logActivity(
          userId: 'cashier_1',
          action: '${method}_PAYMENT',
          resourceType: 'TRANSACTION',
          resourceId: txnId,
          changesBefore: null,
          changesAfter: txnData,
          success: true,
          userName: 'Cashier',
        );
      } catch (e) {
        print('⚠️ Failed to log payment: $e');
      }

      _showReceiptDialog(txnData);
      _clearCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processCashPayment(double subtotal, double tendered) async {
    try {
      final businessInfo = BusinessInfo.instance;
      final tax = businessInfo.isTaxEnabled ? (subtotal * businessInfo.taxRate) : 0.0;
      final serviceCharge = businessInfo.isServiceChargeEnabled
          ? (subtotal * businessInfo.serviceChargeRate)
          : 0.0;
      final total = subtotal + tax + serviceCharge;
      final change = tendered - total;

      // Generate transaction ID
      final now = DateTime.now();
      final txnId = 'txn_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch % 100000}';

      // Build transaction data
      final txnData = {
        'id': txnId,
        'items': cart.map((ci) => {
          'name': ci.product.name,
          'qty': ci.quantity,
          'price': ci.product.price,
          'total': ci.lineTotal,
        }).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'serviceCharge': serviceCharge,
        'total': total,
        'tendered': tendered,
        'change': change,
        'payment_method': 'CASH',
        'created_at': now.toIso8601String(),
      };

      // Log activity
      try {
        await AuditServiceAppwrite.instance.logActivity(
          userId: 'cashier_1',
          action: 'CASH_PAYMENT',
          resourceType: 'TRANSACTION',
          resourceId: txnId,
          changesBefore: null,
          changesAfter: txnData,
          success: true,
          userName: 'Cashier',
        );
      } catch (e) {
        print('⚠️ Failed to log payment: $e');
      }

      // Show receipt
      _showReceiptDialog(txnData);
      _clearCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReceiptDialog(Map<String, dynamic> txn) {
    final businessInfo = BusinessInfo.instance;
    final items = (txn['items'] as List<dynamic>?) ?? [];
    final methodLabel = _paymentLabel(txn['payment_method']?.toString() ?? 'CASH');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Receipt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(businessInfo.businessName,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text(businessInfo.address,
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              Divider(height: 16),
              Text('Receipt #: ${txn['id']}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Date: ${DateTime.parse(txn['created_at'] as String).toLocal()}',
                  style: TextStyle(fontSize: 11)),
                Text('Payment: $methodLabel', style: TextStyle(fontSize: 11)),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.map((item) {
                  final cartItem = item as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${cartItem['name']} x${cartItem['qty']}',
                              style: TextStyle(fontSize: 12)),
                        ),
                        Text('${businessInfo.currencySymbol}${(cartItem['total'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:', style: TextStyle(fontSize: 12)),
                  Text('${businessInfo.currencySymbol}${(txn['subtotal'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              if (((txn['tax'] as num?)?.toDouble() ?? 0.0) > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax:', style: TextStyle(fontSize: 12)),
                    Text('${businessInfo.currencySymbol}${(txn['tax'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              if (((txn['serviceCharge'] as num?)?.toDouble() ?? 0.0) > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Service:', style: TextStyle(fontSize: 12)),
                    Text('${businessInfo.currencySymbol}${(txn['serviceCharge'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${businessInfo.currencySymbol}${(txn['total'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tendered:', style: TextStyle(fontSize: 12)),
                  Text('${businessInfo.currencySymbol}${(txn['tendered'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${businessInfo.currencySymbol}${(txn['change'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.green[700])),
                ],
              ),
              SizedBox(height: 12),
              Center(
                child: Text('Thank you! Please come again.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CARD':
        return 'Card';
      case 'EWALLET':
        return 'E-Wallet';
      case 'CASH':
      default:
        return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('POS — YUMA Style (Prototype)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('POS — YUMA Style (Prototype)')),
        body: Center(child: Text(_error!)),
      );
    }

    if (products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('POS — YUMA Style (Prototype)')),
        body: const Center(child: Text('No products available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('POS — YUMA Style (Prototype)'),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search)), SizedBox(width: 8)],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 900;
        final isDesktop = width >= 900 && width < 1200;

        if (width >= 900) {
          final cartWidth = isDesktop ? 360.0 : 420.0;
          return Row(
            children: [
              Expanded(child: ProductGrid(products: products, onAdd: (p) => _addProduct(p))),
              SizedBox(
                width: cartWidth,
                child: CartPanel(
                  items: cart,
                  onQtyChange: _changeQty,
                  onClear: _clearCart,
                  onCheckout: _checkout,
                ),
              ),
            ],
          );
        }

        final cartHeight = isMobile ? 260.0 : (isTablet ? 300.0 : 320.0);
        return Column(
          children: [
            Expanded(child: ProductGrid(products: products, onAdd: (p) => _addProduct(p))),
            SizedBox(
              height: cartHeight,
              child: CartPanel(
                items: cart,
                onQtyChange: _changeQty,
                onClear: _clearCart,
                onCheckout: _checkout,
              ),
            ),
          ],
        );
      }),
    );
  }
}
