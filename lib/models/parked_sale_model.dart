import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';

/// Helper function to get IconData from code point
/// This ensures we only use known Material Icons to avoid tree-shaking issues
IconData _getIconFromCodePoint(int codePoint) {
  // Map of known icon code points to their IconData constants
  const iconMap = {
    0xe145: Icons.restaurant, // restaurant
    0xe3e8: Icons.local_cafe, // local_cafe
    0xe56c: Icons.local_pizza, // local_pizza
    0xe3e9: Icons.local_bar, // local_bar
    0xe56b: Icons.fastfood, // fastfood
    0xe3ea: Icons.local_dining, // local_dining
    0xe56a: Icons.cake, // cake
    0xe3eb: Icons.local_drink, // local_drink
    0xe569: Icons.icecream, // icecream
    0xe3ec: Icons.free_breakfast, // free_breakfast
    0xe568: Icons.bakery_dining, // bakery_dining
    0xe3ed: Icons.tap_and_play, // tap_and_play (fallback)
  };

  return iconMap[codePoint] ?? Icons.restaurant; // Default fallback
}

/// Model for storing suspended/parked sales
class ParkedSale {
  final String id;
  final String timestamp;
  final List<CartItem> cartItems;
  final double subtotal;
  final double taxAmount;
  final double serviceChargeAmount;
  final double total;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? specialInstructions;
  final String? notes;

  ParkedSale({
    required this.id,
    required this.timestamp,
    required this.cartItems,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.total,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.specialInstructions,
    this.notes,
  });

  /// Create a ParkedSale from current cart state
  factory ParkedSale.fromCart({
    required List<CartItem> cartItems,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double total,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? specialInstructions,
    String? notes,
  }) {
    return ParkedSale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now().toIso8601String(),
      cartItems: List.from(cartItems), // Deep copy
      subtotal: subtotal,
      taxAmount: taxAmount,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      specialInstructions: specialInstructions,
      notes: notes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'cartItems': cartItems
          .map(
            (item) => {
              'productName': item.product.name,
              'productPrice': item.product.price,
              'category': item.product.category,
              'icon': item.product.icon.codePoint, // Store icon code point
              'quantity': item.quantity,
              'modifiers': item.modifiers.map((m) => m.toJson()).toList(),
              'priceAdjustment': item.priceAdjustment,
              'discountPerUnit': item.discountPerUnit,
              'seatNumber': item.seatNumber,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'total': total,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'specialInstructions': specialInstructions,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory ParkedSale.fromJson(Map<String, dynamic> json) {
    return ParkedSale(
      id: json['id'],
      timestamp: json['timestamp'],
      cartItems: (json['cartItems'] as List).map((itemJson) {
        // Reconstruct Product from stored data
        final product = Product(
          itemJson['productName'],
          itemJson['productPrice'],
          itemJson['category'],
          _getIconFromCodePoint(itemJson['icon']),
        );

        // Reconstruct modifiers
        final modifiers =
            (itemJson['modifiers'] as List?)
                ?.map((m) => ModifierItem.fromJson(m))
                .toList() ??
            [];

        return CartItem(
          product,
          itemJson['quantity'],
          modifiers: modifiers,
          priceAdjustment: itemJson['priceAdjustment'] ?? 0.0,
          discountPerUnit: itemJson['discountPerUnit'] ?? 0.0,
          seatNumber: itemJson['seatNumber'],
        );
      }).toList(),
      subtotal: json['subtotal'],
      taxAmount: json['taxAmount'],
      serviceChargeAmount: json['serviceChargeAmount'],
      total: json['total'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      specialInstructions: json['specialInstructions'],
      notes: json['notes'],
    );
  }

  /// Get formatted timestamp for display
  String get formattedTimestamp {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Get item count for display
  int get itemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
}
