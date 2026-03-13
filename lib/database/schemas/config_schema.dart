/// SQL schema definitions for the POS configuration domain.
/// Covers business settings, payment methods, hardware, and restaurant tables.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class ConfigSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  static const String createBusinessInfoTable = '''
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
  ''';

  static const String createReceiptSettingsTable = '''
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
  ''';

  static const String createPaymentMethodsTable = '''
    CREATE TABLE payment_methods (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      status INTEGER DEFAULT 0,
      is_default INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createPrintersTable = '''
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
  ''';

  static const String createCustomerDisplaysTable = '''
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
  ''';

  /// Restaurant / table-service layout.
  static const String createTablesTable = '''
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
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_tables_status ON tables(status)',
  ];

  // ─── Default seed data ────────────────────────────────────────────────────

  /// Returns the default business_info insert map.
  static Map<String, Object> defaultBusinessInfo(String now) => {
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
  };

  /// Returns the default receipt_settings insert map.
  static Map<String, Object> defaultReceiptSettings(String now) => {
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
  };

  /// Default active payment methods (Cash, Credit Card, Debit Card, E-Wallet).
  static List<Map<String, Object>> defaultPaymentMethods(String now) => [
    {'id': '1', 'name': 'Cash', 'status': 0, 'is_default': 1, 'created_at': now, 'updated_at': now},
    {'id': '2', 'name': 'Credit Card', 'status': 0, 'is_default': 0, 'created_at': now, 'updated_at': now},
    {'id': '3', 'name': 'Debit Card', 'status': 0, 'is_default': 0, 'created_at': now, 'updated_at': now},
    {'id': '4', 'name': 'E-Wallet', 'status': 0, 'is_default': 0, 'created_at': now, 'updated_at': now},
  ];

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createBusinessInfoTable,
    createReceiptSettingsTable,
    createPaymentMethodsTable,
    createPrintersTable,
    createCustomerDisplaysTable,
    createTablesTable,
  ];
}
