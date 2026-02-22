import 'package:flutter/material.dart';

/// Enhanced Product model for POS system with database serialization support
/// and business mode filtering
class POSProduct {
  final String id;
  final String name;
  final double price;
  final String category;
  final String mode; // 'retail', 'cafe', 'restaurant', 'all'
  final Color color;
  final String? description;
  final String? barcode;
  final String? imageUrl;
  final bool isAvailable;
  final int stock;
  final bool trackStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  POSProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.mode = 'all',
    Color? color,
    this.description,
    this.barcode,
    this.imageUrl,
    this.isAvailable = true,
    this.stock = 0,
    this.trackStock = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : color = color ?? Colors.blue,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create POSProduct from database map
  factory POSProduct.fromMap(Map<String, dynamic> map) {
    return POSProduct(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String? ?? 'Uncategorized',
      mode: map['mode'] as String? ?? 'all',
      color: Color(map['color_value'] as int? ?? 0xFF2196F3),
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      stock: map['stock'] as int? ?? 0,
      trackStock: (map['track_stock'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert POSProduct to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'mode': mode,
      'color_value': color.value,
      'description': description,
      'barcode': barcode,
      'image_url': imageUrl,
      'is_available': isAvailable ? 1 : 0,
      'stock': stock,
      'track_stock': trackStock ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  POSProduct copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? mode,
    Color? color,
    String? description,
    String? barcode,
    String? imageUrl,
    bool? isAvailable,
    int? stock,
    bool? trackStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return POSProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      mode: mode ?? this.mode,
      color: color ?? this.color,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'POSProduct(id: $id, name: $name, price: $price, category: $category, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is POSProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
