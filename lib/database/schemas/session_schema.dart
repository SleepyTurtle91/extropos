/// SQL schema definitions for the business-session and shift-cash domain.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class SessionSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  /// Per-user cash drawer float tracking.
  static const String createCashSessionsTable = '''
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
  ''';

  /// Business-day open/close record (whole-of-business session).
  static const String createBusinessSessionsTable = '''
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
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_cash_sessions_user ON cash_sessions(user_id)',
    'CREATE INDEX idx_cash_sessions_status ON cash_sessions(status)',
    'CREATE INDEX idx_cash_sessions_date ON cash_sessions(opened_at)',
  ];

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createCashSessionsTable,
    createBusinessSessionsTable,
  ];
}
