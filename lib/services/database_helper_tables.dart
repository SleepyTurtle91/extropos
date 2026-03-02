part of 'database_helper.dart';

extension DatabaseHelperTables on DatabaseHelper {
  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _seedDefaultPaymentMethods(db);
  }

  Future<void> _seedDefaultPaymentMethods(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaultPaymentMethods = [
      ('1', 'Cash', 1, 1), // (id, name, status=active, isDefault=true)
      ('2', 'Credit Card', 1, 0),
      ('3', 'Debit Card', 1, 0),
      ('4', 'E-Wallet', 1, 0),
    ];

    for (final method in defaultPaymentMethods) {
      await db.insert(
        'payment_methods',
        {
          'id': method.$1,
          'name': method.$2,
          'status': method.$3,
          'is_default': method.$4,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
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
        status INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
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
        show_tax_id INTEGER DEFAULT 1,
        tax_id_text TEXT DEFAULT '',
        show_wifi_details INTEGER DEFAULT 0,
        wifi_details TEXT DEFAULT '',
        show_barcode INTEGER DEFAULT 0,
        barcode_data TEXT DEFAULT '',
        show_qr_code INTEGER DEFAULT 0,
        qr_data TEXT DEFAULT '',
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
      'show_tax_id': 1,
      'tax_id_text': '',
      'show_wifi_details': 0,
      'wifi_details': '',
      'show_barcode': 0,
      'barcode_data': '',
      'show_qr_code': 0,
      'qr_data': '',
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

}
