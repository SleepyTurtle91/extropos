import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/screens/ewallet_payment_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<PaymentMethod> availablePaymentMethods;
  final PaymentMethod? preSelectedPaymentMethod; // Pre-selected from POS screen
  final List<CartItem>? cartItems; // Optional: show order summary
  final double billDiscount;
  final String? merchantId;
  final String? orderType;
  final String? tableId;
  final int? cafeOrderNumber;
  final String? userId;
  final Customer? selectedCustomer; // Pre-selected customer from POS
  final String? initialCustomerName;
  final String? initialCustomerPhone;
  final String? initialCustomerEmail;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.availablePaymentMethods,
    this.preSelectedPaymentMethod,
    this.cartItems,
    this.billDiscount = 0.0,
    this.merchantId,
    this.orderType,
    this.tableId,
    this.cafeOrderNumber,
    this.userId,
    this.selectedCustomer,
    this.initialCustomerName,
    this.initialCustomerPhone,
    this.initialCustomerEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isProcessing = false;
  Customer? _selectedCustomer;
  List<Customer> _customerSuggestions = [];
  bool _isSearchingCustomer = false;

  @override
  void initState() {
    super.initState();
    // Use pre-selected payment method from POS screen if provided
    if (widget.preSelectedPaymentMethod != null) {
      _selectedPaymentMethod = widget.preSelectedPaymentMethod;
    } else {
      // Otherwise, set default payment method if available
      final defaultMethod = widget.availablePaymentMethods
          .where(
            (method) =>
                method.isDefault && method.status == PaymentMethodStatus.active,
          )
          .firstOrNull;
      if (defaultMethod != null) {
        _selectedPaymentMethod = defaultMethod;
      } else if (widget.availablePaymentMethods.isNotEmpty) {
        // Select first active method if no default
        _selectedPaymentMethod = widget.availablePaymentMethods.firstWhere(
          (method) => method.status == PaymentMethodStatus.active,
        );
      }
    }

    // Pre-fill amount with total
    _amountController.text = widget.totalAmount.toStringAsFixed(2);

    // Initialize with pre-selected customer if provided
    if (widget.selectedCustomer != null) {
      _selectedCustomer = widget.selectedCustomer;
      _phoneController.text = widget.selectedCustomer!.phone ?? '';
      _nameController.text = widget.selectedCustomer!.name;
      _emailController.text = widget.selectedCustomer!.email ?? '';
    } else {
      // Pre-fill with initial customer information from POS screen
      _nameController.text = widget.initialCustomerName ?? '';
      _phoneController.text = widget.initialCustomerPhone ?? '';
      _emailController.text = widget.initialCustomerEmail ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Search for customer by phone number
  Future<void> _searchCustomerByPhone(String phone) async {
    if (phone.length < 3) {
      setState(() {
        _customerSuggestions = [];
        _selectedCustomer = null;
      });
      return;
    }

    setState(() => _isSearchingCustomer = true);

    try {
      final suggestions = await DatabaseService.instance.searchCustomers(phone);
      setState(() {
        _customerSuggestions = suggestions;
        _isSearchingCustomer = false;
      });
    } catch (e) {
      setState(() => _isSearchingCustomer = false);
    }
  }

  /// Select a customer from suggestions
  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _phoneController.text = customer.phone ?? '';
      _nameController.text = customer.name;
      _emailController.text = customer.email ?? '';
      _customerSuggestions = [];
    });
  }

  /// Clear customer selection
  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _phoneController.clear();
      _nameController.clear();
      _emailController.clear();
      _customerSuggestions = [];
    });
  }

  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _change => _enteredAmount - widget.totalAmount;

  bool get _isValidPayment =>
      _enteredAmount >= widget.totalAmount && _selectedPaymentMethod != null;

  /// Generate smart cash suggestions based on total amount
  List<double> _getCashSuggestions() {
    final total = widget.totalAmount;
    final suggestions = <double>[];

    // Always add exact amount
    suggestions.add(total);

    // Round up to nearest 5, 10, 50, or 100 depending on amount
    if (total < 10) {
      // Small amounts: suggest next RM5, RM10, RM20
      suggestions.add(((total / 5).ceil() * 5).toDouble());
      suggestions.add(10.0);
      suggestions.add(20.0);
    } else if (total < 50) {
      // Medium amounts: suggest next RM10, RM50, RM100
      suggestions.add(((total / 10).ceil() * 10).toDouble());
      suggestions.add(50.0);
      suggestions.add(100.0);
    } else if (total < 100) {
      // Larger amounts: suggest next RM50, RM100, RM200
      suggestions.add(((total / 50).ceil() * 50).toDouble());
      suggestions.add(100.0);
      suggestions.add(200.0);
    } else {
      // Very large amounts: suggest next RM100, RM200, RM500
      suggestions.add(((total / 100).ceil() * 100).toDouble());
      suggestions.add(((total / 200).ceil() * 200).toDouble());
      suggestions.add(((total / 500).ceil() * 500).toDouble());
    }

    // Remove duplicates and ensure suggestions are >= total
    return suggestions.toSet().where((amount) => amount >= total).toList()
      ..sort();
  }

  void _selectCashAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  void _processPayment() async {
    if (!_isValidPayment || _selectedPaymentMethod == null) return;

    setState(() => _isProcessing = true);

    try {
      PaymentResult result;

      // Determine if this is a cash or card payment
      final isCashPayment = _selectedPaymentMethod!.name.toLowerCase().contains(
            'cash',
          );

      // Intercept E-Wallet to show QR flow before processing
      if (!isCashPayment &&
          (_selectedPaymentMethod!.id == 'ewallet' ||
              _selectedPaymentMethod!.name
                  .toLowerCase()
                  .contains('e-wallet'))) {
        setState(() => _isProcessing = false);
        final orderRef = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        final resultMap = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EWalletPaymentScreen(
              amount: widget.totalAmount,
              methodName: _selectedPaymentMethod!.name,
              orderRef: orderRef,
              merchantId: widget.merchantId,
            ),
          ),
        );
        if (!mounted) return;
        if (resultMap is Map && resultMap['success'] == true) {
          setState(() => _isProcessing = true);
        } else {
          // User canceled or failed
          ToastHelper.showToast(context, 'E-Wallet payment canceled');
          return;
        }
      }

      if (isCashPayment) {
        // Process cash payment
        result = await PaymentService.instance.processCashPayment(
          totalAmount: widget.totalAmount,
          amountPaid: _enteredAmount,
          cartItems: widget.cartItems ?? [],
          billDiscount: widget.billDiscount,
          orderType: widget.orderType ?? 'retail',
          tableId: widget.tableId,
          cafeOrderNumber: widget.cafeOrderNumber,
          userId: widget.userId,
          merchantId: widget.merchantId,
          customerName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          customerPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          customerEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
      } else {
        // Process card payment (must be exact amount)
        if (_enteredAmount != widget.totalAmount) {
          setState(() => _isProcessing = false);
          ToastHelper.showToast(
            context,
            'Card payments must be for the exact amount',
          );
          return;
        }

        result = await PaymentService.instance.processCardPayment(
          totalAmount: widget.totalAmount,
          paymentMethod: _selectedPaymentMethod!,
          cartItems: widget.cartItems ?? [],
          billDiscount: widget.billDiscount,
          orderType: widget.orderType ?? 'retail',
          tableId: widget.tableId,
          cafeOrderNumber: widget.cafeOrderNumber,
          userId: widget.userId,
          merchantId: widget.merchantId,
          customerName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          customerPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          customerEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (!mounted) return;
      if (result.success) {
        // Update customer stats if customer was selected or created
        if (_selectedCustomer != null) {
          // Calculate loyalty points (1 point per RM10 spent, double for VIP)
          int pointsEarned = (widget.totalAmount / 10).floor();
          if (_selectedCustomer!.customerTier == 'VIP') {
            pointsEarned *= 2;
          }
          await DatabaseService.instance.updateCustomerStats(
            customerId: _selectedCustomer!.id,
            orderTotal: widget.totalAmount,
            pointsEarned: pointsEarned,
          );
        } else if (_phoneController.text.trim().isNotEmpty &&
            _nameController.text.trim().isNotEmpty) {
          // Create new customer from entered data
          final newCustomer = Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            totalSpent: widget.totalAmount,
            visitCount: 1,
            loyaltyPoints:
                (widget.totalAmount / 10).floor(), // 1 point per RM10 spent
            lastVisit: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await DatabaseService.instance.insertCustomer(newCustomer);
        }

        // Payment successful
        Navigator.pop(context, {
          'success': true,
          'paymentMethod': result.paymentSplits.isNotEmpty
              ? result.paymentSplits.first.paymentMethod
              : PaymentMethod(id: 'cash', name: 'Cash'), // fallback
          'amountPaid': result.amountPaid,
          'change': result.change,
          'transactionId': result.transactionId,
          'receiptNumber': result.receiptNumber,
          'paymentSplits': result.paymentSplits,
        });
      } else {
        // Payment failed - show error dialog with more details
        if (mounted) {
          setState(() => _isProcessing = false);
          final errorMessage = result.errorMessage ?? 'Payment failed';
          developer.log('❌ Payment failed: $errorMessage');

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Failed'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to complete payment. Details:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'What to try:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildTroubleshootingBullet(
                        'Check that all items are from the database'),
                    _buildTroubleshootingBullet(
                        'Try removing and re-adding items'),
                    _buildTroubleshootingBullet(
                        'Restart the app if items are missing'),
                    _buildTroubleshootingBullet(
                        'Contact support if problem persists'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ToastHelper.showToast(context, 'Payment processing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = BusinessInfo.instance.currencySymbol;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = isNarrow ? 12.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.cartItems?.isNotEmpty ?? false)) ...[
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...widget.cartItems!.map((ci) {
                        final unit = ci.finalPrice; // includes modifiers
                        final lineTotal = ci.totalPrice;
                        final mods = ci.modifiers;
                        final hasMods = mods.isNotEmpty;
                        final modsText = hasMods
                            ? mods
                                .map(
                                  (m) => m.priceAdjustment == 0
                                      ? m.name
                                      : '${m.name} (${m.getPriceAdjustmentDisplay()})',
                                )
                                .join(', ')
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            ci.seatNumber != null
                                                ? '${ci.product.name} (Seat ${ci.seatNumber})'
                                                : ci.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'x${ci.quantity}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasMods) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        modsText,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$currencySymbol ${lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '@ $currencySymbol ${unit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if ((widget.cartItems?.isNotEmpty ?? false)) ...[
                const Text(
                  'Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final items = widget.cartItems!;
                    final subtotal = Pricing.subtotal(items);
                    final info = BusinessInfo.instance;
                    final discount = widget.billDiscount;
                    final tax = Pricing.taxAmountWithDiscount(items, discount);
                    final service = Pricing.serviceChargeAmountWithDiscount(
                      items,
                      discount,
                    );
                    final total = Pricing.totalWithDiscount(items, discount);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(
                                  '$currencySymbol ${subtotal.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (discount > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount'),
                                  Text(
                                    '-$currencySymbol ${discount.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (info.isTaxEnabled) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tax (${info.taxRatePercentage})'),
                                  Text(
                                    '$currencySymbol ${tax.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (info.isServiceChargeEnabled) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service Charge (${info.serviceChargeRatePercentage})',
                                  ),
                                  Text(
                                    '$currencySymbol ${service.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$currencySymbol ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
            // Amount Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currencySymbol ${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Customer Information (Optional)
            const Text(
              'Customer Information (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Phone number field with customer search
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _selectedCustomer != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearCustomer,
                        tooltip: 'Clear customer',
                      )
                    : (_isSearchingCustomer
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : null),
                border: const OutlineInputBorder(),
                helperText: 'Search existing customer by phone',
              ),
              onChanged: _searchCustomerByPhone,
              enabled: _selectedCustomer == null,
            ),

            // Customer suggestions dropdown
            if (_customerSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customerSuggestions.length,
                  itemBuilder: (context, index) {
                    final customer = _customerSuggestions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(
                        '${customer.phone ?? 'No phone'} • ${customer.customerTier} • ${customer.visitCount} visits',
                      ),
                      trailing: Text(
                        '${customer.loyaltyPoints} pts',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _selectCustomer(customer),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Customer name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                helperText: _selectedCustomer != null
                    ? '${_selectedCustomer!.customerTier} customer • ${_selectedCustomer!.visitCount} visits'
                    : 'Enter customer name',
              ),
              enabled: _selectedCustomer == null,
            ),

            const SizedBox(height: 12),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              enabled: _selectedCustomer == null,
            ),

            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (widget.availablePaymentMethods.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No active payment methods available. Please add payment methods in settings.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              RadioGroup<PaymentMethod>(
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value);
                },
                child: Column(
                  children: widget.availablePaymentMethods
                      .where(
                        (method) => method.status == PaymentMethodStatus.active,
                      )
                      .map(
                        (method) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<PaymentMethod>(
                            title: Row(
                              children: [
                                Text(method.name),
                                if (method.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            value: method,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Payment Amount Input
            const Text(
              'Payment Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixText: currencySymbol,
                border: const OutlineInputBorder(),
                helperText: 'Enter the amount received from customer',
              ),
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Quick Cash Buttons (only show for cash payments)
            if (_selectedPaymentMethod != null &&
                _selectedPaymentMethod!.name.toLowerCase().contains(
                      'cash',
                    )) ...[
              const Text(
                'Quick Cash',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getCashSuggestions().take(4).map((amount) {
                  final isExact = amount == widget.totalAmount;
                  return OutlinedButton(
                    onPressed: () => _selectCashAmount(amount),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: isExact
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade400,
                        width: isExact ? 2 : 1,
                      ),
                      backgroundColor: _enteredAmount == amount
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currencySymbol ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _enteredAmount == amount
                                ? const Color(0xFF2563EB)
                                : Colors.black87,
                          ),
                        ),
                        if (isExact)
                          const Text(
                            'Exact',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2563EB),
                            ),
                          )
                        else if (amount - widget.totalAmount > 0)
                          Text(
                            'Change: $currencySymbol${(amount - widget.totalAmount).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // Change Display
            if (_enteredAmount > widget.totalAmount)
              Card(
                color: Color.fromRGBO(76, 175, 80, 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$currencySymbol ${_change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final stackButtons = constraints.maxWidth < 520;
                final processButton = ElevatedButton(
                  onPressed:
                      _isProcessing || !_isValidPayment ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Process Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                );

                final cancelButton = OutlinedButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                );

                if (stackButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      processButton,
                      const SizedBox(height: 12),
                      cancelButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: processButton),
                  ],
                );
              },
            ),

            if (!_isValidPayment && !_isProcessing) ...[
              const SizedBox(height: 16),
              Text(
                _selectedPaymentMethod == null
                    ? 'Please select a payment method'
                    : 'Payment amount must be at least the total amount',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
