import 'dart:io';

import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/backend_home_screen.dart';
import 'package:extropos/screens/business_info_screen.dart';
import 'package:extropos/screens/customers_management_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/keygen_home_screen.dart';
import 'package:extropos/screens/kitchen_display_screen.dart';
import 'package:extropos/screens/mode_selection_screen.dart';
import 'package:extropos/screens/order_queue_screen.dart';
import 'package:extropos/screens/pos_order_screen.dart';
import 'package:extropos/screens/printers_management_screen.dart';
import 'package:extropos/screens/reports_screen.dart';
import 'package:extropos/screens/retail_pos_screen.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// NOTE:
// These golden tests are intentionally skipped by default so CI doesn't fail
// when baseline images are not present. To generate/update the goldens run:
// flutter test --update-goldens test/goldens/large_breakpoints_golden_test.dart

void main() {
  final sizes = [
    const Size(2560, 1440), // 2K
    const Size(3840, 2160), // 4K
  ];

  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize sqflite ffi and provide a mock SharedPreferences for tests.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues({});

  // Only run golden tests when explicitly enabled via env var. This prevents
  // CI failures when baseline images are not present. To run locally use:
  // RUN_GOLDENS=true flutter test --update-goldens test/goldens/large_breakpoints_golden_test.dart
  final runGoldens = Platform.environment['RUN_GOLDENS'] == 'true';
  if (!runGoldens) {
    print('Skipping golden tests (set RUN_GOLDENS=true to enable)');
    return;
  }

  for (final size in sizes) {
    testWidgets('Retail POS golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: RetailPOSScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Update goldens locally with --update-goldens
      await expectLater(
        find.byType(RetailPOSScreen),
        matchesGoldenFile(
          'goldens/retail_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Kitchen Display golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: KitchenDisplayScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(KitchenDisplayScreen),
        matchesGoldenFile(
          'goldens/kitchen_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Table Selection golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: TableSelectionScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(TableSelectionScreen),
        matchesGoldenFile(
          'goldens/table_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('POS Order golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      // POSOrderScreen requires a RestaurantTable to be passed
      final table = RestaurantTable(id: 'golden-1', name: 'T1', capacity: 4);
      await tester.pumpWidget(MaterialApp(home: POSOrderScreen(table: table)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(POSOrderScreen),
        matchesGoldenFile(
          'goldens/posorder_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    // Additional app-wide screens to capture broader surface area
    testWidgets('Order Queue golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: OrderQueueScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(OrderQueueScreen),
        matchesGoldenFile(
          'goldens/orderqueue_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Items Management golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: ItemsManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(ItemsManagementScreen),
        matchesGoldenFile(
          'goldens/items_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Tables Management golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: TablesManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(TablesManagementScreen),
        matchesGoldenFile(
          'goldens/tablesmgmt_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Printers Management golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: PrintersManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(PrintersManagementScreen),
        matchesGoldenFile(
          'goldens/printers_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Customers Management golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: CustomersManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(CustomersManagementScreen),
        matchesGoldenFile(
          'goldens/customers_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Business Info golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: BusinessInfoScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(BusinessInfoScreen),
        matchesGoldenFile(
          'goldens/business_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Mode Selection golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: ModeSelectionScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(ModeSelectionScreen),
        matchesGoldenFile(
          'goldens/mode_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Backend Home golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: BackendHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(BackendHomeScreen),
        matchesGoldenFile(
          'goldens/backend_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('KeyGen Home golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: KeyGenHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(KeyGenHomeScreen),
        matchesGoldenFile(
          'goldens/keygen_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Reports Screen golden at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: ReportsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(ReportsScreen),
        matchesGoldenFile(
          'goldens/reports_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  }
}
