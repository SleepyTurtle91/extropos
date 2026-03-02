import 'package:isar/isar.dart';

part 'inventory_model.g.dart';

/// Isar Inventory model for stock tracking
/// Tracks inventory levels, movements, and adjustments
@collection
class IsarInventory {
  /// Local Isar ID (auto-generated)
  Id id = Isar.autoIncrement;

  /// Backend document ID (from Appwrite/MongoDB) for sync matching
  late String backendId;

  /// Product ID (links to IsarProduct)
  late String productId;

  /// Product name (cached)
  String? productName;

  /// Current stock quantity
  late double currentQuantity;

  /// Minimum stock level (reorder point)
  double minStockLevel = 0.0;

  /// Maximum stock capacity
  double maxStockLevel = 0.0;

  /// Reorder quantity (how much to order when restocking)
  double reorderQuantity = 0.0;

  /// Last stock count/adjustment date
  int? lastCountedAt;

  /// Inventory movement history as JSON (array of movements)
  /// Each movement: {type, quantity, reason, timestamp, userId, ...}
  String movementsJson = '[]';

  /// Warehouse/location name
  String? warehouseLocation;

  /// SKU/Barcode reference
  String? sku;

  /// Cost per unit
  double? costPerUnit;

  /// Total inventory value (currentQuantity * costPerUnit)
  double? inventoryValue;

  /// Sync status
  bool isSynced = false;

  /// Timestamp of last sync
  int? lastSyncedAt;

  /// Timestamp of local creation
  late int createdAt;

  /// Timestamp of last local update
  late int updatedAt;

  /// Constructor with named parameters
  IsarInventory({
    required this.backendId,
    required this.productId,
    this.productName,
    required this.currentQuantity,
    this.minStockLevel = 0.0,
    this.maxStockLevel = 0.0,
    this.reorderQuantity = 0.0,
    this.lastCountedAt,
    this.movementsJson = '[]',
    this.warehouseLocation,
    this.sku,
    this.costPerUnit,
    this.inventoryValue,
    this.isSynced = false,
    this.lastSyncedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    createdAt = now;
    updatedAt = now;
  }

  /// Create IsarInventory from backend JSON
  factory IsarInventory.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return IsarInventory(
      backendId: json['\$id'] as String? ?? json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String?,
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0.0,
      maxStockLevel: (json['maxStockLevel'] as num?)?.toDouble() ?? 0.0,
      reorderQuantity: (json['reorderQuantity'] as num?)?.toDouble() ?? 0.0,
      lastCountedAt: json['lastCountedAt'] != null
          ? _parseTimestamp(json['lastCountedAt'])
          : null,
      movementsJson: json['movements'] != null
          ? (json['movements'] is String
              ? json['movements'] as String
              : _jsonEncode(json['movements']))
          : '[]',
      warehouseLocation: json['warehouseLocation'] as String?,
      sku: json['sku'] as String?,
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble(),
      inventoryValue: (json['inventoryValue'] as num?)?.toDouble(),
      isSynced: true,
      lastSyncedAt: now,
    )..createdAt = json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : now
     ..updatedAt = json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : now;
  }

  /// Convert IsarInventory to JSON for backend sync
  Map<String, dynamic> toJson() {
    return {
      '\$id': backendId,
      'id': backendId,
      'productId': productId,
      'productName': productName,
      'currentQuantity': currentQuantity,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'reorderQuantity': reorderQuantity,
      'lastCountedAt': lastCountedAt,
      'movements': _jsonDecode(movementsJson) ?? [],
      'warehouseLocation': warehouseLocation,
      'sku': sku,
      'costPerUnit': costPerUnit,
      'inventoryValue': inventoryValue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Add a stock movement entry
  void addMovement({
    required String type, // 'adjustment', 'sale', 'purchase', 'return', etc.
    required double quantity,
    required String reason,
    String? userId,
  }) {
    final movement = {
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final movements = _jsonDecode(movementsJson) as List? ?? [];
      movements.add(movement);
      movementsJson = _jsonEncode(movements);
        } catch (e) {
      movementsJson = _jsonEncode([movement]);
    }

    updatedAt = DateTime.now().millisecondsSinceEpoch;
    isSynced = false;
  }

  /// Check if stock is low
  bool isStockLow() {
    return currentQuantity <= minStockLevel;
  }

  /// Check if stock needs reorder
  bool needsReorder() {
    return currentQuantity <= minStockLevel && reorderQuantity > 0;
  }

  /// Helper: JSON string encode
  static String _jsonEncode(dynamic value) {
    return value.toString();
  }

  /// Helper: JSON string decode
  static dynamic _jsonDecode(String json) {
    try {
      if (json.startsWith('[') || json.startsWith('{')) {
        return json;
      }
      return json;
    } catch (e) {
      return null;
    }
  }

  /// Helper: Parse timestamp from Appwrite/ISO format
  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) return timestamp;
    if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp);
        return dt.millisecondsSinceEpoch;
      } catch (e) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  String toString() =>
      'IsarInventory(id: $id, backendId: $backendId, productId: $productId, currentQuantity: $currentQuantity, isSynced: $isSynced)';
}
