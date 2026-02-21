/// Stock Movement type
enum StockMovementType { purchase, sale, adjustment, return_, waste, transfer }

/// Stock Movement Model
class StockMovementModel {
  final String? id; // Appwrite document ID
  final String inventoryId; // Reference to InventoryModel
  final String productId; // Reference to Product
  final String productName; // Cached product name
  final StockMovementType type;
  final double quantity; // Can be negative for sales/waste
  final double quantityBefore;
  final double quantityAfter;
  final String? reason; // Why the stock was adjusted
  final String? referenceNumber; // e.g., PO number, sales receipt number
  final String createdBy; // User ID who recorded this movement
  final String? createdByName; // Cached user name
  final int createdAt;
  final String? locationId; // Which warehouse/location
  final Map<String, dynamic>? metadata; // Additional data (e.g., supplier name)

  StockMovementModel({
    this.id,
    required this.inventoryId,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    this.reason,
    this.referenceNumber,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.locationId,
    this.metadata,
  });

  /// Create a copy with modified fields
  StockMovementModel copyWith({
    String? id,
    String? inventoryId,
    String? productId,
    String? productName,
    StockMovementType? type,
    double? quantity,
    double? quantityBefore,
    double? quantityAfter,
    String? reason,
    String? referenceNumber,
    String? createdBy,
    String? createdByName,
    int? createdAt,
    String? locationId,
    Map<String, dynamic>? metadata,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      quantityBefore: quantityBefore ?? this.quantityBefore,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      reason: reason ?? this.reason,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      locationId: locationId ?? this.locationId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'inventoryId': inventoryId,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'quantityBefore': quantityBefore,
      'quantityAfter': quantityAfter,
      'reason': reason,
      'referenceNumber': referenceNumber,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'locationId': locationId,
      'metadata': metadata,
    };
  }

  /// Create from JSON from Appwrite
  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['\$id'] as String?,
      inventoryId: map['inventoryId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      type: _parseMovementType(map['type'] as String?),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      quantityBefore: (map['quantityBefore'] as num?)?.toDouble() ?? 0.0,
      quantityAfter: (map['quantityAfter'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String?,
      referenceNumber: map['referenceNumber'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String?,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      locationId: map['locationId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get movement type display name
  String getTypeDisplay() {
    switch (type) {
      case StockMovementType.purchase:
        return 'Purchase';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.return_:
        return 'Return';
      case StockMovementType.waste:
        return 'Waste';
      case StockMovementType.transfer:
        return 'Transfer';
    }
  }

  /// Get movement icon
  String getTypeIcon() {
    switch (type) {
      case StockMovementType.purchase:
        return '📦';
      case StockMovementType.sale:
        return '🛒';
      case StockMovementType.adjustment:
        return '🔧';
      case StockMovementType.return_:
        return '↩️';
      case StockMovementType.waste:
        return '🗑️';
      case StockMovementType.transfer:
        return '➡️';
    }
  }

  /// Format timestamp for display
  String getFormattedDate() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'StockMovementModel(id: $id, type: ${type.name}, quantity: $quantity)';

  static StockMovementType _parseMovementType(String? value) {
    switch (value?.toLowerCase()) {
      case 'purchase':
        return StockMovementType.purchase;
      case 'sale':
        return StockMovementType.sale;
      case 'adjustment':
        return StockMovementType.adjustment;
      case 'return':
      case 'return_':
        return StockMovementType.return_;
      case 'waste':
        return StockMovementType.waste;
      case 'transfer':
        return StockMovementType.transfer;
      default:
        return StockMovementType.adjustment;
    }
  }
}

/// Inventory Model for Stock Management
class InventoryModel {
  final String? id; // Appwrite document ID
  final String productId; // Reference to Product
  final String productName; // Cached product name
  final String locationId; // Warehouse/branch location
  final double currentQuantity;
  final double minimumStockLevel; // Reorder point
  final double maximumStockLevel; // Max capacity
  final double reorderQuantity; // How much to order when below minimum
  final List<StockMovementModel> movements; // Array of movements
  final double? costPerUnit; // For inventory valuation
  final int lastCountedAt; // When stock was last physically counted
  final int createdAt;
  final int updatedAt;
  final String? notes;

  InventoryModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.locationId,
    required this.currentQuantity,
    required this.minimumStockLevel,
    required this.maximumStockLevel,
    required this.reorderQuantity,
    this.movements = const [],
    this.costPerUnit,
    required this.lastCountedAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Create a copy with modified fields
  InventoryModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? locationId,
    double? currentQuantity,
    double? minimumStockLevel,
    double? maximumStockLevel,
    double? reorderQuantity,
    List<StockMovementModel>? movements,
    double? costPerUnit,
    int? lastCountedAt,
    int? createdAt,
    int? updatedAt,
    String? notes,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      locationId: locationId ?? this.locationId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      maximumStockLevel: maximumStockLevel ?? this.maximumStockLevel,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      movements: movements ?? this.movements,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastCountedAt: lastCountedAt ?? this.lastCountedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'locationId': locationId,
      'currentQuantity': currentQuantity,
      'minimumStockLevel': minimumStockLevel,
      'maximumStockLevel': maximumStockLevel,
      'reorderQuantity': reorderQuantity,
      'movements': movements.map((m) => m.toMap()).toList(),
      'costPerUnit': costPerUnit,
      'lastCountedAt': lastCountedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes,
    };
  }

  /// Create from JSON from Appwrite
  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['\$id'] as String?,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      currentQuantity: (map['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      minimumStockLevel: (map['minimumStockLevel'] as num?)?.toDouble() ?? 0.0,
      maximumStockLevel: (map['maximumStockLevel'] as num?)?.toDouble() ?? 0.0,
      reorderQuantity: (map['reorderQuantity'] as num?)?.toDouble() ?? 0.0,
      movements: (map['movements'] as List<dynamic>?)
              ?.map((m) => StockMovementModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      costPerUnit: (map['costPerUnit'] as num?)?.toDouble(),
      lastCountedAt: map['lastCountedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      notes: map['notes'] as String?,
    );
  }

  /// Check if stock is low
  bool isLowStock() => currentQuantity <= minimumStockLevel;

  /// Check if stock is out
  bool isOutOfStock() => currentQuantity <= 0;

  /// Check if stock needs reorder
  bool needsReorder() => currentQuantity <= minimumStockLevel;

  /// Check if stock is overstock
  bool isOverstock() => currentQuantity > maximumStockLevel;

  /// Get stock status
  String getStockStatus() {
    if (isOutOfStock()) return 'Out of Stock';
    if (isLowStock()) return 'Low Stock';
    if (isOverstock()) return 'Overstock';
    return 'Normal';
  }

  /// Get stock status color
  String getStatusColor() {
    if (isOutOfStock()) return 'red';
    if (isLowStock()) return 'orange';
    if (isOverstock()) return 'yellow';
    return 'green';
  }

  /// Calculate inventory value
  double getInventoryValue() {
    if (costPerUnit == null) return 0.0;
    return currentQuantity * costPerUnit!;
  }

  /// Get stock percentage (0-100)
  double getStockPercentage() {
    if (maximumStockLevel == 0) return 0;
    return (currentQuantity / maximumStockLevel) * 100;
  }

  /// Add a stock movement
  InventoryModel addMovement(StockMovementModel movement) {
    final newMovements = [...movements, movement];
    return copyWith(
      movements: newMovements,
      currentQuantity: movement.quantityAfter,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() => 'InventoryModel(id: $id, productId: $productId, currentQuantity: $currentQuantity)';
}
