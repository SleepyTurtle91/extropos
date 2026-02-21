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

  setUpAll(() async {
    final tmp = await Directory.systemTemp.createTemp('extropos_test_');
    final dbFile = p.join(tmp.path, 'extropos.db');
    DatabaseHelper.overrideDatabaseFilePath(dbFile);
    await DatabaseHelper.instance.resetDatabase();
  });

  test('save printer test', () async {
    final printer = Printer.network(
      id: 'test_printer_1',
      name: 'Test Printer',
      type: PrinterType.receipt,
      ipAddress: '192.168.1.100',
      port: 9100,
    );

    try {
      await DatabaseService.instance.savePrinter(printer);
      print('Printer saved successfully');

      final printers = await DatabaseService.instance.getPrinters();
      print('Found ${printers.length} printers');
      expect(printers.length, 1);
      expect(printers.first.id, 'test_printer_1');
    } catch (e) {
      print('Error saving printer: $e');
      rethrow;
    }
  });
}
