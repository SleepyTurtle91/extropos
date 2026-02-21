import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? sku;
  final String? barcode;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool isFeatured;
  final int stock;
  final bool trackStock;
  final int lowStockThreshold;
  final double? cost;
  final String? imageUrl;
  final Map<String, double> merchantPrices;
  final List<String> tags;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String?
  printerOverride; // Printer ID to override category-based printer selection

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.sku,
    this.barcode,
    required this.icon,
    required this.color,
    this.isAvailable = true,
    this.isFeatured = false,
    this.stock = 0,
    this.trackStock = false,
    this.lowStockThreshold = 5,
    this.cost,
    this.imageUrl,
    Map<String, double>? merchantPrices,
    this.tags = const [],
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.printerOverride,
  }) : merchantPrices = merchantPrices ?? const {},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Item copyWith({
    Map<String, double>? merchantPrices,
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? sku,
    String? barcode,
    IconData? icon,
    Color? color,
    bool? isAvailable,
    bool? isFeatured,
    int? stock,
    bool? trackStock,
    int? lowStockThreshold,
    double? cost,
    String? imageUrl,
    List<String>? tags,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? printerOverride,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      merchantPrices: merchantPrices ?? this.merchantPrices,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      printerOverride: printerOverride ?? this.printerOverride,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'sku': sku,
      'barcode': barcode,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(),
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'stock': stock,
      'trackStock': trackStock,
      'lowStockThreshold': lowStockThreshold,
      'cost': cost,
      'imageUrl': imageUrl,
      'tags': tags,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'merchantPrices': merchantPrices,
      'updatedAt': updatedAt.toIso8601String(),
      'printerOverride': printerOverride,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      icon: Icons.inventory,
      color: Color(json['colorValue'] as int),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      trackStock: json['trackStock'] as bool? ?? false,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
      cost: (json['cost'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      merchantPrices:
          (json['merchantPrices'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      printerOverride: json['printerOverride'] as String?,
    );
  }

  double get profit => cost != null ? price - cost! : 0;
  double get profitMargin =>
      cost != null && cost! > 0 ? ((price - cost!) / cost!) * 100 : 0;
}
