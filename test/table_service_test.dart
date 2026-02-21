import 'dart:io';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/table_service.dart';
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

  group('TableService Tests', () {
    late TableService tableService;

    setUp(() async {
      // Reset database before each test to avoid UNIQUE constraint issues
      await DatabaseHelper.instance.resetDatabase();
      tableService = TableService();
      await tableService.initialize();
    });

    tearDown(() async {
      // Don't dispose singleton service in tests
    });

    test('Initialize loads tables from database', () async {
      final db = DatabaseService.instance;

      // Create test tables
      final t1 = RestaurantTable(id: 't1', name: 'Table 1', capacity: 4);
      final t2 = RestaurantTable(id: 't2', name: 'Table 2', capacity: 6);
      await db.insertTable(t1);
      await db.insertTable(t2);

      // Re-initialize service
      await tableService.initialize();

      expect(tableService.tables.length, 2);
      expect(tableService.totalTables, 2);
      expect(tableService.availableTables, 2);
      expect(tableService.occupiedTables, 0);
    });

    test('Capacity management properties work correctly', () async {
      final table = RestaurantTable(id: 't1', name: 'Table 1', capacity: 4);
      final product = Product('Test Item', 10.0, 'Food', Icons.restaurant);

      // Empty table
      expect(table.currentOccupancy, 0);
      expect(table.occupancyPercentage, 0.0);
      expect(table.needsCapacityWarning, false);
      expect(table.isCapacityCritical, false);
      expect(table.isAtCapacity, false);
      expect(table.isOverCapacity, false);

      // Add items approaching capacity (80% = 3.2, so 3 items = 75%)
      table.addOrder(CartItem(product, 3));
      expect(table.currentOccupancy, 3);
      expect(table.occupancyPercentage, 75.0);
      expect(table.needsCapacityWarning, false); // 75% < 80%

      // Add one more item (100%)
      table.addOrder(CartItem(product, 1));
      expect(table.currentOccupancy, 4);
      expect(table.occupancyPercentage, 100.0);
      expect(table.needsCapacityWarning, true); // 100% >= 80%
      expect(table.isCapacityCritical, true); // 100% >= 100%
      expect(table.isAtCapacity, true);

      // Add one more (over capacity)
      table.addOrder(CartItem(product, 1));
      expect(table.currentOccupancy, 5);
      expect(table.occupancyPercentage, 125.0);
      expect(table.isOverCapacity, true);
    });

    test('Merge tables combines orders correctly', () async {
      final db = DatabaseService.instance;

      final t1 = RestaurantTable(id: 'merge_t1', name: 'Table 1', capacity: 4);
      final t2 = RestaurantTable(id: 'merge_t2', name: 'Table 2', capacity: 4);
      final target = RestaurantTable(id: 'merge_t3', name: 'Table 3', capacity: 8);

      final productA = Product('Pizza', 15.0, 'Food', Icons.local_pizza);
      final productB = Product('Burger', 12.0, 'Food', Icons.fastfood);

      // Setup tables with orders
      t1.addOrder(CartItem(productA, 2));
      t2.addOrder(CartItem(productA, 1));
      t2.addOrder(CartItem(productB, 1));

      await db.insertTable(t1);
      await db.insertTable(t2);
      await db.insertTable(target);

      // Load tables into service
      await tableService.initialize();

      // Add orders to the service's table instances (since orders aren't persisted)
      final serviceT1 = tableService.getTableById(t1.id)!;
      final serviceT2 = tableService.getTableById(t2.id)!;
      serviceT1.addOrder(CartItem(productA, 2));
      serviceT2.addOrder(CartItem(productA, 1));
      serviceT2.addOrder(CartItem(productB, 1));

      // Perform merge
      final success = await tableService.mergeTables(
        targetTableId: target.id,
        sourceTableIds: [t1.id, t2.id],
      );

      expect(success, true);

      // Check target table has combined orders
      final updatedTarget = tableService.getTableById(target.id)!;
      expect(updatedTarget.orders.length, 2);
      expect(updatedTarget.itemCount, 4);
      expect(updatedTarget.currentOccupancy, 4);

      // Check source tables are cleared
      final updatedT1 = tableService.getTableById(t1.id)!;
      final updatedT2 = tableService.getTableById(t2.id)!;
      expect(updatedT1.orders.isEmpty, true);
      expect(updatedT2.orders.isEmpty, true);
      expect(updatedT1.isAvailable, true);
      expect(updatedT2.isAvailable, true);
    });

    test('Split table orders moves items correctly', () async {
      final db = DatabaseService.instance;

      final source = RestaurantTable(id: 'split_source', name: 'Source Table', capacity: 6);
      final target = RestaurantTable(id: 'split_target', name: 'Target Table', capacity: 4);

      final productA = Product('Pizza', 15.0, 'Food', Icons.local_pizza);
      final productB = Product('Burger', 12.0, 'Food', Icons.fastfood);

      // Setup source table with multiple orders
      source.addOrder(CartItem(productA, 2));
      source.addOrder(CartItem(productB, 1));

      await db.insertTable(source);
      await db.insertTable(target);

      // Load tables into service
      await tableService.initialize();

      // Add orders to the service's table instance (since orders aren't persisted)
      final serviceSource = tableService.getTableById(source.id)!;
      serviceSource.addOrder(CartItem(productA, 2));
      serviceSource.addOrder(CartItem(productB, 1));

      // Split one order to target
      final ordersToMove = [serviceSource.orders[0]]; // Move pizza order

      final success = await tableService.splitTableOrders(
        sourceTableId: source.id,
        targetTableId: target.id,
        ordersToMove: ordersToMove,
      );

      expect(success, true);

      // Check source table
      final updatedSource = tableService.getTableById(source.id)!;
      expect(updatedSource.orders.length, 1); // Only burger left
      expect(updatedSource.itemCount, 1);
      expect(updatedSource.isOccupied, true); // Still has orders

      // Check target table
      final updatedTarget = tableService.getTableById(target.id)!;
      expect(updatedTarget.orders.length, 1); // Has pizza
      expect(updatedTarget.itemCount, 2);
      expect(updatedTarget.isOccupied, true);
    });

    test('Capacity warning methods return correct tables', () async {
      final db = DatabaseService.instance;

      final normalTable = RestaurantTable(id: 'normal', name: 'Normal', capacity: 4);
      final warningTable = RestaurantTable(id: 'warning', name: 'Warning', capacity: 4);
      final criticalTable = RestaurantTable(id: 'critical', name: 'Critical', capacity: 2);
      final overTable = RestaurantTable(id: 'over', name: 'Over', capacity: 2);

      final product = Product('Item', 10.0, 'Food', Icons.restaurant);

      // Don't add orders here - we'll add them to service instances later
      // warningTable.addOrder(CartItem(product, 3)); // 75% - no warning yet
      // criticalTable.addOrder(CartItem(product, 2)); // 100% - critical
      // overTable.addOrder(CartItem(product, 3)); // 150% - over capacity

      await db.insertTable(normalTable);
      await db.insertTable(warningTable);
      await db.insertTable(criticalTable);
      await db.insertTable(overTable);

      // Load tables into service
      await tableService.initialize();

      // Add orders to the service's table instances (since orders aren't persisted)
      final serviceWarning = tableService.getTableById(warningTable.id)!;
      final serviceCritical = tableService.getTableById(criticalTable.id)!;
      final serviceOver = tableService.getTableById(overTable.id)!;
      serviceWarning.addOrder(CartItem(product, 3)); // 75% - no warning yet
      serviceCritical.addOrder(CartItem(product, 2)); // 100% - at capacity
      serviceOver.addOrder(CartItem(product, 3)); // 150% - over capacity

      // Test capacity warning getters
      final warningTables = tableService.getCapacityWarningTables();
      expect(warningTables.length, 2); // critical and over tables

      final atCapacityTables = tableService.tablesAtCapacity;
      expect(atCapacityTables.length, 1); // critical table

      final overCapacityTables = tableService.tablesOverCapacity;
      expect(overCapacityTables.length, 1); // over table
    });

    test('Occupancy statistics are calculated correctly', () async {
      final db = DatabaseService.instance;

      final t1 = RestaurantTable(id: 'stats_t1', name: 'Table 1', capacity: 4);
      final t2 = RestaurantTable(id: 'stats_t2', name: 'Table 2', capacity: 6);

      final product = Product('Item', 10.0, 'Food', Icons.restaurant);

      t1.addOrder(CartItem(product, 2)); // 2/4 = 50%
      t2.addOrder(CartItem(product, 4)); // 4/6 = 67%

      await db.insertTable(t1);
      await db.insertTable(t2);

      // Load tables into service
      await tableService.initialize();

      // Add orders to the service's table instances (since orders aren't persisted)
      final serviceT1 = tableService.getTableById(t1.id)!;
      final serviceT2 = tableService.getTableById(t2.id)!;
      serviceT1.addOrder(CartItem(product, 2));
      serviceT2.addOrder(CartItem(product, 4));

      final stats = tableService.getOccupancyStats();

      expect(stats['totalCapacity'], 10);
      expect(stats['currentOccupancy'], 6);
      expect(stats['occupancyRate'], 60.0);
      expect(stats['availableCapacity'], 4);
      expect(stats['tablesAtCapacity'], 0);
      expect(stats['tablesOverCapacity'], 0);
    });

    test('Real-time updates work with table status changes', () async {
      final db = DatabaseService.instance;

      final table = RestaurantTable(id: 'realtime_test', name: 'Test Table', capacity: 4);
      await db.insertTable(table);

      await tableService.initialize();

      expect(tableService.availableTables, 1);
      expect(tableService.occupiedTables, 0);

      // Update table status
      await tableService.updateTableStatus(table.id, TableStatus.occupied);

      expect(tableService.availableTables, 0);
      expect(tableService.occupiedTables, 1);

      final updatedTable = tableService.getTableById(table.id);
      expect(updatedTable?.isOccupied, true);
    });
  });
}