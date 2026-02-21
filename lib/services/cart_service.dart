import 'dart:developer' as developer;

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';

/// Enhanced cart service for robust cart operations with validation and real-time calculations
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// Get all cart items (immutable copy)
  List<CartItem> get items => List.unmodifiable(_items);

  /// Get total number of items in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Get total number of unique products
  int get uniqueItemCount => _items.length;

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  /// Add product to cart with validation
  /// Returns true if successfully added, false if validation failed
  bool addProduct(Product product, {int quantity = 1, String? notes}) {
    if (quantity <= 0) {
      developer.log('CartService: Cannot add product with quantity <= 0');
      return false;
    }

    // Check if product already exists in cart
    final existingIndex = _items.indexWhere((item) => item.product.name == product.name);

    if (existingIndex != -1) {
      // Product exists, increase quantity
      final newQuantity = _items[existingIndex].quantity + quantity;

      // Validate max quantity (reasonable limit)
      if (newQuantity > 999) {
        developer.log('CartService: Cannot exceed maximum quantity of 999');
        return false;
      }

      _items[existingIndex].quantity = newQuantity;
      if (notes != null && notes.isNotEmpty) {
        _items[existingIndex].notes = notes;
      }
    } else {
      // New product, add to cart
      final cartItem = CartItem(product, quantity, notes: notes);
      _items.add(cartItem);
    }

    developer.log('CartService: Added ${product.name} (qty: $quantity) to cart');
    notifyListeners();
    return true;
  }

  /// Remove product from cart by index
  bool removeItem(int index) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for removal');
      return false;
    }

    final removedItem = _items.removeAt(index);
    developer.log('CartService: Removed ${removedItem.product.name} from cart');
    notifyListeners();
    return true;
  }

  /// Update quantity of item at index
  bool updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for quantity update');
      return false;
    }

    if (newQuantity <= 0) {
      // Remove item if quantity is 0 or negative
      return removeItem(index);
    }

    if (newQuantity > 999) {
      developer.log('CartService: Cannot exceed maximum quantity of 999');
      return false;
    }

    _items[index].quantity = newQuantity;
    developer.log('CartService: Updated quantity of ${_items[index].product.name} to $newQuantity');
    notifyListeners();
    return true;
  }

  /// Increment quantity of item at index
  bool incrementQuantity(int index) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for increment');
      return false;
    }

    final currentQuantity = _items[index].quantity;
    if (currentQuantity >= 999) {
      developer.log('CartService: Cannot exceed maximum quantity of 999');
      return false;
    }

    _items[index].quantity = currentQuantity + 1;
    developer.log('CartService: Incremented quantity of ${_items[index].product.name} to ${_items[index].quantity}');
    notifyListeners();
    return true;
  }

  /// Decrement quantity of item at index
  bool decrementQuantity(int index) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for decrement');
      return false;
    }

    final currentQuantity = _items[index].quantity;
    if (currentQuantity <= 1) {
      // Remove item if quantity would be 0 or negative
      return removeItem(index);
    }

    _items[index].quantity = currentQuantity - 1;
    developer.log('CartService: Decremented quantity of ${_items[index].product.name} to ${_items[index].quantity}');
    notifyListeners();
    return true;
  }

  /// Set discount for item at index
  bool setItemDiscount(int index, double discount) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for discount update');
      return false;
    }

    if (discount < 0) {
      developer.log('CartService: Cannot set negative discount');
      return false;
    }

    final item = _items[index];
    final maxDiscount = item.product.price * item.quantity;
    if (discount > maxDiscount) {
      developer.log('CartService: Discount cannot exceed item total price');
      return false;
    }

    _items[index].discountPerUnit = discount / item.quantity;
    developer.log('CartService: Set discount of ${item.product.name} to $discount');
    notifyListeners();
    return true;
  }

  /// Set notes for item at index
  bool setItemNotes(int index, String? notes) {
    if (index < 0 || index >= _items.length) {
      developer.log('CartService: Invalid index $index for notes update');
      return false;
    }

    _items[index].notes = notes;
    developer.log('CartService: Set notes for ${_items[index].product.name}');
    notifyListeners();
    return true;
  }

  /// Clear entire cart
  void clearCart() {
    _items.clear();
    developer.log('CartService: Cleared entire cart');
    notifyListeners();
  }

  /// Get subtotal (sum of all item prices without tax/service charge)
  double getSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get total discount amount
  double getTotalDiscount() {
    return _items.fold(0.0, (sum, item) => sum + (item.discountPerUnit * item.quantity));
  }

  /// Get item at index (null if invalid index)
  CartItem? getItem(int index) {
    if (index < 0 || index >= _items.length) {
      return null;
    }
    return _items[index];
  }

  /// Check if product exists in cart
  bool containsProduct(Product product) {
    return _items.any((item) => item.product.name == product.name);
  }

  /// Get quantity of specific product in cart
  int getProductQuantity(Product product) {
    final item = _items.firstWhere(
      (item) => item.product.name == product.name,
      orElse: () => CartItem(product, 0),
    );
    return item.quantity;
  }

  /// Get cart summary for debugging
  Map<String, dynamic> getSummary() {
    return {
      'itemCount': itemCount,
      'uniqueItemCount': uniqueItemCount,
      'subtotal': getSubtotal(),
      'totalDiscount': getTotalDiscount(),
      'items': _items.map((item) => {
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'total': item.totalPrice,
        'discount': item.discountPerUnit * item.quantity,
      }).toList(),
    };
  }

  /// Validate cart state
  bool validateCart() {
    for (final item in _items) {
      if (item.quantity <= 0) {
        developer.log('CartService: Invalid quantity ${item.quantity} for ${item.product.name}');
        return false;
      }
      if (item.discountPerUnit < 0) {
        developer.log('CartService: Invalid discount ${item.discountPerUnit} for ${item.product.name}');
        return false;
      }
      final maxDiscount = item.product.price;
      if (item.discountPerUnit > maxDiscount) {
        developer.log('CartService: Discount ${item.discountPerUnit} exceeds price $maxDiscount for ${item.product.name}');
        return false;
      }
    }
    return true;
  }
}