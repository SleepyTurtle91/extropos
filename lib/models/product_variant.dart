class ProductVariant {
  final String id;
  final String name; // e.g., "Small", "Medium", "Large", "Red", "Blue"
  final double
  priceModifier; // Additional price (can be negative for discounts)
  final String? sku;
  final String? barcode;
  final bool isAvailable;
  final int stock;
  final bool trackStock;
  final String? imagePath;

  const ProductVariant({
    required this.id,
    required this.name,
    this.priceModifier = 0.0,
    this.sku,
    this.barcode,
    this.isAvailable = true,
    this.stock = 0,
    this.trackStock = false,
    this.imagePath,
  });

  double get totalPrice => priceModifier;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceModifier': priceModifier,
      'sku': sku,
      'barcode': barcode,
      'isAvailable': isAvailable ? 1 : 0,
      'stock': stock,
      'trackStock': trackStock ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'],
      name: map['name'],
      priceModifier: map['priceModifier'] ?? 0.0,
      sku: map['sku'],
      barcode: map['barcode'],
      isAvailable: (map['isAvailable'] ?? 1) == 1,
      stock: map['stock'] ?? 0,
      trackStock: (map['trackStock'] ?? 0) == 1,
      imagePath: map['imagePath'],
    );
  }

  ProductVariant copyWith({
    String? id,
    String? name,
    double? priceModifier,
    String? sku,
    String? barcode,
    bool? isAvailable,
    int? stock,
    bool? trackStock,
    String? imagePath,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      priceModifier: priceModifier ?? this.priceModifier,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductVariant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProductVariant(id: $id, name: $name, priceModifier: $priceModifier)';
  }
}
