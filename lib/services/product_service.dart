import 'package:extropos/models/product.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/material.dart';

/// ProductService – Abstraction for product queries (Appwrite or local DB)
///
/// Reads from Appwrite if enabled; falls back to local SQLite when offline.
/// Provides a unified interface for POS and other parts of the app.
class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() => _instance;

  ProductService._internal();

  /// Fetch all products (from Appwrite or local DB based on IsEnabled state)
  Future<List<Product>> getProducts({int limit = 100, int offset = 0}) async {
    if (AppwritePhase1Service.isEnabled) {
      return _getProductsFromAppwrite(limit, offset);
    } else {
      return _getProductsFromLocalDB(limit, offset);
    }
  }

  /// Fetch products by category
  Future<List<Product>> getProductsByCategory({
    required String categoryName,
    int limit = 100,
  }) async {
    if (AppwritePhase1Service.isEnabled) {
      return _getProductsByCategoryAppwrite(categoryName, limit);
    } else {
      return _getProductsByCategoryLocalDB(categoryName, limit);
    }
  }

  /// Get all distinct categories
  Future<List<String>> getCategories() async {
    if (AppwritePhase1Service.isEnabled) {
      return _getCategoriesAppwrite();
    } else {
      return _getCategoriesLocalDB();
    }
  }

  // ===== Local DB Methods =====

  Future<List<Product>> _getProductsFromLocalDB(int limit, int offset) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'items',
        orderBy: 'sort_order ASC, name ASC',
        limit: limit,
        offset: offset,
        where: 'is_available = ?',
        whereArgs: [1],
      );
      return rows.map(_rowToProduct).toList();
    } catch (e) {
      print('❌ Error fetching products from local DB: $e');
      return [];
    }
  }

  Future<List<Product>> _getProductsByCategoryLocalDB(
    String categoryName,
    int limit,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Find category ID first
      final catRows = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [categoryName],
      );

      if (catRows.isEmpty) return [];
      final categoryId = catRows.first['id'];

      // Query items by category
      final rows = await db.query(
        'items',
        where: 'category_id = ? AND is_available = ?',
        whereArgs: [categoryId, 1],
        orderBy: 'sort_order ASC, name ASC',
        limit: limit,
      );
      return rows.map(_rowToProduct).toList();
    } catch (e) {
      print('❌ Error fetching products by category from local DB: $e');
      return [];
    }
  }

  Future<List<String>> _getCategoriesLocalDB() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'categories',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, name ASC',
      );
      return rows.map((r) => (r['name'] as String?) ?? '').toList();
    } catch (e) {
      print('❌ Error fetching categories from local DB: $e');
      return [];
    }
  }

  // ===== Appwrite Methods (Stubs) =====
  // These are placeholder stubs for Appwrite integration. Implement when needed.

  Future<List<Product>> _getProductsFromAppwrite(int limit, int offset) async {
    print('⚠️ Appwrite product fetch not yet implemented');
    return [];
  }

  Future<List<Product>> _getProductsByCategoryAppwrite(
    String categoryName,
    int limit,
  ) async {
    print('⚠️ Appwrite category filter not yet implemented');
    return [];
  }

  Future<List<String>> _getCategoriesAppwrite() async {
    print('⚠️ Appwrite category list not yet implemented');
    return [];
  }

  // ===== Converters =====

  /// Convert a local DB items row to a Product
  Product _rowToProduct(Map<String, dynamic> row) {
    return Product(
      row['name']?.toString() ?? '',
      (row['price'] as num?)?.toDouble() ?? 0.0,
      row['category_id']?.toString() ?? 'Uncategorized',
      _iconFromCodePoint(
        (row['icon_code_point'] as int?) ?? 61184, // default icon
      ),
      imagePath: row['image_url']?.toString(),
      printerOverride: row['printer_override']?.toString(),
    );
  }

  /// Map icon code point to MaterialIcons.IconData
  IconData _iconFromCodePoint(int codePoint) {
    const iconMap = <int, IconData>{
      61184: Icons.shopping_bag, // default fallback
      0xf0068: Icons.local_cafe,
      0xf0071: Icons.lunch_dining,
      0xf0112: Icons.cake,
      0xf0059: Icons.local_drink,
    };
    return iconMap[codePoint] ?? Icons.shopping_bag;
  }
}
