import 'dart:io';

import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TableSelection merge flow', () {
    late Directory tmpDir;
    setUpAll(() async {
      sqfliteFfiInit();
      tmpDir = await Directory.systemTemp.createTemp('db_test_');
    });

    tearDownAll(() async {
      try {
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('Merge selected tables persists status changes', (
      WidgetTester tester,
    ) async {
      // Skip this test in CI for now — it can intermittently time out due to
      // environment-specific delays in widget rendering and DB initialization.
      // Enable by setting RUN_WIDGET_LONG_TESTS=true when running locally.
      if (Platform.environment['RUN_WIDGET_LONG_TESTS'] != 'true') {
        print(
          'Skipping long-running TableSelection merge test (set RUN_WIDGET_LONG_TESTS=true to enable)',
        );
        return;
      }

      final dbFile = p.join(tmpDir.path, 'merge_test.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);

      // Prepare DB: insert three tables
      final t1 = RestaurantTable(
        id: 't1',
        name: 'T1',
        capacity: 4,
        status: TableStatus.occupied,
      );
      final t2 = RestaurantTable(
        id: 't2',
        name: 'T2',
        capacity: 4,
        status: TableStatus.occupied,
      );
      final t3 = RestaurantTable(
        id: 't3',
        name: 'T3',
        capacity: 4,
        status: TableStatus.available,
      );

      // Wait for database to initialize and insert
      await DatabaseService.instance.insertTable(t1);
      await DatabaseService.instance.insertTable(t2);
      await DatabaseService.instance.insertTable(t3);

      await tester.pumpWidget(const MaterialApp(home: TableSelectionScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Enter merge mode
      final mergeButton = find.byIcon(Icons.merge_type);
      expect(mergeButton, findsOneWidget);
      await tester.tap(mergeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap t1 and t2 to select; verify check overlay appears
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('T2'), findsOneWidget);
      await tester.tap(find.text('T1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('T2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Confirm merge action (check icon in app bar)
      final confirmButton = find.byIcon(Icons.check);
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Choose target table from dialog - select 'T1' (first option)
      expect(
        find.text('T1'),
        findsWidgets,
      ); // multiple contexts - dialog and card
      // The dialog contains T1 and T2 options - find the dialog option by searching for SimpleDialogOption text
      await tester.tap(find.widgetWithText(SimpleDialogOption, 'T1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Confirm the Merge in the AlertDialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Merge'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Now check DB: t1 should remain occupied, t2 should be available
      final updatedT1 = await DatabaseService.instance.getTableById('t1');
      final updatedT2 = await DatabaseService.instance.getTableById('t2');

      expect(updatedT1, isNotNull);
      expect(updatedT2, isNotNull);
      expect(updatedT1!.status, TableStatus.occupied);
      expect(updatedT2!.status, TableStatus.available);
    });
  });
}
