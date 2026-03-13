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

      if (request.amount < 0.01) {
        return PaymentResult(
          success: false,
          errorMessage: 'Minimum amount is RM 0.01',
          errorCode: 'INVALID_AMOUNT',
          timestamp: DateTime.now(),
        );
      }

      // Simulated API Flow:
      // 1. Authenticate with TNG Business API
      final token = await _authenticate();
      if (token == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'Touch \'n Go authentication failed',
          timestamp: DateTime.now(),
        );
      }

      // 2. Create Transaction Request
      await Future.delayed(const Duration(seconds: 1));
      
      final transactionId = 'TNG-${DateTime.now().millisecondsSinceEpoch}';

      return PaymentResult(
        success: true,
        transactionId: transactionId,
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

  Future<String?> _authenticate() async {
    // Simulated auth flow
    await Future.delayed(const Duration(milliseconds: 500));
    return 'tng_access_token_simulated';
  }

  @override
  Future<RefundResult> refundPayment(String transactionId, double amount) async {
    try {
      print('🔄 Refunding Touch \'n Go: RM ${amount.toStringAsFixed(2)}');

      final token = await _authenticate();
      if (token == null) throw Exception('Auth failed');

      await Future.delayed(const Duration(seconds: 1));

      return RefundResult(
        success: true,
        refundId: 'TNG-REFUND-${DateTime.now().millisecondsSinceEpoch}',
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
      final token = await _authenticate();
      if (token == null) throw Exception('Auth failed');

      await Future.delayed(const Duration(milliseconds: 800));

      return PaymentStatus(
        transactionId: transactionId,
        status: PaymentStatusEnum.success,
      );
    } catch (e) {
      print('🔥 Error getting Touch \'n Go status: $e');
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
