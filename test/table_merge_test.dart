import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/table_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Merge two tables merges orders correctly and clears donors', () {
    final t1 = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
    final t2 = RestaurantTable(id: 't2', name: 'T2', capacity: 4);
    final target = RestaurantTable(id: 't3', name: 'T3', capacity: 6);

    final pA = Product('A', 10.0, 'Cat', Icons.shop);
    final pB = Product('B', 5.0, 'Cat', Icons.shop);

    t1.addOrMergeOrder(CartItem(pA, 2));
    t2.addOrMergeOrder(CartItem(pA, 1));
    t2.addOrMergeOrder(CartItem(pB, 1));

    // Merge t1 and t2 into target
    for (final ci in t1.orders) {
      target.addOrMergeOrder(ci);
    }
    for (final ci in t2.orders) {
      target.addOrMergeOrder(ci);
    }
    t1.clearOrders();
    t2.clearOrders();

    expect(target.orders.length, 2);
    final a = target.orders.firstWhere((o) => o.product.name == 'A');
    final b = target.orders.firstWhere((o) => o.product.name == 'B');
    expect(a.quantity, 3);
    expect(b.quantity, 1);
    expect(t1.orders.isEmpty, true);
    expect(t2.orders.isEmpty, true);
  });

  test('Merge respects seat numbers: items with different seats should not merge', () {
    final t1 = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
    final t2 = RestaurantTable(id: 't2', name: 'T2', capacity: 4);
    final target = RestaurantTable(id: 't3', name: 'T3', capacity: 6);

    final pA = Product('A', 10.0, 'Cat', Icons.shop);

    // t1 has A for seat 1, t2 has A for seat 2
    t1.addOrMergeOrder(CartItem(pA, 2, seatNumber: 1));
    t2.addOrMergeOrder(CartItem(pA, 1, seatNumber: 2));

    // Merge t1 and t2 into target
    for (final ci in t1.orders) {
      target.addOrMergeOrder(ci);
    }
    for (final ci in t2.orders) {
      target.addOrMergeOrder(ci);
    }

    expect(target.orders.length, 2);
    final seat1 = target.orders.firstWhere((o) => o.seatNumber == 1);
    final seat2 = target.orders.firstWhere((o) => o.seatNumber == 2);
    expect(seat1.quantity, 2);
    expect(seat2.quantity, 1);
  });
}
