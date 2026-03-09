/// Product-related Models
/// Product definitions, variants, and pricing information
library;
import 'package:flutter/material.dart';

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

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final IconData icon;
  final String? imagePath; // Local file path to product image
  final String?
  printerOverride; // Printer ID to override category-based printer selection
  final List<ProductVariant> variants; // Available variants for this product
  final bool hasVariants; // Whether this product has variants
  final int stockQuantity; // Total stock quantity across all variants

  Product(
    this.name,
    this.price,
    this.category,
    this.icon, {
    required this.id,
    this.imagePath,
    this.printerOverride,
    this.variants = const [],
    this.stockQuantity = 0,
  }) : hasVariants = variants.isNotEmpty;

  // Get the display price (base price if no variants, or "From X" if variants exist)
  String getDisplayPrice(String currencySymbol) {
    if (!hasVariants) {
      return '$currencySymbol${price.toStringAsFixed(2)}';
    }

    final variantPrices = variants.map((v) => price + v.priceModifier);
    final minPrice = variantPrices.reduce((a, b) => a < b ? a : b);
    final maxPrice = variantPrices.reduce((a, b) => a > b ? a : b);

    if (minPrice == maxPrice) {
      return '$currencySymbol${minPrice.toStringAsFixed(2)}';
    } else {
      return 'From $currencySymbol${minPrice.toStringAsFixed(2)}';
    }
  }

  // Get variant by ID
  ProductVariant? getVariant(String variantId) {
    return variants.cast<ProductVariant?>().firstWhere(
      (v) => v?.id == variantId,
      orElse: () => null,
    );
  }

  // Create a copy with different variants
  Product copyWithVariants(List<ProductVariant> newVariants) {
    return Product(
      name,
      price,
      category,
      icon,
      id: id,
      imagePath: imagePath,
      printerOverride: printerOverride,
      variants: newVariants,
      stockQuantity: stockQuantity,
    );
  }
}
