import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/utils/pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pricing helpers', () {
    test('Subtotal, tax, service charge and total (tax on, service off)', () async {
      // Configure BusinessInfo flags
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.10,
        isServiceChargeEnabled: false,
        serviceChargeRate: 0.05,
      );
      await BusinessInfo.updateInstance(info);

      final p1 = Product('Coffee', 10.0, 'Beverages', Icons.local_cafe);
      final p2 = Product('Cake', 15.0, 'Desserts', Icons.cake);
      final items = [
        CartItem(p1, 2), // 20.0
        CartItem(p2, 1), // 15.0
      ];

      expect(Pricing.subtotal(items), 35.0);
      expect(Pricing.taxAmount(items), 3.5);
      expect(Pricing.serviceChargeAmount(items), 0.0);
      expect(Pricing.total(items), 38.5);
    });

    test('Subtotal, tax off, service charge on', () async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: false,
        taxRate: 0.10,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.10,
      );
      await BusinessInfo.updateInstance(info);

      final p = Product('Burger', 12.0, 'Food', Icons.fastfood);
      final items = [CartItem(p, 3)]; // 36.0

      expect(Pricing.subtotal(items), 36.0);
      expect(Pricing.taxAmount(items), 0.0);
      expect(Pricing.serviceChargeAmount(items), 3.6);
      expect(Pricing.total(items), 39.6);
    });

    test('Variant, modifiers and discounts are reflected in totals', () async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.06,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.04,
      );
      await BusinessInfo.updateInstance(info);

      final base = Product('Pizza', 20.0, 'Food', Icons.local_pizza);
      final item = CartItem(base, 2, priceAdjustment: 2.0, discountPerUnit: 1.0);
      // finalPrice per unit = 20 + 2 - 1 = 21; total = 42
      final items = [item];

      expect(Pricing.subtotal(items), 42.0);
      expect(Pricing.taxAmount(items), closeTo(2.52, 0.0001)); // 6%
      expect(Pricing.serviceChargeAmount(items), closeTo(1.68, 0.0001)); // 4%
      expect(Pricing.total(items), closeTo(46.2, 0.0001));
    });

    test('Discount-aware totals clamp at zero and apply charges on net', () async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.10,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.05,
      );
      await BusinessInfo.updateInstance(info);

      final p = Product('Tea', 5.0, 'Drink', Icons.local_drink);
      final items = [CartItem(p, 2)]; // subtotal = 10.0

      // Large discount that exceeds subtotal
      expect(Pricing.totalWithDiscount(items, 20.0), 0.0);

      // Partial discount
      final total = Pricing.totalWithDiscount(items, 2.0);
      // Net base = 8.0, tax = 0.8, svc = 0.4, total = 9.2
      expect(total, closeTo(9.2, 0.0001));
    });
  });
}
