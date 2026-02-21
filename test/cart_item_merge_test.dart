import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cart items with different priceAdjustment should not be equal', () {
    final product = Product('Test Product', 10.0, 'Test', Icons.shop);
    final mods = <ModifierItem>[];
    final a = CartItem(product, 1, modifiers: mods, priceAdjustment: 0.0);
    final b = CartItem(product, 1, modifiers: mods, priceAdjustment: 2.0);
    expect(a.hasSameConfiguration(product, mods, otherPriceAdjustment: 0.0), true);
    expect(b.hasSameConfiguration(product, mods, otherPriceAdjustment: 2.0), true);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0), true);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 2.0), false);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0), true);
    expect(b.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0), false);
  });

  test('Cart items with different discountPerUnit should not be equal', () {
    final product = Product('Test Product', 10.0, 'Test', Icons.shop);
    final mods = <ModifierItem>[];
    final a = CartItem(product, 1, modifiers: mods, priceAdjustment: 0.0, discountPerUnit: 0.0);
    final b = CartItem(product, 1, modifiers: mods, priceAdjustment: 0.0, discountPerUnit: 1.0);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0), true);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 1.0, otherPriceAdjustment: 0.0), false);
    expect(b.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0), false);
  });

  test('Cart items with seat numbers should only merge when seat matches', () {
    final product = Product('Seat Product', 12.0, 'Test', Icons.shop);
    final mods = <ModifierItem>[];
    final a = CartItem(product, 1, modifiers: mods, priceAdjustment: 0.0, discountPerUnit: 0.0, seatNumber: 1);
    final b = CartItem(product, 1, modifiers: mods, priceAdjustment: 0.0, discountPerUnit: 0.0, seatNumber: 2);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: 1), true);
    expect(b.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: 2), true);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: 2), false);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: null), false);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: 1), true);
    expect(a.hasSameConfigurationWithDiscount(product, mods, 0.0, otherPriceAdjustment: 0.0, otherSeatNumber: 3), false);
  });
}
