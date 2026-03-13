import 'dart:convert';

/// Lightweight compatibility models for legacy Isar-oriented services.
///
/// The project currently runs on SQLite; these models preserve API shape used
/// by legacy sync/migration helpers without requiring Isar code generation.
class IsarProduct {
  int id;
  String backendId;
  String name;
  double price;
  String categoryId;
  String? categoryName;
  String? sku;
  String? icon;
  String? imageUrl;
  String? variantsJson;
  String? modifierGroupIdsJson;
  double quantity;
  double? costPerUnit;
  bool isActive;
  bool isSynced;
  int? lastSyncedAt;
  int createdAt;
  int updatedAt;

  IsarProduct({
    this.id = 0,
    required this.backendId,
    required this.name,
    required this.price,
    required this.categoryId,
    this.categoryName,
    this.sku,
    this.icon,
    this.imageUrl,
    this.variantsJson,
    this.modifierGroupIdsJson,
    this.quantity = 0.0,
    this.costPerUnit,
    this.isActive = true,
    this.isSynced = false,
    this.lastSyncedAt,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt =
           updatedAt ?? createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory IsarProduct.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hasSyncFlag =
        json.containsKey('isSynced') || json.containsKey('is_synced');

    return IsarProduct(
      id: _asInt(json['id']) ?? 0,
      backendId:
          _asString(json[r'$id']) ??
          _asString(json['backendId']) ??
          _asString(json['backend_id']) ??
          '',
      name: _asString(json['name']) ?? '',
      price: _asDouble(json['price']) ?? 0.0,
      categoryId:
          _asString(json['categoryId']) ?? _asString(json['category_id']) ?? '',
      categoryName:
          _asString(json['categoryName']) ?? _asString(json['category_name']),
      sku: _asString(json['sku']),
      icon: _asString(json['icon']),
      imageUrl: _asString(json['imageUrl']) ?? _asString(json['image_url']),
      variantsJson:
          _asString(json['variantsJson']) ?? _asString(json['variants_json']),
      modifierGroupIdsJson:
          _asString(json['modifierGroupIdsJson']) ??
          _asString(json['modifier_group_ids_json']),
      quantity: _asDouble(json['quantity']) ?? 0.0,
      costPerUnit:
          _asDouble(json['costPerUnit']) ?? _asDouble(json['cost_per_unit']),
      isActive: _asBool(json['isActive'] ?? json['is_active']) ?? true,
      isSynced: hasSyncFlag
          ? (_asBool(json['isSynced'] ?? json['is_synced']) ?? false)
          : true,
      lastSyncedAt:
          _asInt(json['lastSyncedAt']) ?? _asInt(json['last_synced_at']),
      createdAt: _asInt(json['createdAt']) ?? _asInt(json['created_at']) ?? now,
      updatedAt: _asInt(json['updatedAt']) ?? _asInt(json['updated_at']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      r'$id': backendId,
      'id': id,
      'backendId': backendId,
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sku': sku,
      'icon': icon,
      'imageUrl': imageUrl,
      'variantsJson': variantsJson,
      'modifierGroupIdsJson': modifierGroupIdsJson,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'isActive': isActive,
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class IsarTransaction {
  int id;
  String backendId;
  String transactionNumber;
  int transactionDate;
  String userId;
  String? userName;
  double subtotal;
  double taxAmount;
  double serviceChargeAmount;
  double totalAmount;
  double discountAmount;
  String paymentMethod;
  String businessMode;
  String? tableId;
  String? tableName;
  int? orderNumber;
  String? customerId;
  String itemsJson;
  String? paymentsJson;
  String refundStatus;
  double refundAmount;
  String? refundReason;
  bool isSynced;
  int? lastSyncedAt;
  int createdAt;
  int updatedAt;

  IsarTransaction({
    this.id = 0,
    required this.backendId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.userId,
    this.userName,
    required this.subtotal,
    this.taxAmount = 0.0,
    this.serviceChargeAmount = 0.0,
    required this.totalAmount,
    this.discountAmount = 0.0,
    required this.paymentMethod,
    required this.businessMode,
    this.tableId,
    this.tableName,
    this.orderNumber,
    this.customerId,
    required this.itemsJson,
    this.paymentsJson,
    this.refundStatus = 'none',
    this.refundAmount = 0.0,
    this.refundReason,
    this.isSynced = false,
    this.lastSyncedAt,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt =
           updatedAt ?? createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory IsarTransaction.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hasSyncFlag =
        json.containsKey('isSynced') || json.containsKey('is_synced');

    String resolvedItemsJson =
        _asString(json['itemsJson']) ?? _asString(json['items_json']) ?? '[]';
    if ((resolvedItemsJson.isEmpty || resolvedItemsJson == '[]') &&
        json['items'] != null) {
      resolvedItemsJson = jsonEncode(json['items']);
    }

    String? resolvedPaymentsJson =
        _asString(json['paymentsJson']) ?? _asString(json['payments_json']);
    if ((resolvedPaymentsJson == null || resolvedPaymentsJson.isEmpty) &&
        json['payments'] != null) {
      resolvedPaymentsJson = jsonEncode(json['payments']);
    }

    return IsarTransaction(
      id: _asInt(json['id']) ?? 0,
      backendId:
          _asString(json[r'$id']) ??
          _asString(json['backendId']) ??
          _asString(json['backend_id']) ??
          '',
      transactionNumber:
          _asString(json['transactionNumber']) ??
          _asString(json['transaction_number']) ??
          '',
      transactionDate:
          _asInt(json['transactionDate']) ??
          _asInt(json['transaction_date']) ??
          now,
      userId: _asString(json['userId']) ?? _asString(json['user_id']) ?? '',
      userName: _asString(json['userName']) ?? _asString(json['user_name']),
      subtotal: _asDouble(json['subtotal']) ?? 0.0,
      taxAmount:
          _asDouble(json['taxAmount']) ?? _asDouble(json['tax_amount']) ?? 0.0,
      serviceChargeAmount:
          _asDouble(json['serviceChargeAmount']) ??
          _asDouble(json['service_charge_amount']) ??
          0.0,
      totalAmount:
          _asDouble(json['totalAmount']) ??
          _asDouble(json['total_amount']) ??
          0.0,
      discountAmount:
          _asDouble(json['discountAmount']) ??
          _asDouble(json['discount_amount']) ??
          0.0,
      paymentMethod:
          _asString(json['paymentMethod']) ??
          _asString(json['payment_method']) ??
          '',
      businessMode:
          _asString(json['businessMode']) ??
          _asString(json['business_mode']) ??
          '',
      tableId: _asString(json['tableId']) ?? _asString(json['table_id']),
      tableName: _asString(json['tableName']) ?? _asString(json['table_name']),
      orderNumber: _asInt(json['orderNumber']) ?? _asInt(json['order_number']),
      customerId:
          _asString(json['customerId']) ?? _asString(json['customer_id']),
      itemsJson: resolvedItemsJson,
      paymentsJson: resolvedPaymentsJson,
      refundStatus:
          _asString(json['refundStatus']) ??
          _asString(json['refund_status']) ??
          'none',
      refundAmount:
          _asDouble(json['refundAmount']) ??
          _asDouble(json['refund_amount']) ??
          0.0,
      refundReason:
          _asString(json['refundReason']) ?? _asString(json['refund_reason']),
      isSynced: hasSyncFlag
          ? (_asBool(json['isSynced'] ?? json['is_synced']) ?? false)
          : true,
      lastSyncedAt:
          _asInt(json['lastSyncedAt']) ?? _asInt(json['last_synced_at']),
      createdAt: _asInt(json['createdAt']) ?? _asInt(json['created_at']) ?? now,
      updatedAt: _asInt(json['updatedAt']) ?? _asInt(json['updated_at']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      r'$id': backendId,
      'id': id,
      'backendId': backendId,
      'transactionNumber': transactionNumber,
      'transactionDate': transactionDate,
      'userId': userId,
      'userName': userName,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'paymentMethod': paymentMethod,
      'businessMode': businessMode,
      'tableId': tableId,
      'tableName': tableName,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'itemsJson': itemsJson,
      'paymentsJson': paymentsJson,
      'refundStatus': refundStatus,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class IsarInventory {
  int id;
  String backendId;
  String productId;
  String? productName;
  double currentQuantity;
  double minStockLevel;
  double maxStockLevel;
  double reorderQuantity;
  String movementsJson;
  double? costPerUnit;
  double? inventoryValue;
  bool isSynced;
  int? lastSyncedAt;
  int createdAt;
  int updatedAt;

  IsarInventory({
    this.id = 0,
    required this.backendId,
    required this.productId,
    this.productName,
    required this.currentQuantity,
    required this.minStockLevel,
    this.maxStockLevel = 0.0,
    this.reorderQuantity = 0.0,
    this.movementsJson = '[]',
    this.costPerUnit,
    this.inventoryValue,
    this.isSynced = false,
    this.lastSyncedAt,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt =
           updatedAt ?? createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory IsarInventory.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hasSyncFlag =
        json.containsKey('isSynced') || json.containsKey('is_synced');

    return IsarInventory(
      id: _asInt(json['id']) ?? 0,
      backendId:
          _asString(json[r'$id']) ??
          _asString(json['backendId']) ??
          _asString(json['backend_id']) ??
          '',
      productId:
          _asString(json['productId']) ?? _asString(json['product_id']) ?? '',
      productName:
          _asString(json['productName']) ?? _asString(json['product_name']),
      currentQuantity:
          _asDouble(json['currentQuantity']) ??
          _asDouble(json['current_quantity']) ??
          0.0,
      minStockLevel:
          _asDouble(json['minStockLevel']) ??
          _asDouble(json['min_stock_level']) ??
          0.0,
      maxStockLevel:
          _asDouble(json['maxStockLevel']) ??
          _asDouble(json['max_stock_level']) ??
          0.0,
      reorderQuantity:
          _asDouble(json['reorderQuantity']) ??
          _asDouble(json['reorder_quantity']) ??
          0.0,
      movementsJson:
          _asString(json['movementsJson']) ??
          _asString(json['movements_json']) ??
          '[]',
      costPerUnit:
          _asDouble(json['costPerUnit']) ?? _asDouble(json['cost_per_unit']),
      inventoryValue:
          _asDouble(json['inventoryValue']) ??
          _asDouble(json['inventory_value']),
      isSynced: hasSyncFlag
          ? (_asBool(json['isSynced'] ?? json['is_synced']) ?? false)
          : true,
      lastSyncedAt:
          _asInt(json['lastSyncedAt']) ?? _asInt(json['last_synced_at']),
      createdAt: _asInt(json['createdAt']) ?? _asInt(json['created_at']) ?? now,
      updatedAt: _asInt(json['updatedAt']) ?? _asInt(json['updated_at']) ?? now,
    );
  }

  bool isStockLow() => currentQuantity < minStockLevel;

  bool needsReorder() => isStockLow() && reorderQuantity > 0;

  void addMovement({
    required String type,
    required double quantity,
    required String reason,
    String? userId,
  }) {
    final existing = _safeDecodeList(movementsJson);
    existing.add({
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'userId': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    movementsJson = jsonEncode(existing);
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toJson() {
    return {
      r'$id': backendId,
      'id': id,
      'backendId': backendId,
      'productId': productId,
      'productName': productName,
      'currentQuantity': currentQuantity,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'reorderQuantity': reorderQuantity,
      'movementsJson': movementsJson,
      'costPerUnit': costPerUnit,
      'inventoryValue': inventoryValue,
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

bool? _asBool(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value.toString().toLowerCase().trim();
  if (normalized == 'true' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == '0') {
    return false;
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }
  return value.toString();
}

List<dynamic> _safeDecodeList(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is List<dynamic>) {
      return decoded;
    }
  } catch (_) {
    // Fall through to empty list.
  }
  return <dynamic>[];
}
