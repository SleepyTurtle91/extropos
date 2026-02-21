import 'dart:io';

import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Printer Database Debug', () {
    setUpAll(() async {
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);
      await DatabaseHelper.instance.resetDatabase();
    });

    test('verify printers table exists', () async {
      final db = await DatabaseHelper.instance.database;

      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='printers'",
      );
      print('Tables found: $tables');
      expect(tables.isNotEmpty, true);

      // Get table schema
      final schema = await db.rawQuery('PRAGMA table_info(printers)');
      print('Printers table schema:');
      for (final column in schema) {
        print(
          '  ${column['name']}: ${column['type']} (nullable: ${column['notnull'] == 0})',
        );
      }
    });

    test('test insert printer with all fields', () async {
      final db = await DatabaseHelper.instance.database;

      final testData = {
        'id': 'test_001',
        'name': 'Test Network Printer',
        'type': 'receipt',
        'connection_type': 'network',
        'ip_address': '192.168.1.100',
        'port': 9100,
        'device_id': null,
        'device_name': 'Test Model',
        'is_default': 0,
        'is_active': 1,
        'paper_size': 'mm80',
        'status': 'offline',
        'has_permission': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Attempting to insert: $testData');

      try {
        final result = await db.insert('printers', testData);
        print('Insert result: $result');
        expect(result, greaterThan(0));

        // Verify it was inserted
        final rows = await db.query(
          'printers',
          where: 'id = ?',
          whereArgs: ['test_001'],
        );
        print('Retrieved row: $rows');
        expect(rows.length, 1);
      } catch (e) {
        print('ERROR inserting printer: $e');
        rethrow;
      }
    });

    test('test savePrinter via DatabaseService', () async {
      final printer = Printer.network(
        id: 'service_test_001',
        name: 'Service Test Printer',
        type: PrinterType.receipt,
        ipAddress: '192.168.1.200',
        port: 9100,
      );

      print('Saving printer via DatabaseService: ${printer.name}');

      try {
        await DatabaseService.instance.savePrinter(printer);
        print('Printer saved successfully via DatabaseService');

        // Verify it was saved
        final printers = await DatabaseService.instance.getPrinters();
        print('Found ${printers.length} printers');
        final found = printers.any((p) => p.id == 'service_test_001');
        expect(found, true);
      } catch (e) {
        print('ERROR saving printer via DatabaseService: $e');
        rethrow;
      }
    });
  });
}
