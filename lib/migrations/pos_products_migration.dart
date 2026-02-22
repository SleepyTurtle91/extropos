import 'package:extropos/services/database_helper.dart';

/// Database migration to add pos_products table for ExtroPOS system
/// 
/// This script adds a new table optimized for POS operations with:
/// - Business mode filtering (retail, cafe, restaurant, all)
/// - Color coding for UI
/// - Stock tracking
/// - Barcode support
/// 
/// Run this once before using the ProductRepository
class POSProductsMigration {
  static Future<void> migrate() async {
    final db = await DatabaseHelper.instance.database;

    print('🔄 Starting POS Products table migration...');

    try {
      // Create pos_products table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_products (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          mode TEXT DEFAULT 'all',
          color_value INTEGER DEFAULT 0xFF2196F3,
          description TEXT,
          barcode TEXT,
          image_url TEXT,
          is_available INTEGER DEFAULT 1,
          stock INTEGER DEFAULT 0,
          track_stock INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for better query performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_pos_products_mode 
        ON pos_products(mode)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_pos_products_category 
        ON pos_products(category)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_pos_products_barcode 
        ON pos_products(barcode)
      ''');

      print('✅ POS Products table created successfully');
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }

  /// Optional: Check if migration is needed
  static Future<bool> isTableExists() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='pos_products'",
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error checking table existence: $e');
      return false;
    }
  }
}
