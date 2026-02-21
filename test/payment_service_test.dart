import 'dart:io';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock SharedPreferences for tests (some services read prefs during init)
  SharedPreferences.setMockInitialValues({});

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tmp = await Directory.systemTemp.createTemp('extropos_test_');
    final dbFile = p.join(tmp.path, 'extropos.db');
    DatabaseHelper.overrideDatabaseFilePath(dbFile);
    await DatabaseHelper.instance.resetDatabase();

    // Insert test items to allow saveCompletedSale to persist orders successfully
    await DatabaseService.instance.insertItem(
      Item(
        id: 'test-1',
        name: 'Test Product',
        description: 'Test product',
        price: 10.0,
        categoryId: '',
        icon: Icons.shopping_cart,
        color: Colors.blue,
      ),
    );
    await DatabaseService.instance.insertItem(
      Item(
        id: 'test-2',
        name: 'Test Product 15',
        description: 'Test product 15',
        price: 15.0,
        categoryId: '',
        icon: Icons.shopping_cart,
        color: Colors.blue,
      ),
    );
  });

  setUp(() {
    // Force card validation success for deterministic tests
    PaymentService.instance.forceCardSuccess = true;
    // Enable training mode to avoid database operations
    TrainingModeService.instance.toggleTrainingMode(true);
  });

  tearDown(() {
    // Reset training mode after each test
    TrainingModeService.instance.toggleTrainingMode(false);
  });

  group('PaymentService', () {
    test('processCashPayment - successful payment with change', () async {
      final cartItems = [
        CartItem(Product('Test Product', 10.0, 'Test', Icons.shopping_cart), 2),
      ];

      final result = await PaymentService.instance.processCashPayment(
        totalAmount: 20.0,
        amountPaid: 25.0,
        cartItems: cartItems,
      );

      if (!result.success) {
        print('Payment failed: ${result.errorMessage}');
      }
      expect(result.success, true);
      expect(result.amountPaid, 25.0);
      expect(result.change, 5.0);
      expect(result.transactionId, isNotNull);
      expect(result.receiptNumber, isNotNull);
      expect(result.paymentSplits.first.paymentMethod.name, 'Cash');
    });

    test('processCashPayment - insufficient payment', () async {
      final cartItems = [
        CartItem(Product('Test Product', 10.0, 'Test', Icons.shopping_cart), 1),
      ];

      final result = await PaymentService.instance.processCashPayment(
        totalAmount: 10.0,
        amountPaid: 5.0,
        cartItems: cartItems,
      );

      expect(result.success, false);
      expect(result.errorMessage, contains('Insufficient payment'));
      expect(result.amountPaid, 5.0);
      expect(result.change, 0.0);
    });

    test('processCardPayment - successful payment', () async {
      final cartItems = [
        CartItem(Product('Test Product', 15.0, 'Test', Icons.shopping_cart), 1),
      ];

      final paymentMethod = PaymentMethod(id: 'card', name: 'Credit Card');

      final result = await PaymentService.instance.processCardPayment(
        totalAmount: 15.0,
        paymentMethod: paymentMethod,
        cartItems: cartItems,
      );

      expect(result.success, true);
      expect(result.amountPaid, 15.0);
      expect(result.change, 0.0);
      expect(result.transactionId, isNotNull);
      expect(result.receiptNumber, isNotNull);
      expect(result.paymentSplits.first.paymentMethod.name, 'Credit Card');
    });
  });
}
