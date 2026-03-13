part of 'payment_screen.dart';

/// Payment processing logic and helpers
extension _PaymentScreenOperations on _PaymentScreenState {
  /// Get the amount entered by user
  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0.0;

  /// Calculate change from entered amount
  double get _change => _enteredAmount - widget.totalAmount;

  /// Validate if payment can be processed
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

  /// Select a quick cash amount
  void _selectCashAmount(double amount) {
    _updateState(() {
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  /// Process the payment based on selected method
  void _processPayment() async {
    if (!_isValidPayment || _selectedPaymentMethod == null) return;

    _updateState(() => _isProcessing = true);

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
        _updateState(() => _isProcessing = false);
        
        final resultMap = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EWalletPaymentScreen(
              amount: widget.totalAmount,
              methodName: _selectedPaymentMethod!.name,
              orderRef: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
              merchantId: widget.merchantId,
            ),
          ),
        );

        if (!mounted) return;
        
        if (resultMap is Map && resultMap['success'] == true) {
          _updateState(() => _isProcessing = true);
          // Continue processing with the confirmed payment
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
          _updateState(() => _isProcessing = false);
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
      _updateState(() => _isProcessing = false);
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

        // Payment successful - show receipt preview
        final businessInfo = BusinessInfo.instance;
        final subtotal = widget.cartItems?.fold<double>(
              0.0,
              (sum, item) => sum + (item.finalPrice * item.quantity),
            ) ??
            widget.totalAmount;
        final taxAmount = businessInfo.isTaxEnabled
            ? subtotal * businessInfo.taxRate
            : 0.0;
        final serviceChargeAmount = businessInfo.isServiceChargeEnabled
            ? subtotal * businessInfo.serviceChargeRate
            : 0.0;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPreviewScreen(
              cartItems: widget.cartItems?.map((item) => {
                'product_id': item.product.id,
                'name': item.product.name,
                'price': item.finalPrice,
                'quantity': item.quantity,
                'category_id': item.product.category,
              }).toList() ?? [],
              subtotal: subtotal,
              tax: taxAmount,
              serviceCharge: serviceChargeAmount,
              total: widget.totalAmount,
              paymentResult: result,
              onPrint: () {
                // Receipt will be printed automatically after preview
              },
              onComplete: () {
                // Transaction completed
              },
            ),
          ),
        );

        // Return payment result regardless of receipt preview outcome
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
          _updateState(() => _isProcessing = false);
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
      _updateState(() => _isProcessing = false);
      if (!mounted) return;
      ToastHelper.showToast(context, 'Payment processing error: $e');
    }
  }
}
