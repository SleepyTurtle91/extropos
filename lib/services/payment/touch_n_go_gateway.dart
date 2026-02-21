import 'package:extropos/services/payment/payment_gateway.dart';

/// Touch 'n Go payment gateway implementation
/// Supports QRPM (QR Proxy Method) for Malaysian e-wallet
class TouchNGoGateway extends PaymentGateway {
  static const String _apiUrl = 'https://api.touchngo.com.my/v1';
  static const String _sandbox = 'https://sandbox.touchngo.com.my/v1';

  final String merchantId;
  final String apiKey;
  final bool useSandbox;

  TouchNGoGateway({
    required this.merchantId,
    required this.apiKey,
    this.useSandbox = true,
  });

  // ignore: unused_element
  String get _baseUrl => useSandbox ? _sandbox : _apiUrl;

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      print('💳 Processing Touch \'n Go payment: RM ${request.amount.toStringAsFixed(2)}');

      // Validate amount (Touch 'n Go minimum: RM 0.01)
      if (request.amount < 0.01) {
        return PaymentResult(
          success: false,
          errorMessage: 'Minimum amount is RM 0.01',
          errorCode: 'INVALID_AMOUNT',
          timestamp: DateTime.now(),
        );
      }

      // TODO: Implement actual API call to Touch 'n Go
      // For now, return mock success
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult(
        success: true,
        transactionId: 'TNG-${DateTime.now().millisecondsSinceEpoch}',
        reference: request.orderId,
        processedAmount: request.amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 Touch \'n Go payment error: $e');
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
      print('🔄 Refunding Touch \'n Go: RM ${amount.toStringAsFixed(2)}');

      // TODO: Implement actual refund API call

      return RefundResult(
        success: true,
        refundId: 'REFUND-$transactionId',
        refundedAmount: amount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🔥 Touch \'n Go refund error: $e');
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
      print('🔥 Error getting Touch \'n Go status: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // TODO: Check device connectivity and Touch 'n Go availability
      return true;
    } catch (e) {
      return false;
    }
  }
}
