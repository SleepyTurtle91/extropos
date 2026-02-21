import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Split logic reduces quantities correctly', () {
    final p1 = Product('A', 10.0, 'Cat', Icons.shop);
    final p2 = Product('B', 12.0, 'Cat', Icons.shop);

    final cart = [
      CartItem(p1, 3),
      CartItem(p2, 2),
    ];

    final split = [
      CartItem(p1, 2),
      CartItem(p2, 1),
    ];

    // Simulate split subtraction logic
    for (final s in split) {
      final idx = cart.indexWhere((ci) => ci.hasSameConfigurationWithDiscount(s.product, s.modifiers, s.discountPerUnit, otherPriceAdjustment: s.priceAdjustment, otherSeatNumber: s.seatNumber));
      if (idx != -1) {
        final orig = cart[idx];
        final remaining = orig.quantity - s.quantity;
        if (remaining <= 0) {
          cart.removeAt(idx);
        } else {
          cart[idx].quantity = remaining;
        }
      }
    }

    expect(cart.length, 2);
    expect(cart[0].product.name, 'A');
    expect(cart[0].quantity, 1);
    expect(cart[1].product.name, 'B');
    expect(cart[1].quantity, 1);
  });
}
