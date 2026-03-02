part of '../database_helper.dart';

extension DatabaseHelperUpgradePart3 on DatabaseHelper {
  Future<void> _applyUpgrades_v31_v31(Database db, int oldVersion) async {
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
}
