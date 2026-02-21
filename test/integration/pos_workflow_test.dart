import 'package:extropos/screens/retail_pos_screen_modern.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_helper.dart';

void main() {
  group('POS Integration Tests', () {
    late CartService cartService;

    setUp(() {
      cartService = CartService();
    });

    tearDown(() {
      cartService.clearCart();
    });

    testWidgets('complete retail POS workflow', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cartService),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 1200,
              height: 800,
              child: RetailPOSScreenModern(),
            ),
          ),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify initial state - cart should be empty
      expect(cartService.isEmpty, true);

      // Note: In a real integration test, we would need to mock the database
      // and provide actual product data to the screen. For now, this tests
      // the basic screen structure and cart integration.

      // Verify that the screen has the expected structure
      expect(find.byType(RetailPOSScreenModern), findsOneWidget);

      // Test that cart service is properly integrated
      expect(cartService, isNotNull);
    });

    testWidgets('cart operations integration', (tester) async {
      // Test cart operations work correctly in the context of a POS screen
      final product = TestHelper.createTestProduct();

      // Add product to cart
      final success = cartService.addProduct(product, quantity: 2);
      expect(success, true);
      expect(cartService.itemCount, 2);

      // Update quantity
      final updateSuccess = cartService.updateQuantity(0, 3);
      expect(updateSuccess, true);
      expect(cartService.itemCount, 3);

      // Check subtotal calculation
      expect(cartService.getSubtotal(), 30.0); // 3 * 10.0

      // Clear cart
      cartService.clearCart();
      expect(cartService.isEmpty, true);
    });

    testWidgets('cart persistence across operations', (tester) async {
      final product1 = TestHelper.createTestProduct(name: 'Item 1', price: 10.0);
      final product2 = TestHelper.createTestProduct(name: 'Item 2', price: 20.0);

      // Add multiple items
      cartService.addProduct(product1, quantity: 2);
      cartService.addProduct(product2, quantity: 1);

      expect(cartService.uniqueItemCount, 2);
      expect(cartService.itemCount, 3);
      expect(cartService.getSubtotal(), 40.0); // (2*10) + (1*20)

      // Modify quantities
      cartService.updateQuantity(0, 1); // Reduce first item to 1
      expect(cartService.itemCount, 2);
      expect(cartService.getSubtotal(), 30.0); // (1*10) + (1*20)

      // Add notes
      cartService.setItemNotes(1, 'Extra spicy');
      expect(cartService.getItem(1)!.notes, 'Extra spicy');

      // Apply discount
      cartService.setItemDiscount(0, 2.0);
      expect(cartService.getTotalDiscount(), 2.0);
      expect(cartService.getSubtotal(), 28.0); // 30.0 - 2.0
    });

    testWidgets('cart validation integration', (tester) async {
      final product = TestHelper.createTestProduct();

      // Add valid item
      cartService.addProduct(product);
      expect(cartService.validateCart(), true);

      // Test various invalid operations are rejected
      expect(cartService.addProduct(product, quantity: 0), false);
      expect(cartService.addProduct(product, quantity: -1), false);
      expect(cartService.updateQuantity(0, 1000), false); // Exceeds max
      expect(cartService.setItemDiscount(0, 100.0), false); // Exceeds price

      // Cart should still be valid
      expect(cartService.validateCart(), true);
    });

    testWidgets('performance with large cart', (tester) async {
      final products = TestHelper.createTestProducts(50);

      final stopwatch = Stopwatch()..start();

      // Add many items quickly
      for (final product in products) {
        cartService.addProduct(product);
      }

      stopwatch.stop();

      expect(cartService.uniqueItemCount, 50);
      expect(cartService.itemCount, 50);

      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Calculations should still work
      expect(cartService.getSubtotal(), 12750.0); // Sum of prices 10+20+...+500 = 12750

      // Clearing should be fast
      final clearStopwatch = Stopwatch()..start();
      cartService.clearCart();
      clearStopwatch.stop();

      expect(clearStopwatch.elapsedMilliseconds, lessThan(100));
      expect(cartService.isEmpty, true);
    });
  });
}