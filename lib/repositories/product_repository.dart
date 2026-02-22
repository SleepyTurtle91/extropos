import 'package:extropos/models/pos_product.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:uuid/uuid.dart';

/// Repository abstraction for POS product data access
/// Provides a clean interface for UI screens to interact with products
abstract class ProductRepository {
  Future<List<POSProduct>> getProducts({String? mode});
  Future<List<POSProduct>> getProductsByCategory(String category, {String? mode});
  Future<List<String>> getCategories({String? mode});
  Future<POSProduct> createProduct(POSProduct product);
  Future<POSProduct> updateProduct(POSProduct product);
  Future<void> deleteProduct(String id);
  Future<POSProduct?> getProductById(String id);
  Future<POSProduct?> getProductByBarcode(String barcode);
}

/// SQLite implementation of ProductRepository
/// Integrates with existing DatabaseHelper and items/categories tables
class DatabaseProductRepository implements ProductRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  @override
  Future<List<POSProduct>> getProducts({String? mode}) async {
    try {
      final database = await _db.database;
      
      // Build query based on mode filter
      String whereClause = 'is_available = ?';
      List<dynamic> whereArgs = [1];
      
      if (mode != null && mode != 'all') {
        whereClause += ' AND (mode = ? OR mode = ?)';
        whereArgs.addAll([mode, 'all']);
      }

      final results = await database.query(
        'pos_products',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'category, name ASC',
      );

      return results.map((map) => POSProduct.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }

  @override
  Future<List<POSProduct>> getProductsByCategory(
    String category, {
    String? mode,
  }) async {
    try {
      final database = await _db.database;
      
      String whereClause = 'is_available = ? AND category = ?';
      List<dynamic> whereArgs = [1, category];
      
      if (mode != null && mode != 'all') {
        whereClause += ' AND (mode = ? OR mode = ?)';
        whereArgs.addAll([mode, 'all']);
      }

      final results = await database.query(
        'pos_products',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      return results.map((map) => POSProduct.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error fetching products by category: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getCategories({String? mode}) async {
    try {
      final database = await _db.database;
      
      // Build query based on mode filter
      String whereClause = 'is_available = ?';
      List<dynamic> whereArgs = [1];
      
      if (mode != null && mode != 'all') {
        whereClause += ' AND (mode = ? OR mode = ?)';
        whereArgs.addAll([mode, 'all']);
      }

      final results = await database.query(
        'pos_products',
        columns: ['DISTINCT category'],
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'category ASC',
      );

      return results
          .map((map) => map['category'] as String)
          .where((cat) => cat.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  @override
  Future<POSProduct> createProduct(POSProduct product) async {
    try {
      final database = await _db.database;
      
      // Generate ID if not provided
      final newProduct = product.id.isEmpty
          ? product.copyWith(id: _uuid.v4())
          : product;

      await database.insert('pos_products', newProduct.toMap());
      
      print('✅ Product created: ${newProduct.name}');
      return newProduct;
    } catch (e) {
      print('❌ Error creating product: $e');
      rethrow;
    }
  }

  @override
  Future<POSProduct> updateProduct(POSProduct product) async {
    try {
      final database = await _db.database;
      
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      
      await database.update(
        'pos_products',
        updatedProduct.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      
      print('✅ Product updated: ${product.name}');
      return updatedProduct;
    } catch (e) {
      print('❌ Error updating product: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final database = await _db.database;
      
      await database.delete(
        'pos_products',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ Product deleted: $id');
    } catch (e) {
      print('❌ Error deleting product: $e');
      rethrow;
    }
  }

  @override
  Future<POSProduct?> getProductById(String id) async {
    try {
      final database = await _db.database;
      
      final results = await database.query(
        'pos_products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      
      return POSProduct.fromMap(results.first);
    } catch (e) {
      print('❌ Error fetching product by ID: $e');
      return null;
    }
  }

  @override
  Future<POSProduct?> getProductByBarcode(String barcode) async {
    try {
      final database = await _db.database;
      
      final results = await database.query(
        'pos_products',
        where: 'barcode = ? AND is_available = ?',
        whereArgs: [barcode, 1],
        limit: 1,
      );

      if (results.isEmpty) return null;
      
      return POSProduct.fromMap(results.first);
    } catch (e) {
      print('❌ Error fetching product by barcode: $e');
      return null;
    }
  }
}
