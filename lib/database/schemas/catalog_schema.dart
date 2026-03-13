/// SQL schema definitions for the product catalog domain.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class CatalogSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  static const String createCategoriesTable = '''
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
  ''';

  static const String createItemsTable = '''
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
  ''';

  static const String createModifierGroupsTable = '''
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
  ''';

  static const String createModifierItemsTable = '''
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
  ''';

  /// Legacy/simple per-item modifiers (variants, add-ons).
  static const String createItemModifiersTable = '''
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
  ''';

  static const String createDiscountsTable = '''
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
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_categories_active ON categories(is_active)',
    'CREATE INDEX idx_categories_sort ON categories(sort_order)',
    'CREATE INDEX idx_items_category ON items(category_id)',
    'CREATE INDEX idx_items_available ON items(is_available)',
    'CREATE INDEX idx_items_sku ON items(sku)',
    'CREATE INDEX idx_items_barcode ON items(barcode)',
    'CREATE INDEX idx_modifier_groups_active ON modifier_groups(is_active)',
    'CREATE INDEX idx_modifier_groups_sort ON modifier_groups(sort_order)',
    'CREATE INDEX idx_modifier_items_group ON modifier_items(modifier_group_id)',
    'CREATE INDEX idx_modifier_items_available ON modifier_items(is_available)',
    'CREATE INDEX idx_modifier_items_sort ON modifier_items(sort_order)',
  ];

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createCategoriesTable,
    createItemsTable,
    createModifierGroupsTable,
    createModifierItemsTable,
    createItemModifiersTable,
    createDiscountsTable,
  ];
}
