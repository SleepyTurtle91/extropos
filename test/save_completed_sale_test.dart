import 'dart:io';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
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
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService.saveCompletedSale', () {
    setUpAll(() async {
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);
      await DatabaseHelper.instance.resetDatabase();
    });

    test('happy path: saves order, items and transaction', () async {
      final dbService = DatabaseService.instance;

      // Create a category with a unique id to avoid collisions when tests run repeatedly
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      final category = Category(
        id: 'cat-$uniqueSuffix',
        name: 'Beverages',
        description: 'Drinks',
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertCategory(category);

      // Insert an item in DB
      final item = Item(
        id: 'item-$uniqueSuffix',
        name: 'Test Coffee',
        description: 'Tasty',
        price: 3.5,
        categoryId: category.id,
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertItem(item);

      // Prepare cart item with a Product that matches DB item name
      final product = Product(item.name, item.price, category.name, item.icon);
      final cartItem = CartItem(product, 2);

      final subtotal = cartItem.totalPrice;
      final tax = 0.0;
      final serviceCharge = 0.0;
      final total = subtotal;

      final paymentMethod = PaymentMethod(id: '1', name: 'Cash');

      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: total,
        paymentMethod: paymentMethod,
        amountPaid: total,
        change: 0.0,
        orderType: 'retail',
      );

      expect(orderNumber, isNotNull);

      // Verify order exists and related rows
      final orders = await dbService.getRecentOrders(limit: 10);
      final orderMap = orders.firstWhere(
        (o) => o['order_number'] == orderNumber,
        orElse: () => {},
      );
      expect(orderMap.isNotEmpty, isTrue);

      final orderId = orderMap['id'] as String;

      final items = await dbService.getOrderItems(orderId);
      expect(items.length, 1);
      expect(items.first['item_name'], item.name);

      final txs = await dbService.getTransactionsForOrder(orderId);
      expect(txs.length, 1);
      expect((txs.first['amount'] as num).toDouble(), total);
    });

    test('unmapped items should skip persistence (return null)', () async {
      final dbService = DatabaseService.instance;

      final product = Product('Nonexistent Item', 5.0, 'Misc', Icons.help);
      final cartItem = CartItem(product, 1);

      final subtotal = cartItem.totalPrice;
      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: 0.0,
        serviceCharge: 0.0,
        total: subtotal,
        paymentMethod: PaymentMethod(id: '1', name: 'Cash'),
        amountPaid: subtotal,
        change: 0.0,
      );

      expect(orderNumber, isNull);
    });

    test('order-level discount persists in DB', () async {
      final dbService = DatabaseService.instance;

      // Insert category and item
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      final category = Category(
        id: 'cat2-$uniqueSuffix',
        name: 'Snacks',
        description: 'Light bites',
        icon: Icons.fastfood,
        color: Colors.orange,
      );
      await dbService.insertCategory(category);
      final item = Item(
        id: 'item2-$uniqueSuffix',
        name: 'Test Snack',
        description: 'Tasty',
        price: 2.5,
        categoryId: category.id,
        icon: Icons.fastfood,
        color: Colors.orange,
      );
      await dbService.insertItem(item);

      final product = Product(item.name, item.price, category.name, item.icon);
      final cartItem = CartItem(product, 1);

      final subtotal = cartItem.totalPrice;
      final paymentMethod = PaymentMethod(id: '1', name: 'Cash');

      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: 0.0,
        serviceCharge: 0.0,
        total: subtotal - 1.0,
        paymentMethod: paymentMethod,
        amountPaid: subtotal - 1.0,
        change: 0.0,
        orderType: 'retail',
        discount: 1.0,
        merchantId: 'grabfood',
      );

      expect(orderNumber, isNotNull);
      final orders = await dbService.getRecentOrders(limit: 10);
      final orderMap = orders.firstWhere((o) => o['order_number'] == orderNumber);
      expect((orderMap['discount'] as num?)?.toDouble() ?? 0.0, 1.0);
      expect(orderMap['merchant_id'], 'grabfood');
    });

    test('seat number is saved for order items', () async {
      final dbService = DatabaseService.instance;

      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      final category = Category(
        id: 'catseat-$uniqueSuffix',
        name: 'SeatCat',
        description: 'Seats',
        icon: Icons.event_seat,
        color: Colors.grey,
      );
      await dbService.insertCategory(category);
      final item = Item(
        id: 'itemseat-$uniqueSuffix',
        name: 'Seat Coffee',
        description: 'Seat test',
        price: 5.0,
        categoryId: category.id,
        icon: Icons.event_seat,
        color: Colors.grey,
      );
      await dbService.insertItem(item);

      final product = Product(item.name, item.price, category.name, item.icon);
      final cartItem = CartItem(product, 1, seatNumber: 3);

      final subtotal = cartItem.totalPrice;
      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: 0.0,
        serviceCharge: 0.0,
        total: subtotal,
        paymentMethod: PaymentMethod(id: '1', name: 'Cash'),
        amountPaid: subtotal,
        change: 0.0,
      );

      expect(orderNumber, isNotNull);
      final orders = await dbService.getRecentOrders(limit: 10);
      final orderMap = orders.firstWhere((o) => o['order_number'] == orderNumber);
      final items = await dbService.getOrderItems(orderMap['id'] as String);
      expect(items.first['seat_number'], 3);
    });

    test('happy hour discount persists in saved price', () async {
      final dbService = DatabaseService.instance;

      // Enable happy hour for the purpose of this test
      final cur = BusinessInfo.instance;
      BusinessInfo.updateInstance(cur.copyWith(
        isHappyHourEnabled: true,
        happyHourStart: '00:00',
        happyHourEnd: '23:59',
        happyHourDiscountPercent: 0.2,
      ));

      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      final category = Category(
        id: 'hcat-$uniqueSuffix',
        name: 'Happy',
        description: 'HH',
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertCategory(category);
      final item = Item(
        id: 'hitem-$uniqueSuffix',
        name: 'Happy Coffee',
        description: 'HH Test',
        price: 100.0,
        categoryId: category.id,
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertItem(item);

      final product = Product(item.name, item.price, category.name, item.icon);
      final hhDiscount = item.price * BusinessInfo.instance.happyHourDiscountPercent;
      final cartItem = CartItem(product, 1, priceAdjustment: -hhDiscount);

      final subtotal = cartItem.totalPrice;
      final receipt = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: 0.0,
        serviceCharge: 0.0,
        total: subtotal,
        paymentMethod: PaymentMethod(id: '1', name: 'Cash'),
        amountPaid: subtotal,
        change: 0.0,
      );

      expect(receipt, isNotNull);
      final orders = await dbService.getRecentOrders(limit: 10);
      final orderMap = orders.firstWhere((o) => o['order_number'] == receipt);
      final items = await dbService.getOrderItems(orderMap['id'] as String);
      final savedPrice = (items.first['item_price'] as num).toDouble();
      expect(savedPrice, equals(80.0)); // 100 - 20%
    });
  });
}
