// Inventory management models for stock tracking and control

class InventoryItem {
  final String id;
  final String productId;
  final String productName;

  /// Current stock quantity
  double currentQuantity;

  /// Minimum stock level (triggers reorder alert)
  double minStockLevel;

  /// Maximum stock level (prevents overstocking)
  double maxStockLevel;

  /// Quantity to reorder when stock is low
  double reorderQuantity;

  /// Cost per unit (for inventory valuation)
  double? costPerUnit;

  /// Stock movements history (JSON string)
  List<StockMovement> movements;

  /// Last stock count date
  DateTime? lastStockCountDate;

  /// Unit of measurement (e.g., 'pcs', 'kg', 'L')
  String unit;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.currentQuantity = 0.0,
    this.minStockLevel = 0.0,
    this.maxStockLevel = 0.0,
    this.reorderQuantity = 0.0,
    this.costPerUnit,
    List<StockMovement>? movements,
    this.lastStockCountDate,
    this.unit = 'pcs',
  }) : movements = movements ?? [];

  /// Check if stock is low
  bool get isLowStock => currentQuantity <= minStockLevel && minStockLevel > 0;

  /// Check if needs reorder
  bool get needsReorder => isLowStock && reorderQuantity > 0;

  /// Check if out of stock
  bool get isOutOfStock => currentQuantity <= 0;

  /// Get inventory value
  double get inventoryValue {
    if (costPerUnit == null) return 0.0;
    return currentQuantity * costPerUnit!;
  }

  /// Get stock status
  StockStatus get status {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.low;
    if (maxStockLevel > 0 && currentQuantity >= maxStockLevel) return StockStatus.overstock;
    return StockStatus.normal;
  }

  /// Get stock status display text
  String get statusDisplay {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.low:
        return 'Low Stock';
      case StockStatus.overstock:
        return 'Overstock';
      case StockStatus.normal:
        return 'Normal';
    }
  }

  /// Add stock movement
  void addMovement(StockMovement movement) {
    movements.add(movement);
    currentQuantity += movement.quantity;
    lastStockCountDate = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'currentQuantity': currentQuantity,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'reorderQuantity': reorderQuantity,
      'costPerUnit': costPerUnit,
      'movements': movements.map((m) => m.toJson()).toList(),
      'lastStockCountDate': lastStockCountDate?.millisecondsSinceEpoch,
      'unit': unit,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      currentQuantity: (json['currentQuantity'] ?? 0.0).toDouble(),
      minStockLevel: (json['minStockLevel'] ?? 0.0).toDouble(),
      maxStockLevel: (json['maxStockLevel'] ?? 0.0).toDouble(),
      reorderQuantity: (json['reorderQuantity'] ?? 0.0).toDouble(),
      costPerUnit: json['costPerUnit']?.toDouble(),
      movements: (json['movements'] as List? ?? [])
          .map((m) => StockMovement.fromJson(m))
          .toList(),
      lastStockCountDate: json['lastStockCountDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastStockCountDate'])
          : null,
      unit: json['unit'] ?? 'pcs',
    );
  }
}

/// Stock movement record
class StockMovement {
  final String id;
  final String type; // 'sale', 'purchase', 'adjustment', 'return', 'damage', 'transfer'
  final double quantity; // Positive for increase, negative for decrease
  final String reason;
  final DateTime date;
  final String? userId;
  final String? referenceId; // Transaction ID or PO ID

  StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    this.userId,
    this.referenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'date': date.millisecondsSinceEpoch,
      'userId': userId,
      'referenceId': referenceId,
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      userId: json['userId'],
      referenceId: json['referenceId'],
    );
  }
}

/// Stock status enum
enum StockStatus { outOfStock, low, normal, overstock }

/// Purchase order for restocking
class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final PurchaseOrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? receivedDate;
  final String? notes;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.receivedDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poNumber': poNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'expectedDeliveryDate': expectedDeliveryDate?.millisecondsSinceEpoch,
      'receivedDate': receivedDate?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] ?? '',
      poNumber: json['poNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => PurchaseOrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      status: PurchaseOrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PurchaseOrderStatus.draft,
      ),
      orderDate: DateTime.fromMillisecondsSinceEpoch(json['orderDate'] ?? 0),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expectedDeliveryDate'])
          : null,
      receivedDate: json['receivedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['receivedDate'])
          : null,
      notes: json['notes'],
    );
  }
}

/// Purchase order item
class PurchaseOrderItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double totalCost;

  PurchaseOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost,
    };
  }

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] ?? 0.0).toDouble(),
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
    );
  }
}

/// Purchase order status
enum PurchaseOrderStatus {
  draft,
  sent,
  confirmed,
  partiallyReceived,
  received,
  cancelled,
}

/// Supplier information
class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String? taxNumber;
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    this.taxNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'taxNumber': taxNumber,
      'isActive': isActive,
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      taxNumber: json['taxNumber'],
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Inventory report summary
class InventoryReport {
  final DateTime reportDate;
  final int totalProducts;
  final int lowStockItems;
  final int outOfStockItems;
  final double totalInventoryValue;
  final List<InventoryItem> topValueItems;
  final List<InventoryItem> lowStockList;

  InventoryReport({
    required this.reportDate,
    required this.totalProducts,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalInventoryValue,
    required this.topValueItems,
    required this.lowStockList,
  });

  String getSummary() {
    return '''
Inventory Report - ${reportDate.toString().split(' ')[0]}
═══════════════════════════════════════════════════
Total Products: $totalProducts
Low Stock Items: $lowStockItems
Out of Stock: $outOfStockItems
Total Inventory Value: RM ${totalInventoryValue.toStringAsFixed(2)}
═══════════════════════════════════════════════════
''';
  }
}
