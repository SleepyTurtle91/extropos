import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:extropos/services/isar_database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Helper for migrating data from SQLite (sqflite) to Isar.
/// 
/// Provides methods to:
/// - Migrate products from SQLite to Isar
/// - Migrate transactions from SQLite to Isar
/// - Migrate inventory from SQLite to Isar
/// - Perform complete database migration
class SQLiteToIsarMigration {
  final Database sqliteDb;
  
  SQLiteToIsarMigration(this.sqliteDb);
  
  /// Migrate all products from SQLite to Isar.
  /// 
  /// Assumes SQLite table structure matches old schema.
  /// Returns MigrationResult with counts.
  Future<MigrationResult> migrateProducts() async {
    try {
      final List<Map<String, dynamic>> sqliteProducts = await sqliteDb.query('products');
      
      int migrated = 0;
      int failed = 0;
      
      for (final row in sqliteProducts) {
        try {
          final product = IsarProduct(
            backendId: row['backend_id'] as String? ?? '',
            name: row['name'] as String,
            price: (row['price'] as num).toDouble(),
            categoryId: row['category_id'] as String? ?? '',
            categoryName: row['category_name'] as String?,
            sku: row['sku'] as String?,
            icon: row['icon'] as String?,
            imageUrl: row['image_url'] as String?,
            variantsJson: row['variants_json'] as String?,
            modifierGroupIdsJson: row['modifier_group_ids_json'] as String?,
            quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
            costPerUnit: (row['cost_per_unit'] as num?)?.toDouble(),
            isActive: (row['is_active'] as int?) == 1,
            isSynced: (row['is_synced'] as int?) == 1,
            lastSyncedAt: row['last_synced_at'] as int?,
          );
          
          await IsarDatabaseService.saveProduct(product);
          migrated++;
        } catch (e) {
          failed++;
          print('Failed to migrate product: $e');
        }
      }
      
      return MigrationResult(
        tableName: 'products',
        totalRecords: sqliteProducts.length,
        migrated: migrated,
        failed: failed,
      );
    } catch (e) {
      print('Migration failed: $e');
      return MigrationResult(
        tableName: 'products',
        totalRecords: 0,
        migrated: 0,
        failed: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Migrate all transactions from SQLite to Isar.
  Future<MigrationResult> migrateTransactions() async {
    try {
      final List<Map<String, dynamic>> sqliteTransactions = await sqliteDb.query('transactions');
      
      int migrated = 0;
      int failed = 0;
      
      for (final row in sqliteTransactions) {
        try {
          final transaction = IsarTransaction(
            backendId: row['backend_id'] as String? ?? '',
            transactionNumber: row['transaction_number'] as String,
            transactionDate: row['transaction_date'] as int,
            userId: row['user_id'] as String,
            subtotal: (row['subtotal'] as num).toDouble(),
            taxAmount: (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
            serviceChargeAmount: (row['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
            totalAmount: (row['total_amount'] as num).toDouble(),
            discountAmount: (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: row['payment_method'] as String,
            businessMode: row['business_mode'] as String,
            tableId: row['table_id'] as String?,
            orderNumber: row['order_number'] as int?,
            customerId: row['customer_id'] as String?,
            itemsJson: row['items_json'] as String,
            paymentsJson: row['payments_json'] as String?,
            refundStatus: row['refund_status'] as String? ?? 'none',
            refundAmount: (row['refund_amount'] as num?)?.toDouble() ?? 0.0,
            isSynced: (row['is_synced'] as int?) == 1,
            lastSyncedAt: row['last_synced_at'] as int?,
          );
          
          await IsarDatabaseService.saveTransaction(transaction);
          migrated++;
        } catch (e) {
          failed++;
          print('Failed to migrate transaction: $e');
        }
      }
      
      return MigrationResult(
        tableName: 'transactions',
        totalRecords: sqliteTransactions.length,
        migrated: migrated,
        failed: failed,
      );
    } catch (e) {
      print('Migration failed: $e');
      return MigrationResult(
        tableName: 'transactions',
        totalRecords: 0,
        migrated: 0,
        failed: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Migrate all inventory records from SQLite to Isar.
  Future<MigrationResult> migrateInventory() async {
    try {
      final List<Map<String, dynamic>> sqliteInventory = await sqliteDb.query('inventory');
      
      int migrated = 0;
      int failed = 0;
      
      for (final row in sqliteInventory) {
        try {
          final inventory = IsarInventory(
            backendId: row['backend_id'] as String? ?? '',
            productId: row['product_id'] as String,
            currentQuantity: (row['current_quantity'] as num).toDouble(),
            minStockLevel: (row['min_stock_level'] as num?)?.toDouble() ?? 0.0,
            maxStockLevel: (row['max_stock_level'] as num?)?.toDouble() ?? 0.0,
            reorderQuantity: (row['reorder_quantity'] as num?)?.toDouble() ?? 0.0,
            movementsJson: row['movements_json'] as String? ?? '[]',
            costPerUnit: (row['cost_per_unit'] as num?)?.toDouble(),
            inventoryValue: (row['inventory_value'] as num?)?.toDouble(),
            isSynced: (row['is_synced'] as int?) == 1,
            lastSyncedAt: row['last_synced_at'] as int?,
          );
          
          await IsarDatabaseService.saveInventory(inventory);
          migrated++;
        } catch (e) {
          failed++;
          print('Failed to migrate inventory: $e');
        }
      }
      
      return MigrationResult(
        tableName: 'inventory',
        totalRecords: sqliteInventory.length,
        migrated: migrated,
        failed: failed,
      );
    } catch (e) {
      print('Migration failed: $e');
      return MigrationResult(
        tableName: 'inventory',
        totalRecords: 0,
        migrated: 0,
        failed: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Perform complete migration from SQLite to Isar.
  /// 
  /// Migrates all tables in sequence.
  /// Returns list of MigrationResults for each table.
  Future<List<MigrationResult>> migrateAll() async {
    print('Starting full migration from SQLite to Isar...');
    
    final results = <MigrationResult>[];
    
    // Migrate products
    print('Migrating products...');
    final productResult = await migrateProducts();
    results.add(productResult);
    print(productResult.toString());
    
    // Migrate transactions
    print('Migrating transactions...');
    final transactionResult = await migrateTransactions();
    results.add(transactionResult);
    print(transactionResult.toString());
    
    // Migrate inventory
    print('Migrating inventory...');
    final inventoryResult = await migrateInventory();
    results.add(inventoryResult);
    print(inventoryResult.toString());
    
    // Summary
    final totalMigrated = results.fold<int>(0, (sum, r) => sum + r.migrated);
    final totalFailed = results.fold<int>(0, (sum, r) => sum + r.failed);
    
    print('\nMigration complete!');
    print('Total migrated: $totalMigrated');
    print('Total failed: $totalFailed');
    
    return results;
  }
  
  /// Verify migration integrity by comparing record counts.
  Future<Map<String, Map<String, int>>> verifyMigration() async {
    final productCount = (await sqliteDb.query('products')).length;
    final transactionCount = (await sqliteDb.query('transactions')).length;
    final inventoryCount = (await sqliteDb.query('inventory')).length;
    
    final isarProductCount = (await IsarDatabaseService.getAllProducts()).length;
    final isarTransactionCount = (await IsarDatabaseService.getAllTransactions()).length;
    final isarInventoryCount = (await IsarDatabaseService.getAllInventory()).length;
    
    return {
      'products': {'sqlite': productCount, 'isar': isarProductCount},
      'transactions': {'sqlite': transactionCount, 'isar': isarTransactionCount},
      'inventory': {'sqlite': inventoryCount, 'isar': isarInventoryCount},
    };
  }
}

/// Result of a table migration operation.
class MigrationResult {
  final String tableName;
  final int totalRecords;
  final int migrated;
  final int failed;
  final String? error;
  
  MigrationResult({
    required this.tableName,
    required this.totalRecords,
    required this.migrated,
    required this.failed,
    this.error,
  });
  
  bool get isSuccess => error == null && failed == 0 && migrated == totalRecords;
  
  double get successRate => totalRecords > 0 ? (migrated / totalRecords) * 100 : 0.0;
  
  @override
  String toString() {
    if (error != null) {
      return 'MigrationResult($tableName: ERROR - $error)';
    }
    return 'MigrationResult($tableName: $migrated/$totalRecords migrated, $failed failed, ${successRate.toStringAsFixed(1)}% success)';
  }
}
