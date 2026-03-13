/// SQL schema definitions for the sales / orders domain.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class OrdersSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  static const String createOrdersTable = '''
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
  ''';

  static const String createOrderItemsTable = '''
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
  ''';

  /// Stores completed payment events linked to orders.
  static const String createTransactionsTable = '''
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
  ''';

  /// Stores per-method split detail for split-payment transactions.
  static const String createPaymentSplitsTable = '''
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
  ''';

  static const String createInventoryAdjustmentsTable = '''
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
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_orders_number ON orders(order_number)',
    'CREATE INDEX idx_orders_status ON orders(status)',
    'CREATE INDEX idx_orders_date ON orders(created_at)',
    'CREATE INDEX idx_orders_user ON orders(user_id)',
    'CREATE INDEX idx_orders_table ON orders(table_id)',
    'CREATE INDEX idx_order_items_order ON order_items(order_id)',
    'CREATE INDEX idx_order_items_item ON order_items(item_id)',
    'CREATE INDEX idx_transactions_order ON transactions(order_id)',
    'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
    'CREATE INDEX idx_inventory_item ON inventory_adjustments(item_id)',
    'CREATE INDEX idx_inventory_date ON inventory_adjustments(created_at)',
  ];

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createOrdersTable,
    createOrderItemsTable,
    createTransactionsTable,
    createPaymentSplitsTable,
    createInventoryAdjustmentsTable,
  ];
}
