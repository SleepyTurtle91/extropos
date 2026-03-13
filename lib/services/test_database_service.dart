import 'dart:io';

import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/sqlite3_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

part 'test_database_service_schemas.dart';
part 'test_database_service_data.dart';

/// Service for managing test databases with comprehensive sample data
class TestDatabaseService {
  static final TestDatabaseService instance = TestDatabaseService._init();
  TestDatabaseService._init();

  static const String _testDbName = 'flutterpos_test.db';
  Database? _testDatabase;
  bool _isTestMode = false;

  bool get isTestMode => _isTestMode;
  Database? get testDatabase => _testDatabase;

  /// Initialize test database
  Future<void> initializeTestDatabase() async {
    if (_testDatabase != null) return;

    await SQLite3Bootstrap.ensureInitialized();

    final dbPath = await _getTestDatabasePath();
    _testDatabase = await openDatabase(
      dbPath,
      version: 26,
      onConfigure: SQLite3Bootstrap.configureDatabase,
      onCreate: _onCreateTestDatabase,
      onUpgrade: _onUpgradeTestDatabase,
    );

    _isTestMode = true;
    debugPrint('✅ Test database initialized at: $dbPath');
  }

  /// Switch to test database
  Future<void> switchToTestDatabase() async {
    await initializeTestDatabase();
    if (_testDatabase != null) {
      DatabaseHelper.instance.testDatabase = _testDatabase;
      _isTestMode = true;
      debugPrint('🔄 Switched to test database');
    }
  }

  /// Switch back to production database
  Future<void> switchToProductionDatabase() async {
    DatabaseHelper.instance.testDatabase = null;
    _isTestMode = false;
    debugPrint('🔄 Switched to production database');
  }

  /// Populate test database with comprehensive sample data
  Future<void> populateTestData() async {
    if (_testDatabase == null) await initializeTestDatabase();
    if (_testDatabase == null) return;

    debugPrint('📝 Populating test database with sample data...');

    try {
      await _clearExistingData();
      await _insertSampleCategories();
      await _insertSampleItems();
      await _insertSampleUsers();
      await _insertSampleTables();
      await _insertSamplePaymentMethods();
      await _insertSamplePrinters();
      await _insertSampleCustomerDisplays();
      await _insertSampleBusinessInfo();
      debugPrint('✅ Test database populated successfully');
    } catch (e) {
      debugPrint('❌ Error populating test database: $e');
      rethrow;
    }
  }

  /// Clear all existing test data
  Future<void> _clearExistingData() async {
    if (_testDatabase == null) return;
    await _testDatabase!.delete('business_info');
    await _testDatabase!.delete('customer_displays');
    await _testDatabase!.delete('printers');
    await _testDatabase!.delete('payment_methods');
    await _testDatabase!.delete('tables');
    await _testDatabase!.delete('users');
    await _testDatabase!.delete('items');
    await _testDatabase!.delete('categories');
  }

  /// Clear all test data
  Future<void> clearTestData() async {
    if (_testDatabase == null) return;
    debugPrint('🧹 Clearing test database...');
    try {
      await _testDatabase!.delete('customer_displays');
      await _testDatabase!.delete('printers');
      await _testDatabase!.delete('payment_methods');
      await _testDatabase!.delete('tables');
      await _testDatabase!.delete('users');
      await _testDatabase!.delete('items');
      await _testDatabase!.delete('categories');
      await _testDatabase!.delete('business_info');
      debugPrint('✅ Test database cleared');
    } catch (e) {
      debugPrint('❌ Error clearing test database: $e');
      rethrow;
    }
  }

  /// Reset test database
  Future<void> resetTestDatabase() async {
    await clearTestData();
    await populateTestData();
  }

  /// Delete test database file
  Future<void> deleteTestDatabase() async {
    final dbPath = await _getTestDatabasePath();
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ Test database file deleted');
    }
    _testDatabase = null;
    _isTestMode = false;
  }

  /// Get test database path
  Future<String> _getTestDatabasePath() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return inMemoryDatabasePath;
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _testDbName);
  }

  /// Upgrade test database
  Future<void> _onUpgradeTestDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('⬆️ Upgrading test database from $oldVersion to $newVersion');
    await _onCreateTestDatabase(db, newVersion);
  }
}
