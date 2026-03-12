part of '../database_helper.dart';

extension DatabaseHelperUpgradePart1 on DatabaseHelper {
  Future<void> _applyUpgradesV2V35(Database db, int oldVersion) async {
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
    if (oldVersion < 35) {
      try {
        await db.execute(
          'ALTER TABLE receipt_settings ADD COLUMN show_tax_id INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE receipt_settings ADD COLUMN tax_id_text TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE receipt_settings ADD COLUMN show_wifi_details INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE receipt_settings ADD COLUMN wifi_details TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE receipt_settings ADD COLUMN show_barcode INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE receipt_settings ADD COLUMN barcode_data TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE receipt_settings ADD COLUMN show_qr_code INTEGER DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE receipt_settings ADD COLUMN qr_data TEXT DEFAULT ''",
        );
      } catch (_) {}
    }
    if (oldVersion < 33) {
      try { await db.execute('ALTER TABLE e_wallet_transactions ADD COLUMN qr_expires_at INTEGER'); } catch (_) {}
    }
    if (oldVersion < 32) {
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN provider TEXT DEFAULT \'duitnow\''); } catch (_) {}
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN callback_url TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE e_wallet_settings ADD COLUMN webhook_secret TEXT'); } catch (_) {}
    }
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
  }
}
