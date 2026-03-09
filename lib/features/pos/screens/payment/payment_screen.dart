import 'dart:developer' as developer;

import 'package:extropos/features/pos/screens/payment/widgets/amount_input_widget.dart';
import 'package:extropos/features/pos/screens/payment/widgets/order_summary_widget.dart';
import 'package:extropos/features/pos/screens/payment/widgets/payment_breakdown_widget.dart';
import 'package:extropos/features/pos/screens/payment/widgets/payment_method_selector_widget.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/screens/receipt_preview_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'payment_screen_operations.dart';
part 'payment_screen_ui.dart';

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

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

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
      _updateState(() {
        _customerSuggestions = [];
        _selectedCustomer = null;
      });
      return;
    }

    _updateState(() => _isSearchingCustomer = true);

    try {
      final suggestions = await DatabaseService.instance.searchCustomers(phone);
      _updateState(() {
        _customerSuggestions = suggestions;
        _isSearchingCustomer = false;
      });
    } catch (e) {
      _updateState(() => _isSearchingCustomer = false);
    }
  }

  /// Select a customer from suggestions
  void _selectCustomer(Customer customer) {
    _updateState(() {
      _selectedCustomer = customer;
      _phoneController.text = customer.phone ?? '';
      _nameController.text = customer.name;
      _emailController.text = customer.email ?? '';
      _customerSuggestions = [];
    });
  }

  /// Clear customer selection
  void _clearCustomer() {
    _updateState(() {
      _selectedCustomer = null;
      _phoneController.clear();
      _nameController.clear();
      _emailController.clear();
      _customerSuggestions = [];
    });
  }

  // Payment processing methods and helpers moved to payment_screen_operations.dart extension

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
              OrderSummaryWidget(
                cartItems: widget.cartItems!,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 24),
              PaymentBreakdownWidget(
                cartItems: widget.cartItems!,
                billDiscount: widget.billDiscount,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: 24),
            ],
            // Amount Summary Card
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
            // Use builder methods from PaymentScreenUI extension
            buildCustomerSection(),
            const SizedBox(height: 24),
            buildPaymentMethodSection(),
            const SizedBox(height: 24),
            buildAmountSection(),
            const SizedBox(height: 16),
            buildChangeDisplay(),
            const SizedBox(height: 32),
            buildActionButtons(),
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
