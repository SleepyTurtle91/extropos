import 'dart:io';

import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Displays DB', () {
    setUpAll(() async {
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);
      await DatabaseHelper.instance.resetDatabase();
    });

    test('verify customer_displays table exists', () async {
      final db = await DatabaseHelper.instance.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='customer_displays'",
      );
      expect(tables.isNotEmpty, true);
    });

    test('insert & fetch customer display via DatabaseService', () async {
      final display = CustomerDisplay(
        id: 'cd_001',
        name: 'Test Display',
        connectionType: PrinterConnectionType.network,
        ipAddress: '10.0.0.100',
        port: 9000,
      );
      await DatabaseService.instance.saveCustomerDisplay(display);
      final saved = await DatabaseService.instance.getCustomerDisplayById('cd_001');
      expect(saved != null, true);
      expect(saved!.name, 'Test Display');
    });
  });
}
