part of 'payment_service.dart';

extension PaymentServiceCashCard on PaymentService {
  /// Process a cash payment
  Future<PaymentResult> processCashPayment({
    required double totalAmount,
    required double amountPaid,
    required List<CartItem> cartItems,
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
      final validationError = await _validateCartItemsExistInDB(cartItems);
      if (validationError != null) {
        developer.log('❌ Cart validation failed: $validationError');
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: [PaymentSplit(paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'), amount: amountPaid)],
          amountPaid: amountPaid,
        );
      }

      if (amountPaid < totalAmount) {
        return PaymentResult.failure(
          errorMessage:
              'Insufficient payment amount. Required: \$${totalAmount.toStringAsFixed(2)}, Paid: \$${amountPaid.toStringAsFixed(2)}',
          paymentSplits: [PaymentSplit(paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'), amount: amountPaid)],
          amountPaid: amountPaid,
        );
      }

      final change = amountPaid - totalAmount;

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

      final paymentMethod = PaymentMethod(id: 'cash', name: 'Cash');

      if (TrainingModeService.instance.isTrainingMode) {
        final fakeReceipt = 'TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        TrainingModeService.instance.addTrainingTransaction({
          'receiptNumber': fakeReceipt,
          'cartItems': cartItems.map((c) => c.toJson()).toList(),
          'subtotal': subtotal,
          'tax': tax,
          'serviceCharge': serviceCharge,
          'total': totalAmount,
          'paymentMethod': paymentMethod.name,
          'amountPaid': amountPaid,
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

        developer.log('Training mode: stored fake receipt $fakeReceipt');
        return PaymentResult.success(
          transactionId: fakeReceipt,
          receiptNumber: fakeReceipt,
          amountPaid: amountPaid,
          change: change,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: amountPaid)],
        );
      }

      final receiptNumber = await DatabaseService.instance.saveCompletedSaleWithSplits(
        cartItems: cartItems,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: amountPaid)],
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        discount: billDiscount,
        amountPaid: amountPaid,
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
        developer.log('❌ Database save returned null - products may not match DB items');
        return PaymentResult.failure(
          errorMessage: 'Failed to save transaction: products not found in database. Try adding items from database first.',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: amountPaid)],
          amountPaid: amountPaid,
        );
      }

      if (!TrainingModeService.instance.isTrainingMode) {
        await _deductStockForItems(cartItems);
      }

      developer.log('Cash payment processed successfully: $receiptNumber');

      await _submitToMyInvoisIfEnabled(
        receiptNumber: receiptNumber,
        cartItems: cartItems,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        paymentMethod: paymentMethod.name,
      );

      return PaymentResult.success(
        transactionId: receiptNumber,
        receiptNumber: receiptNumber,
        amountPaid: amountPaid,
        change: change,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: amountPaid)],
      );
    } catch (e) {
      developer.log('❌ Cash payment processing failed: $e');
      developer.log('Stack trace: ${StackTrace.current}');
      return PaymentResult.failure(
        errorMessage: 'Payment error: ${e.toString().replaceAll('Exception: ', '')}',
        paymentSplits: [PaymentSplit(paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'), amount: amountPaid)],
        amountPaid: amountPaid,
      );
    }
  }

  /// Process a card payment (mock implementation)
  Future<PaymentResult> processCardPayment({
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required List<CartItem> cartItems,
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
      final validationError = await _validateCartItemsExistInDB(cartItems);
      if (validationError != null) {
        developer.log('❌ Cart validation failed: $validationError');
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
          amountPaid: totalAmount,
        );
      }

      await Future.delayed(const Duration(seconds: 2));

      final isValidCard = await _validateCardPayment(totalAmount);

      if (!isValidCard) {
        return PaymentResult.failure(
          errorMessage:
              'Card payment declined. Please try a different card or payment method.',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
          amountPaid: totalAmount,
        );
      }

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

      if (TrainingModeService.instance.isTrainingMode) {
        final fakeReceipt = 'TRAIN-${DateTime.now().millisecondsSinceEpoch}';
        TrainingModeService.instance.addTrainingTransaction({
          'receiptNumber': fakeReceipt,
          'cartItems': cartItems.map((c) => c.toJson()).toList(),
          'subtotal': subtotal,
          'tax': tax,
          'serviceCharge': serviceCharge,
          'total': totalAmount,
          'discount': billDiscount,
          'paymentMethod': paymentMethod.name,
          'amountPaid': totalAmount,
          'change': 0.0,
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
        developer.log('Training mode: stored fake receipt $fakeReceipt');
        return PaymentResult.success(
          transactionId: fakeReceipt,
          receiptNumber: fakeReceipt,
          amountPaid: totalAmount,
          change: 0.0,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
        );
      }

      final receiptNumber = await DatabaseService.instance.saveCompletedSaleWithSplits(
        cartItems: cartItems,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        discount: billDiscount,
        amountPaid: totalAmount,
        change: 0.0,
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
        developer.log('❌ Card payment: DB save returned null - products may not match DB items');
        return PaymentResult.failure(
          errorMessage: 'Failed to save transaction: products not found in database. Try adding items from database first.',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
          amountPaid: totalAmount,
        );
      }

      await _deductStockForItems(cartItems);

      developer.log('Card payment processed successfully: $receiptNumber');

      await _submitToMyInvoisIfEnabled(
        receiptNumber: receiptNumber,
        cartItems: cartItems,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        paymentMethod: paymentMethod.name,
      );

      return PaymentResult.success(
        transactionId: receiptNumber,
        receiptNumber: receiptNumber,
        amountPaid: totalAmount,
        change: 0.0,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
      );
    } catch (e) {
      developer.log('\u274c Card payment processing failed: $e');
      developer.log('Stack trace: ${StackTrace.current}');
      return PaymentResult.failure(
        errorMessage: 'Card payment error: ${e.toString().replaceAll('Exception: ', '')}',
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
        amountPaid: totalAmount,
      );
    }
  }

  /// Process a payment with automatic method detection
  Future<PaymentResult> processPayment({
    required double totalAmount,
    required double amountPaid,
    required PaymentMethod paymentMethod,
    required List<CartItem> cartItems,
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
    if (paymentMethod.name.toLowerCase().contains('cash')) {
      return processCashPayment(
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        cartItems: cartItems,
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
    } else {
      return processCardPayment(
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        cartItems: cartItems,
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
    }
  }

  /// Mock card validation - in real implementation, this would call payment processor
  Future<bool> _validateCardPayment(double amount) async {
    if (forceCardSuccess) return true;
    await Future.delayed(const Duration(milliseconds: 500));
    return DateTime.now().millisecond % 20 != 0;
  }
}
