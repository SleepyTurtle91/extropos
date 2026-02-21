// Abstract base class for payment gateway integrations
// Allows switching between providers (Touch 'n Go, GrabPay, Boost, etc.)

abstract class PaymentGateway {
  /// Process a payment transaction
  Future<PaymentResult> processPayment(PaymentRequest request);

  /// Refund a previously processed payment
  Future<RefundResult> refundPayment(String transactionId, double amount);

  /// Get payment status
  Future<PaymentStatus> getPaymentStatus(String transactionId);

  /// Check if gateway is available/connected
  Future<bool> isAvailable();
}

/// Payment processing request
class PaymentRequest {
  final double amount;
  final String orderId;
  final String? customerId;
  final String? customerPhone;
  final String? customerEmail;
  final String? description;
  final Map<String, dynamic>? metadata;
  final int timeoutSeconds;

  PaymentRequest({
    required this.amount,
    required this.orderId,
    this.customerId,
    this.customerPhone,
    this.customerEmail,
    this.description,
    this.metadata,
    this.timeoutSeconds = 30,
  });
}

/// Payment result from gateway
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? reference;
  final String? authCode;
  final double? processedAmount;
  final String? errorMessage;
  final String? errorCode;
  final DateTime timestamp;
  final Map<String, dynamic>? rawResponse;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.reference,
    this.authCode,
    this.processedAmount,
    this.errorMessage,
    this.errorCode,
    required this.timestamp,
    this.rawResponse,
  });

  @override
  String toString() {
    if (success) {
      return '✅ Payment Success: $reference';
    } else {
      return '❌ Payment Failed: $errorMessage ($errorCode)';
    }
  }
}

/// Refund result from gateway
class RefundResult {
  final bool success;
  final String? refundId;
  final String? reference;
  final double? refundedAmount;
  final String? errorMessage;
  final DateTime timestamp;

  RefundResult({
    required this.success,
    this.refundId,
    this.reference,
    this.refundedAmount,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() {
    if (success) {
      return '✅ Refund Success: RM ${refundedAmount?.toStringAsFixed(2) ?? 'N/A'}';
    } else {
      return '❌ Refund Failed: $errorMessage';
    }
  }
}

/// Payment status from gateway
enum PaymentStatusEnum { pending, processing, success, failed, refunded, cancelled }

class PaymentStatus {
  final String transactionId;
  final PaymentStatusEnum status;
  final double? amount;
  final DateTime? processedAt;
  final String? notes;

  PaymentStatus({
    required this.transactionId,
    required this.status,
    this.amount,
    this.processedAt,
    this.notes,
  });
}

/// Payment method enum
enum PaymentMethod {
  cash,
  card,
  touchNGo,
  grabPay,
  boost,
  alipay,
  wechatPay,
  bankTransfer,
  cheque,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    const names = {
      PaymentMethod.cash: 'Cash',
      PaymentMethod.card: 'Debit/Credit Card',
      PaymentMethod.touchNGo: 'Touch \'n Go',
      PaymentMethod.grabPay: 'GrabPay',
      PaymentMethod.boost: 'Boost',
      PaymentMethod.alipay: 'Alipay',
      PaymentMethod.wechatPay: 'WeChat Pay',
      PaymentMethod.bankTransfer: 'Bank Transfer',
      PaymentMethod.cheque: 'Cheque',
    };
    return names[this] ?? 'Unknown';
  }

  String get code {
    const codes = {
      PaymentMethod.cash: 'CASH',
      PaymentMethod.card: 'CARD',
      PaymentMethod.touchNGo: 'TOUCHNGO',
      PaymentMethod.grabPay: 'GRABPAY',
      PaymentMethod.boost: 'BOOST',
      PaymentMethod.alipay: 'ALIPAY',
      PaymentMethod.wechatPay: 'WECHATPAY',
      PaymentMethod.bankTransfer: 'BANK_TRANSFER',
      PaymentMethod.cheque: 'CHEQUE',
    };
    return codes[this] ?? 'UNKNOWN';
  }

  bool get isEWallet {
    return [
      PaymentMethod.touchNGo,
      PaymentMethod.grabPay,
      PaymentMethod.boost,
      PaymentMethod.alipay,
      PaymentMethod.wechatPay,
    ].contains(this);
  }

  bool get isCard => this == PaymentMethod.card;
  bool get isCash => this == PaymentMethod.cash;
}
