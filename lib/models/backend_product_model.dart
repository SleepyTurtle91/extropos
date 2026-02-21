/// Backend Product Model
/// This is BACKEND-specific for centralized product management
/// Separate from POS Product model which is for local sales operations
class BackendProductModel {
  final String? id; // Appwrite document ID
  final String name;
  final String description;
  final String? sku;
  final double basePrice;
  final double? costPrice;
  final String categoryId;
  final String? categoryName; // Cached for display
  final bool isActive;
  final bool trackInventory;
  final List<String> variantIds; // References to product variants
  final List<String> modifierGroupIds; // References to modifier groups
  final String? imageUrl;
  final Map<String, dynamic> customFields; // Flexible additional data
  final int createdAt;
  final int updatedAt;
  final String? createdBy;
  final String? updatedBy;

  BackendProductModel({
    this.id,
    required this.name,
    this.description = '',
    this.sku,
    required this.basePrice,
    this.costPrice,
    required this.categoryId,
    this.categoryName,
    this.isActive = true,
    this.trackInventory = true,
    this.variantIds = const [],
    this.modifierGroupIds = const [],
    this.imageUrl,
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Create a copy with modified fields
  BackendProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    double? basePrice,
    double? costPrice,
    String? categoryId,
    String? categoryName,
    bool? isActive,
    bool? trackInventory,
    List<String>? variantIds,
    List<String>? modifierGroupIds,
    String? imageUrl,
    Map<String, dynamic>? customFields,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return BackendProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      basePrice: basePrice ?? this.basePrice,
      costPrice: costPrice ?? this.costPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      trackInventory: trackInventory ?? this.trackInventory,
      variantIds: variantIds ?? this.variantIds,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      imageUrl: imageUrl ?? this.imageUrl,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sku': sku,
      'price': basePrice,
      'cost': costPrice,
      'category_id': categoryId,
      'categoryName': categoryName,
      'is_available': isActive,
      'track_stock': trackInventory,
      'variantIds': variantIds,
      'modifierGroupIds': modifierGroupIds,
      'image_url': imageUrl,
      'customFields': customFields,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  /// Create from JSON (Appwrite document)
  factory BackendProductModel.fromMap(Map<String, dynamic> map) {
    return BackendProductModel(
      id: map[r'$id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      sku: map['sku'] as String?,
      basePrice: (map['price'] as num).toDouble(),
      costPrice: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      categoryId: map['category_id'] as String,
      categoryName: map['categoryName'] as String?,
      isActive: map['is_available'] as bool? ?? true,
      trackInventory: map['track_stock'] as bool? ?? true,
      variantIds: List<String>.from(map['variantIds'] as List? ?? []),
      modifierGroupIds: List<String>.from(map['modifierGroupIds'] as List? ?? []),
      imageUrl: map['image_url'] as String?,
      customFields: Map<String, dynamic>.from(map['customFields'] as Map? ?? {}),
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
    );
  }

  /// Calculate profit margin percentage
  double? getProfitMargin() {
    if (costPrice == null || costPrice! <= 0) return null;
    return ((basePrice - costPrice!) / basePrice) * 100;
  }

  /// Check if product has variants
  bool get hasVariants => variantIds.isNotEmpty;

  /// Check if product has modifiers
  bool get hasModifiers => modifierGroupIds.isNotEmpty;

  @override
  String toString() =>
      'BackendProductModel(id: $id, name: $name, sku: $sku, basePrice: $basePrice, categoryId: $categoryId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          sku == other.sku &&
          basePrice == other.basePrice &&
          categoryId == other.categoryId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      sku.hashCode ^
      basePrice.hashCode ^
      categoryId.hashCode;
}
