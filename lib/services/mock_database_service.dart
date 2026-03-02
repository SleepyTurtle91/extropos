import 'dart:convert';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Service to restore mock database data for retail and restaurant modes
/// Loads training data from JSON files for easy maintenance and updates
class MockDatabaseService {
  static final MockDatabaseService instance = MockDatabaseService._init();
  MockDatabaseService._init();

  /// Restore complete mock database for retail mode
  Future<void> restoreRetailMockData() async {
    await _loadAndRestoreFromJson('assets/training_data/retail_training_database.json');
  }

  /// Restore complete mock database for restaurant mode
  Future<void> restoreRestaurantMockData() async {
    await _loadAndRestoreFromJson('assets/training_data/restaurant_training_database.json');
  }

  /// Load and restore database from JSON file
  Future<void> _loadAndRestoreFromJson(String assetPath) async {
    try {
      // Load JSON file
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = json.decode(jsonString);

      // Clear all existing data
      await _clearAllData();

      // Get database instance
      final db = await DatabaseHelper.instance.database;

      // Insert data in correct order (respecting foreign keys)
      await _insertTableData(db, 'business_info', data['business_info']);
      await _insertTableData(db, 'categories', data['categories']);
      await _insertTableData(db, 'items', data['items']);
      await _insertTableData(db, 'users', data['users']);
      await _insertTableData(db, 'tables', data['tables']);
      await _insertTableData(db, 'payment_methods', data['payment_methods']);
      await _insertTableData(db, 'printers', data['printers']);
      await _insertTableData(db, 'customers', data['customers']);
      await _insertTableData(db, 'modifier_groups', data['modifier_groups']);
      await _insertTableData(db, 'modifier_items', data['modifier_items']);
      await _insertTableData(db, 'receipt_settings', data['receipt_settings']);
      await _insertTableData(db, 'discounts', data['discounts']);

      print('✅ Mock database restored successfully from $assetPath');
    } catch (e) {
      print('❌ Error loading mock database: $e');
      rethrow;
    }
  }

  /// Insert data into a specific table
  Future<void> _insertTableData(
    Database db,
    String tableName,
    dynamic tableData,
  ) async {
    if (tableData == null) return;

    final List<Map<String, dynamic>> rows = tableData is List
        ? List<Map<String, dynamic>>.from(tableData)
        : [Map<String, dynamic>.from(tableData)];

    for (final row in rows) {
      await db.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Inserted ${rows.length} rows into $tableName');
  }

  /// Clear all data from database
  Future<void> _clearAllData() async {
    final db = await DatabaseHelper.instance.database;

    // Delete in reverse order of dependencies
    final tables = [
      'payment_splits',
      'transactions',
      'order_items',
      'orders',
      'inventory_adjustments',
      'cash_sessions',
      'shifts',
      'user_activity_log',
      'audit_log',
      'item_modifiers',
      'modifier_items',
      'modifier_groups',
      'discounts',
      'items',
      'categories',
      'customers',
      'customer_displays',
      'printers',
      // Keep payment_methods as they are seeded by default
      'tables',
      'users',
      'receipt_settings',
      'business_info',
    ];

    for (final table in tables) {
      try {
        await db.delete(table);
      } catch (e) {
        // Table might not exist, continue
        print('Warning: Could not clear table $table: $e');
      }
    }
    print('✅ All data cleared from database');
  }
}