/// SQL schema definitions for the user / staff domain.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class UsersSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  static const String createUsersTable = '''
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
  ''';

  static const String createCustomersTable = '''
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
  ''';

  static const String createShiftsTable = '''
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
  ''';

  /// Lightweight activity tracking for no-shift environments.
  static const String createUserActivityLogTable = '''
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
  ''';

  static const String createAuditLogTable = '''
    CREATE TABLE audit_log (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      action TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT,
      old_values TEXT,
      new_values TEXT,
      ip_address TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  ''';

  static const String createCustomerConsentsTable = '''
    CREATE TABLE customer_consents (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      consent_type TEXT NOT NULL,
      granted INTEGER NOT NULL,
      timestamp TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
    )
  ''';

  static const String createDataDeletionRequestsTable = '''
    CREATE TABLE data_deletion_requests (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      status TEXT NOT NULL,
      requested_at TEXT NOT NULL,
      completed_at TEXT,
      reason TEXT,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
    )
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_users_email ON users(email)',
    'CREATE INDEX idx_users_active ON users(is_active)',
    'CREATE INDEX idx_customers_phone ON customers(phone)',
    'CREATE INDEX idx_customers_email ON customers(email)',
    'CREATE INDEX idx_customers_active ON customers(is_active)',
    'CREATE INDEX idx_audit_user ON audit_log(user_id)',
    'CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id)',
    'CREATE INDEX idx_audit_date ON audit_log(created_at)',
    'CREATE INDEX idx_user_activity_user ON user_activity_log(user_id)',
    'CREATE INDEX idx_user_activity_type ON user_activity_log(activity_type)',
    'CREATE INDEX idx_user_activity_timestamp ON user_activity_log(timestamp)',
    'CREATE INDEX idx_consents_customer ON customer_consents(customer_id)',
    'CREATE INDEX idx_deletion_customer ON data_deletion_requests(customer_id)',
  ];

  // ─── Default seed data ────────────────────────────────────────────────────

  /// Returns an insert map for the default admin user.
  static Map<String, Object> defaultAdminUser(String now) => {
    'id': '1',
    'name': 'Admin',
    'email': 'admin@example.com',
    'role': 'admin',
    'is_active': 1,
    'created_at': now,
    'updated_at': now,
  };

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createUsersTable,
    createCustomersTable,
    createShiftsTable,
    createUserActivityLogTable,
    createAuditLogTable,
    createCustomerConsentsTable,
    createDataDeletionRequestsTable,
  ];
}
