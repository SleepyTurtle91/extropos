import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_variant.dart';
import 'package:flutter/material.dart';

class CartItem {
  final Product product;
  int quantity;
  final List<ModifierItem> modifiers;
  final double priceAdjustment;
  double discountPerUnit;
  int? seatNumber;
  final ProductVariant? selectedVariant; // Selected product variant
  String? notes; // Kitchen instructions or special notes

  CartItem(
    this.product,
    this.quantity, {
    this.modifiers = const [],
    this.priceAdjustment = 0.0,
    this.discountPerUnit = 0.0,
    this.seatNumber,
    this.selectedVariant,
    this.notes,
  });

  /// Get the final price including modifiers and variant price modifier
  double get finalPrice {
    double basePrice = product.price + priceAdjustment - discountPerUnit;
    if (selectedVariant != null) {
      basePrice += selectedVariant!.priceModifier;
    }
    return basePrice < 0 ? 0.0 : basePrice;
  }

  /// Get the total price for this cart item (price * quantity)
  double get totalPrice => finalPrice * quantity;

  /// Get a display string for selected modifiers
  String getModifiersDisplay() {
    if (modifiers.isEmpty) return '';
    return modifiers.map((m) => m.name).join(', ');
  }

  /// Get display string for selected variant
  String getVariantDisplay() {
    return selectedVariant?.name ?? '';
  }

  /// Get full display name including variant
  String getFullDisplayName() {
    final variantText = selectedVariant != null
        ? ' (${selectedVariant!.name})'
        : '';
    return '${product.name}$variantText';
  }

  /// Check if this cart item has the same product and modifiers as another
  bool hasSameConfiguration(
    Product otherProduct,
    List<ModifierItem> otherModifiers, {
    double otherPriceAdjustment = 0.0,
    int? otherSeatNumber,
    ProductVariant? otherVariant,
  }) {
    if (product.name != otherProduct.name) return false;
    if (modifiers.length != otherModifiers.length) return false;

    // Check variant match
    if (selectedVariant?.id != otherVariant?.id) return false;

    // Check if all modifier IDs match
    final thisModifierIds = modifiers.map((m) => m.id).toSet();
    final otherModifierIds = otherModifiers.map((m) => m.id).toSet();
    if (thisModifierIds.difference(otherModifierIds).isNotEmpty ||
        otherModifierIds.difference(thisModifierIds).isNotEmpty) {
      return false;
    }

    // Ensure price adjustment (merchant/variant) is the same. Different merchant
    // or modifier-induced price adjustments should result in separate cart lines.
    if (priceAdjustment != otherPriceAdjustment) return false;
    // Seats are part of the configuration for restaurant mode; if seat numbers
    // are set they must match or else items should be separate lines.
    if (seatNumber != otherSeatNumber) return false;

    return true;
    // Also ensure discount per unit matches for configuration equality
    // (if discounts differ, these should be treated as separate lines)
    // NOTE: equality check above returns early; append a final check
    // by ensuring discounts match exactly. If they don't, treat as not same.
    // (We perform discount comparison last to avoid early exit above.)
    // But since the current logic returns before, add a dedicated check below.
  }

  bool hasSameConfigurationWithDiscount(
    Product otherProduct,
    List<ModifierItem> otherModifiers,
    double otherDiscountPerUnit, {
    double otherPriceAdjustment = 0.0,
    int? otherSeatNumber,
    ProductVariant? otherVariant,
  }) {
    if (!hasSameConfiguration(
      otherProduct,
      otherModifiers,
      otherPriceAdjustment: otherPriceAdjustment,
      otherSeatNumber: otherSeatNumber,
      otherVariant: otherVariant,
    )) {
      return false;
    }
    return discountPerUnit == otherDiscountPerUnit;
  }

  /// Convert to JSON for serialization (e.g., for dual display streaming)
  Map<String, dynamic> toJson() {
    return {
      'productName': product.name,
      'productPrice': product.price,
      'quantity': quantity,
      'modifiers': modifiers.map((m) => m.name).toList(),
      'priceAdjustment': priceAdjustment,
      'discountPerUnit': discountPerUnit,
      'selectedVariant': selectedVariant?.name,
      'variantPriceModifier': selectedVariant?.priceModifier ?? 0.0,
      'finalPrice': finalPrice,
      'totalPrice': totalPrice,
      'seatNumber': seatNumber,
      'notes': notes,
    };
  }

  /// Create a simple CartItem from JSON (for dual display parsing)
  factory CartItem.fromDisplayJson(Map<String, dynamic> json) {
    // Create a minimal product for display purposes
    final product = Product(
      json['productName'] as String,
      (json['productPrice'] as num).toDouble(),
      '', // category not needed for display
      Icons.shopping_cart, // default icon
    );

    // Convert modifier names back to ModifierItem objects for display
    final modifierNames = (json['modifiers'] as List?)?.cast<String>() ?? [];
    final modifierItems = modifierNames
        .asMap()
        .entries
        .map(
          (entry) => ModifierItem(
            id: 'display_mod_${entry.key}',
            modifierGroupId: 'display_group',
            name: entry.value,
            priceAdjustment: 0.0, // Price already included in totalPrice
          ),
        )
        .toList();

    return CartItem(
      product,
      json['quantity'] as int,
      modifiers: modifierItems,
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
      discountPerUnit: (json['discountPerUnit'] as num?)?.toDouble() ?? 0.0,
      seatNumber: json['seatNumber'] as int?,
      notes: json['notes'] as String?,
    );
  }

  /// Create a copy of this cart item with modified properties
  CartItem copyWith({
    Product? product,
    int? quantity,
    List<ModifierItem>? modifiers,
    double? priceAdjustment,
    double? discountPerUnit,
    int? seatNumber,
    String? notes,
  }) {
    return CartItem(
      product ?? this.product,
      quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      discountPerUnit: discountPerUnit ?? this.discountPerUnit,
      seatNumber: seatNumber ?? this.seatNumber,
      notes: notes ?? this.notes,
    );
  }
}
