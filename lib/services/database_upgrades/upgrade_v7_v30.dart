part of '../database_helper.dart';

extension DatabaseHelperUpgradePart2 on DatabaseHelper {
  Future<void> _applyUpgrades_v7_v30(Database db, int oldVersion) async {
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
  }
}
