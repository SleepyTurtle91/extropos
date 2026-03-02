import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/my_invois_service.dart';
import 'package:extropos/services/training_mode_service.dart';

part 'payment_service_split_payment.dart';
part 'payment_service_cash_card.dart';
part 'payment_service_refund.dart';
part 'payment_service_validation.dart';
part 'payment_service_myinvois.dart';
part 'payment_service_stock.dart';

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
}
