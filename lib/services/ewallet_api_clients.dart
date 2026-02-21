import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// Response from dynamic QR generation
class DynamicQRResponse {
  final String qrData;
  final String transactionId;
  final DateTime expiresAt;
  final String? paymentUrl;
  final Map<String, dynamic>? metadata;

  DynamicQRResponse({
    required this.qrData,
    required this.transactionId,
    required this.expiresAt,
    this.paymentUrl,
    this.metadata,
  });
}

/// Base class for e-wallet API clients
abstract class EWalletAPIClient {
  final String baseUrl;
  final String apiKey;
  final bool useSandbox;

  EWalletAPIClient({
    required this.baseUrl,
    required this.apiKey,
    required this.useSandbox,
  });

  /// Generate dynamic QR code
  Future<DynamicQRResponse> createDynamicQR({
    required String merchantId,
    required double amount,
    required String currency,
    required String referenceId,
    String? callbackUrl,
    int expiryMinutes = 5,
  });

  /// Query payment status
  Future<Map<String, dynamic>> getPaymentStatus({
    required String transactionId,
  });

  /// Cancel/void a pending payment
  Future<bool> cancelPayment({
    required String transactionId,
  });

  /// Common HTTP headers
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'X-Sandbox-Mode': useSandbox ? 'true' : 'false',
    };
  }

  /// Handle HTTP errors
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      developer.log('API Error ${response.statusCode}: ${response.body}');
      throw Exception('API request failed: ${response.statusCode}');
    }
  }
}

/// DuitNow QR API Client (Malaysian standard)
class DuitNowAPIClient extends EWalletAPIClient {
  DuitNowAPIClient({
    required super.baseUrl,
    required super.apiKey,
    required super.useSandbox,
  });

  @override
  Future<DynamicQRResponse> createDynamicQR({
    required String merchantId,
    required double amount,
    required String currency,
    required String referenceId,
    String? callbackUrl,
    int expiryMinutes = 5,
  }) async {
    // Real DuitNow API endpoint (sandbox/production)
    final endpoint = useSandbox
        ? 'https://sandbox-api.duitnow.my/v1/qr/create'
        : 'https://api.duitnow.my/v1/qr/create';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: _buildHeaders(),
        body: jsonEncode({
          'merchant_id': merchantId,
          'amount': amount.toStringAsFixed(2),
          'currency': currency,
          'reference': referenceId,
          'callback_url': callbackUrl,
          'expiry_minutes': expiryMinutes,
        }),
      );

      _handleError(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      return DynamicQRResponse(
        qrData: data['qr_data'] as String,
        transactionId: data['transaction_id'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
        paymentUrl: data['payment_url'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      developer.log('DuitNow API error: $e');
      // Fallback to static QR if API fails
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus({
    required String transactionId,
  }) async {
    final endpoint = useSandbox
        ? 'https://sandbox-api.duitnow.my/v1/payments/$transactionId'
        : 'https://api.duitnow.my/v1/payments/$transactionId';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );

    _handleError(response);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<bool> cancelPayment({required String transactionId}) async {
    final endpoint = useSandbox
        ? 'https://sandbox-api.duitnow.my/v1/payments/$transactionId/cancel'
        : 'https://api.duitnow.my/v1/payments/$transactionId/cancel';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );

    return response.statusCode == 200;
  }
}

/// GrabPay API Client
class GrabPayAPIClient extends EWalletAPIClient {
  final String clientId;
  final String clientSecret;

  GrabPayAPIClient({
    required super.baseUrl,
    required super.apiKey,
    required this.clientId,
    required this.clientSecret,
    required super.useSandbox,
  });

  @override
  Future<DynamicQRResponse> createDynamicQR({
    required String merchantId,
    required double amount,
    required String currency,
    required String referenceId,
    String? callbackUrl,
    int expiryMinutes = 5,
  }) async {
    final endpoint = useSandbox
        ? 'https://partner-api.stg-myteksi.com/grabpay/partner/v2/charge/init'
        : 'https://partner-api.grab.com/grabpay/partner/v2/charge/init';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-GID-AUX-POP': _generatePOP(),
      },
      body: jsonEncode({
        'partnerTxID': referenceId,
        'partnerGroupTxID': referenceId,
        'amount': (amount * 100).toInt(), // Amount in cents
        'currency': currency,
        'merchantID': merchantId,
        'description': 'POS Transaction',
        'metaInfo': {
          'callbackUrl': callbackUrl,
          'expiryMinutes': expiryMinutes,
        },
      }),
    );

    _handleError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    return DynamicQRResponse(
      qrData: data['qrCode'] as String? ?? '',
      transactionId: data['partnerTxID'] as String,
      expiresAt: DateTime.now().add(Duration(minutes: expiryMinutes)),
      paymentUrl: data['request']['url'] as String?,
      metadata: data,
    );
  }

  String _generatePOP() {
    // Proof of Possession signature (simplified)
    return base64Encode(utf8.encode('$clientId:$clientSecret'));
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus({
    required String transactionId,
  }) async {
    final endpoint = useSandbox
        ? 'https://partner-api.stg-myteksi.com/grabpay/partner/v2/charge/$transactionId/status'
        : 'https://partner-api.grab.com/grabpay/partner/v2/charge/$transactionId/status';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );

    _handleError(response);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<bool> cancelPayment({required String transactionId}) async {
    final endpoint = useSandbox
        ? 'https://partner-api.stg-myteksi.com/grabpay/partner/v2/cancel'
        : 'https://partner-api.grab.com/grabpay/partner/v2/cancel';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
      body: jsonEncode({'partnerTxID': transactionId}),
    );

    return response.statusCode == 200;
  }
}

/// Touch 'n Go eWallet API Client
class TouchNGoAPIClient extends EWalletAPIClient {
  TouchNGoAPIClient({
    required super.baseUrl,
    required super.apiKey,
    required super.useSandbox,
  });

  @override
  Future<DynamicQRResponse> createDynamicQR({
    required String merchantId,
    required double amount,
    required String currency,
    required String referenceId,
    String? callbackUrl,
    int expiryMinutes = 5,
  }) async {
    final endpoint = useSandbox
        ? 'https://sandbox-api.tngdigital.com.my/v1/qr/create'
        : 'https://api.tngdigital.com.my/v1/qr/create';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
      body: jsonEncode({
        'merchant_id': merchantId,
        'amount': amount,
        'currency': currency,
        'order_id': referenceId,
        'callback_url': callbackUrl,
        'expiry_seconds': expiryMinutes * 60,
      }),
    );

    _handleError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    return DynamicQRResponse(
      qrData: data['qr_content'] as String,
      transactionId: data['txn_id'] as String,
      expiresAt: DateTime.now().add(Duration(minutes: expiryMinutes)),
      paymentUrl: data['payment_url'] as String?,
      metadata: data,
    );
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus({
    required String transactionId,
  }) async {
    final endpoint = useSandbox
        ? 'https://sandbox-api.tngdigital.com.my/v1/payments/$transactionId'
        : 'https://api.tngdigital.com.my/v1/payments/$transactionId';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );

    _handleError(response);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<bool> cancelPayment({required String transactionId}) async {
    final endpoint = useSandbox
        ? 'https://sandbox-api.tngdigital.com.my/v1/payments/$transactionId/void'
        : 'https://api.tngdigital.com.my/v1/payments/$transactionId/void';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );

    return response.statusCode == 200;
  }
}
