import 'dart:io';

import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/e_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Create an isolated test database and necessary tables
    final dir = await Directory.systemTemp.createTemp('extropos_test');
    final dbPath = p.join(dir.path, 'extropos_test.db');
    final db = await databaseFactory.openDatabase(dbPath);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS e_wallet_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        amount REAL NOT NULL,
        reference_id TEXT,
        auth_code TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        gateway_response TEXT,
        refund_amount REAL DEFAULT 0.0,
        refund_reference TEXT,
        refund_date INTEGER,
        qr_expires_at INTEGER,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS e_wallet_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_method TEXT NOT NULL UNIQUE,
        provider TEXT DEFAULT 'duitnow',
        merchant_id TEXT,
        api_key TEXT,
        client_id TEXT,
        client_secret TEXT,
        callback_url TEXT,
        webhook_secret TEXT,
        use_sandbox INTEGER DEFAULT 1,
        is_enabled INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Direct future DB calls to our test DB
    DatabaseHelper.instance.testDatabase = db;
  });

  test('EWallet settings load defaults then saved values', () async {
    final service = EWalletService.instance;

    // Defaults when no row exists
    final defaults = await service.getSettings();
    expect(defaults['provider'], 'duitnow');
    expect(defaults['is_enabled'], false);

    // Insert settings row
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('e_wallet_settings', {
      'payment_method': 'ewallet',
      'provider': 'duitnow',
      'merchant_id': 'MID123',
      'api_key': 'KEY',
      'client_id': 'CID',
      'client_secret': 'SECRET',
      'callback_url': 'https://example.com/callback',
      'webhook_secret': 'WHSEC',
      'use_sandbox': 0,
      'is_enabled': 1,
      'created_at': now,
      'updated_at': now,
    });

    final loaded = await service.getSettings();
    expect(loaded['provider'], 'duitnow');
    expect(loaded['merchant_id'], 'MID123');
    expect(loaded['use_sandbox'], false);
    expect(loaded['is_enabled'], true);
  });

  test('EWallet transaction status transitions', () async {
    final service = EWalletService.instance;

    final id = await service.createPendingTransaction(
      transactionId: 'TX123',
      paymentMethod: 'E-Wallet',
      amount: 12.34,
      referenceId: 'REF123',
    );

    var status = await service.getTransactionStatus(id: id);
    expect(status, 'pending');

    await service.markSuccess(id: id);
    status = await service.getTransactionStatus(id: id);
    expect(status, 'success');

    final id2 = await service.createPendingTransaction(
      transactionId: 'TX124',
      paymentMethod: 'E-Wallet',
      amount: 10.00,
      referenceId: 'REF124',
    );
    await service.markFailed(id: id2, errorMessage: 'DECLINED');
    final status2 = await service.getTransactionStatus(id: id2);
    expect(status2, 'failed');
  });
}
