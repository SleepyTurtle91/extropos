import 'dart:io';

import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// no unused model imports required here

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

  test('table status persists after merge and updateTable calls', () async {
    final db = DatabaseService.instance;

    final t1 = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
    final t2 = RestaurantTable(id: 't2', name: 'T2', capacity: 4);
    final target = RestaurantTable(id: 't3', name: 'T3', capacity: 6);

    // Insert tables into DB
    await db.insertTable(t1);
    await db.insertTable(t2);
    await db.insertTable(target);

    // Simulate merging: set target occupied, donors available
    target.status = TableStatus.occupied;
    t1.status = TableStatus.available;
    t2.status = TableStatus.available;

    await db.updateTable(target);
    await db.updateTable(t1);
    await db.updateTable(t2);

    // Read back from DB and verify persisted status
    final t1FromDb = await db.getTableById('t1');
    final t2FromDb = await db.getTableById('t2');
    final targetFromDb = await db.getTableById('t3');

    expect(t1FromDb, isNotNull);
    expect(t2FromDb, isNotNull);
    expect(targetFromDb, isNotNull);

    expect(t1FromDb!.status, TableStatus.available);
    expect(t2FromDb!.status, TableStatus.available);
    expect(targetFromDb!.status, TableStatus.occupied);
  });
}
