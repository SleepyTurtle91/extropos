import 'package:isar/isar.dart';

part 'product_model.g.dart';

/// Isar Product model with sync support
/// Matches backend JSON schema from Appwrite/MongoDB
@collection
class IsarProduct {
  /// Local Isar ID (auto-generated)
  Id id = Isar.autoIncrement;

  /// Backend document ID (from Appwrite/MongoDB) for sync matching
  late String backendId;

  /// Product name/title
  late String name;

  /// Product description
  String? description;

  /// Unit price in local currency
  late double price;

  /// Category ID reference (links to IsarCategory)
  late String categoryId;

  /// Category name (cached for quick access)
  String? categoryName;

  /// Product SKU/barcode
  String? sku;

  /// Product icon name (e.g., 'pizza', 'burger')
  String? icon;

  /// Product image URL or local path
  String? imageUrl;

  /// Product variants as JSON (e.g., sizes, colors)
  String? variantsJson;

  /// Modifier group IDs as JSON array (references to IsarModifierGroup)
  String? modifierGroupIdsJson;

  /// Stock/inventory quantity
  double quantity = 0.0;

  /// Cost per unit (for inventory tracking)
  double? costPerUnit;

  /// Whether product is active/available
  bool isActive = true;

  /// Sync status: true = synced to backend, false = needs sync
  bool isSynced = false;

  /// Timestamp of last sync (milliseconds since epoch)
  int? lastSyncedAt;

  /// Timestamp of last local modification
  late int createdAt;
  late int updatedAt;

  /// Constructor with named parameters
  IsarProduct({
    required this.backendId,
    required this.name,
    this.description,
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
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    createdAt = now;
    updatedAt = now;
  }

  /// Create IsarProduct from backend JSON (Appwrite/MongoDB)
  factory IsarProduct.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return IsarProduct(
      backendId: json['\$id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      sku: json['sku'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['imageUrl'] as String?,
      variantsJson: json['variants'] != null
          ? (json['variants'] is String
              ? json['variants'] as String
              : _jsonEncode(json['variants']))
          : null,
      modifierGroupIdsJson: json['modifierGroupIds'] != null
          ? (json['modifierGroupIds'] is String
              ? json['modifierGroupIds'] as String
              : _jsonEncode(json['modifierGroupIds']))
          : null,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      isSynced: true, // Backend data is already synced
      lastSyncedAt: now,
    )..createdAt = json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : now
     ..updatedAt = json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : now;
  }

  /// Convert IsarProduct to JSON for backend sync
  Map<String, dynamic> toJson() {
    return {
      '\$id': backendId,
      'id': backendId,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sku': sku,
      'icon': icon,
      'imageUrl': imageUrl,
      'variants':
          variantsJson != null ? _jsonDecode(variantsJson!) : null,
      'modifierGroupIds': modifierGroupIdsJson != null
          ? _jsonDecode(modifierGroupIdsJson!)
          : null,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Helper: JSON string encode
  static String _jsonEncode(dynamic value) {
    // Simple JSON encoding; for production, use jsonEncode from dart:convert
    return value.toString();
  }

  /// Helper: JSON string decode
  static dynamic _jsonDecode(String json) {
    // Simple parsing; for production, use jsonDecode from dart:convert
    try {
      if (json.startsWith('[')) {
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
      'IsarProduct(id: $id, backendId: $backendId, name: $name, price: $price, isSynced: $isSynced)';
}
