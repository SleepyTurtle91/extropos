import 'package:extropos/services/payment/payment_gateway.dart';

/// Boost payment gateway implementation
class BoostGateway extends PaymentGateway {
  static const String _apiUrl = 'https://api.boostpay.my/v1';
  static const String _sandbox = 'https://sandbox.boostpay.my/v1';

  final String merchantId;
  final String apiKey;
  final bool useSandbox;

  BoostGateway({
    required this.merchantId,
    required this.apiKey,
    this.useSandbox = true,
  });

  // ignore: unused_element
  String get _baseUrl => useSandbox ? _sandbox : _apiUrl;

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      print('💳 Processing Boost payment: RM ${request.amount.toStringAsFixed(2)}');

      // Validate amount (Boost minimum: RM 0.01)
      if (request.amount < 0.01) {
        return PaymentResult(
          success: false,
          errorMessage: 'Minimum amount is RM 0.01',
          errorCode: 'INVALID_AMOUNT',
          timestamp: DateTime.now(),
        );
      }

      // TODO: Implement actual API call to Boost
      // For now, return mock success
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult(
        success: true,
        transactionId: 'BOOST-${DateTime.now().millisecondsSinceEpoch}',
        reference: request.orderId,
        processedAmount: request.amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 Boost payment error: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<RefundResult> refundPayment(String transactionId, double amount) async {
    try {
      print('🔄 Refunding Boost: RM ${amount.toStringAsFixed(2)}');

      // TODO: Implement actual refund API call

      return RefundResult(
        success: true,
        refundId: 'REFUND-$transactionId',
        refundedAmount: amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 Boost refund error: $e');
      return RefundResult(
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<PaymentStatus> getPaymentStatus(String transactionId) async {
    try {
      // TODO: Implement actual status check

      return PaymentStatus(
        transactionId: transactionId,
        status: PaymentStatusEnum.success,
      );
    } catch (e) {
      print('🔥 Error getting Boost status: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // TODO: Check Boost availability
      return true;
    } catch (e) {
      return false;
    }
  }
}
