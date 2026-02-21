import 'dart:convert';

import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/foundation.dart';

/// Phase 1 Inventory Service - Appwrite Version
///
/// Manages inventory tracking with Appwrite backend
/// - Stock tracking per product
/// - Stock movements (sale, restock, adjustment, return, damage, stocktake)
/// - Low stock alerts
/// - Stock takes (physical inventory counts)
/// - Real-time inventory value calculations
class Phase1InventoryServiceAppwrite extends ChangeNotifier {
  static Phase1InventoryServiceAppwrite? _instance;

  final AppwritePhase1Service _appwrite = AppwritePhase1Service();
  final AuditService _auditService = AuditService.instance;

  // Local cache for performance
  final Map<String, InventoryModel> _inventoryCache = {};
  DateTime? _lastCacheRefresh;
  final Duration _cacheExpiry = const Duration(minutes: 5);
  static bool get _isTest {
    return bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  Phase1InventoryServiceAppwrite._internal();

  factory Phase1InventoryServiceAppwrite() {
    _instance ??= Phase1InventoryServiceAppwrite._internal();
    return _instance!;
  }

  static Phase1InventoryServiceAppwrite get instance =>
      Phase1InventoryServiceAppwrite();

  /// Ensure Appwrite is initialized
  Future<bool> ensureInitialized() async {
    if (_isTest) {
      return false;
    }
    if (!_appwrite.isInitialized) {
      try {
        return await _appwrite
            .initialize()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ Appwrite initialization failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Refresh cache if expired
  Future<void> _refreshCacheIfNeeded() async {
    final now = DateTime.now();
    if (_lastCacheRefresh == null ||
        now.difference(_lastCacheRefresh!).compareTo(_cacheExpiry) > 0) {
      print('🔄 Refreshing inventory cache...');
      final items = await _fetchAllInventoryFromAppwrite();
      _inventoryCache.clear();
      for (final item in items) {
        _inventoryCache[item.productId] = item;
      }
      _lastCacheRefresh = now;
    }
  }

  /// Get all inventory items
  Future<List<InventoryModel>> getAllInventory() async {
    print('📦 Fetching all inventory...');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _inventoryCache.values.toList();
    }

    try {
      await _refreshCacheIfNeeded();
      return _inventoryCache.values.toList();
    } catch (e) {
      print('❌ Error fetching inventory: $e');
      return _inventoryCache.values.toList();
    }
  }

  /// Get inventory item by product ID
  Future<InventoryModel?> getInventoryByProductId(String productId) async {
    print('🔍 Fetching inventory for product: $productId');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _inventoryCache[productId];
    }

    if (_inventoryCache.containsKey(productId)) {
      return _inventoryCache[productId];
    }

    try {
      final doc = await _appwrite
          .getDocument(
            collectionId: AppwritePhase1Service.inventoryCol,
            documentId: productId,
          )
          .timeout(const Duration(seconds: 2));

      final inventory = _documentToInventoryModel(doc);
      _inventoryCache[productId] = inventory;
      return inventory;
    } catch (e) {
      print('❌ Error fetching inventory: $e');
      return null;
    }
  }

  /// Get low stock items
  Future<List<InventoryModel>> getLowStockItems() async {
    print('⚠️ Fetching low stock items...');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _inventoryCache.values
          .where((item) => item.currentQuantity <= item.minimumStockLevel)
          .toList();
    }

    try {
      final allItems = await getAllInventory();
      return allItems
          .where((item) => item.currentQuantity <= item.minimumStockLevel)
          .toList();
    } catch (e) {
      print('❌ Error fetching low stock items: $e');
      return [];
    }
  }

  /// Create inventory entry for new product
  Future<InventoryModel> createInventoryItem({
    required String productId,
    required String productName,
    required double minimumStockLevel,
    required double maximumStockLevel,
    double initialQuantity = 0.0,
    double? costPerUnit,
    String? createdBy,
    String locationId = 'main_warehouse',
  }) async {
    print('➕ Creating inventory for product: $productName');
    if (productId.trim().isEmpty) {
      throw Exception('Product ID cannot be empty');
    }

    if (productName.trim().isEmpty) {
      throw Exception('Product name cannot be empty');
    }

    if (initialQuantity < 0) {
      throw Exception('Initial quantity must be positive');
    }

    final initialized = await ensureInitialized();
    if (!initialized) {
      throw Exception('Appwrite not initialized');
    }

    if (await getInventoryByProductId(productId) != null) {
      throw Exception('Inventory already exists for product: $productId');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newInventory = InventoryModel(
      id: 'inv_$productId',
      productId: productId,
      productName: productName,
      locationId: locationId,
      currentQuantity: initialQuantity,
      minimumStockLevel: minimumStockLevel,
      maximumStockLevel: maximumStockLevel,
      reorderQuantity: 0.0,
      movements: initialQuantity > 0
          ? [
              StockMovementModel(
                inventoryId: 'inv_$productId',
                productId: productId,
                productName: productName,
                type: StockMovementType.purchase,
                quantity: initialQuantity,
                quantityBefore: 0.0,
                quantityAfter: initialQuantity,
                reason: 'Initial stock',
                createdBy: createdBy ?? 'system',
                createdAt: now,
              ),
            ]
          : [],
      costPerUnit: costPerUnit,
      lastCountedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final documentId = 'inv_$productId';
      await _appwrite.createDocument(
        collectionId: AppwritePhase1Service.inventoryCol,
        documentId: documentId,
        data: _inventoryModelToDocument(newInventory),
      );

      _inventoryCache[productId] = newInventory;
      notifyListeners();

      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'Inventory',
        resourceId: productId,
        changesAfter: _inventoryModelToDocument(newInventory),
        success: true,
      );

      print('✅ Inventory created: ${newInventory.id}');
      return newInventory;
    } catch (e) {
      print('❌ Error creating inventory: $e');

      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'Inventory',
        resourceId: productId,
        success: false,
      );

      throw Exception('Failed to create inventory: $e');
    }
  }

  /// Add stock movement (sale, restock, adjustment, return, damage, stocktake)
  Future<InventoryModel> addStockMovement({
    required String productId,
    required String movementType, // SALE, RESTOCK, ADJUSTMENT, RETURN, DAMAGE, STOCKTAKE
    required double quantity,
    required String reason,
    required String userId,
    double? newQuantity,
  }) async {
    print(
      '📝 Adding $movementType movement to product: $productId (qty: $quantity)',
    );
    if (quantity <= 0) {
      throw Exception('Quantity must be positive');
    }

    const validTypes = {
      'SALE',
      'RESTOCK',
      'ADJUSTMENT',
      'RETURN',
      'DAMAGE',
      'STOCKTAKE',
      'PURCHASE',
      'TRANSFER',
      'WASTE',
    };

    if (!validTypes.contains(movementType.toUpperCase())) {
      throw Exception('Invalid movement type: $movementType');
    }

    final initialized = await ensureInitialized();
    if (!initialized) {
      throw Exception('Appwrite not initialized');
    }

    final existing = await getInventoryByProductId(productId);
    if (existing == null) {
      throw Exception('Inventory not found for product: $productId');
    }

    // Validate quantity
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    // Calculate new quantity based on movement type
    double calculatedNewQuantity = existing.currentQuantity;
    switch (movementType.toUpperCase()) {
      case 'SALE':
      case 'DAMAGE':
      case 'ADJUSTMENT':
        calculatedNewQuantity -= quantity;
        break;
      case 'RESTOCK':
      case 'RETURN':
      case 'INITIAL':
        calculatedNewQuantity += quantity;
        break;
      case 'STOCKTAKE':
        // For stocktake, newQuantity must be provided
        calculatedNewQuantity = newQuantity ?? existing.currentQuantity;
        break;
    }

    // Validate non-negative quantity
    if (calculatedNewQuantity < 0) {
      throw Exception(
        'Insufficient stock. Current: ${existing.currentQuantity}, Requested: $quantity',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final movement = StockMovementModel(
      inventoryId: productId,
      productId: existing.productId,
      productName: existing.productName,
      type: _parseMovementType(movementType),
      quantity: quantity,
      quantityBefore: existing.currentQuantity,
      quantityAfter: calculatedNewQuantity,
      reason: reason,
      createdBy: userId,
      createdAt: now,
      locationId: existing.locationId,
    );

    // Create new movements list
    final updatedMovements = [...existing.movements, movement];

    final updatedInventory = existing.copyWith(
      currentQuantity: calculatedNewQuantity,
      movements: updatedMovements,
      updatedAt: now,
    );

    try {
      final documentId = existing.id ?? 'inv_${existing.productId}';
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.inventoryCol,
        documentId: documentId,
        data: {
          'currentQuantity': calculatedNewQuantity,
          'movements': jsonEncode(
            updatedMovements.map((m) => m.toMap()).toList(),
          ),
          'updatedAt': now,
        },
      );

      _inventoryCache[productId] = updatedInventory;
      notifyListeners();

      await _auditService.logActivity(
        userId: userId,
        userName: userId,
        action: 'STOCK_MOVEMENT',
        resourceType: 'Inventory',
        resourceId: productId,
        changesBefore: {
          'currentQuantity': existing.currentQuantity,
        },
        changesAfter: {
          'currentQuantity': calculatedNewQuantity,
          'movementType': movementType,
          'movementQuantity': quantity,
          'reason': reason,
        },
        success: true,
      );

      print('✅ Stock movement recorded: ${movement.id}');
      return updatedInventory;
    } catch (e) {
      print('❌ Error adding stock movement: $e');

      await _auditService.logActivity(
        userId: userId,
        userName: userId,
        action: 'STOCK_MOVEMENT',
        resourceType: 'Inventory',
        resourceId: productId,
        success: false,
      );

      throw Exception('Failed to add stock movement: $e');
    }
  }

  /// Adjust stock (quick adjustment without detailed reason)
  Future<InventoryModel> adjustStock({
    required String productId,
    required double newQuantity,
    required String reason,
    required String userId,
  }) async {
    print('🔧 Adjusting stock for product: $productId to $newQuantity');

    final existing = await getInventoryByProductId(productId);
    if (existing == null) {
      throw Exception('Inventory not found for product: $productId');
    }

    final quantityChange = newQuantity - existing.currentQuantity;
    final movementType = quantityChange > 0 ? 'ADJUSTMENT' : 'ADJUSTMENT';

    return await addStockMovement(
      productId: productId,
      movementType: movementType,
      quantity: quantityChange.abs(),
      reason: reason,
      userId: userId,
      newQuantity: newQuantity,
    );
  }

  /// Perform stock take (physical inventory count)
  Future<InventoryModel> performStockTake({
    required String productId,
    required double countedQuantity,
    required String userId,
    String? notes,
  }) async {
    print('📊 Recording stock take for product: $productId');

    final existing = await getInventoryByProductId(productId);
    if (existing == null) {
      throw Exception('Inventory not found for product: $productId');
    }

    final variance = countedQuantity - existing.currentQuantity;

    return await addStockMovement(
      productId: productId,
      movementType: 'STOCKTAKE',
      quantity: variance.abs(),
      reason: 'Stock take${notes != null ? ': $notes' : ''}',
      userId: userId,
      newQuantity: countedQuantity,
    );
  }

  /// Get stock movement history
  Future<List<StockMovementModel>> getMovementHistory({
    required String productId,
    int limit = 50,
  }) async {
    print('📜 Fetching movement history for product: $productId');

    final inventory = await getInventoryByProductId(productId);
    if (inventory == null) {
      return [];
    }

    return inventory.movements.take(limit).toList();
  }

  /// Calculate inventory value
  Future<double> calculateInventoryValue() async {
    print('💰 Calculating total inventory value...');

    final allItems = await getAllInventory();
    double totalValue = 0.0;

    for (final item in allItems) {
      if (item.costPerUnit != null) {
        totalValue += item.currentQuantity * item.costPerUnit!;
      }
    }

    return totalValue;
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStatistics() async {
    print('📊 Calculating inventory statistics...');

    try {
      final allItems = await getAllInventory();
      final lowStockItems = await getLowStockItems();

      double totalQuantity = 0.0;
      double totalValue = 0.0;
      int totalProducts = allItems.length;

      for (final item in allItems) {
        totalQuantity += item.currentQuantity;
        if (item.costPerUnit != null) {
          totalValue += item.currentQuantity * item.costPerUnit!;
        }
      }

      return {
        'totalProducts': totalProducts,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue.toStringAsFixed(2),
        'lowStockCount': lowStockItems.length,
        'lowStockPercentage':
            totalProducts > 0 ? (lowStockItems.length / totalProducts * 100) : 0,
        'averageStockLevel':
            totalProducts > 0 ? totalQuantity / totalProducts : 0,
      };
    } catch (e) {
      print('❌ Error calculating statistics: $e');
      return {};
    }
  }

  /// Fetch all inventory from Appwrite
  Future<List<InventoryModel>> _fetchAllInventoryFromAppwrite() async {
    try {
      final docs = await _appwrite
          .listDocuments(
            collectionId: AppwritePhase1Service.inventoryCol,
            limit: 100,
          )
          .timeout(const Duration(seconds: 2));

      return docs.map(_documentToInventoryModel).toList();
    } catch (e) {
      print('❌ Error fetching inventory from Appwrite: $e');
      return [];
    }
  }

  /// Convert Appwrite document to InventoryModel
  InventoryModel _documentToInventoryModel(Map<String, dynamic> doc) {
    List<StockMovementModel> movements = [];
    final movementsJson = doc['movements'];

    if (movementsJson != null) {
      try {
        if (movementsJson is String) {
          final decoded = jsonDecode(movementsJson) as List;
          movements = decoded
              .map((m) => StockMovementModel.fromMap(m as Map<String, dynamic>))
              .toList();
        } else if (movementsJson is List) {
          movements = movementsJson
              .map(
                (m) => StockMovementModel.fromMap(m as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (e) {
        print('⚠️ Error parsing movements: $e');
      }
    }

    return InventoryModel(
      id: doc[r'$id'] ?? doc['id'] ?? '',
      productId: doc['productId'] ?? '',
      productName: doc['productName'] ?? '',
      locationId: doc['locationId'] ?? 'main_warehouse',
      currentQuantity: (doc['currentQuantity'] ?? 0).toDouble(),
      minimumStockLevel: (doc['minimumStockLevel'] ?? 0).toDouble(),
      maximumStockLevel: (doc['maximumStockLevel'] ?? 0).toDouble(),
      reorderQuantity: (doc['reorderQuantity'] ?? 0).toDouble(),
      movements: movements,
      costPerUnit: doc['costPerUnit'] != null
          ? (doc['costPerUnit'] as num).toDouble()
          : null,
      lastCountedAt: doc['lastCountedAt'] ?? 0,
      createdAt: doc['createdAt'] ?? 0,
      updatedAt: doc['updatedAt'] ?? 0,
      notes: doc['notes'],
    );
  }

  /// Convert InventoryModel to Appwrite document format
  Map<String, dynamic> _inventoryModelToDocument(InventoryModel inventory) {
    return {
      'productId': inventory.productId,
      'productName': inventory.productName,
      'locationId': inventory.locationId,
      'currentQuantity': inventory.currentQuantity,
      'minimumStockLevel': inventory.minimumStockLevel,
      'maximumStockLevel': inventory.maximumStockLevel,
      'reorderQuantity': inventory.reorderQuantity,
      'costPerUnit': inventory.costPerUnit,
      'lastCountedAt': inventory.lastCountedAt,
      'createdAt': inventory.createdAt,
      'updatedAt': inventory.updatedAt,
      'notes': inventory.notes,
      'movements':
          jsonEncode(inventory.movements.map((m) => m.toMap()).toList()),
    };
  }

  /// Parse movement type string to enum
  StockMovementType _parseMovementType(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return StockMovementType.purchase;
      case 'restock':
        return StockMovementType.purchase;
      case 'sale':
        return StockMovementType.sale;
      case 'adjustment':
        return StockMovementType.adjustment;
      case 'stocktake':
        return StockMovementType.adjustment;
      case 'return':
        return StockMovementType.return_;
      case 'damage':
        return StockMovementType.waste;
      case 'waste':
        return StockMovementType.waste;
      case 'transfer':
        return StockMovementType.transfer;
      default:
        return StockMovementType.adjustment;
    }
  }

  @override
  void dispose() {
    _inventoryCache.clear();
    super.dispose();
  }
}
