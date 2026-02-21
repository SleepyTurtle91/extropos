import 'dart:io';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tmp = await Directory.systemTemp.createTemp('extropos_test_');
    final dbFile = p.join(tmp.path, 'extropos.db');
    DatabaseHelper.overrideDatabaseFilePath(dbFile);
    await DatabaseHelper.instance.resetDatabase();

    final item = Item(
      id: 'sitem',
      name: 'Seat Product',
      description: 'Seat test',
      price: 10.0,
      categoryId: '',
      icon: Icons.shop,
      color: const Color(0xFF000000),
    );
    await DatabaseService.instance.insertItem(item);
  });

  test('CSV export includes seat numbers in order items', () async {
    final cartItem = CartItem(
      Product('Seat Product', 10.0, 'Cat', Icons.shop),
      1,
      seatNumber: 2,
    );
    final receipt = await DatabaseService.instance.saveCompletedSale(
      cartItems: [cartItem],
      subtotal: 10.0,
      tax: 0.0,
      serviceCharge: 0.0,
      total: 10.0,
      paymentMethod: PaymentMethod(id: '1', name: 'Cash'),
      amountPaid: 10.0,
      change: 0.0,
    );
    expect(receipt, isNotNull);

    final csv = await DatabaseService.instance.exportOrdersCsv();
    expect(csv, contains('seat'));
    expect(csv, contains(',2,'));
  });
}
