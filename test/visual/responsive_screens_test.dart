import 'dart:io';

import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/cafe_pos_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/kitchen_display_screen.dart';
import 'package:extropos/screens/order_queue_screen.dart';
import 'package:extropos/screens/pos_order_screen_fixed.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/retail_pos_screen.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final sizes = [
    const Size(360, 800), // phone portrait
    const Size(812, 375), // phone landscape
    const Size(800, 1280), // tablet
    const Size(1366, 768), // desktop
    const Size(2560, 1440), // large desktop / 2K
    const Size(3840, 2160), // 4K
  ];

  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize ffi database factory for tests which use sqflite Common FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Skip visual/responsive tests by default in CI. Run locally with
  // RUN_VISUALS=true flutter test test/visual/responsive_screens_test.dart
  final runVisuals = Platform.environment['RUN_VISUALS'] == 'true';
  if (!runVisuals) {
    print('Skipping visual responsive tests (set RUN_VISUALS=true to enable)');
    return;
  }

  for (final size in sizes) {
    testWidgets('Retail POS at ${size.width}x${size.height} does not overflow', (
      WidgetTester tester,
    ) async {
      // Use the WidgetTester.view APIs (preferred over the deprecated window test helpers)
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(home: RetailPOSScreen()));
      // Use controlled pumps to allow async initialization without hanging
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Cafe POS at ${size.width}x${size.height} does not overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(home: CafePOSScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      'Kitchen Display at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: KitchenDisplayScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Order Queue at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: OrderQueueScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Items management at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: ItemsManagementScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Tables management at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: TablesManagementScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Printers management at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: PrintersManagementScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Table selection at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: TableSelectionScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'POS Order screen at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final table = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
        await tester.pumpWidget(
          MaterialApp(home: POSOrderScreen(table: table)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  }
}
