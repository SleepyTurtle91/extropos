import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CartItem finalPrice and totalPrice with per-item discount', () {
    final p = Product('Test Product', 10.0, 'Cat', Icons.shopping_bag);
    final ci = CartItem(p, 2, priceAdjustment: 1.5, discountPerUnit: 2.0);

    // final unit price = base 10 + adjustment 1.5 - discount 2.0 = 9.5
    expect(ci.finalPrice, 9.5);
    // total = finalPrice * quantity = 9.5 * 2 = 19.0
    expect(ci.totalPrice, 19.0);
  });
}
