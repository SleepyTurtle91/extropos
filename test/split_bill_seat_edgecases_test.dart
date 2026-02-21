import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('split subtraction avoids negative quantities and preserves seats', () {
    final p1 = Product('A', 10.0, 'Test', Icons.shop);
    final p2 = Product('B', 12.0, 'Test', Icons.shop);

    final cart = [
      CartItem(p1, 2, seatNumber: 1),
      CartItem(p2, 1, seatNumber: 2),
    ];

    final split = [
      CartItem(p1, 2, seatNumber: 1), // subtract exactly all A for seat 1
      CartItem(p2, 2, seatNumber: 2), // attempt to subtract 2 but only 1 exists
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

    // Verify A removed, B removed and no negative quantities
    expect(cart.length, 0);
  });
}
