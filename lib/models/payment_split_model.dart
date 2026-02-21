import 'package:extropos/models/payment_method_model.dart';

/// Represents a single payment split in a transaction
class PaymentSplit {
  final PaymentMethod paymentMethod;
  final double amount;
  final String? reference; // Card number, transaction ID, etc.

  PaymentSplit({
    required this.paymentMethod,
    required this.amount,
    this.reference,
  });

  PaymentSplit copyWith({
    PaymentMethod? paymentMethod,
    double? amount,
    String? reference,
  }) {
    return PaymentSplit(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod.toJson(),
      'amount': amount,
      'reference': reference,
    };
  }

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod']),
      amount: json['amount'] as double,
      reference: json['reference'] as String?,
    );
  }
}