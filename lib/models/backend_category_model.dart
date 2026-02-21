/// Backend Category Model
/// This is BACKEND-specific for centralized category management
/// Separate from POS Category model which is for local sales operations
class BackendCategoryModel {
  final String? id; // Appwrite document ID
  final String name;
  final String description;
  final String? parentCategoryId; // For hierarchical categories
  final int sortOrder;
  final bool isActive;
  final String? iconName; // Icon reference (e.g., 'food', 'drink')
  final String? colorHex; // Color in hex format (e.g., '#FF5733')
  final double? defaultTaxRate; // Default tax rate for products in this category
  final Map<String, dynamic> customFields; // Flexible additional data
  final int createdAt;
  final int updatedAt;
  final String? createdBy;
  final String? updatedBy;

  BackendCategoryModel({
    this.id,
    required this.name,
    this.description = '',
    this.parentCategoryId,
    this.sortOrder = 0,
    this.isActive = true,
    this.iconName,
    this.colorHex,
    this.defaultTaxRate,
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Create a copy with modified fields
  BackendCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? parentCategoryId,
    int? sortOrder,
    bool? isActive,
    String? iconName,
    String? colorHex,
    double? defaultTaxRate,
    Map<String, dynamic>? customFields,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return BackendCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
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
      'parentCategoryId': parentCategoryId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'iconName': iconName,
      'colorHex': colorHex,
      'defaultTaxRate': defaultTaxRate,
      'customFields': customFields,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  /// Create from JSON (Appwrite document)
  factory BackendCategoryModel.fromMap(Map<String, dynamic> map) {
    return BackendCategoryModel(
      id: map[r'$id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      parentCategoryId: map['parentCategoryId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      iconName: map['iconName'] as String?,
      colorHex: map['colorHex'] as String?,
      defaultTaxRate: map['defaultTaxRate'] != null
          ? (map['defaultTaxRate'] as num).toDouble()
          : null,
      customFields: Map<String, dynamic>.from(map['customFields'] as Map? ?? {}),
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
    );
  }

  /// Check if this is a root category (no parent)
  bool get isRootCategory => parentCategoryId == null || parentCategoryId!.isEmpty;

  /// Check if this is a subcategory
  bool get isSubcategory => !isRootCategory;

  @override
  String toString() =>
      'BackendCategoryModel(id: $id, name: $name, sortOrder: $sortOrder, isActive: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          parentCategoryId == other.parentCategoryId;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ parentCategoryId.hashCode;
}
