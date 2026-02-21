import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_variant.dart';
import 'package:flutter/material.dart';

/// Test helper utilities for FlutterPOS testing
class TestHelper {
  /// Create a test product with default values
  static Product createTestProduct({
    String name = 'Test Product',
    double price = 10.0,
    String category = 'Test Category',
    IconData icon = Icons.star,
    String? imagePath,
    String? printerOverride,
    List<ProductVariant> variants = const [],
  }) {
    return Product(
      name,
      price,
      category,
      icon,
      imagePath: imagePath,
      printerOverride: printerOverride,
      variants: variants,
    );
  }

  /// Create multiple test products
  static List<Product> createTestProducts(int count) {
    return List.generate(
      count,
      (index) => createTestProduct(
        name: 'Product ${index + 1}',
        price: (index + 1) * 10.0,
      ),
    );
  }

  /// Create a cart item for testing
  static CartItem createTestCartItem({
    String name = 'Test Product',
    double price = 10.0,
    int quantity = 1,
    String? notes,
  }) {
    final product = createTestProduct(name: name, price: price);
    return CartItem(product, quantity, notes: notes);
  }
}