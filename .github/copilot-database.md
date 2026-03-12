# FlutterPOS Database Guide

## SQLite Database System



### Overview


FlutterPOS currently uses **SQLite** via the `sqflite` package for local data persistence.

**Key Components**:


- **DatabaseHelper** (`lib/services/database_helper.dart`): Singleton service managing SQLite operations

- **Tables**: products, transactions, users, categories, printers, etc.

- **Platform Support**: Android, Windows, Linux, Web (via sqlflite_ffi)


### Database Schema

```sql
-- Products table

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  category_id TEXT,
  sku TEXT,
  icon TEXT,
  image_url TEXT,
  variants_json TEXT,
  modifier_group_ids_json TEXT,
  quantity REAL DEFAULT 0.0,
  cost_per_unit REAL,
  is_active INTEGER DEFAULT 1,
  is_synced INTEGER DEFAULT 0,
  last_synced_at INTEGER,
  created_at INTEGER,
  updated_at INTEGER
);

-- Transactions table

CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_number TEXT UNIQUE,
  transaction_date INTEGER,
  user_id TEXT,
  subtotal REAL,
  tax_amount REAL,
  service_charge_amount REAL,
  total_amount REAL,
  discount_amount REAL,
  payment_method TEXT,
  business_mode TEXT,
  table_id TEXT,
  order_number INTEGER,
  customer_id TEXT,
  items_json TEXT,
  payments_json TEXT,
  refund_status TEXT DEFAULT 'none',
  refund_amount REAL DEFAULT 0.0,
  is_synced INTEGER DEFAULT 0,
  last_synced_at INTEGER,
  created_at INTEGER,
  updated_at INTEGER
);

```


### Current Usage Patterns

```dart
// Initialize database
final db = await DatabaseHelper.instance.database;

// Query operations
final products = await db.query('products',
  where: 'is_active = ?',
  whereArgs: [1],
  orderBy: 'name ASC'
);

// Insert operations
await db.insert('products', product.toMap());

// Update operations
await db.update('products', product.toMap(),
  where: 'id = ?',
  whereArgs: [product.id]
);

// Delete operations
await db.delete('products',
  where: 'id = ?',
  whereArgs: [productId]
);

```

---

**Last Updated**: March 6, 2026 - SQLite-only version





---

> **Note**: Isar migration was evaluated and abandoned in March 2026.
> SQLite via sqflite remains the sole local persistence layer.
