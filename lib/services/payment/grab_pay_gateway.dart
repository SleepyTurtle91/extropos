import 'package:extropos/services/payment/payment_gateway.dart';

/// GrabPay payment gateway implementation
class GrabPayGateway extends PaymentGateway {
  static const String _apiUrl = 'https://partner-api.grab.com/grabpay/v1';
  static const String _sandbox = 'https://partner-api-sandbox.grab.com/grabpay/v1';

  final String clientId;
  final String clientSecret;
  final bool useSandbox;

  GrabPayGateway({
    required this.clientId,
    required this.clientSecret,
    this.useSandbox = true,
  });

  // ignore: unused_element
  String get _baseUrl => useSandbox ? _sandbox : _apiUrl;

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      print('💳 Processing GrabPay payment: RM ${request.amount.toStringAsFixed(2)}');

      // Validate amount (GrabPay minimum: RM 0.01)
      if (request.amount < 0.01) {
        return PaymentResult(
          success: false,
          errorMessage: 'Minimum amount is RM 0.01',
          errorCode: 'INVALID_AMOUNT',
          timestamp: DateTime.now(),
        );
      }

      // TODO: Implement actual API call to GrabPay
      // For now, return mock success
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult(
        success: true,
        transactionId: 'GRAB-${DateTime.now().millisecondsSinceEpoch}',
        reference: request.orderId,
        processedAmount: request.amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 GrabPay payment error: $e');
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
      print('🔄 Refunding GrabPay: RM ${amount.toStringAsFixed(2)}');

      // TODO: Implement actual refund API call

      return RefundResult(
        success: true,
        refundId: 'REFUND-$transactionId',
        refundedAmount: amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 GrabPay refund error: $e');
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
      print('🔥 Error getting GrabPay status: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // TODO: Check GrabPay availability
      return true;
    } catch (e) {
      return false;
    }
  }
}
