import 'package:extropos/widgets/cart_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helper.dart';

void main() {
  group('CartItemWidget Tests', () {
    testWidgets('should display product name and price', (tester) async {
      final cartItem = TestHelper.createTestCartItem(
        name: 'Pizza',
        price: 18.50,
        quantity: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('RM 18.50'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Quantity
    });

    testWidgets('should display line total correctly', (tester) async {
      final cartItem = TestHelper.createTestCartItem(
        price: 10.0,
        quantity: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('RM 30.00'), findsOneWidget); // 10.0 * 3
    });

    testWidgets('should call onAdd when plus button is tapped', (tester) async {
      bool addCalled = false;
      final cartItem = TestHelper.createTestCartItem();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () => addCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      expect(addCalled, true);
    });

    testWidgets('should call onRemove when minus button is tapped', (tester) async {
      bool removeCalled = false;
      final cartItem = TestHelper.createTestCartItem();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () => removeCalled = true,
              onAdd: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      expect(removeCalled, true);
    });

    testWidgets('should display notes when available', (tester) async {
      final cartItem = TestHelper.createTestCartItem(
        notes: 'Extra cheese, no onions',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('Note: Extra cheese, no onions'), findsOneWidget);
    });

    testWidgets('should not display notes section when no notes', (tester) async {
      final cartItem = TestHelper.createTestCartItem(); // No notes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      // Notes text should not be present
      expect(find.textContaining('Notes:'), findsNothing);
    });

    testWidgets('should handle quantity of 1', (tester) async {
      final cartItem = TestHelper.createTestCartItem(quantity: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should handle large quantities', (tester) async {
      final cartItem = TestHelper.createTestCartItem(quantity: 99);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('should handle zero price items', (tester) async {
      final cartItem = TestHelper.createTestCartItem(price: 0.0, quantity: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.text('RM 0.00'), findsWidgets); // Should display zero price correctly
    });

    testWidgets('should have proper button accessibility', (tester) async {
      final cartItem = TestHelper.createTestCartItem();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      // Check for add button
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      // Check for remove button
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('should handle very long product names', (tester) async {
      final cartItem = TestHelper.createTestCartItem(
        name: 'Very Long Product Name That Might Cause Layout Issues',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Constrain width
              child: CartItemWidget(
                item: cartItem,
                onRemove: () {},
                onAdd: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Very Long Product'), findsOneWidget);
    });

    testWidgets('should handle very long notes', (tester) async {
      final cartItem = TestHelper.createTestCartItem(
        notes: 'Very long notes that might wrap to multiple lines and cause layout issues in the widget',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemWidget(
              item: cartItem,
              onRemove: () {},
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Very long notes'), findsOneWidget);
    });
  });
}