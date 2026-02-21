import 'package:extropos/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helper.dart';

void main() {
  group('ProductCard Widget Tests', () {
    testWidgets('should display product name and price', (tester) async {
      final product = TestHelper.createTestProduct(
        name: 'Burger',
        price: 15.99,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('RM15.99'), findsOneWidget);
    });

    testWidgets('should display product icon', (tester) async {
      final product = TestHelper.createTestProduct(icon: Icons.fastfood);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fastfood), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;
      final product = TestHelper.createTestProduct();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProductCard));
      expect(tapped, true);
    });

    testWidgets('should be accessible', (tester) async {
      final product = TestHelper.createTestProduct(
        name: 'Accessible Product',
        price: 10.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check that the product name is displayed (basic accessibility)
      expect(find.text('Accessible Product'), findsOneWidget);
    });

    testWidgets('should handle long product names', (tester) async {
      final product = TestHelper.createTestProduct(
        name: 'Very Long Product Name That Should Be Truncated',
        price: 25.50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // Constrain width to test truncation
              child: ProductCard(
                product: product,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // The text should still be findable even if truncated
      expect(find.textContaining('Very Long Product'), findsOneWidget);
    });

    testWidgets('should display different currencies', (tester) async {
      final product = TestHelper.createTestProduct(price: 12.34);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      // Note: This test assumes RM currency formatting in the widget
      expect(find.text('RM12.34'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (tester) async {
      final product = TestHelper.createTestProduct();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check that it contains an Icon
      expect(find.byType(Icon), findsOneWidget);

      // Check that it contains Text widgets
      expect(find.byType(Text), findsAtLeastNWidgets(2)); // Name and price
    });

    testWidgets('should handle zero price', (tester) async {
      final product = TestHelper.createTestProduct(price: 0.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('RM0.00'), findsOneWidget);
    });

    testWidgets('should handle very high prices', (tester) async {
      final product = TestHelper.createTestProduct(price: 999999.99);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: product,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('RM999999.99'), findsOneWidget);
    });
  });
}