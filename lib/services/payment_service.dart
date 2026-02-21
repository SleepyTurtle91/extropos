import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/payment_split_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/my_invois_service.dart';
import 'package:extropos/services/training_mode_service.dart';

/// Enhanced PaymentResult with split payment support
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? receiptNumber;
  final double amountPaid;
  final double change;
  final String? errorMessage;
  final List<PaymentSplit> paymentSplits;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.receiptNumber,
    required this.amountPaid,
    required this.change,
    this.errorMessage,
    required this.paymentSplits,
  });

  factory PaymentResult.success({
    required String transactionId,
    required String receiptNumber,
    required double amountPaid,
    required double change,
    required List<PaymentSplit> paymentSplits,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      receiptNumber: receiptNumber,
      amountPaid: amountPaid,
      change: change,
      paymentSplits: paymentSplits,
    );
  }

  factory PaymentResult.failure({
    required String errorMessage,
    required List<PaymentSplit> paymentSplits,
    required double amountPaid,
  }) {
    return PaymentResult(
      success: false,
      errorMessage: errorMessage,
      amountPaid: amountPaid,
      change: 0.0,
      paymentSplits: paymentSplits,
    );
  }

  bool get requiresChange => change > 0;
}

/// Service for handling payment processing operations
class PaymentService {
  static final PaymentService instance = PaymentService._init();
  PaymentService._init();
  // Test hook: force card validation to succeed (deterministic tests)
  bool forceCardSuccess = false;

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
      // Calculate totals
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

      // Validate payment splits
      final validationError = validatePaymentSplits(paymentSplits, totalAmount);
      if (validationError != null) {
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: paymentSplits,
          amountPaid: totalPaid,
        );
      }

      // Calculate change with Malaysian rounding
      final rawChange = totalPaid - totalAmount;
      final change = _calculateMalaysianRounding(rawChange);

      // Process each payment split
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

      // If training mode is enabled, add transaction to in-memory training list
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

      // Save the completed sale to database with split payments
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

      // Deduct stock for sold items (skip if training mode)
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

    // Check for negative amounts
    for (final split in paymentSplits) {
      if (split.amount <= 0) {
        return 'Payment amount for ${split.paymentMethod.name} must be greater than 0';
      }
    }

    return null; // Valid
  }

  /// Calculate Malaysian rounding (round to nearest 0.05)
  double _calculateMalaysianRounding(double amount) {
    if (amount <= 0) return 0.0;

    // Round to nearest 0.05
    final rounded = (amount / 0.05).round() * 0.05;
    return rounded;
  }

  /// Process individual payment split
  Future<bool> _processPaymentSplit(PaymentSplit split) async {
    try {
      // Simulate payment processing based on method
      switch (split.paymentMethod.id) {
        case 'cash':
          // Cash is always successful
          return true;
        case 'card':
          // Simulate card processing
          await Future.delayed(const Duration(milliseconds: 500));
          return forceCardSuccess || (DateTime.now().millisecondsSinceEpoch % 10 != 0); // 90% success rate
        case 'ewallet':
          // Simulate e-wallet processing
          await Future.delayed(const Duration(milliseconds: 300));
          return forceCardSuccess || (DateTime.now().millisecondsSinceEpoch % 5 != 0); // 80% success rate
        default:
          // Unknown payment method
          return false;
      }
    } catch (e) {
      developer.log('Error processing payment split: $e');
      return false;
    }
  }

  /// Pre-validate that all cart items exist in database before processing payment
  Future<String?> _validateCartItemsExistInDB(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return null;

    try {
      final db = await DatabaseHelper.instance.database;
      final rawItems = await db.query('items', columns: ['name']);
      final itemNames = {for (final row in rawItems) (row['name'] as String)};

      final unmappedItems = cartItems
          .where((ci) => !itemNames.contains(ci.product.name))
          .map((ci) => ci.product.name)
          .toList();

      if (unmappedItems.isNotEmpty) {
        developer.log('❌ Cart items not found in database: ${unmappedItems.join(', ')}');
        return 'The following items are not in the database: ${unmappedItems.join(", ")}. '
            'Please use products from the database or ensure all items are properly synced.';
      }

      return null; // All items valid
    } catch (e) {
      developer.log('⚠️ Warning: Could not validate cart items in DB: $e');
      return null; // Allow payment to proceed (fallback)
    }
  }

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
      // Pre-validate cart items exist in database
      final validationError = await _validateCartItemsExistInDB(cartItems);
      if (validationError != null) {
        developer.log('❌ Cart validation failed: $validationError');
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: [PaymentSplit(paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'), amount: amountPaid)],
          amountPaid: amountPaid,
        );
      }

      // Validate payment amount
      if (amountPaid < totalAmount) {
        return PaymentResult.failure(
          errorMessage:
              'Insufficient payment amount. Required: \$${totalAmount.toStringAsFixed(2)}, Paid: \$${amountPaid.toStringAsFixed(2)}',
          paymentSplits: [PaymentSplit(paymentMethod: PaymentMethod(id: 'cash', name: 'Cash'), amount: amountPaid)],
          amountPaid: amountPaid,
        );
      }

      final change = amountPaid - totalAmount;

      // Calculate totals
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

      // Create payment method
      final paymentMethod = PaymentMethod(id: 'cash', name: 'Cash');

      // Save the completed sale to database
      if (TrainingModeService.instance.isTrainingMode) {
        // In training mode, store the transaction in-memory and skip DB writes and stock deductions
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

      // Deduct stock for sold items (skip if training mode)
      if (!TrainingModeService.instance.isTrainingMode) {
        await _deductStockForItems(cartItems);
      }

      developer.log('Cash payment processed successfully: $receiptNumber');

      // Submit to MyInvois if enabled and conditions met
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
      // Pre-validate cart items exist in database
      final validationError = await _validateCartItemsExistInDB(cartItems);
      if (validationError != null) {
        developer.log('❌ Cart validation failed: $validationError');
        return PaymentResult.failure(
          errorMessage: validationError,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
          amountPaid: totalAmount,
        );
      }

      // Simulate card processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock card validation - in real implementation, this would integrate with payment processor
      final isValidCard = await _validateCardPayment(totalAmount);

      if (!isValidCard) {
        return PaymentResult.failure(
          errorMessage:
              'Card payment declined. Please try a different card or payment method.',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
          amountPaid: totalAmount,
        );
      }

      // Calculate totals
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

      // If training mode is enabled, add transaction to in-memory training list and avoid DB writes.
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
        // No stock deduction in training mode.
        return PaymentResult.success(
          transactionId: fakeReceipt,
          receiptNumber: fakeReceipt,
          amountPaid: totalAmount,
          change: 0.0,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
        );
      }

      // Save the completed sale to database
      final receiptNumber = await DatabaseService.instance.saveCompletedSaleWithSplits(
        cartItems: cartItems,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: totalAmount)],
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: totalAmount,
        discount: billDiscount,
        amountPaid: totalAmount, // Card payments are exact amount
        change: 0.0, // No change for card payments
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

      // Deduct stock for sold items
      await _deductStockForItems(cartItems);

      developer.log('Card payment processed successfully: $receiptNumber');

      // Submit to MyInvois if enabled and conditions met
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
    // Determine payment type and route accordingly
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
      // Assume card payment for non-cash methods
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

  /// Calculate change for a given payment
  double calculateChange(double amountPaid, double totalAmount) {
    if (amountPaid < totalAmount) return 0.0;
    return amountPaid - totalAmount;
  }

  /// Validate if payment amount is sufficient
  bool isPaymentValid(double amountPaid, double totalAmount) {
    return amountPaid >= totalAmount;
  }

  /// Get suggested payment amounts (common denominations)
  List<double> getSuggestedAmounts(double totalAmount) {
    final suggestions = <double>[];

    // Round up to nearest common denominations
    final roundedUp = (totalAmount / 5).ceil() * 5.0;
    suggestions.add(roundedUp);

    final nextTen = (totalAmount / 10).ceil() * 10.0;
    if (nextTen != roundedUp) suggestions.add(nextTen);

    final nextTwenty = (totalAmount / 20).ceil() * 20.0;
    if (nextTwenty != nextTen && nextTwenty != roundedUp) {
      suggestions.add(nextTwenty);
    }

    // Sort and return
    suggestions.sort();
    return suggestions.where((amount) => amount >= totalAmount).toList();
  }

  /// Mock card validation - in real implementation, this would call payment processor
  Future<bool> _validateCardPayment(double amount) async {
    if (forceCardSuccess) return true;
    // Simulate random approval/decline for demo purposes
    // In real implementation, this would integrate with payment processor API
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: 95% approval rate
    return DateTime.now().millisecond % 20 != 0;
  }

  /// Process a refund for a completed order
  Future<PaymentResult> processRefund({
    required String orderId,
    required double refundAmount,
    required PaymentMethod paymentMethod,
    String? reason,
    String? userId,
  }) async {
    try {
      // Validate refund amount
      if (refundAmount <= 0) {
        return PaymentResult.failure(
          errorMessage: 'Refund amount must be greater than zero',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
          amountPaid: refundAmount,
        );
      }

      // Check if in training mode
      if (TrainingModeService.instance.isTrainingMode) {
        developer.log('TRAINING MODE: Refund processed (no database update)');

        return PaymentResult.success(
          transactionId:
              'TRAIN-REFUND-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber:
              'TRAIN-REFUND-${DateTime.now().millisecondsSinceEpoch}',
          amountPaid: refundAmount,
          change: 0.0,
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
        );
      }

      // Process refund in database
      final success = await DatabaseService.instance.refundOrder(
        orderId: orderId,
        refundAmount: refundAmount,
        paymentMethodId: paymentMethod.id,
        reason: reason,
        userId: userId,
      );

      if (!success) {
        return PaymentResult.failure(
          errorMessage: 'Failed to process refund in database',
          paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
          amountPaid: refundAmount,
        );
      }

      // For card payments, would integrate with payment processor here
      // For now, we handle all refunds the same way
      final receiptNumber = 'REFUND-${DateTime.now().millisecondsSinceEpoch}';

      developer.log('Refund processed successfully: $receiptNumber');

      return PaymentResult.success(
        transactionId: orderId,
        receiptNumber: receiptNumber,
        amountPaid: refundAmount,
        change: 0.0,
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
      );
    } catch (e) {
      developer.log('Error processing refund: $e');
      return PaymentResult.failure(
        errorMessage: 'Refund processing failed: ${e.toString()}',
        paymentSplits: [PaymentSplit(paymentMethod: paymentMethod, amount: refundAmount)],
        amountPaid: refundAmount,
      );
    }
  }

  /// Submit transaction to MyInvois if enabled and production guard passes
  Future<void> _submitToMyInvoisIfEnabled({
    required String receiptNumber,
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required String paymentMethod,
  }) async {
    try {
      final info = BusinessInfo.instance;

      // Skip if MyInvois is not enabled
      if (!info.isMyInvoisEnabled) {
        developer.log('MyInvois: Disabled, skipping submission');
        return;
      }

      // Skip if in training mode
      if (TrainingModeService.instance.isTrainingMode) {
        developer.log('MyInvois: Training mode, skipping submission');
        return;
      }

      // Production guard: check if recent successful test exists
      if (!info.useMyInvoisSandbox) {
        final testSuccess = info.myInvoisLastTestSuccess == true;
        final testTime = info.myInvoisLastTestedAt;
        final guardHours = info.myInvoisProductionGuardHours;

        if (!testSuccess || testTime == null) {
          developer.log(
            '⚠️ MyInvois: Production blocked - no successful test recorded',
          );
          return;
        }

        final testDate = DateTime.fromMillisecondsSinceEpoch(testTime);
        final hoursSinceTest = DateTime.now().difference(testDate).inHours;

        if (hoursSinceTest >= guardHours) {
          developer.log(
            '⚠️ MyInvois: Production blocked - test is $hoursSinceTest hours old (guard: $guardHours hours)',
          );
          return;
        }
      }

      // Build transaction data
      final transactionData = {
        'receiptNumber': receiptNumber,
        'items': cartItems
            .map((item) => {
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'unitPrice': item.product.price,
                  'total': item.totalPrice,
                })
            .toList(),
        'subtotal': subtotal,
        'taxAmount': tax,
        'serviceChargeAmount': serviceCharge,
        'totalAmount': total,
        'paymentMethod': paymentMethod,
      };

      // Submit invoice
      final service = MyInvoiceService(
        useSandboxOverride: info.useMyInvoisSandbox,
      );
      final documentUUID = await service.submitInvoice(transactionData);

      if (documentUUID != null) {
        developer.log(
          '✅ MyInvois: Invoice submitted successfully [${info.useMyInvoisSandbox ? 'sandbox' : 'production'}] - UUID: $documentUUID',
        );
      } else {
        developer.log(
          '⚠️ MyInvois: Invoice submission failed, queued for manual retry',
        );
      }
    } catch (e) {
      developer.log('❌ MyInvois: Submission error - $e');
      // Don't throw - payment already succeeded, just log the error
    }
  }

  /// Deduct stock for sold items
  Future<void> _deductStockForItems(List<CartItem> cartItems) async {
    try {
      for (final cartItem in cartItems) {
        // Find the corresponding Item in database by name
        final items = await DatabaseService.instance.getItems();
        Item? matchingItem;
        try {
          matchingItem = items.firstWhere(
            (item) => item.name == cartItem.product.name,
          );
        } catch (e) {
          matchingItem = null;
        }

        if (matchingItem != null &&
            matchingItem.trackStock &&
            matchingItem.stock > 0) {
          final newStock = matchingItem.stock - cartItem.quantity;
          if (newStock >= 0) {
            // Update the item stock in database
            final updatedItem = matchingItem.copyWith(stock: newStock);
            await DatabaseService.instance.updateItem(updatedItem);
            developer.log(
              'Deducted ${cartItem.quantity} from ${matchingItem.name} stock. New stock: $newStock',
            );
          } else {
            developer.log(
              'Warning: Insufficient stock for ${matchingItem.name}. Current: ${matchingItem.stock}, Required: ${cartItem.quantity}',
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error deducting stock: $e');
      // Don't fail the payment if stock deduction fails
    }
  }
}
