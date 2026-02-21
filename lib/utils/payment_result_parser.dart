import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/payment_split_model.dart';

class ParsedPaymentResult {
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final String? transactionId;
  final String? receiptNumber;
  final List<PaymentSplit> paymentSplits;

  const ParsedPaymentResult({
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.transactionId,
    this.receiptNumber,
    this.paymentSplits = const [],
  });
}

class PaymentResultParser {
  static ParsedPaymentResult? parse(
    dynamic rawResult, {
    required double fallbackAmount,
    PaymentMethod? fallbackPaymentMethod,
  }) {
    if (rawResult is! Map) {
      return null;
    }

    if (rawResult['success'] != true) {
      return null;
    }

    final paymentMethodRaw = rawResult['paymentMethod'];
    final paymentMethod = paymentMethodRaw is PaymentMethod
        ? paymentMethodRaw
        : (fallbackPaymentMethod ?? PaymentMethod(id: 'cash', name: 'Cash'));

    final amountPaidRaw = rawResult['amountPaid'];
    final amountPaid = amountPaidRaw is num
        ? amountPaidRaw.toDouble()
        : double.tryParse('$amountPaidRaw') ?? fallbackAmount;

    final changeRaw = rawResult['change'];
    final change = changeRaw is num
        ? changeRaw.toDouble()
        : double.tryParse('$changeRaw') ?? 0.0;

    final transactionIdRaw = rawResult['transactionId'];
    final transactionId = transactionIdRaw is String ? transactionIdRaw : null;

    final receiptNumberRaw = rawResult['receiptNumber'];
    final receiptNumber = receiptNumberRaw is String ? receiptNumberRaw : null;

    final paymentSplitsRaw = rawResult['paymentSplits'];
    final paymentSplits = <PaymentSplit>[];
    if (paymentSplitsRaw is List) {
      for (final split in paymentSplitsRaw) {
        if (split is PaymentSplit) {
          paymentSplits.add(split);
        } else if (split is Map<String, dynamic>) {
          try {
            paymentSplits.add(PaymentSplit.fromJson(split));
          } catch (_) {}
        }
      }
    }

    return ParsedPaymentResult(
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: change,
      transactionId: transactionId,
      receiptNumber: receiptNumber,
      paymentSplits: paymentSplits,
    );
  }
}
