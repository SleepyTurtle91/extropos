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

      if (request.amount < 0.01) {
        return PaymentResult(
          success: false,
          errorMessage: 'Minimum amount is RM 0.01',
          errorCode: 'INVALID_AMOUNT',
          timestamp: DateTime.now(),
        );
      }

      // Simulated API Flow:
      // 1. Authenticate with Grab ID
      final token = await _authenticate();
      if (token == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'GrabPay authentication failed',
          timestamp: DateTime.now(),
        );
      }

      // 2. Create Create Charge Request
      await Future.delayed(const Duration(seconds: 1));
      
      // 3. Simulated network success
      final transactionId = 'GRAB-${DateTime.now().millisecondsSinceEpoch}';

      return PaymentResult(
        success: true,
        transactionId: transactionId,
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

  Future<String?> _authenticate() async {
    // Simulated OAuth flow
    await Future.delayed(const Duration(milliseconds: 500));
    return 'grab_access_token_simulated';
  }

  @override
  Future<RefundResult> refundPayment(String transactionId, double amount) async {
    try {
      print('🔄 Refunding GrabPay: RM ${amount.toStringAsFixed(2)}');

      final token = await _authenticate();
      if (token == null) throw Exception('Auth failed');

      await Future.delayed(const Duration(seconds: 1));

      return RefundResult(
        success: true,
        refundId: 'GRAB-REFUND-${DateTime.now().millisecondsSinceEpoch}',
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
      final token = await _authenticate();
      if (token == null) throw Exception('Auth failed');

      await Future.delayed(const Duration(milliseconds: 800));

      return PaymentStatus(
        transactionId: transactionId,
        status: PaymentStatusEnum.success,
      );
    } catch (e) {
      print('🔥 Error getting GrabPay status: $e');
      return PaymentStatus(
        transactionId: transactionId,
        status: PaymentStatusEnum.failed,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final token = await _authenticate();
      return token != null;
    } catch (e) {
      return false;
    }
  }
}
