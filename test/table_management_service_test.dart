import 'dart:io';

import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/table_management_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Create isolated test database
    final dir = await Directory.systemTemp.createTemp('table_mgmt_test');
    final dbPath = p.join(dir.path, 'test.db');
    final db = await databaseFactory.openDatabase(dbPath);

    // Create restaurant_tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS restaurant_tables (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        status TEXT DEFAULT 'available',
        customer_name TEXT,
        customer_phone TEXT,
        notes TEXT,
        merged_table_ids TEXT,
        occupied_since INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    DatabaseHelper.instance.testDatabase = db;
  });

  group('Table Model', () {
    test('Create table with default values', () {
      final table = RestaurantTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
      );

      expect(table.id, 'T1');
      expect(table.name, 'Table 1');
      expect(table.capacity, 4);
      expect(table.status, TableStatus.available);
      expect(table.isAvailable, true);
      expect(table.orders, isEmpty);
    });

    test('Table occupancy calculation', () {
      final table = RestaurantTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
      );

      expect(table.currentOccupancy, 0);
      expect(table.occupancyPercentage, 0.0);
      expect(table.isAtCapacity, false);
      expect(table.isOverCapacity, false);
      expect(table.needsCapacityWarning, false);
    });

    test('Table status helpers', () {
      final available = RestaurantTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
        status: TableStatus.available,
      );

      expect(available.isAvailable, true);
      expect(available.isOccupied, false);
      expect(available.isReserved, false);

      final occupied = available.copyWith(status: TableStatus.occupied);
      expect(occupied.isOccupied, true);

      final reserved = available.copyWith(status: TableStatus.reserved);
      expect(reserved.isReserved, true);

      final merged = available.copyWith(status: TableStatus.merged);
      expect(merged.isMerged, true);

      final cleaning = available.copyWith(status: TableStatus.cleaning);
      expect(cleaning.isCleaning, true);
    });

    test('Table duration calculation', () async {
      final now = DateTime.now();
      final table = RestaurantTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
        occupiedSince: now.subtract(const Duration(minutes: 30)),
      );

      // Should be approximately 30 minutes (with small variance)
      expect(table.occupiedDurationMinutes, greaterThanOrEqualTo(29));
      expect(table.occupiedDurationMinutes, lessThanOrEqualTo(31));
    });

    test('Convert table to/from map', () {
      final original = RestaurantTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
        status: TableStatus.occupied,
        customerName: 'John Doe',
        customerPhone: '1234567890',
        notes: 'VIP Customer',
        createdAt: DateTime(2025, 1, 23),
        updatedAt: DateTime(2025, 1, 23),
      );

      final map = original.toMap();
      final restored = RestaurantTable.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.capacity, original.capacity);
      expect(restored.status, original.status);
      expect(restored.customerName, original.customerName);
      expect(restored.customerPhone, original.customerPhone);
      expect(restored.notes, original.notes);
    });

    test('Parse table status from string via fromMap', () {
      final availableMap = {
        'id': 'T1',
        'name': 'Table 1',
        'capacity': 4,
        'status': 'available',
      };
      var table = RestaurantTable.fromMap(availableMap);
      expect(table.status, TableStatus.available);

      final occupiedMap = {
        'id': 'T2',
        'name': 'Table 2',
        'capacity': 4,
        'status': 'occupied',
      };
      table = RestaurantTable.fromMap(occupiedMap);
      expect(table.status, TableStatus.occupied);

      final mergedMap = {
        'id': 'T3',
        'name': 'Table 3',
        'capacity': 4,
        'status': 'merged',
      };
      table = RestaurantTable.fromMap(mergedMap);
      expect(table.status, TableStatus.merged);

      final cleaningMap = {
        'id': 'T4',
        'name': 'Table 4',
        'capacity': 4,
        'status': 'cleaning',
      };
      table = RestaurantTable.fromMap(cleaningMap);
      expect(table.status, TableStatus.cleaning);

      final unknownMap = {
        'id': 'T5',
        'name': 'Table 5',
        'capacity': 4,
        'status': 'unknown',
      };
      table = RestaurantTable.fromMap(unknownMap);
      expect(table.status, TableStatus.available); // Default to available
    });
  });

  group('Table Management Service - CRUD', () {
    test('Create table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      final success = await service.createTable(
        id: 'T1',
        name: 'Table 1',
        capacity: 4,
      );

      expect(success, true);
      expect(service.tables.length, greaterThan(0));

      final table = service.getTableById('T1');
      expect(table, isNotNull);
      expect(table!.name, 'Table 1');
      expect(table.capacity, 4);
    });

    test('Create duplicate table fails', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T2', name: 'Table 2', capacity: 4);
      final result = await service.createTable(
        id: 'T2',
        name: 'Table 2',
        capacity: 4,
      );

      expect(result, false);
    });

    test('Update table information', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T3', name: 'Table 3', capacity: 4);

      final success = await service.updateTable(
        id: 'T3',
        customerName: 'Jane Smith',
        customerPhone: '0987654321',
        notes: 'Allergic to peanuts',
      );

      expect(success, true);

      final table = service.getTableById('T3');
      expect(table!.customerName, 'Jane Smith');
      expect(table.customerPhone, '0987654321');
      expect(table.notes, 'Allergic to peanuts');
    });

    test('Delete available table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T4', name: 'Table 4', capacity: 4);
      expect(service.getTableById('T4'), isNotNull);

      final success = await service.deleteTable('T4');
      expect(success, true);
      expect(service.getTableById('T4'), isNull);
    });

    test('Cannot delete occupied table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T5', name: 'Table 5', capacity: 4);
      await service.occupyTable('T5');

      final success = await service.deleteTable('T5');
      expect(success, false);

      expect(service.getTableById('T5'), isNotNull);
    });
  });

  group('Table Management Service - Status Operations', () {
    test('Occupy table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T6', name: 'Table 6', capacity: 4);
      await service.occupyTable('T6', customerName: 'John', customerPhone: '123');

      final table = service.getTableById('T6');
      expect(table!.isOccupied, true);
      expect(table.customerName, 'John');
      expect(table.customerPhone, '123');
      expect(table.occupiedSince, isNotNull);
    });

    test('Release table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T7', name: 'Table 7', capacity: 4);
      await service.occupyTable('T7');
      await service.releaseTable('T7');

      final table = service.getTableById('T7');
      expect(table!.isAvailable, true);
      expect(table.customerName, isNull);
      expect(table.occupiedSince, isNull);
    });

    test('Set table for cleaning', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T8', name: 'Table 8', capacity: 4);
      await service.setTableCleaning('T8');

      final table = service.getTableById('T8');
      expect(table!.isCleaning, true);
    });

    test('Reserve table', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'T9', name: 'Table 9', capacity: 4);
      await service.reserveTable(
        'T9',
        customerName: 'Smith',
        reservedUntil: DateTime.now().add(const Duration(hours: 2)),
      );

      final table = service.getTableById('T9');
      expect(table!.isReserved, true);
      expect(table.customerName, 'Smith');
    });
  });

  group('Table Management Service - Filtering', () {
    test('Get available tables', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'TA', name: 'Available', capacity: 4);
      await service.createTable(id: 'TB', name: 'Occupied', capacity: 4);
      await service.occupyTable('TB');

      final available = service.getAvailableTables();
      expect(available.any((t) => t.id == 'TA'), true);
      expect(available.any((t) => t.id == 'TB'), false);
    });

    test('Get occupied tables', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'TC', name: 'Occ1', capacity: 4);
      await service.occupyTable('TC');

      final occupied = service.getOccupiedTables();
      expect(occupied.any((t) => t.id == 'TC'), true);
    });

    test('Get reserved tables', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'TD', name: 'Reserved', capacity: 4);
      await service.reserveTable(
        'TD',
        customerName: 'Reserved',
        reservedUntil: DateTime.now().add(const Duration(hours: 1)),
      );

      final reserved = service.getReservedTables();
      expect(reserved.any((t) => t.id == 'TD'), true);
    });
  });

  group('Table Management Service - Statistics', () {
    test('Get table statistics', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'S1', name: 'Stat1', capacity: 4);
      await service.createTable(id: 'S2', name: 'Stat2', capacity: 4);
      await service.occupyTable('S2');

      final stats = service.getTableStatistics();
      expect(stats['total']!, greaterThanOrEqualTo(2));
      expect(stats['available']!, greaterThanOrEqualTo(1));
      expect(stats['occupied']!, greaterThanOrEqualTo(1));
    });

    test('Get average table duration', () async {
      final service = TableManagementService();
      await service.loadTablesFromDatabase();

      await service.createTable(id: 'D1', name: 'Dur1', capacity: 4);
      await service.occupyTable('D1');

      final avg = service.getAverageTableDuration();
      expect(avg, greaterThanOrEqualTo(0));
    });
  });
}
