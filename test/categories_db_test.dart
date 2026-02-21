import 'dart:io';

import 'package:extropos/models/category_model.dart';
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

  setUp(() async {
    final tmp = await Directory.systemTemp.createTemp('extropos_cat_db_test_');
    final dbFile = p.join(tmp.path, 'extropos.db');
    DatabaseHelper.overrideDatabaseFilePath(dbFile);
    await DatabaseHelper.instance.resetDatabase();
  });

  test(
    'reorder persistence: updating sortOrder persists and getCategories returns ordered list',
    () async {
      final db = DatabaseService.instance;

      final a = Category(
        id: 'a',
        name: 'A',
        description: '',
        icon: Icons.category,
        color: Colors.red,
        sortOrder: 1,
      );
      final b = Category(
        id: 'b',
        name: 'B',
        description: '',
        icon: Icons.category,
        color: Colors.green,
        sortOrder: 2,
      );
      final c = Category(
        id: 'c',
        name: 'C',
        description: '',
        icon: Icons.category,
        color: Colors.blue,
        sortOrder: 3,
      );

      await db.insertCategory(a);
      await db.insertCategory(b);
      await db.insertCategory(c);

      // Swap sort order: make C first
      final c2 = c.copyWith(sortOrder: 1);
      final a2 = a.copyWith(sortOrder: 2);
      final b2 = b.copyWith(sortOrder: 3);

      await db.updateCategory(c2);
      await db.updateCategory(a2);
      await db.updateCategory(b2);

      final cats = await db.getCategories();
      expect(cats.length, 3);
      expect(cats[0].id, 'c');
      expect(cats[1].id, 'a');
      expect(cats[2].id, 'b');
    },
  );
}
