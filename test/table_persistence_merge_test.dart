import 'dart:io';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/table_model.dart';
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
  });

  test('updateTable persists status after merge', () async {
    final db = DatabaseService.instance;

    // Create and insert two tables
    final t1 = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
    final t2 = RestaurantTable(id: 't2', name: 'T2', capacity: 4);
    final t3 = RestaurantTable(id: 't3', name: 'T3', capacity: 6);
    await db.insertTable(t1);
    await db.insertTable(t2);
    await db.insertTable(t3);

    // Set t1 and t2 as occupied in-memory and persist the change
    t1.status = TableStatus.occupied;
    t1.occupiedSince = DateTime.now();
    await db.updateTable(t1);

    t2.status = TableStatus.occupied;
    t2.occupiedSince = DateTime.now();
    await db.updateTable(t2);

    // Merge: move orders from t1 and t2 into t3 in-memory and persist t3 occupied
    t3.addOrMergeOrder(CartItem(Product('A', 10.0, 'Cat', Icons.shop), 2));
    t3.addOrMergeOrder(CartItem(Product('B', 5.0, 'Cat', Icons.shop), 1));
    t3.status = TableStatus.occupied;
    await db.updateTable(t3);

    // Verify persisted status
    final persisted = await db.getTableById('t3');
    expect(persisted, isNotNull);
    expect(persisted?.status, TableStatus.occupied);

    // Verify donors can be cleared and persisted
    t1.clearOrders();
    t1.status = TableStatus.available;
    await db.updateTable(t1);
    final p1 = await db.getTableById('t1');
    expect(p1?.isAvailable, true);
  });
}
