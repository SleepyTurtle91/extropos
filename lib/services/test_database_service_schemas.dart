part of 'test_database_service.dart';

extension TestDatabaseServiceSchemas on TestDatabaseService {
  /// Create test database tables
  Future<void> _onCreateTestDatabase(Database db, int version) async {
    debugPrint('🏗️ Creating test database tables...');

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
}
