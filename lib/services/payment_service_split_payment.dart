part of 'payment_service.dart';

extension PaymentServiceSplitPayment on PaymentService {
  /// Process a payment with multiple splits (enhanced split payment support)
  Future<PaymentResult> processSplitPayment({
    required List<CartItem> cartItems,
    required List<PaymentSplit> paymentSplits,
    double billDiscount = 0.0,
    String orderType = 'retail',
    String? tableId,
    int? cafeOrderNumber,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? specialInstructions,
    String? merchantId,
  }) async {
    try {
      final subtotal = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final subtotalAfterDiscount = (subtotal - billDiscount) < 0
          ? 0.0
          : (subtotal - billDiscount);
      final info = BusinessInfo.instance;
      final tax = info.isTaxEnabled
          ? subtotalAfterDiscount * info.taxRate
          : 0.0;
      final serviceCharge = info.isServiceChargeEnabled
          ? subtotalAfterDiscount * info.serviceChargeRate
          : 0.0;

      final totalAmount = subtotalAfterDiscount + tax + serviceCharge;
      final totalPaid = paymentSplits.fold(0.0, (sum, split) => sum + split.amount);

      final validationError = validatePaymentSplits(paymentSplits, totalAmount);
      if (validationError != null) {
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: paymentSplits,
          amountPaid: totalPaid,
        );
      }

      final rawChange = totalPaid - totalAmount;
      final change = _calculateMalaysianRounding(rawChange);

      for (final split in paymentSplits) {
        final success = await _processPaymentSplit(split);
        if (!success) {
          return PaymentResult.failure(
            errorMessage: 'Payment processing failed for ${split.paymentMethod.name}',
            paymentSplits: paymentSplits,
            amountPaid: totalPaid,
          );
        }
      }

      if (TrainingModeService.instance.isTrainingMode) {
        final fakeReceipt = 'TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        TrainingModeService.instance.addTrainingTransaction({
          'receiptNumber': fakeReceipt,
          'cartItems': cartItems.map((c) => c.toJson()).toList(),
          'paymentSplits': paymentSplits.map((s) => s.toJson()).toList(),
          'subtotal': subtotal,
          'tax': tax,
          'serviceCharge': serviceCharge,
          'total': totalAmount,
          'discount': billDiscount,
          'amountPaid': totalPaid,
          'change': change,
          'orderType': orderType,
          'tableId': tableId,
          'cafeOrderNumber': cafeOrderNumber,
          'userId': userId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'notes': notes,
          'specialInstructions': specialInstructions,
          'merchantId': merchantId,
        });

        developer.log('Training mode: stored split payment receipt $fakeReceipt');
        return PaymentResult.success(
          transactionId: fakeReceipt,
          receiptNumber: fakeReceipt,
          amountPaid: totalPaid,
          change: change,
          paymentSplits: paymentSplits,
        );
      }

      final receiptNumber = await DatabaseService.instance.saveCompletedSaleWithSplits(
        cartItems: cartItems,
        paymentSplits: paymentSplits,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        discount: billDiscount,
        amountPaid: totalPaid,
        change: change,
        orderType: orderType,
        tableId: tableId,
        cafeOrderNumber: cafeOrderNumber,
        userId: userId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        notes: notes,
        specialInstructions: specialInstructions,
        merchantId: merchantId,
      );

      if (receiptNumber == null) {
        return PaymentResult.failure(
          errorMessage: 'Failed to save split payment transaction to database',
          paymentSplits: paymentSplits,
          amountPaid: totalPaid,
        );
      }

      if (!TrainingModeService.instance.isTrainingMode) {
        await _deductStockForItems(cartItems);
      }

      developer.log('Split payment processed successfully. Receipt: $receiptNumber');
      return PaymentResult.success(
        transactionId: receiptNumber,
        receiptNumber: receiptNumber,
        amountPaid: totalPaid,
        change: change,
        paymentSplits: paymentSplits,
      );
    } catch (e) {
      developer.log('Error processing split payment: $e');
      return PaymentResult.failure(
        errorMessage: 'Payment processing failed: $e',
        paymentSplits: paymentSplits,
        amountPaid: paymentSplits.fold(0.0, (sum, split) => sum + split.amount),
      );
    }
  }

  /// Validate payment splits
  String? validatePaymentSplits(List<PaymentSplit> paymentSplits, double totalAmount) {
    if (paymentSplits.isEmpty) {
      return 'At least one payment method is required';
    }

    final totalPaid = paymentSplits.fold(0.0, (sum, split) => sum + split.amount);
    if (totalPaid < totalAmount) {
      return 'Total payment amount \$${totalPaid.toStringAsFixed(2)} is less than required \$${totalAmount.toStringAsFixed(2)}';
    }

    for (final split in paymentSplits) {
      if (split.amount <= 0) {
        return 'Payment amount for ${split.paymentMethod.name} must be greater than 0';
      }
    }

    return null;
  }

  /// Calculate Malaysian rounding (round to nearest 0.05)
  double _calculateMalaysianRounding(double amount) {
    if (amount <= 0) return 0.0;
    final rounded = (amount / 0.05).round() * 0.05;
    return rounded;
  }

  /// Process individual payment split
  Future<bool> _processPaymentSplit(PaymentSplit split) async {
    try {
      switch (split.paymentMethod.id) {
        case 'cash':
          return true;
        case 'card':
          await Future.delayed(const Duration(milliseconds: 500));
          return forceCardSuccess || (DateTime.now().millisecondsSinceEpoch % 10 != 0);
        case 'ewallet':
          await Future.delayed(const Duration(milliseconds: 300));
          return forceCardSuccess || (DateTime.now().millisecondsSinceEpoch % 5 != 0);
        default:
          return false;
      }
    } catch (e) {
      developer.log('Error processing payment split: $e');
      return false;
    }
  }
}
