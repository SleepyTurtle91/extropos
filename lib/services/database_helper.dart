import 'package:extropos/services/pin_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:universal_io/io.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // Optional override for database file path (used by tests to isolate DB files)
  static String? _overrideDatabaseFilePath;
  // Optional test database override
  static Database? _testDatabase;

  DatabaseHelper._init();

  // Test database override setter
  set testDatabase(Database? db) {
    _testDatabase = db;
  }

  Future<Database> get database async {
    // Return test database if set
    if (_testDatabase != null) return _testDatabase!;

    if (_database != null) return _database!;

    // Initialize FFI for Web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    // Initialize FFI for desktop platforms if not already initialized
    else if (Platform.isWindows || Platform.isLinux) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print(
          '✅ DatabaseHelper: SQLite FFI initialized for Desktop (Linux/Windows)',
        );
      } catch (e) {
        print('❌ DatabaseHelper: Failed to initialize SQLite FFI: $e');
      }
    }

    _database = await _initDB('extropos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      // On Web, just use the filename. sqflite_common_ffi_web handles it.
      path = filePath;
    } else {
      path =
          _overrideDatabaseFilePath ?? join(await getDatabasesPath(), filePath);
    }

    // Check database integrity before opening (skip on Web)
    if (!kIsWeb) {
      await _checkDatabaseIntegrity(path);
    }

    return await openDatabase(
      path,
      // Phase 1 features: MyInvois, E-Wallet, Loyalty, PDPA, Inventory
      // v34: Table Management System (restaurant mode)
      version: 34,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onDowngrade: _onDowngrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // v34: Table Management System
    if (oldVersion < 34) {
      try {
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
      } catch (_) {}
    }
    // v33: E-Wallet QR expiry tracking
    if (oldVersion < 33) {
      try { await db.execute('ALTER TABLE e_wallet_transactions ADD COLUMN qr_expires_at INTEGER'); } catch (_) {}
    }
    // v32: E-Wallet provider + webhook columns
    if (oldVersion < 32) {
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN provider TEXT DEFAULT \'duitnow\''); } catch (_) {}
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN callback_url TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN webhook_secret TEXT'); } catch (_) {}
    }
    // Create backup before migration (skip on Web)
    if (!kIsWeb) {
      try {
        await _createBackupBeforeMigration();
      } catch (e) {
        // Log but don't fail migration
        // Warning: Could not create backup before migration: $e
      }
    }

    // Handle database upgrades here
    if (oldVersion < 2) {
      // v2: Add show_service_charge_breakdown column to receipt_settings
      await db.execute(
        'ALTER TABLE receipt_settings ADD COLUMN show_service_charge_breakdown INTEGER DEFAULT 1',
      );
      // Optionally update timestamps
      await db.execute(
        "UPDATE receipt_settings SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
      );
    }

    if (oldVersion < 3) {
      // v3: Add category_ids column to modifier_groups
      await db.execute(
        "ALTER TABLE modifier_groups ADD COLUMN category_ids TEXT DEFAULT ''",
      );
      // Update timestamps
      await db.execute(
        "UPDATE modifier_groups SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
      );
    }

    if (oldVersion < 4) {
      // v4: Add compatibility columns to tables to support newer code that
      // expects `name`, `capacity`, `occupied_since`, and `customer_name`.
      // Keep original `number` and `seats` columns for backward compatibility.
      try {
        await db.execute("ALTER TABLE tables ADD COLUMN name TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE tables ADD COLUMN capacity INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tables ADD COLUMN occupied_since TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tables ADD COLUMN customer_name TEXT');
      } catch (_) {}

      // Migrate existing values from number/seats where available
      try {
        await db.execute(
          "UPDATE tables SET name = 'Table ' || number WHERE (name IS NULL OR name = '') AND number IS NOT NULL",
        );
      } catch (_) {}
      try {
        await db.execute(
          'UPDATE tables SET capacity = seats WHERE (capacity IS NULL OR capacity = 0) AND seats IS NOT NULL',
        );
      } catch (_) {}
    }

    if (oldVersion < 5) {
      // v5: Remove plaintext `pin` column from users table. PINs are now
      // persisted in the encrypted Hive PinStore. SQLite doesn't support
      // dropping a column directly, so recreate the users table without the
      // `pin` column and copy over data.
      try {
        // If there are plaintext pins in the existing DB, move them into the
        // PinStore first (PinStore should be initialized by main before DB open).
        try {
          final List<Map<String, Object?>> rows = await db.query(
            'users',
            columns: ['id', 'pin'],
          );
          for (final r in rows) {
            final id = (r['id'] ?? '').toString();
            final pin = (r['pin'] as String?) ?? '';
            if (id.isNotEmpty && pin.isNotEmpty) {
              try {
                await PinStore.instance.setPinForUser(id, pin);
              } catch (_) {}
            }
          }
        } catch (_) {
          // If the column doesn't exist or query fails, continue — we'll still
          // proceed to recreate the table without the column below.
        }

        // Create a new users table WITHOUT the plaintext 'pin' column.
        await db.execute('''
          CREATE TABLE users_new (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT,
            role TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Copy existing user data into the new table but deliberately omit
        // the legacy 'pin' column so plaintext pins are removed from SQLite.
        await db.execute('''
          INSERT INTO users_new (id, name, email, role, is_active, created_at, updated_at)
          SELECT id, name, email, role, is_active, created_at, updated_at FROM users
        ''');

        await db.execute('DROP TABLE users');
        await db.execute('ALTER TABLE users_new RENAME TO users');

        // Recreate users indexes that might have been dropped during table swap
        try {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)',
          );
        } catch (_) {}
      } catch (_) {
        // If migration fails for any reason, ignore and allow older codepaths to continue.
      }
    }

    if (oldVersion < 6) {
      // v6: Recreate tables table with correct schema to match RestaurantTable model
      // The old schema used 'number' and 'seats' but the model expects 'name' and 'capacity'
      try {
        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE tables_new (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            capacity INTEGER NOT NULL,
            status TEXT NOT NULL,
            section TEXT,
            occupied_since TEXT,
            customer_name TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Migrate data from old table if it exists
        try {
          await db.execute('''
            INSERT INTO tables_new (id, name, capacity, status, section, created_at, updated_at)
            SELECT id, 
                   CASE WHEN number IS NOT NULL THEN 'Table ' || number ELSE 'Table' END,
                   CASE WHEN seats IS NOT NULL THEN seats ELSE 4 END,
                   CASE 
                     WHEN status = 0 THEN 'available'
                     WHEN status = 1 THEN 'occupied' 
                     WHEN status = 2 THEN 'reserved'
                     ELSE 'available'
                   END,
                   section, created_at, updated_at
            FROM tables
          ''');
        } catch (_) {
          // If old table doesn't exist or migration fails, continue with empty new table
        }

        // Replace old table with new one
        await db.execute('DROP TABLE IF EXISTS tables');
        await db.execute('ALTER TABLE tables_new RENAME TO tables');

        // Recreate indexes
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tables_status ON tables(status)',
        );
      } catch (_) {
        // If migration fails, the onCreate will create the correct schema
      }
    }

    if (oldVersion < 16) {
      // v16: Add seat_number to order_items to support seat-based splits
      try {
        await db.execute(
          'ALTER TABLE order_items ADD COLUMN seat_number INTEGER',
        );
      } catch (_) {}
    }

    if (oldVersion < 17) {
      // v17: Add customer_displays table for customer-facing displays
      try {
        await db.execute('''
          CREATE TABLE customer_displays (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            connection_type TEXT NOT NULL,
            ip_address TEXT,
            port INTEGER,
            usb_device_id TEXT,
            bluetooth_address TEXT,
            platform_specific_id TEXT,
            device_name TEXT,
            is_default INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            status TEXT DEFAULT 'offline',
            has_permission INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 18) {
      // v18: Add categories column to printers for kitchen/bar category filtering
      try {
        await db.execute(
          "ALTER TABLE printers ADD COLUMN categories TEXT DEFAULT '[]'",
        );
      } catch (_) {}
    }

    if (oldVersion < 19) {
      // v19: Add printer_override column to items for per-item printer selection
      try {
        await db.execute('ALTER TABLE items ADD COLUMN printer_override TEXT');
      } catch (_) {}
    }

    if (oldVersion < 20) {
      // v20: Add pin column to users table for PinStore fallback mechanism
      // This allows PIN storage in database when encrypted PinStore fails
      try {
        await db.execute("ALTER TABLE users ADD COLUMN pin TEXT DEFAULT ''");
        // Note: Existing PINs are in PinStore, this column is only for fallback
      } catch (_) {
        // Column may already exist, ignore error
      }
    }

    if (oldVersion < 21) {
      // v21: Add customers table for customer management
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          total_spent REAL DEFAULT 0,
          visit_count INTEGER DEFAULT 0,
          loyalty_points INTEGER DEFAULT 0,
          last_visit TEXT,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for customers
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_email ON customers (email)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_active ON customers (is_active)',
        );
      } catch (_) {}
    }

    if (oldVersion < 22) {
      // v22: Add order status tracking for kitchen display system
      try {
        // Add sent_to_kitchen_at timestamp
        await db.execute(
          'ALTER TABLE orders ADD COLUMN sent_to_kitchen_at TEXT',
        );
      } catch (_) {
        // Column may already exist, ignore error
      }

      // Create order_status_history table for audit trail
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS order_status_history (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL,
            status TEXT NOT NULL,
            changed_by TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_order_status_history_order ON order_status_history (order_id)',
        );
      } catch (_) {}

      // Create index on orders.status for efficient kitchen display queries
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status)',
        );
      } catch (_) {}
    }

    if (oldVersion < 23) {
      // v23: Add advanced reporting tables (scheduled reports, forecasting, custom templates)
      try {
        // Scheduled reports table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS scheduled_reports (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            report_type TEXT NOT NULL,
            period_type TEXT,
            period_start TEXT,
            period_end TEXT,
            period_label TEXT,
            frequency TEXT NOT NULL,
            recipient_emails TEXT NOT NULL,
            export_formats TEXT NOT NULL,
            custom_filters TEXT,
            is_active INTEGER DEFAULT 1,
            next_run TEXT,
            last_run TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scheduled_reports_next_run ON scheduled_reports(next_run)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scheduled_reports_is_active ON scheduled_reports(is_active)',
        );

        // Report execution history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS report_execution_history (
            id TEXT PRIMARY KEY,
            scheduled_report_id TEXT NOT NULL,
            executed_at TEXT NOT NULL,
            status TEXT NOT NULL,
            error_message TEXT,
            report_data TEXT,
            export_paths TEXT,
            execution_time_ms INTEGER,
            FOREIGN KEY (scheduled_report_id) REFERENCES scheduled_reports(id) ON DELETE CASCADE
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_execution_history_scheduled_report ON report_execution_history(scheduled_report_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_execution_history_executed_at ON report_execution_history(executed_at)',
        );

        // Forecast models table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS forecast_models (
            id TEXT PRIMARY KEY,
            model_type TEXT NOT NULL,
            parameters TEXT NOT NULL,
            accuracy REAL,
            generated_at TEXT NOT NULL,
            forecast_start TEXT NOT NULL,
            forecast_end TEXT NOT NULL,
            historical_period_start TEXT NOT NULL,
            historical_period_end TEXT NOT NULL,
            confidence_interval REAL,
            is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_forecast_models_generated_at ON forecast_models(generated_at)',
        );

        // Custom report templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS custom_report_templates (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            selected_metrics TEXT NOT NULL,
            group_by_fields TEXT,
            filters TEXT,
            sorting TEXT,
            created_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            is_shared INTEGER DEFAULT 0
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_custom_templates_created_by ON custom_report_templates(created_by)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_custom_templates_is_shared ON custom_report_templates(is_shared)',
        );
      } catch (e) {
        // Log error but don't fail migration
        print('Error creating advanced reporting tables: $e');
      }
    }

    if (oldVersion < 24) {
      // v24: Add dealer_customers table for SaaS tenant management
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS dealer_customers (
            id TEXT PRIMARY KEY,
            business_name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            phone TEXT NOT NULL,
            address TEXT NOT NULL,
            city TEXT NOT NULL,
            state TEXT NOT NULL,
            postcode TEXT NOT NULL,
            country TEXT DEFAULT 'Malaysia',
            registration_number TEXT,
            tax_number TEXT,
            website TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Create indexes for dealer customers
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_dealer_customers_email ON dealer_customers(email)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_dealer_customers_business_name ON dealer_customers(business_name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_dealer_customers_active ON dealer_customers(is_active)',
        );
      } catch (e) {
        // Log error but don't fail migration
        print('Error creating dealer_customers table: $e');
      }
    }

    if (oldVersion < 25) {
      // v25: Add tenants table for linking customers to tenant databases
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tenants (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            tenant_name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            owner_email TEXT NOT NULL,
            custom_domain TEXT,
            api_key TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES dealer_customers (id) ON DELETE CASCADE
          )
        ''');

        // Create indexes for tenants
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tenants_customer_id ON tenants(customer_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tenants_owner_email ON tenants(owner_email)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tenants_active ON tenants(is_active)',
        );
      } catch (e) {
        // Log error but don't fail migration
        print('Error creating tenants table: $e');
      }
    }

    if (oldVersion < 26) {
      // v26: Add shifts table and shift_id to orders
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS shifts (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            business_session_id INTEGER,
            start_time TEXT NOT NULL,
            end_time TEXT,
            opening_cash REAL NOT NULL,
            closing_cash REAL,
            expected_cash REAL,
            notes TEXT,
            status TEXT DEFAULT 'active',
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Add shift_id to orders table
        try {
          await db.execute('ALTER TABLE orders ADD COLUMN shift_id TEXT');
          await db.execute('CREATE INDEX idx_orders_shift ON orders(shift_id)');
        } catch (_) {
          // Column might already exist
        }
      } catch (e) {
        print('Error creating shifts table: $e');
      }
    }

    if (oldVersion < 7) {
      // v7: Enhance users table to support full User model fields
      // Add missing columns: username, phone_number, last_login_at
      try {
        await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN phone_number TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN last_login_at TEXT');

        // Migrate existing name values to both username and name (for backward compatibility)
        // For now, keep name as fullName and set username to empty or derived value
        await db.execute(
          "UPDATE users SET username = '' WHERE username IS NULL",
        );

        // Update timestamps
        await db.execute(
          "UPDATE users SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
        );
      } catch (_) {
        // If migration fails, continue - new columns will be created by onCreate if needed
      }
    }

    if (oldVersion < 8) {
      // v8: Add business_sessions table for business session management
      try {
        await db.execute('''
          CREATE TABLE business_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            open_date TEXT NOT NULL,
            close_date TEXT,
            opening_cash REAL NOT NULL,
            closing_cash REAL,
            expected_cash REAL,
            notes TEXT,
            is_open INTEGER DEFAULT 1
          )
        ''');
      } catch (_) {
        // If migration fails, continue - table will be created by onCreate if needed
      }
    }

    if (oldVersion < 9) {
      // v9: Add paper_size column to printers table
      try {
        await db.execute(
          "ALTER TABLE printers ADD COLUMN paper_size TEXT DEFAULT 'mm80'",
        );
        // Update timestamps for existing records
        await db.execute(
          "UPDATE printers SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
        );
      } catch (_) {
        // If migration fails, continue - column will be created by onCreate if needed
      }
    }

    if (oldVersion < 10) {
      // v10: Add status column to printers table
      try {
        await db.execute(
          "ALTER TABLE printers ADD COLUMN status TEXT DEFAULT 'offline'",
        );
        // Update timestamps for existing records
        await db.execute(
          "UPDATE printers SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
        );
      } catch (_) {
        // If migration fails, continue - column will be created by onCreate if needed
      }
    }

    if (oldVersion < 11) {
      // v11: Add has_permission column to printers table
      try {
        await db.execute(
          'ALTER TABLE printers ADD COLUMN has_permission INTEGER DEFAULT 1',
        );
        // Update timestamps for existing records
        await db.execute(
          "UPDATE printers SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
        );
      } catch (_) {
        // If migration fails, continue - column will be created by onCreate if needed
      }
    }

    if (oldVersion < 12) {
      // v12: Add customer information fields to orders table
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN customer_name TEXT');
        await db.execute('ALTER TABLE orders ADD COLUMN customer_phone TEXT');
        await db.execute('ALTER TABLE orders ADD COLUMN customer_email TEXT');
        await db.execute(
          'ALTER TABLE orders ADD COLUMN special_instructions TEXT',
        );

        // Update timestamps for existing records
        await db.execute(
          "UPDATE orders SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE updated_at IS NOT NULL",
        );
      } catch (_) {
        // If migration fails, continue - new columns will be created by onCreate if needed
      }
    }

    if (oldVersion < 13) {
      // v13: Add low stock threshold to items table
      try {
        await db.execute(
          'ALTER TABLE items ADD COLUMN low_stock_threshold INTEGER DEFAULT 5',
        );

        // Update timestamps for existing records
        await db.execute(
          "UPDATE items SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE updated_at IS NOT NULL",
        );
      } catch (_) {
        // If migration fails, continue - new column will be created by onCreate if needed
      }
    }

    if (oldVersion < 14) {
      // v14: Enable auto print by default for existing receipt settings
      try {
        await db.execute(
          'UPDATE receipt_settings SET auto_print = 1 WHERE auto_print = 0',
        );

        // Update timestamps for existing records
        await db.execute(
          "UPDATE receipt_settings SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
        );
      } catch (_) {
        // If migration fails, continue - auto print will be enabled by default in new installations
      }
    }

    if (oldVersion < 15) {
      // v15: Add merchant pricing for items and merchant_id on orders
      try {
        await db.execute(
          "ALTER TABLE items ADD COLUMN merchant_prices TEXT DEFAULT '{}'",
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN merchant_id TEXT');
      } catch (_) {}
    }

    if (oldVersion < 27) {
      // v27: Add variance tracking columns to shifts table for Malaysian POS compliance
      try {
        await db.execute('ALTER TABLE shifts ADD COLUMN variance REAL');
        await db.execute(
          'ALTER TABLE shifts ADD COLUMN variance_acknowledged INTEGER DEFAULT 0',
        );
      } catch (_) {
        // Columns might already exist
      }
    }

    if (oldVersion < 28) {
      // v28: Add tax_rate to categories and expand user_activity_log for daily staff performance reports
      try {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN tax_rate REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN payment_method TEXT',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN discount_amount REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN tax_amount REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN tax_rate REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN order_id TEXT',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute(
          'ALTER TABLE user_activity_log ADD COLUMN amount REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
    }

    if (oldVersion < 29) {
      // v29: Add service_charge column to orders table
      try {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN service_charge REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
    }

    if (oldVersion < 30) {
      // v30: Ensure service_charge exists for any databases created without it at v29
      try {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN service_charge REAL DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
    }

    if (oldVersion < 31) {
      // v31: Phase 1 Malaysian Features - MyInvois, E-Wallet, Loyalty, PDPA, Inventory
      print('🔄 Starting Phase 1 migration (v31)...');
      
      try {
        // ==================== MyInvois e-Invoice ====================
        print('  📝 Creating MyInvois tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS invoices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL UNIQUE,
            invoice_number TEXT NOT NULL UNIQUE,
            document_uuid TEXT UNIQUE,
            status TEXT NOT NULL DEFAULT 'pending',
            submission_date INTEGER,
            acceptance_date INTEGER,
            rejection_reason TEXT,
            qr_code BLOB,
            is_synced INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS invoice_sequences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            sequence_number INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS invoice_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL,
            invoice_data TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_retry_at INTEGER,
            error_message TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        // ==================== E-Wallet Payments ====================
        print('  💳 Creating E-Wallet tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS e_wallet_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            amount REAL NOT NULL,
            reference_id TEXT,
            auth_code TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            gateway_response TEXT,
            refund_amount REAL DEFAULT 0.0,
            refund_reference TEXT,
            refund_date INTEGER,
            qr_expires_at INTEGER,
            is_synced INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS e_wallet_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payment_method TEXT NOT NULL UNIQUE,
            provider TEXT DEFAULT 'duitnow',
            merchant_id TEXT,
            api_key TEXT,
            client_id TEXT,
            client_secret TEXT,
            callback_url TEXT,
            webhook_secret TEXT,
            use_sandbox INTEGER DEFAULT 1,
            is_enabled INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // ==================== Restaurant Table Management ====================
        print('  🍽️  Creating Restaurant Table Management tables...');
        
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

        // ==================== Loyalty Program ====================
        print('  🎁 Creating Loyalty Program tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS loyalty_programs (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            is_enabled INTEGER DEFAULT 1,
            points_per_rm_spent REAL DEFAULT 1.0,
            redemption_value REAL DEFAULT 0.10,
            award_on_tax INTEGER DEFAULT 0,
            exempt_categories TEXT,
            min_points_to_redeem INTEGER DEFAULT 100,
            points_expiry_months INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS loyalty_tiers (
            id TEXT PRIMARY KEY,
            program_id TEXT NOT NULL,
            name TEXT NOT NULL,
            min_spend REAL NOT NULL,
            discount_percentage REAL DEFAULT 0.0,
            benefits TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_loyalty (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL UNIQUE,
            accumulated_points REAL DEFAULT 0.0,
            current_tier TEXT DEFAULT 'bronze',
            total_spent REAL DEFAULT 0.0,
            join_date INTEGER NOT NULL,
            last_purchase_date INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS loyalty_transactions (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            type TEXT NOT NULL,
            points REAL NOT NULL,
            description TEXT,
            transaction_id TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        // ==================== PDPA Compliance ====================
        print('  🔒 Creating PDPA Compliance tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audit_logs (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            action TEXT NOT NULL,
            details TEXT,
            customer_id TEXT,
            ip_address TEXT,
            timestamp INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_consents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id TEXT NOT NULL,
            consent_type TEXT NOT NULL,
            granted INTEGER NOT NULL,
            recorded_at INTEGER NOT NULL,
            expires_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS data_deletion_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id TEXT NOT NULL,
            requested_by TEXT NOT NULL,
            request_date INTEGER NOT NULL,
            processed_date INTEGER,
            status TEXT DEFAULT 'pending',
            notes TEXT
          )
        ''');

        // ==================== Inventory Management ====================
        print('  📦 Creating Inventory Management tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inventory (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL UNIQUE,
            product_name TEXT NOT NULL,
            current_quantity REAL DEFAULT 0.0,
            min_stock_level REAL DEFAULT 0.0,
            max_stock_level REAL DEFAULT 0.0,
            reorder_quantity REAL DEFAULT 0.0,
            cost_per_unit REAL,
            last_stock_count_date INTEGER,
            unit TEXT DEFAULT 'pcs',
            is_synced INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS stock_movements (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            reason TEXT NOT NULL,
            date INTEGER NOT NULL,
            user_id TEXT,
            reference_id TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS purchase_orders (
            id TEXT PRIMARY KEY,
            po_number TEXT NOT NULL UNIQUE,
            supplier_id TEXT NOT NULL,
            supplier_name TEXT NOT NULL,
            total_amount REAL NOT NULL,
            status TEXT DEFAULT 'draft',
            order_date INTEGER NOT NULL,
            expected_delivery_date INTEGER,
            received_date INTEGER,
            notes TEXT,
            is_synced INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS purchase_order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_cost REAL NOT NULL,
            total_cost REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS suppliers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            contact_person TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            address TEXT NOT NULL,
            tax_number TEXT,
            is_active INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // ==================== Offline Sync Queue ====================
        print('  🔄 Creating Offline Sync tables...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_queue (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            priority INTEGER DEFAULT 2,
            data TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_retry_at INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total_queued INTEGER DEFAULT 0,
            total_synced INTEGER DEFAULT 0,
            total_failed INTEGER DEFAULT 0,
            last_successful_sync INTEGER,
            updated_at INTEGER NOT NULL
          )
        ''');

        // ==================== Create Indexes ====================
        print('  🗂️  Creating indexes...');
        
        // MyInvois indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_transaction ON invoices(transaction_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(submission_date)');

        // E-wallet indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ewallet_transaction ON e_wallet_transactions(transaction_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ewallet_status ON e_wallet_transactions(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ewallet_method ON e_wallet_transactions(payment_method)');

        // Loyalty indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_loyalty_customer ON customer_loyalty(customer_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_loyalty_tier ON customer_loyalty(current_tier)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_loyalty_trans_customer ON loyalty_transactions(customer_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_loyalty_trans_date ON loyalty_transactions(created_at)');

        // PDPA indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_customer ON audit_logs(customer_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_logs(timestamp)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_consents_customer ON customer_consents(customer_id)');

        // Inventory indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory(product_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_low_stock ON inventory(current_quantity, min_stock_level)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movement_product ON stock_movements(product_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movement_date ON stock_movements(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_po_status ON purchase_orders(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_po_supplier ON purchase_orders(supplier_id)');

        // Sync queue indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_type ON sync_queue(type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_priority ON sync_queue(priority)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at)');

        // ==================== Insert Default Data ====================
        print('  📊 Inserting default data...');
        
        // Default loyalty program
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.execute('''
          INSERT OR IGNORE INTO loyalty_programs (id, name, is_enabled, points_per_rm_spent, redemption_value, award_on_tax, min_points_to_redeem, points_expiry_months, created_at, updated_at)
          VALUES ('loyalty_default', 'Standard Loyalty Program', 1, 1.0, 0.10, 0, 100, 24, $now, $now)
        ''');

        // Default loyalty tiers
        await db.execute('''
          INSERT OR IGNORE INTO loyalty_tiers (id, program_id, name, min_spend, discount_percentage, benefits, created_at)
          VALUES ('bronze', 'loyalty_default', 'Bronze', 0.0, 0.0, '["1x points earning"]', $now)
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO loyalty_tiers (id, program_id, name, min_spend, discount_percentage, benefits, created_at)
          VALUES ('silver', 'loyalty_default', 'Silver', 500.0, 0.5, '["1.25x points earning", "0.5% discount"]', $now)
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO loyalty_tiers (id, program_id, name, min_spend, discount_percentage, benefits, created_at)
          VALUES ('gold', 'loyalty_default', 'Gold', 2000.0, 1.0, '["1.5x points earning", "1% discount", "Free item voucher/month"]', $now)
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO loyalty_tiers (id, program_id, name, min_spend, discount_percentage, benefits, created_at)
          VALUES ('platinum', 'loyalty_default', 'Platinum', 5000.0, 2.0, '["2x points earning", "2% discount", "VIP support"]', $now)
        ''');

        // Default sync stats
        await db.execute('''
          INSERT OR IGNORE INTO sync_stats (id, total_queued, total_synced, total_failed, updated_at)
          VALUES (1, 0, 0, 0, $now)
        ''');

        print('✅ Phase 1 migration (v31) completed successfully!');
        print('   📝 MyInvois: 3 tables');
        print('   💳 E-Wallet: 2 tables');
        print('   🎁 Loyalty: 4 tables');
        print('   🔒 PDPA: 3 tables');
        print('   📦 Inventory: 5 tables');
        print('   🔄 Sync: 2 tables');
        print('   📊 Total: 19 new tables + 16 indexes');
        
      } catch (e) {
        print('❌ Phase 1 migration failed: $e');
        rethrow;
      }
    }
  }

  Future<void> _createTables(Database db) async {
    // Business Information Table
    await db.execute('''
      CREATE TABLE business_info (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_number TEXT,
        tax_rate REAL DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        logo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        tax_rate REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Items Table
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT,
        name TEXT NOT NULL,
        email TEXT,
        phone_number TEXT,
        role TEXT NOT NULL,
        pin TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1,
        last_login_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tables Table (Restaurant)
    await db.execute('''
      CREATE TABLE tables (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        status TEXT NOT NULL,
        section TEXT,
        occupied_since TEXT,
        customer_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Payment Methods Table
    await db.execute('''
      CREATE TABLE payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Printers Table
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

    // Customer Displays Table
    await db.execute('''
      CREATE TABLE customer_displays (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        ip_address TEXT,
        port INTEGER,
        usb_device_id TEXT,
        bluetooth_address TEXT,
        platform_specific_id TEXT,
        device_name TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        status TEXT DEFAULT 'offline',
        has_permission INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        total_spent REAL DEFAULT 0,
        visit_count INTEGER DEFAULT 0,
        loyalty_points INTEGER DEFAULT 0,
        last_visit TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL UNIQUE,
        table_id TEXT,
        user_id TEXT NOT NULL,
        shift_id TEXT,
        status TEXT NOT NULL,
        order_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        service_charge REAL DEFAULT 0,
        merchant_id TEXT,
        payment_method_id TEXT,
        notes TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT,
        special_instructions TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (table_id) REFERENCES tables (id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)
      )
    ''');

    // Order Items Table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        item_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        seat_number INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items (id)
      )
    ''');

    // Transactions Table (Payment History)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        payment_method_id TEXT NOT NULL,
        amount REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        transaction_date TEXT NOT NULL,
        receipt_number TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)
      )
    ''');

    // Payment Splits Table (Split Payment Details)
    await db.execute('''
      CREATE TABLE payment_splits (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        payment_method_id TEXT NOT NULL,
        amount REAL NOT NULL,
        reference TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)
      )
    ''');

    // Receipt Settings Table
    await db.execute('''
      CREATE TABLE receipt_settings (
        id TEXT PRIMARY KEY,
        header_text TEXT DEFAULT '',
        footer_text TEXT DEFAULT '',
        show_logo INTEGER DEFAULT 1,
        show_date_time INTEGER DEFAULT 1,
        show_order_number INTEGER DEFAULT 1,
        show_cashier_name INTEGER DEFAULT 1,
        show_tax_breakdown INTEGER DEFAULT 1,
        show_service_charge_breakdown INTEGER DEFAULT 1,
        show_thank_you_message INTEGER DEFAULT 1,
        auto_print INTEGER DEFAULT 1,
        paper_size TEXT DEFAULT 'mm80',
        paper_width INTEGER DEFAULT 80,
        font_size INTEGER DEFAULT 12,
        thank_you_message TEXT DEFAULT 'Thank you for your purchase!',
        terms_and_conditions TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Inventory Adjustments Table
    await db.execute('''
      CREATE TABLE inventory_adjustments (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        adjustment_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Cash Drawer Sessions Table
    await db.execute('''
      CREATE TABLE cash_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        opening_balance REAL NOT NULL,
        closing_balance REAL,
        expected_balance REAL,
        total_sales REAL DEFAULT 0,
        total_cash REAL DEFAULT 0,
        total_card REAL DEFAULT 0,
        total_other REAL DEFAULT 0,
        status TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Discounts Table
    await db.execute('''
      CREATE TABLE discounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        start_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Modifier Groups Table
    await db.execute('''
      CREATE TABLE modifier_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        category_ids TEXT DEFAULT '',
        is_required INTEGER DEFAULT 0,
        allow_multiple INTEGER DEFAULT 0,
        min_selection INTEGER,
        max_selection INTEGER,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Modifier Items Table
    await db.execute('''
      CREATE TABLE modifier_items (
        id TEXT PRIMARY KEY,
        modifier_group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price_adjustment REAL DEFAULT 0,
        icon_code_point INTEGER,
        icon_font_family TEXT,
        color_value INTEGER,
        is_default INTEGER DEFAULT 0,
        is_available INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (modifier_group_id) REFERENCES modifier_groups (id) ON DELETE CASCADE
      )
    ''');

    // Item Modifiers Table (Variants, Add-ons) - Legacy/Simple modifiers
    await db.execute('''
      CREATE TABLE item_modifiers (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price_adjustment REAL DEFAULT 0,
        is_available INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    // Audit Log Table
    await db.execute('''
      CREATE TABLE audit_log (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        old_values TEXT,
        new_values TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Business Sessions Table
    await db.execute('''
      CREATE TABLE business_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        open_date TEXT NOT NULL,
        close_date TEXT,
        opening_cash REAL NOT NULL,
        closing_cash REAL,
        expected_cash REAL,
        notes TEXT,
        is_open INTEGER DEFAULT 1
      )
    ''');

    // Dealer Customers Table
    await db.execute('''
      CREATE TABLE dealer_customers (
        id TEXT PRIMARY KEY,
        business_name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        postcode TEXT NOT NULL,
        country TEXT DEFAULT 'Malaysia',
        registration_number TEXT,
        tax_number TEXT,
        website TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tenants Table
    await db.execute('''
      CREATE TABLE tenants (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        tenant_name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        owner_email TEXT NOT NULL,
        custom_domain TEXT,
        api_key TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES dealer_customers (id) ON DELETE CASCADE
      )
    ''');

    // Shifts Table
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        business_session_id INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        opening_cash REAL NOT NULL,
        closing_cash REAL,
        expected_cash REAL,
        variance REAL,
        variance_acknowledged INTEGER DEFAULT 0,
        notes TEXT,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // User Activity Log Table (for No-Shift tracking)
    await db.execute('''
      CREATE TABLE user_activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        description TEXT,
        order_id TEXT,
        amount REAL DEFAULT 0.0,
        payment_method TEXT,
        discount_amount REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        tax_rate REAL DEFAULT 0.0,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    // Categories indexes
    await db.execute(
      'CREATE INDEX idx_categories_active ON categories(is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_sort ON categories(sort_order)',
    );

    // Items indexes
    await db.execute('CREATE INDEX idx_items_category ON items(category_id)');
    await db.execute('CREATE INDEX idx_items_available ON items(is_available)');
    await db.execute('CREATE INDEX idx_items_sku ON items(sku)');
    await db.execute('CREATE INDEX idx_items_barcode ON items(barcode)');

    // Orders indexes
    await db.execute('CREATE INDEX idx_orders_number ON orders(order_number)');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_orders_date ON orders(created_at)');
    await db.execute('CREATE INDEX idx_orders_user ON orders(user_id)');
    await db.execute('CREATE INDEX idx_orders_table ON orders(table_id)');

    // Order Items indexes
    await db.execute(
      'CREATE INDEX idx_order_items_order ON order_items(order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_order_items_item ON order_items(item_id)',
    );

    // Transactions indexes
    await db.execute(
      'CREATE INDEX idx_transactions_order ON transactions(order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
    );

    // Users indexes
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_active ON users(is_active)');

    // Customers indexes
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_customers_email ON customers(email)');
    await db.execute(
      'CREATE INDEX idx_customers_active ON customers(is_active)',
    );

    // Tables indexes
    await db.execute('CREATE INDEX idx_tables_status ON tables(status)');
    // Note: No index on name column as it's used for display purposes

    // Inventory adjustments indexes
    await db.execute(
      'CREATE INDEX idx_inventory_item ON inventory_adjustments(item_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_date ON inventory_adjustments(created_at)',
    );

    // Cash sessions indexes
    await db.execute(
      'CREATE INDEX idx_cash_sessions_user ON cash_sessions(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cash_sessions_status ON cash_sessions(status)',
    );
    await db.execute(
      'CREATE INDEX idx_cash_sessions_date ON cash_sessions(opened_at)',
    );

    // Audit log indexes
    await db.execute('CREATE INDEX idx_audit_user ON audit_log(user_id)');
    await db.execute(
      'CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id)',
    );
    await db.execute('CREATE INDEX idx_audit_date ON audit_log(created_at)');

    // Modifier groups indexes
    await db.execute(
      'CREATE INDEX idx_modifier_groups_active ON modifier_groups(is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_groups_sort ON modifier_groups(sort_order)',
    );

    // Modifier items indexes
    await db.execute(
      'CREATE INDEX idx_modifier_items_group ON modifier_items(modifier_group_id)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_items_available ON modifier_items(is_available)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_items_sort ON modifier_items(sort_order)',
    );

    // Dealer customers indexes
    await db.execute(
      'CREATE INDEX idx_dealer_customers_email ON dealer_customers(email)',
    );
    await db.execute(
      'CREATE INDEX idx_dealer_customers_business_name ON dealer_customers(business_name)',
    );
    await db.execute(
      'CREATE INDEX idx_dealer_customers_active ON dealer_customers(is_active)',
    );

    // Tenants indexes
    await db.execute(
      'CREATE INDEX idx_tenants_customer_id ON tenants(customer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_tenants_owner_email ON tenants(owner_email)',
    );
    await db.execute('CREATE INDEX idx_tenants_active ON tenants(is_active)');

    // User activity log indexes
    await db.execute(
      'CREATE INDEX idx_user_activity_user ON user_activity_log(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_activity_type ON user_activity_log(activity_type)',
    );
    await db.execute(
      'CREATE INDEX idx_user_activity_timestamp ON user_activity_log(timestamp)',
    );
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert default business info
    await db.insert('business_info', {
      'id': '1',
      'name': 'My Business',
      'address': '',
      'phone': '',
      'email': '',
      'tax_number': '',
      'tax_rate': 10.0,
      'currency': 'USD',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default receipt settings
    await db.insert('receipt_settings', {
      'id': '1',
      'header_text': 'My Business',
      'footer_text': 'Thank you for your business!',
      'show_logo': 1,
      'show_date_time': 1,
      'show_order_number': 1,
      'show_cashier_name': 1,
      'show_tax_breakdown': 1,
      'show_service_charge_breakdown': 1,
      'show_thank_you_message': 1,
      'auto_print': 1,
      'paper_size': 'mm80',
      'paper_width': 80,
      'font_size': 12,
      'thank_you_message': 'Thank you for your purchase!',
      'terms_and_conditions': '',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default admin user
    await db.insert('users', {
      'id': '1',
      'name': 'Admin',
      'email': 'admin@example.com',
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Insert default payment methods
    final paymentMethods = [
      'Cash',
      'Credit Card',
      'Debit Card',
      'Mobile Payment',
    ];
    for (int i = 0; i < paymentMethods.length; i++) {
      await db.insert('payment_methods', {
        'id': '${i + 1}',
        'name': paymentMethods[i],
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Helper method to reset database (for development/testing)
  Future<void> resetDatabase() async {
    String path;
    if (kIsWeb) {
      path = 'extropos.db';
    } else {
      path =
          _overrideDatabaseFilePath ??
          join(await getDatabasesPath(), 'extropos.db');
    }

    try {
      await deleteDatabase(path);
    } catch (_) {
      // ignore
    }
    _database = null;
    await database; // Reinitialize
  }

  /// Safely reset database with automatic backup (recommended for production)
  Future<String> safeResetDatabase({bool createBackup = true}) async {
    String path;
    if (kIsWeb) {
      path = 'extropos.db';
    } else {
      path =
          _overrideDatabaseFilePath ??
          join(await getDatabasesPath(), 'extropos.db');
    }

    String? backupPath;
    if (createBackup && !kIsWeb) {
      try {
        backupPath = await backupDatabase();
        // Database backed up before reset: $backupPath
      } catch (e) {
        // Warning: Could not create backup before reset: $e
      }
    }

    // Close current connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete and recreate
    try {
      await deleteDatabase(path);
    } catch (_) {
      // ignore
    }

    // Reinitialize
    await database;

    return backupPath ?? 'No backup created';
  }

  /// Create a timestamped backup copy of the on-disk database file and
  /// return the absolute path to the backup file. Throws on failure.
  Future<String> backupDatabase() async {
    if (kIsWeb) {
      throw Exception('Database backup not supported on Web');
    }

    final path =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final src = File(path);
    if (!await src.exists()) {
      throw Exception('Database file not found at $path');
    }

    final backupDir = dirname(path);
    final now = DateTime.now();
    final ts = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final destPath = join(backupDir, 'extropos_backup_$ts.db');
    final dest = File(destPath);

    await src.copy(dest.path);
    return dest.path;
  }

  /// Override the database file path. When non-null, the helper will open and
  /// reset the database at the given absolute file path. Intended for tests.
  static void overrideDatabaseFilePath(String? absoluteFilePath) {
    _overrideDatabaseFilePath = absoluteFilePath;
  }

  /// Check database file integrity before opening
  Future<void> _checkDatabaseIntegrity(String dbPath) async {
    if (kIsWeb) return; // Skip integrity check on Web

    final file = File(dbPath);
    if (!await file.exists()) return; // New database, no integrity check needed

    try {
      // Try to open database for a quick integrity check
      final testDb = await openDatabase(dbPath, readOnly: true);
      await testDb.close();
    } catch (e) {
      // Database integrity check failed: $e
      // Try to restore from backup
      await _restoreFromBackupIfAvailable(dbPath);
    }
  }

  /// Handle database downgrades (should not happen in production)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Warning: Database downgrade detected from v$oldVersion to v$newVersion
    // In production, we should not allow downgrades as they can cause data loss
    // For now, we'll allow it but create a backup first
    if (!kIsWeb) {
      try {
        await _createBackupBeforeMigration();
      } catch (e) {
        // Could not create backup before downgrade: $e
      }
    }
  }

  /// Create a backup before risky operations like migrations
  Future<void> _createBackupBeforeMigration() async {
    if (kIsWeb) return; // Skip backup on Web

    try {
      await backupDatabase();
      // Database backup created
    } catch (e) {
      // Failed to create backup: $e
      rethrow;
    }
  }

  /// Try to restore from the most recent backup if database is corrupted
  Future<void> _restoreFromBackupIfAvailable(String dbPath) async {
    if (kIsWeb) return; // Skip restore on Web

    try {
      final backupDir = dirname(dbPath);
      final dir = Directory(backupDir);
      if (!await dir.exists()) return;

      final backupFiles = await dir
          .list()
          .where(
            (entity) =>
                entity is File &&
                basename(entity.path).startsWith('extropos_backup_') &&
                basename(entity.path).endsWith('.db'),
          )
          .toList();

      if (backupFiles.isEmpty) return;

      // Sort by modification time, most recent first
      backupFiles.sort(
        (a, b) => (b as File).lastModifiedSync().compareTo(
          (a as File).lastModifiedSync(),
        ),
      );

      final mostRecentBackup = backupFiles.first as File;
      await mostRecentBackup.copy(dbPath);
      // Database restored from backup: ${mostRecentBackup.path}
    } catch (e) {
      // Failed to restore from backup: $e
    }
  }

  /// Get list of available backup files
  Future<List<String>> getBackupFiles() async {
    if (kIsWeb) return []; // No file backups on Web

    final dbPath =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final backupDir = dirname(dbPath);
    final dir = Directory(backupDir);

    if (!await dir.exists()) return [];

    final backupFiles = await dir
        .list()
        .where(
          (entity) =>
              entity is File &&
              basename(entity.path).startsWith('extropos_backup_') &&
              basename(entity.path).endsWith('.db'),
        )
        .map((entity) => entity.path)
        .toList();

    return backupFiles;
  }

  /// Restore database from a specific backup file
  Future<void> restoreFromBackup(String backupPath) async {
    if (kIsWeb) return; // No file restore on Web

    final dbPath =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');

    // Close current database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Copy backup to main database location
    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);

    // Database restored from: $backupPath
  }

  /// Clean up old backup files (keep only the most recent N backups)
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    if (kIsWeb) return; // No file cleanup on Web

    try {
      final backups = await getBackupFiles();
      if (backups.length <= keepCount) return;

      // Sort by modification time, oldest first
      final backupFiles = backups.map((path) => File(path)).toList();
      backupFiles.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );

      // Delete oldest backups
      final toDelete = backupFiles.take(backupFiles.length - keepCount);
      for (final file in toDelete) {
        await file.delete();
        // Deleted old backup: ${file.path}
      }
    } catch (e) {
      // Failed to cleanup old backups: $e
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (kIsWeb) {
      return {
        'database_path': 'IndexedDB/extropos.db',
        'exists': true,
        'size_bytes': 0,
        'size_mb': 0.0,
        'last_modified': null,
        'backup_count': 0,
      };
    }

    final dbPath =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final file = File(dbPath);

    final stats = {
      'database_path': dbPath,
      'exists': await file.exists(),
      'size_bytes': 0,
      'size_mb': 0.0,
      'last_modified': null,
      'backup_count': 0,
    };

    if (await file.exists()) {
      final stat = await file.stat();
      stats['size_bytes'] = stat.size;
      stats['size_mb'] = stat.size / (1024 * 1024);
      stats['last_modified'] = stat.modified.toIso8601String();
    }

    stats['backup_count'] = (await getBackupFiles()).length;

    return stats;
  }

  /// Get the current database file path
  Future<String> getDatabasePath() async {
    if (kIsWeb) return 'extropos.db';

    return _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
  }
}
