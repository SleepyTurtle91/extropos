import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';

import 'package:extropos/services/database_helper.dart';

/// Webhook payload from payment gateway
class WebhookPayload {
  final String provider;
  final String transactionId;
  final String status; // 'success', 'failed', 'pending'
  final double? amount;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic> rawData;

  WebhookPayload({
    required this.provider,
    required this.transactionId,
    required this.status,
    this.amount,
    this.errorMessage,
    required this.timestamp,
    required this.rawData,
  });

  factory WebhookPayload.fromJson(String provider, Map<String, dynamic> json) {
    switch (provider) {
      case 'duitnow':
        return WebhookPayload._fromDuitNow(json);
      case 'grabpay':
        return WebhookPayload._fromGrabPay(json);
      case 'tng':
        return WebhookPayload._fromTouchNGo(json);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  factory WebhookPayload._fromDuitNow(Map<String, dynamic> json) {
    return WebhookPayload(
      provider: 'duitnow',
      transactionId: json['transaction_id'] as String,
      status: _mapDuitNowStatus(json['status'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      errorMessage: json['error_message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      rawData: json,
    );
  }

  factory WebhookPayload._fromGrabPay(Map<String, dynamic> json) {
    return WebhookPayload(
      provider: 'grabpay',
      transactionId: json['partnerTxID'] as String,
      status: _mapGrabPayStatus(json['txStatus'] as String),
      amount: ((json['amount'] as num?) ?? 0) / 100.0, // Cents to dollars
      errorMessage: json['errMsg'] as String?,
      timestamp: DateTime.parse(json['txTime'] as String),
      rawData: json,
    );
  }

  factory WebhookPayload._fromTouchNGo(Map<String, dynamic> json) {
    return WebhookPayload(
      provider: 'tng',
      transactionId: json['txn_id'] as String,
      status: _mapTouchNGoStatus(json['payment_status'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      errorMessage: json['error_desc'] as String?,
      timestamp: DateTime.parse(json['updated_at'] as String),
      rawData: json,
    );
  }

  static String _mapDuitNowStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'success';
      case 'failed':
      case 'error':
        return 'failed';
      default:
        return 'pending';
    }
  }

  static String _mapGrabPayStatus(String status) {
    switch (status) {
      case 'success':
        return 'success';
      case 'failed':
        return 'failed';
      default:
        return 'pending';
    }
  }

  static String _mapTouchNGoStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return 'success';
      case 'failed':
      case 'cancelled':
        return 'failed';
      default:
        return 'pending';
    }
  }
}

/// Service to handle incoming webhooks from payment gateways
class EWalletWebhookService {
  /// Verify webhook signature to ensure authenticity
  static bool verifySignature({
    required String provider,
    required String signature,
    required String payload,
    required String secret,
  }) {
    try {
      final expectedSignature = _generateSignature(
        provider: provider,
        payload: payload,
        secret: secret,
      );
      return signature == expectedSignature;
    } catch (e) {
      developer.log('Signature verification error: $e');
      return false;
    }
  }

  static String _generateSignature({
    required String provider,
    required String payload,
    required String secret,
  }) {
    switch (provider) {
      case 'duitnow':
        // HMAC-SHA256 signature
        final key = utf8.encode(secret);
        final bytes = utf8.encode(payload);
        final hmac = Hmac(sha256, key);
        return hmac.convert(bytes).toString();

      case 'grabpay':
        // GrabPay uses HMAC-SHA256 with special formatting
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final message = '$timestamp.$payload';
        final key = utf8.encode(secret);
        final bytes = utf8.encode(message);
        final hmac = Hmac(sha256, key);
        return hmac.convert(bytes).toString();

      case 'tng':
        // Touch 'n Go uses MD5 hash
        final combined = '$payload$secret';
        return md5.convert(utf8.encode(combined)).toString();

      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  /// Process incoming webhook
  static Future<bool> handleWebhook({
    required String provider,
    required Map<String, dynamic> payload,
    required String signature,
    required String webhookSecret,
  }) async {
    try {
      // Verify signature first
      final payloadString = jsonEncode(payload);
      if (!verifySignature(
        provider: provider,
        signature: signature,
        payload: payloadString,
        secret: webhookSecret,
      )) {
        developer.log('❌ Webhook signature verification failed');
        return false;
      }

      // Parse webhook payload
      final webhookData = WebhookPayload.fromJson(provider, payload);
      
      developer.log('✅ Webhook received: ${webhookData.transactionId} → ${webhookData.status}');

      // Update transaction status in database
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'e_wallet_transactions',
        {
          'status': webhookData.status,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'error_message': webhookData.errorMessage,
        },
        where: 'reference_id = ?',
        whereArgs: [webhookData.transactionId],
      );

      developer.log('📝 Transaction status updated: ${webhookData.transactionId} → ${webhookData.status}');
      
      return true;
    } catch (e) {
      developer.log('❌ Webhook processing error: $e');
      return false;
    }
  }

  /// Simulate webhook callback for testing (sandbox mode)
  static Future<void> simulateWebhookCallback({
    required String provider,
    required String transactionId,
    required String status,
    required String webhookSecret,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final payload = {
      'transaction_id': transactionId,
      'status': status,
      'amount': 10.0,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final payloadString = jsonEncode(payload);
    final signature = _generateSignature(
      provider: provider,
      payload: payloadString,
      secret: webhookSecret,
    );

    await handleWebhook(
      provider: provider,
      payload: payload,
      signature: signature,
      webhookSecret: webhookSecret,
    );
  }
}
