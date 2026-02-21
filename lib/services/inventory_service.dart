import 'package:extropos/models/inventory_models.dart';

/// Inventory management service
/// Handles stock tracking, reordering, and inventory reports
class InventoryService {
  static final InventoryService _instance = InventoryService._internal();

  factory InventoryService() {
    return _instance;
  }

  InventoryService._internal();

  final Map<String, InventoryItem> _inventory = {};
  final List<PurchaseOrder> _purchaseOrders = [];
  final List<Supplier> _suppliers = [];

  /// Initialize inventory service
  Future<void> initialize() async {
    try {
      // TODO: Load from database
      print('✅ Inventory service initialized');
    } catch (e) {
      print('🔥 Error initializing inventory service: $e');
      rethrow;
    }
  }

  /// Get inventory item by product ID
  InventoryItem? getInventoryItem(String productId) {
    return _inventory[productId];
  }

  /// Get all inventory items
  List<InventoryItem> getAllInventory() {
    return _inventory.values.toList();
  }

  /// Get low stock items
  List<InventoryItem> getLowStockItems() {
    return _inventory.values.where((item) => item.isLowStock).toList();
  }

  /// Get out of stock items
  List<InventoryItem> getOutOfStockItems() {
    return _inventory.values.where((item) => item.isOutOfStock).toList();
  }

  /// Get items needing reorder
  List<InventoryItem> getItemsNeedingReorder() {
    return _inventory.values.where((item) => item.needsReorder).toList();
  }

  /// Update stock after sale
  Future<void> updateStockAfterSale(
    String productId,
    double quantity, {
    required String transactionId,
    String? userId,
  }) async {
    try {
      final item = _inventory[productId];

      if (item == null) {
        print('⚠️ Product not found in inventory: $productId');
        return;
      }

      final movement = StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'sale',
        quantity: -quantity, // Negative for stock reduction
        reason: 'Sale - Transaction $transactionId',
        date: DateTime.now(),
        userId: userId,
        referenceId: transactionId,
      );

      item.addMovement(movement);

      print('📦 Stock updated: ${item.productName} - ${item.currentQuantity} ${item.unit}');

      // Check if reorder is needed
      if (item.needsReorder) {
        print('⚠️ REORDER ALERT: ${item.productName} is low (${item.currentQuantity} ${item.unit})');
      }

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error updating stock: $e');
      rethrow;
    }
  }

  /// Add stock (purchase/restock)
  Future<void> addStock(
    String productId,
    double quantity, {
    required String reason,
    String? userId,
    String? referenceId,
  }) async {
    try {
      final item = _inventory[productId];

      if (item == null) {
        print('⚠️ Product not found in inventory: $productId');
        return;
      }

      final movement = StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'purchase',
        quantity: quantity, // Positive for stock increase
        reason: reason,
        date: DateTime.now(),
        userId: userId,
        referenceId: referenceId,
      );

      item.addMovement(movement);

      print('✅ Stock added: ${item.productName} + $quantity ${item.unit}');

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error adding stock: $e');
      rethrow;
    }
  }

  /// Adjust stock (manual count correction)
  Future<void> adjustStock(
    String productId,
    double newQuantity, {
    required String reason,
    String? userId,
  }) async {
    try {
      final item = _inventory[productId];

      if (item == null) {
        print('⚠️ Product not found in inventory: $productId');
        return;
      }

      final difference = newQuantity - item.currentQuantity;

      final movement = StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'adjustment',
        quantity: difference,
        reason: reason,
        date: DateTime.now(),
        userId: userId,
      );

      item.addMovement(movement);

      print('🔧 Stock adjusted: ${item.productName} → $newQuantity ${item.unit}');

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error adjusting stock: $e');
      rethrow;
    }
  }

  /// Record damaged/lost stock
  Future<void> recordDamage(
    String productId,
    double quantity, {
    required String reason,
    String? userId,
  }) async {
    try {
      final item = _inventory[productId];

      if (item == null) {
        print('⚠️ Product not found in inventory: $productId');
        return;
      }

      final movement = StockMovement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'damage',
        quantity: -quantity, // Negative for stock reduction
        reason: reason,
        date: DateTime.now(),
        userId: userId,
      );

      item.addMovement(movement);

      print('⚠️ Damage recorded: ${item.productName} - $quantity ${item.unit}');

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error recording damage: $e');
      rethrow;
    }
  }

  /// Create purchase order
  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required String supplierName,
    required List<PurchaseOrderItem> items,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) async {
    try {
      final poNumber = _generatePONumber();
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalCost);

      final po = PurchaseOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poNumber: poNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        items: items,
        totalAmount: totalAmount,
        status: PurchaseOrderStatus.draft,
        orderDate: DateTime.now(),
        expectedDeliveryDate: expectedDeliveryDate,
        notes: notes,
      );

      _purchaseOrders.add(po);

      print('📝 Purchase order created: $poNumber (RM ${totalAmount.toStringAsFixed(2)})');

      // TODO: Save to database

      return po;
    } catch (e) {
      print('🔥 Error creating purchase order: $e');
      rethrow;
    }
  }

  /// Receive purchase order
  Future<void> receivePurchaseOrder(String poId) async {
    try {
      final po = _purchaseOrders.firstWhere((p) => p.id == poId);

      // Add stock for each item
      for (final item in po.items) {
        await addStock(
          item.productId,
          item.quantity,
          reason: 'Purchase Order ${po.poNumber}',
          referenceId: po.id,
        );
      }

      print('✅ Purchase order received: ${po.poNumber}');

      // TODO: Update PO status in database
    } catch (e) {
      print('🔥 Error receiving purchase order: $e');
      rethrow;
    }
  }

  /// Generate inventory report
  Future<InventoryReport> generateInventoryReport() async {
    try {
      final allItems = getAllInventory();
      final lowStock = getLowStockItems();
      final outOfStock = getOutOfStockItems();

      final totalValue = allItems.fold(0.0, (sum, item) => sum + item.inventoryValue);

      // Get top 10 most valuable items
      final topValue = List<InventoryItem>.from(allItems)
        ..sort((a, b) => b.inventoryValue.compareTo(a.inventoryValue));

      return InventoryReport(
        reportDate: DateTime.now(),
        totalProducts: allItems.length,
        lowStockItems: lowStock.length,
        outOfStockItems: outOfStock.length,
        totalInventoryValue: totalValue,
        topValueItems: topValue.take(10).toList(),
        lowStockList: lowStock,
      );
    } catch (e) {
      print('🔥 Error generating inventory report: $e');
      rethrow;
    }
  }

  /// Set stock levels for product
  Future<void> setStockLevels({
    required String productId,
    required double minStock,
    required double maxStock,
    required double reorderQty,
  }) async {
    try {
      final item = _inventory[productId];

      if (item == null) {
        print('⚠️ Product not found in inventory: $productId');
        return;
      }

      item.minStockLevel = minStock;
      item.maxStockLevel = maxStock;
      item.reorderQuantity = reorderQty;

      print('✅ Stock levels updated: ${item.productName}');
      print('   Min: $minStock, Max: $maxStock, Reorder: $reorderQty');

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error setting stock levels: $e');
      rethrow;
    }
  }

  /// Get inventory statistics
  Map<String, dynamic> getInventoryStats() {
    final allItems = getAllInventory();
    final totalValue = allItems.fold(0.0, (sum, item) => sum + item.inventoryValue);

    return {
      'totalProducts': allItems.length,
      'lowStock': getLowStockItems().length,
      'outOfStock': getOutOfStockItems().length,
      'needsReorder': getItemsNeedingReorder().length,
      'totalValue': totalValue,
    };
  }

  /// Generate PO number: PO-YYYYMMDD-XXX
  String _generatePONumber() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final sequence = _purchaseOrders.length + 1;
    return 'PO-$dateStr-${sequence.toString().padLeft(3, '0')}';
  }

  /// Add supplier
  Future<void> addSupplier(Supplier supplier) async {
    try {
      _suppliers.add(supplier);
      print('✅ Supplier added: ${supplier.name}');

      // TODO: Save to database
    } catch (e) {
      print('🔥 Error adding supplier: $e');
      rethrow;
    }
  }

  /// Get all suppliers
  List<Supplier> getAllSuppliers() {
    return _suppliers.where((s) => s.isActive).toList();
  }
}
