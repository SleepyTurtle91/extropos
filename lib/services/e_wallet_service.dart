import 'dart:developer' as developer;

import 'package:extropos/services/database_helper.dart';

class EWalletService {
  static final EWalletService instance = EWalletService._();
  EWalletService._();

  /// Load E-Wallet settings from local DB (payment_method='ewallet').
  /// Returns keys: provider, merchant_id, api_key, client_id, client_secret, callback_url, webhook_secret, use_sandbox, is_enabled
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'e_wallet_settings',
        where: 'payment_method = ?',
        whereArgs: ['ewallet'],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        return {
          'provider': (row['provider'] as String?) ?? 'duitnow',
          'merchant_id': (row['merchant_id'] as String?) ?? '',
          'api_key': (row['api_key'] as String?) ?? '',
          'client_id': (row['client_id'] as String?) ?? '',
          'client_secret': (row['client_secret'] as String?) ?? '',
          'callback_url': (row['callback_url'] as String?) ?? '',
          'webhook_secret': (row['webhook_secret'] as String?) ?? '',
          'use_sandbox': ((row['use_sandbox'] as int?) ?? 1) == 1,
          'is_enabled': ((row['is_enabled'] as int?) ?? 0) == 1,
        };
      }
    } catch (e) {
      developer.log('EWallet: failed to load settings - $e');
    }
    return {
      'provider': 'duitnow',
      'merchant_id': '',
      'api_key': '',
      'client_id': '',
      'client_secret': '',
      'callback_url': '',
      'webhook_secret': '',
      'use_sandbox': true,
      'is_enabled': false,
    };
  }

  /// Create a pending e-wallet transaction record in local DB
  Future<int> createPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required double amount,
    required String referenceId,
    DateTime? qrExpiresAt,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db.insert('e_wallet_transactions', {
        'transaction_id': transactionId,
        'payment_method': paymentMethod,
        'amount': amount,
        'reference_id': referenceId,
        'status': 'pending',
        'qr_expires_at': qrExpiresAt?.millisecondsSinceEpoch,
        'created_at': now,
        'updated_at': now,
      });
      developer.log('EWallet: pending transaction created id=$id');
      return id;
    } catch (e) {
      developer.log('EWallet: failed to create pending tx - $e');
      rethrow;
    }
  }

  /// Check if QR code has expired
  Future<bool> isQRExpired({required int id}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'e_wallet_transactions',
        columns: ['qr_expires_at'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final expiresAt = rows.first['qr_expires_at'] as int?;
        if (expiresAt != null) {
          return DateTime.now().millisecondsSinceEpoch > expiresAt;
        }
      }
    } catch (e) {
      developer.log('EWallet: failed to check expiry - $e');
    }
    return false;
  }

  /// Get remaining time in seconds until QR expires
  Future<int> getQRRemainingSeconds({required int id}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'e_wallet_transactions',
        columns: ['qr_expires_at'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final expiresAt = rows.first['qr_expires_at'] as int?;
        if (expiresAt != null) {
          final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
          return (remaining / 1000).round();
        }
      }
    } catch (e) {
      developer.log('EWallet: failed to get remaining time - $e');
    }
    return 0;
  }

  /// Mark transaction as expired
  Future<void> markExpired({required int id}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'e_wallet_transactions',
        {
          'status': 'expired',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('EWallet: transaction $id marked expired');
    } catch (e) {
      developer.log('EWallet: failed to mark expired - $e');
      rethrow;
    }
  }

  /// Mark an e-wallet transaction as successful
  Future<void> markSuccess({
    required int id,
    String? authCode,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'e_wallet_transactions',
        {
          'status': 'success',
          'auth_code': authCode,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('EWallet: transaction $id marked success');
    } catch (e) {
      developer.log('EWallet: failed to mark success - $e');
      rethrow;
    }
  }

  /// Get current status for a local e-wallet transaction by row id.
  Future<String?> getTransactionStatus({required int id}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'e_wallet_transactions',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first['status'] as String?;
      }
    } catch (e) {
      developer.log('EWallet: failed to get status - $e');
    }
    return null;
  }

  /// Mark an e-wallet transaction as failed
  Future<void> markFailed({
    required int id,
    String? errorMessage,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'e_wallet_transactions',
        {
          'status': 'failed',
          'gateway_response': errorMessage,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('EWallet: transaction $id marked failed');
    } catch (e) {
      developer.log('EWallet: failed to mark failed - $e');
      rethrow;
    }
  }

  /// Build a placeholder DuitNow QR payload string.
  /// In a real integration, follow the official DuitNow QR spec.
  String buildDuitNowQR({
    required double amount,
    required String referenceId,
    String? merchantId,
  }) {
    // Placeholder payload format for on-screen QR display
    // Example: DNQR|MID=XXXX|AMT=12.34|REF=ORDER123
    final amt = amount.toStringAsFixed(2);
    final mid = merchantId ?? 'MERCHANT-LOCAL';
    return 'DNQR|MID=$mid|AMT=$amt|REF=$referenceId';
  }
}
