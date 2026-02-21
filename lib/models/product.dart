import 'package:extropos/models/product_variant.dart';
import 'package:flutter/material.dart';

class Product {
  final String name;
  final double price;
  final String category;
  final IconData icon;
  final String? imagePath; // Local file path to product image
  final String?
  printerOverride; // Printer ID to override category-based printer selection
  final List<ProductVariant> variants; // Available variants for this product
  final bool hasVariants; // Whether this product has variants

  Product(
    this.name,
    this.price,
    this.category,
    this.icon, {
    this.imagePath,
    this.printerOverride,
    this.variants = const [],
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
      imagePath: imagePath,
      printerOverride: printerOverride,
      variants: newVariants,
    );
  }
}
