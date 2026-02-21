import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/ewallet_webhook_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database testDb;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE e_wallet_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id TEXT NOT NULL,
              payment_method TEXT NOT NULL,
              amount REAL NOT NULL,
              reference_id TEXT,
              auth_code TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              gateway_response TEXT,
              error_message TEXT,
              refund_amount REAL DEFAULT 0.0,
              refund_reference TEXT,
              refund_date INTEGER,
              qr_expires_at INTEGER,
              is_synced INTEGER DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    DatabaseHelper.instance.testDatabase = testDb;

    // Insert test transaction
    await testDb.insert('e_wallet_transactions', {
      'transaction_id': 'TXN_TEST_123',
      'payment_method': 'duitnow',
      'amount': 50.0,
      'reference_id': 'REF_123',
      'status': 'pending',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  });

  tearDown(() async {
    DatabaseHelper.instance.testDatabase = null;
    await testDb.close();
  });

  group('Signature Verification', () {
    test('DuitNow HMAC-SHA256 signature verification', () {
      const payload = '{"transaction_id":"TXN_123","status":"success"}';
      const secret = 'test_secret_key';

      final key = utf8.encode(secret);
      final bytes = utf8.encode(payload);
      final hmac = Hmac(sha256, key);
      final expectedSignature = hmac.convert(bytes).toString();

      final isValid = EWalletWebhookService.verifySignature(
        provider: 'duitnow',
        signature: expectedSignature,
        payload: payload,
        secret: secret,
      );

      expect(isValid, true);
    });

    test('Invalid signature should fail verification', () {
      const payload = '{"transaction_id":"TXN_123","status":"success"}';
      const secret = 'test_secret_key';
      const wrongSignature = 'invalid_signature_hash';

      final isValid = EWalletWebhookService.verifySignature(
        provider: 'duitnow',
        signature: wrongSignature,
        payload: payload,
        secret: secret,
      );

      expect(isValid, false);
    });

    test('GrabPay signature with timestamp', () {
      const payload = '{"partnerTxID":"TXN_123","txStatus":"success"}';
      const secret = 'grab_secret';

      // GrabPay uses timestamp + payload
      final isValid = EWalletWebhookService.verifySignature(
        provider: 'grabpay',
        signature: 'test_sig', // Would be real signature in production
        payload: payload,
        secret: secret,
      );

      // Expect false because we're using test signature
      expect(isValid, false);
    });

    test('Touch n Go MD5 signature', () {
      const payload = '{"txn_id":"TNG_123","payment_status":"paid"}';
      const secret = 'tng_secret';

      final combined = '$payload$secret';
      final expectedSignature = md5.convert(utf8.encode(combined)).toString();

      final isValid = EWalletWebhookService.verifySignature(
        provider: 'tng',
        signature: expectedSignature,
        payload: payload,
        secret: secret,
      );

      expect(isValid, true);
    });
  });

  group('Webhook Payload Parsing', () {
    test('Parse DuitNow webhook payload', () {
      final json = {
        'transaction_id': 'TXN_123',
        'status': 'completed',
        'amount': 50.0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = WebhookPayload.fromJson('duitnow', json);

      expect(payload.provider, 'duitnow');
      expect(payload.transactionId, 'TXN_123');
      expect(payload.status, 'success'); // 'completed' maps to 'success'
      expect(payload.amount, 50.0);
    });

    test('Parse GrabPay webhook payload', () {
      final json = {
        'partnerTxID': 'ORD_456',
        'txStatus': 'success',
        'amount': 5000, // cents
        'txTime': DateTime.now().toIso8601String(),
      };

      final payload = WebhookPayload.fromJson('grabpay', json);

      expect(payload.provider, 'grabpay');
      expect(payload.transactionId, 'ORD_456');
      expect(payload.status, 'success');
      expect(payload.amount, 50.0); // Converted from cents
    });

    test('Parse Touch n Go webhook payload', () {
      final json = {
        'txn_id': 'TNG_789',
        'payment_status': 'paid',
        'amount': 100.0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final payload = WebhookPayload.fromJson('tng', json);

      expect(payload.provider, 'tng');
      expect(payload.transactionId, 'TNG_789');
      expect(payload.status, 'success'); // 'paid' maps to 'success'
      expect(payload.amount, 100.0);
    });

    test('Map failed status correctly', () {
      final json = {
        'transaction_id': 'TXN_FAIL',
        'status': 'failed',
        'error_message': 'Insufficient balance',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = WebhookPayload.fromJson('duitnow', json);

      expect(payload.status, 'failed');
      expect(payload.errorMessage, 'Insufficient balance');
    });
  });

  group('Webhook Processing', () {
    test('Handle successful webhook and update DB', () async {
      const secret = 'test_secret';
      final payload = {
        'transaction_id': 'REF_123', // Matches reference_id in test DB
        'status': 'completed',
        'amount': 50.0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payloadString = jsonEncode(payload);
      final key = utf8.encode(secret);
      final bytes = utf8.encode(payloadString);
      final hmac = Hmac(sha256, key);
      final signature = hmac.convert(bytes).toString();

      final result = await EWalletWebhookService.handleWebhook(
        provider: 'duitnow',
        payload: payload,
        signature: signature,
        webhookSecret: secret,
      );

      expect(result, true);

      // Verify DB update
      final rows = await testDb.query(
        'e_wallet_transactions',
        where: 'reference_id = ?',
        whereArgs: ['REF_123'],
      );
      expect(rows.first['status'], 'success');
    });

    test('Reject webhook with invalid signature', () async {
      const secret = 'test_secret';
      final payload = {
        'transaction_id': 'REF_123',
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final result = await EWalletWebhookService.handleWebhook(
        provider: 'duitnow',
        payload: payload,
        signature: 'invalid_signature',
        webhookSecret: secret,
      );

      expect(result, false);

      // Verify DB NOT updated
      final rows = await testDb.query(
        'e_wallet_transactions',
        where: 'reference_id = ?',
        whereArgs: ['REF_123'],
      );
      expect(rows.first['status'], 'pending'); // Still pending
    });

    test('Handle failed payment webhook', () async {
      const secret = 'test_secret';
      final payload = {
        'transaction_id': 'REF_123',
        'status': 'failed',
        'error_message': 'Payment declined',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payloadString = jsonEncode(payload);
      final key = utf8.encode(secret);
      final bytes = utf8.encode(payloadString);
      final hmac = Hmac(sha256, key);
      final signature = hmac.convert(bytes).toString();

      final result = await EWalletWebhookService.handleWebhook(
        provider: 'duitnow',
        payload: payload,
        signature: signature,
        webhookSecret: secret,
      );

      expect(result, true);

      // Verify DB shows failed status
      final rows = await testDb.query(
        'e_wallet_transactions',
        where: 'reference_id = ?',
        whereArgs: ['REF_123'],
      );
      expect(rows.first['status'], 'failed');
      expect(rows.first['error_message'], 'Payment declined');
    });
  });

  group('Webhook Simulation', () {
    test('Simulate successful webhook callback', () async {
      const secret = 'test_secret';

      await EWalletWebhookService.simulateWebhookCallback(
        provider: 'duitnow',
        transactionId: 'REF_123',
        status: 'completed',
        webhookSecret: secret,
      );

      // Wait for async processing
      await Future.delayed(const Duration(milliseconds: 2100));

      final rows = await testDb.query(
        'e_wallet_transactions',
        where: 'reference_id = ?',
        whereArgs: ['REF_123'],
      );
      expect(rows.first['status'], 'success');
    });
  });
}
