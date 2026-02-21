import 'dart:io';

import 'package:extropos/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

    // Initialize database factory for tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getTestDatabasePath();
    _testDatabase = await openDatabase(
      dbPath,
      version: 26,
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
      // Replace the main database with test database
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
      // Clear existing data first
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
      // Clear in order of dependencies (reverse order)
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

  /// Reset test database (clear and repopulate)
  Future<void> resetTestDatabase() async {
    await clearTestData();
    await populateTestData();
  }

  /// Delete test database file completely
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
    // For tests, use in-memory database
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return inMemoryDatabasePath;
    }

    // For regular use, create file-based database
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _testDbName);
  }

  /// Create test database tables
  Future<void> _onCreateTestDatabase(Database db, int version) async {
    debugPrint('🏗️ Creating test database tables...');

    // Create basic tables for testing
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_code_point INTEGER,
        icon_font_family TEXT,
        color_value INTEGER,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        tax_rate REAL DEFAULT 0.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category_id TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        is_available INTEGER DEFAULT 1,
        is_featured INTEGER DEFAULT 0,
        stock INTEGER DEFAULT 0,
        track_stock INTEGER DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 5,
        cost REAL,
        image_url TEXT,
        tags TEXT,
        merchant_prices TEXT DEFAULT '{}',
        sort_order INTEGER DEFAULT 0,
        printer_override TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        email TEXT,
        role TEXT NOT NULL,
        pin TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        last_login_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        phone_number TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        status TEXT DEFAULT 'available',
        occupied_since TEXT,
        customer_name TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        is_default INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE printers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        ip_address TEXT,
        port INTEGER,
        device_id TEXT,
        device_name TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        paper_size TEXT DEFAULT 'mm80',
        status TEXT DEFAULT 'offline',
        has_permission INTEGER DEFAULT 1,
        categories TEXT DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_displays (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        ip_address TEXT,
        port INTEGER DEFAULT 9100,
        status TEXT DEFAULT 'offline',
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        has_permission INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE business_info (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        business_name TEXT NOT NULL,
        owner_name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        postcode TEXT,
        country TEXT DEFAULT 'Malaysia',
        registration_number TEXT,
        tax_number TEXT,
        tax_rate REAL DEFAULT 0.10,
        is_tax_enabled INTEGER DEFAULT 1,
        currency_symbol TEXT DEFAULT 'RM',
        is_service_charge_enabled INTEGER DEFAULT 1,
        service_charge_rate REAL DEFAULT 0.10,
        logo_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE user_activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        description TEXT,
        payment_method TEXT,
        discount_amount REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        tax_rate REAL DEFAULT 0.0,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  /// Upgrade test database
  Future<void> _onUpgradeTestDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('⬆️ Upgrading test database from $oldVersion to $newVersion');
    // For simplicity, just recreate tables for test database
    await _onCreateTestDatabase(db, newVersion);
  }

  /// Insert sample categories
  Future<void> _insertSampleCategories() async {
    final categories = [
      {
        'id': 'test_cat_beverages',
        'name': 'Beverages',
        'description': 'Hot and cold drinks',
        'icon_code_point': Icons.local_cafe.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF8B4513).value,
        'sort_order': 1,
        'is_active': 1,
      },
      {
        'id': 'test_cat_food',
        'name': 'Food',
        'description': 'Meals and main courses',
        'icon_code_point': Icons.restaurant.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFFFF6B35).value,
        'sort_order': 2,
        'is_active': 1,
      },
      {
        'id': 'test_cat_desserts',
        'name': 'Desserts',
        'description': 'Sweet treats and desserts',
        'icon_code_point': Icons.cake.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFFF72585).value,
        'sort_order': 3,
        'is_active': 1,
      },
      {
        'id': 'test_cat_appetizers',
        'name': 'Appetizers',
        'description': 'Starters and small plates',
        'icon_code_point': Icons.restaurant_menu.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF4CC9F0).value,
        'sort_order': 4,
        'is_active': 1,
      },
      {
        'id': 'test_cat_merchandise',
        'name': 'Merchandise',
        'description': 'Retail products and merchandise',
        'icon_code_point': Icons.shopping_bag.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF4361EE).value,
        'sort_order': 5,
        'is_active': 1,
      },
    ];

    for (final category in categories) {
      await _testDatabase!.insert('categories', category);
    }
  }

  /// Insert sample items
  Future<void> _insertSampleItems() async {
    final items = [
      // Beverages
      {
        'id': 'test_item_espresso',
        'name': 'Espresso',
        'description': 'Strong coffee shot',
        'category_id': 'test_cat_beverages',
        'price': 3.50,
        'cost': 0.80,
        'sku': 'BEV-ESP-001',
        'icon_code_point': Icons.coffee.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF8B4513).value,
        'stock': 100,
        'is_available': 1,
        'is_featured': 1,
        'track_stock': 0,
        'sort_order': 1,
      },
      {
        'id': 'test_item_cappuccino',
        'name': 'Cappuccino',
        'description': 'Espresso with steamed milk foam',
        'category_id': 'test_cat_beverages',
        'price': 4.50,
        'cost': 1.20,
        'sku': 'BEV-CAP-001',
        'icon_code_point': Icons.coffee.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF8B4513).value,
        'stock': 100,
        'is_available': 1,
        'is_featured': 1,
        'track_stock': 0,
        'sort_order': 2,
      },
      {
        'id': 'test_item_latte',
        'name': 'Latte',
        'description': 'Espresso with steamed milk',
        'category_id': 'test_cat_beverages',
        'price': 4.75,
        'cost': 1.50,
        'sku': 'BEV-LAT-001',
        'icon_code_point': Icons.coffee.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF8B4513).value,
        'stock': 100,
        'is_available': 1,
        'is_featured': 0,
        'track_stock': 0,
        'sort_order': 3,
      },
      {
        'id': 'test_item_iced_tea',
        'name': 'Iced Tea',
        'description': 'Refreshing iced tea',
        'category_id': 'test_cat_beverages',
        'price': 2.50,
        'cost': 0.50,
        'sku': 'BEV-ITE-001',
        'icon_code_point': Icons.local_drink.codePoint,
        'icon_font_family': 'MaterialIcons',
        'color_value': const Color(0xFF4CAF50).value,
        'stock': 50,
        'is_available': 1,
        'is_featured': 0,
        'track_stock': 1,
        'sort_order': 4,
      },
      // Add more items here as needed
    ];

    for (final item in items) {
      await _testDatabase!.insert('items', item);
    }
  }

  /// Insert sample users
  Future<void> _insertSampleUsers() async {
    final users = [
      {
        'id': 'test_user_admin',
        'username': 'admin',
        'full_name': 'Administrator',
        'email': 'admin@test.com',
        'role': 'admin',
        'pin': '1234',
        'status': 'active',
        'last_login_at': DateTime.now().toIso8601String(),
        'phone_number': null,
      },
      {
        'id': 'test_user_manager',
        'username': 'manager',
        'full_name': 'Manager',
        'email': 'manager@test.com',
        'role': 'manager',
        'pin': '5678',
        'status': 'active',
        'last_login_at': null,
        'phone_number': null,
      },
      {
        'id': 'test_user_cashier1',
        'username': 'cashier1',
        'full_name': 'Cashier One',
        'email': 'cashier1@test.com',
        'role': 'cashier',
        'pin': '1111',
        'status': 'active',
        'last_login_at': null,
        'phone_number': null,
      },
      {
        'id': 'test_user_cashier2',
        'username': 'cashier2',
        'full_name': 'Cashier Two',
        'email': 'cashier2@test.com',
        'role': 'cashier',
        'pin': '2222',
        'status': 'active',
        'last_login_at': null,
        'phone_number': null,
      },
    ];

    for (final user in users) {
      await _testDatabase!.insert('users', user);
    }
  }

  /// Insert sample tables
  Future<void> _insertSampleTables() async {
    final tables = [
      {
        'id': 'test_table_1',
        'name': 'Table 1',
        'capacity': 2,
        'status': 'available',
        'occupied_since': null,
        'customer_name': null,
      },
      {
        'id': 'test_table_2',
        'name': 'Table 2',
        'capacity': 4,
        'status': 'available',
        'occupied_since': null,
        'customer_name': null,
      },
      {
        'id': 'test_table_3',
        'name': 'Table 3',
        'capacity': 6,
        'status': 'available',
        'occupied_since': null,
        'customer_name': null,
      },
      {
        'id': 'test_table_4',
        'name': 'Table 4',
        'capacity': 2,
        'status': 'available',
        'occupied_since': null,
        'customer_name': null,
      },
      {
        'id': 'test_table_5',
        'name': 'Bar Counter',
        'capacity': 8,
        'status': 'available',
        'occupied_since': null,
        'customer_name': null,
      },
    ];

    for (final table in tables) {
      await _testDatabase!.insert('tables', table);
    }
  }

  /// Insert sample payment methods
  Future<void> _insertSamplePaymentMethods() async {
    final paymentMethods = [
      {
        'id': 'test_pm_cash',
        'name': 'Cash',
        'status': 'active',
        'is_default': 1,
      },
      {
        'id': 'test_pm_card',
        'name': 'Credit Card',
        'status': 'active',
        'is_default': 0,
      },
      {
        'id': 'test_pm_wallet',
        'name': 'Digital Wallet',
        'status': 'active',
        'is_default': 0,
      },
    ];

    for (final pm in paymentMethods) {
      await _testDatabase!.insert('payment_methods', pm);
    }
  }

  /// Insert sample printers
  Future<void> _insertSamplePrinters() async {
    final now = DateTime.now().toIso8601String();
    final printers = [
      {
        'id': 'test_printer_receipt',
        'name': 'Receipt Printer',
        'type': 'receipt',
        'connection_type': 'usb',
        'ip_address': null,
        'port': null,
        'device_id': 'USB001',
        'device_name': 'EPSON TM-T88V',
        'is_default': 1,
        'is_active': 1,
        'paper_size': 'mm58',
        'status': 'offline',
        'has_permission': 1,
        'categories': '[]',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'test_printer_kitchen',
        'name': 'Kitchen Printer',
        'type': 'kitchen',
        'connection_type': 'network',
        'ip_address': '192.168.1.100',
        'port': 9100,
        'device_id': null,
        'device_name': 'Star Micronics TSP100',
        'is_default': 0,
        'is_active': 1,
        'paper_size': 'mm80',
        'status': 'offline',
        'has_permission': 1,
        'categories': '["food","beverages"]',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final printer in printers) {
      await _testDatabase!.insert('printers', printer);
    }
  }

  /// Insert sample customer displays
  Future<void> _insertSampleCustomerDisplays() async {
    final displays = [
      {
        'id': 'test_display_main',
        'name': 'Main Customer Display',
        'connection_type': 'network',
        'ip_address': '192.168.1.101',
        'port': 8080,
        'status': 'offline',
        'is_default': 1,
        'is_active': 1,
        'has_permission': 1,
      },
    ];

    for (final display in displays) {
      await _testDatabase!.insert('customer_displays', display);
    }
  }

  /// Insert sample business info
  Future<void> _insertSampleBusinessInfo() async {
    final businessInfo = {
      'id': 1,
      'business_name': 'FlutterPOS Test Restaurant',
      'owner_name': 'Test Owner',
      'email': 'test@flutterpos.com',
      'phone': '+1 (555) 123-4567',
      'address': '123 Test Street',
      'city': 'Test City',
      'state': 'Test State',
      'postcode': '12345',
      'country': 'Malaysia',
      'registration_number': 'REG123456789',
      'tax_number': 'TAX123456789',
      'tax_rate': 0.06,
      'is_tax_enabled': 1,
      'currency_symbol': 'RM',
      'is_service_charge_enabled': 1,
      'service_charge_rate': 0.10,
      'logo_path': null,
    };

    await _testDatabase!.insert('business_info', businessInfo);
  }
}
