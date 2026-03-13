/// SQL schema definitions for the inventory domain.
abstract final class InventorySchema {
  static const String createInventoryTable = '''
    CREATE TABLE inventory (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL UNIQUE,
      product_name TEXT NOT NULL,
      current_quantity REAL NOT NULL DEFAULT 0.0,
      min_stock_level REAL NOT NULL DEFAULT 0.0,
      max_stock_level REAL NOT NULL DEFAULT 0.0,
      reorder_quantity REAL NOT NULL DEFAULT 0.0,
      cost_per_unit REAL,
      unit TEXT NOT NULL DEFAULT 'pcs',
      last_stock_count_date TEXT,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createStockMovementsTable = '''
    CREATE TABLE stock_movements (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      type TEXT NOT NULL,
      quantity REAL NOT NULL,
      reason TEXT NOT NULL,
      date TEXT NOT NULL,
      user_id TEXT,
      reference_id TEXT,
      FOREIGN KEY (product_id) REFERENCES inventory (product_id) ON DELETE CASCADE
    )
  ''';

  static const String createSuppliersTable = '''
    CREATE TABLE suppliers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      contact_person TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      tax_number TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const String createPurchaseOrdersTable = '''
    CREATE TABLE purchase_orders (
      id TEXT PRIMARY KEY,
      po_number TEXT NOT NULL UNIQUE,
      supplier_id TEXT NOT NULL,
      supplier_name TEXT NOT NULL,
      total_amount REAL NOT NULL,
      status TEXT NOT NULL,
      order_date TEXT NOT NULL,
      expected_delivery_date TEXT,
      received_date TEXT,
      notes TEXT,
      FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
    )
  ''';

  static const String createPurchaseOrderItemsTable = '''
    CREATE TABLE purchase_order_items (
      purchase_order_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_cost REAL NOT NULL,
      total_cost REAL NOT NULL,
      PRIMARY KEY (purchase_order_id, product_id),
      FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE
    )
  ''';

  static const List<String> indexes = [
    'CREATE INDEX idx_inventory_product ON inventory(product_id)',
    'CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)',
    'CREATE INDEX idx_stock_movements_date ON stock_movements(date)',
    'CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id)',
    'CREATE INDEX idx_purchase_orders_date ON purchase_orders(order_date)',
  ];

  static const List<String> allTables = [
    createInventoryTable,
    createStockMovementsTable,
    createSuppliersTable,
    createPurchaseOrdersTable,
    createPurchaseOrderItemsTable,
  ];
}
