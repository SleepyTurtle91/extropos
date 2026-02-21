import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/foundation.dart';

/// Phase 1 Inventory Service for Stock Management
/// Handles inventory operations, stock adjustments, and movements tracking
/// This is the BACKEND-specific inventory service (separate from POS inventory)
class Phase1InventoryService extends ChangeNotifier {
  static Phase1InventoryService? _instance;

  // In-memory storage (in Phase 2, this will use Appwrite)
  final Map<String, InventoryModel> _inventory = {};
  final AuditService _auditService = AuditService.instance;

  Phase1InventoryService._internal();

  factory Phase1InventoryService() {
    _instance ??= Phase1InventoryService._internal();
    return _instance!;
  }

  static Phase1InventoryService get instance => Phase1InventoryService();

  /// Get all inventory items
  Future<List<InventoryModel>> getAllInventory() async {
    print('📦 Fetching all inventory items...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _inventory.values.toList();
  }

  /// Get inventory for a specific location
  Future<List<InventoryModel>> getInventoryByLocation(String locationId) async {
    print('📦 Fetching inventory for location: $locationId');
    await Future.delayed(const Duration(milliseconds: 100));
    return _inventory.values
        .where((item) => item.locationId == locationId)
        .toList();
  }

  /// Get inventory item by ID
  Future<InventoryModel?> getInventoryById(String inventoryId) async {
    print('🔍 Fetching inventory item: $inventoryId');
    await Future.delayed(const Duration(milliseconds: 50));
    return _inventory[inventoryId];
  }

  /// Get inventory for a product at a location
  Future<InventoryModel?> getInventoryByProductAndLocation(
    String productId,
    String locationId,
  ) async {
    print('🔍 Fetching inventory: product=$productId, location=$locationId');
    await Future.delayed(const Duration(milliseconds: 50));
    return _inventory.values.firstWhere(
      (item) =>
          item.productId == productId && item.locationId == locationId,
      orElse: () => null as dynamic,
    ) as InventoryModel?;
  }

  /// Create inventory for a product at a location
  Future<InventoryModel> createInventory({
    required String productId,
    required String productName,
    required String locationId,
    double initialQuantity = 0,
    double minimumStockLevel = 10,
    double maximumStockLevel = 100,
    double reorderQuantity = 50,
    double? costPerUnit,
  }) async {
    print('➕ Creating inventory: product=$productId, location=$locationId');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newInventory = InventoryModel(
      productId: productId,
      productName: productName,
      locationId: locationId,
      currentQuantity: initialQuantity,
      minimumStockLevel: minimumStockLevel,
      maximumStockLevel: maximumStockLevel,
      reorderQuantity: reorderQuantity,
      costPerUnit: costPerUnit,
      lastCountedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final key = '${productId}_${locationId}_${DateTime.now().millisecondsSinceEpoch}';
    final inventoryWithId = newInventory.copyWith(id: key);
    _inventory[key] = inventoryWithId;
    
    print('✅ Inventory created: $key');
    notifyListeners();
    return inventoryWithId;
  }

  /// Adjust stock (add or subtract)
  Future<InventoryModel> adjustStock({
    required String inventoryId,
    required double quantityChange,
    required String reason,
    required String adjustedBy,
    String? adjustedByName,
    String? referenceNumber,
  }) async {
    print('⚙️  Adjusting stock: $inventoryId, change: $quantityChange');

    final inventory = _inventory[inventoryId];
    if (inventory == null) {
      throw Exception('Inventory $inventoryId not found');
    }

    final newQuantity = inventory.currentQuantity + quantityChange;
    if (newQuantity < 0) {
      throw Exception('Cannot adjust stock below 0');
    }

    // Create stock movement
    final movement = StockMovementModel(
      inventoryId: inventoryId,
      productId: inventory.productId,
      productName: inventory.productName,
      type: StockMovementType.adjustment,
      quantity: quantityChange,
      quantityBefore: inventory.currentQuantity,
      quantityAfter: newQuantity,
      reason: reason,
      referenceNumber: referenceNumber,
      createdBy: adjustedBy,
      createdByName: adjustedByName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      locationId: inventory.locationId,
    );

    // Update inventory
    final updatedInventory = inventory.addMovement(movement);
    _inventory[inventoryId] = updatedInventory;

    // Log activity
    await _auditService.logActivity(
      userId: adjustedBy,
      userName: adjustedByName ?? adjustedBy,
      action: 'adjust_stock',
      resourceType: 'inventory',
      resourceId: inventoryId,
      resourceName: inventory.productName,
      description: '$reason (${quantityChange > 0 ? '+' : ''}$quantityChange)',
      changesBefore: {'quantity': inventory.currentQuantity},
      changesAfter: {'quantity': newQuantity},
    );

    print('✅ Stock adjusted: $inventoryId');
    notifyListeners();
    return updatedInventory;
  }

  /// Record a sale (reduces stock)
  Future<InventoryModel> recordSale({
    required String inventoryId,
    required double quantity,
    required String recordedBy,
    String? recordedByName,
    String? receiptNumber,
  }) async {
    print('🛒 Recording sale: $inventoryId, quantity: $quantity');

    if (quantity <= 0) {
      throw Exception('Sale quantity must be positive');
    }

    return adjustStock(
      inventoryId: inventoryId,
      quantityChange: -quantity,
      reason: 'Sale',
      adjustedBy: recordedBy,
      adjustedByName: recordedByName,
      referenceNumber: receiptNumber,
    );
  }

  /// Perform stock take (physical count)
  Future<InventoryModel> performStockTake({
    required String inventoryId,
    required double countedQuantity,
    required String countedBy,
    String? countedByName,
    String? notes,
  }) async {
    print('📊 Performing stock take: $inventoryId, counted: $countedQuantity');

    final inventory = _inventory[inventoryId];
    if (inventory == null) {
      throw Exception('Inventory $inventoryId not found');
    }

    final variance = countedQuantity - inventory.currentQuantity;

    final movement = StockMovementModel(
      inventoryId: inventoryId,
      productId: inventory.productId,
      productName: inventory.productName,
      type: StockMovementType.adjustment,
      quantity: variance,
      quantityBefore: inventory.currentQuantity,
      quantityAfter: countedQuantity,
      reason: 'Physical stock take',
      createdBy: countedBy,
      createdByName: countedByName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      locationId: inventory.locationId,
      metadata: {'variance': variance, 'notes': notes},
    );

    final updatedInventory = inventory.copyWith(
      currentQuantity: countedQuantity,
      movements: [...inventory.movements, movement],
      lastCountedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _inventory[inventoryId] = updatedInventory;

    // Log activity
    await _auditService.logActivity(
      userId: countedBy,
      userName: countedByName ?? countedBy,
      action: 'stock_take',
      resourceType: 'inventory',
      resourceId: inventoryId,
      resourceName: inventory.productName,
      description: 'Stock take - variance: $variance',
      changesBefore: {'quantity': inventory.currentQuantity},
      changesAfter: {'quantity': countedQuantity},
    );

    print('✅ Stock take completed: $inventoryId, variance: $variance');
    notifyListeners();
    return updatedInventory;
  }

  /// Get low stock items
  Future<List<InventoryModel>> getLowStockItems({String? locationId}) async {
    print('⚠️  Fetching low stock items...');
    await Future.delayed(const Duration(milliseconds: 100));

    return _inventory.values
        .where((item) {
          if (locationId != null && item.locationId != locationId) return false;
          return item.isLowStock();
        })
        .toList();
  }

  /// Get out of stock items
  Future<List<InventoryModel>> getOutOfStockItems({String? locationId}) async {
    print('❌ Fetching out of stock items...');
    await Future.delayed(const Duration(milliseconds: 100));

    return _inventory.values
        .where((item) {
          if (locationId != null && item.locationId != locationId) return false;
          return item.isOutOfStock();
        })
        .toList();
  }

  /// Get items that need reorder
  Future<List<InventoryModel>> getItemsNeedingReorder({String? locationId}) async {
    print('📦 Fetching items needing reorder...');
    await Future.delayed(const Duration(milliseconds: 100));

    return _inventory.values
        .where((item) {
          if (locationId != null && item.locationId != locationId) return false;
          return item.needsReorder();
        })
        .toList();
  }

  /// Get total inventory value
  Future<double> getTotalInventoryValue({String? locationId}) async {
    print('💰 Calculating total inventory value...');
    await Future.delayed(const Duration(milliseconds: 100));

    return _inventory.values
        .where((item) =>
            locationId == null || item.locationId == locationId)
        .fold(0.0, (sum, item) => sum + item.getInventoryValue());
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStatistics({String? locationId}) async {
    print('📊 Calculating inventory statistics...');
    await Future.delayed(const Duration(milliseconds: 200));

    final items = locationId != null
        ? _inventory.values
            .where((item) => item.locationId == locationId)
            .toList()
        : _inventory.values.toList();

    final lowStockCount = items.where((item) => item.isLowStock()).length;
    final outOfStockCount = items.where((item) => item.isOutOfStock()).length;
    final totalValue = items.fold(0.0, (sum, item) => sum + item.getInventoryValue());
    final totalQuantity =
        items.fold(0.0, (sum, item) => sum + item.currentQuantity);

    return {
      'totalItems': items.length,
      'lowStockItems': lowStockCount,
      'outOfStockItems': outOfStockCount,
      'totalInventoryValue': totalValue.toStringAsFixed(2),
      'totalQuantity': totalQuantity.toStringAsFixed(2),
      'averageItemValue': items.isEmpty
          ? 0
          : (totalValue / items.length).toStringAsFixed(2),
    };
  }

  /// Seed test data
  Future<void> seedTestData({String? createdBy}) async {
    print('🌱 Seeding test inventory...');

    try {
      await createInventory(
        productId: 'prod_pizza_001',
        productName: 'Margherita Pizza',
        locationId: 'loc_main',
        initialQuantity: 15,
        minimumStockLevel: 5,
        maximumStockLevel: 30,
        reorderQuantity: 20,
        costPerUnit: 5.50,
      );

      await createInventory(
        productId: 'prod_burger_001',
        productName: 'Classic Burger',
        locationId: 'loc_main',
        initialQuantity: 8,
        minimumStockLevel: 5,
        maximumStockLevel: 25,
        reorderQuantity: 15,
        costPerUnit: 3.50,
      );

      await createInventory(
        productId: 'prod_coffee_001',
        productName: 'Espresso',
        locationId: 'loc_main',
        initialQuantity: 2,
        minimumStockLevel: 10,
        maximumStockLevel: 50,
        reorderQuantity: 30,
        costPerUnit: 2.00,
      );

      print('✅ Test inventory seeded successfully (3 items)');
    } catch (e) {
      print('❌ Error seeding test inventory: $e');
      rethrow;
    }
  }

  /// Clear all inventory (for testing)
  void _clearAllInventory() {
    _inventory.clear();
    notifyListeners();
  }

  @override
  String toString() => 'Phase1InventoryService(totalItems: ${_inventory.length})';
}
