import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/cafe_pos_screen.dart';
import 'package:extropos/screens/pos_order_screen_fixed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CafePOSScreen totals (with test seams)', () {
    testWidgets('computes totals with discount applied', (tester) async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.10,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.05,
      );
      await BusinessInfo.updateInstance(info);

      final items = [
        CartItem(Product('Coffee', 10, 'Drink', Icons.local_cafe), 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CafePOSScreen(
            initialCartItems: items,
            skipDbLoad: true,
            skipShiftCheck: true,
          ),
        ),
      );

      final state = tester.state(find.byType(CafePOSScreen)) as dynamic;
      state.billDiscount = 2.0; // Apply flat discount before tax/service

      expect(state.getSubtotal(), 20.0);
      expect(state.getTaxAmount(), closeTo(1.8, 0.0001)); // (20-2)*10%
      expect(state.getServiceChargeAmount(), closeTo(0.9, 0.0001)); // (20-2)*5%
      expect(state.getTotal(), closeTo(20 - 2 + 1.8 + 0.9, 0.0001));
    });
  });

  group('POSOrderScreen (Restaurant) totals with test seams', () {
    testWidgets('computes totals with discount applied', (tester) async {
      final info = BusinessInfo.instance.copyWith(
        isTaxEnabled: true,
        taxRate: 0.06,
        isServiceChargeEnabled: true,
        serviceChargeRate: 0.04,
      );
      await BusinessInfo.updateInstance(info);

      final table = RestaurantTable(id: 'A1', name: 'A1', capacity: 4);
      final items = [
        CartItem(Product('Pizza', 20, 'Food', Icons.local_pizza), 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: POSOrderScreen(
            table: table,
            initialCartItems: items,
            skipDbLoad: true,
          ),
        ),
      );

      final state = tester.state(find.byType(POSOrderScreen)) as dynamic;
      state.billDiscount = 4.0;

      expect(state.getSubtotal(), 40.0);
      expect(state.getTaxAmount(), closeTo(2.16, 0.0001)); // (40-4)*6%
      expect(state.getServiceChargeAmount(), closeTo(1.44, 0.0001)); // (40-4)*4%
      expect(state.getTotal(), closeTo(40 - 4 + 2.16 + 1.44, 0.0001));
    });
  });
}
