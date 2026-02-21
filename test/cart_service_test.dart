import 'package:extropos/services/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

void main() {
  group('CartService - Comprehensive Test Suite', () {
    late CartService cartService;

    setUp(() {
      cartService = CartService();
    });

    tearDown(() {
      cartService.clearCart();
    });

    group('Basic Cart Operations', () {
      test('should initialize empty', () {
        expect(cartService.items, isEmpty);
        expect(cartService.itemCount, 0);
        expect(cartService.uniqueItemCount, 0);
        expect(cartService.isEmpty, true);
        expect(cartService.isNotEmpty, false);
      });

      test('should add product to cart successfully', () {
        final product = TestHelper.createTestProduct();
        final success = cartService.addProduct(product);

        expect(success, true);
        expect(cartService.items.length, 1);
        expect(cartService.items[0].product.name, 'Test Product');
        expect(cartService.items[0].quantity, 1);
        expect(cartService.itemCount, 1);
        expect(cartService.uniqueItemCount, 1);
      });

      test('should add product with custom quantity', () {
        final product = TestHelper.createTestProduct();
        final success = cartService.addProduct(product, quantity: 5);

        expect(success, true);
        expect(cartService.items[0].quantity, 5);
        expect(cartService.itemCount, 5);
      });

      test('should add product with notes', () {
        final product = TestHelper.createTestProduct();
        final success = cartService.addProduct(product, notes: 'Extra spicy');

        expect(success, true);
        expect(cartService.items[0].notes, 'Extra spicy');
      });

      test('should combine quantities for same product', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 2);
        cartService.addProduct(product, quantity: 3);

        expect(cartService.items.length, 1);
        expect(cartService.items[0].quantity, 5);
        expect(cartService.itemCount, 5);
      });

      test('should merge notes when combining products', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 1, notes: 'Mild');
        cartService.addProduct(product, quantity: 1, notes: 'Extra spicy');

        expect(cartService.items.length, 1);
        expect(cartService.items[0].quantity, 2);
        expect(cartService.items[0].notes, 'Extra spicy'); // Last notes win
      });
    });

    group('Quantity Management', () {
      test('should update quantity successfully', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final success = cartService.updateQuantity(0, 5);
        expect(success, true);
        expect(cartService.items[0].quantity, 5);
        expect(cartService.itemCount, 5);
      });

      test('should increment quantity', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final success = cartService.incrementQuantity(0);
        expect(success, true);
        expect(cartService.items[0].quantity, 2);
      });

      test('should decrement quantity', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 3);

        final success = cartService.decrementQuantity(0);
        expect(success, true);
        expect(cartService.items[0].quantity, 2);
      });

      test('should remove item when decrementing to zero', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 1);

        final success = cartService.decrementQuantity(0);
        expect(success, true);
        expect(cartService.items, isEmpty);
      });

      test('should remove item when updating quantity to zero', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final success = cartService.updateQuantity(0, 0);
        expect(success, true);
        expect(cartService.items, isEmpty);
      });
    });

    group('Validation & Error Handling', () {
      test('should reject invalid quantity on add', () {
        final product = TestHelper.createTestProduct();
        final success = cartService.addProduct(product, quantity: 0);

        expect(success, false);
        expect(cartService.items, isEmpty);
      });

      test('should reject negative quantity on add', () {
        final product = TestHelper.createTestProduct();
        final success = cartService.addProduct(product, quantity: -1);

        expect(success, false);
        expect(cartService.items, isEmpty);
      });

      test('should reject quantity exceeding maximum', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 999);

        final success = cartService.addProduct(product, quantity: 1);
        expect(success, false);
        expect(cartService.items[0].quantity, 999);
      });

      test('should reject invalid index operations', () {
        final success = cartService.updateQuantity(-1, 5);
        expect(success, false);

        final success2 = cartService.updateQuantity(99, 5);
        expect(success2, false);

        final success3 = cartService.removeItem(-1);
        expect(success3, false);
      });

      test('should reject negative discount', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final success = cartService.setItemDiscount(0, -5.0);
        expect(success, false);
      });

      test('should reject discount exceeding item total', () {
        final product = TestHelper.createTestProduct(price: 10.0);
        cartService.addProduct(product, quantity: 2); // Total: 20.0

        final success = cartService.setItemDiscount(0, 25.0);
        expect(success, false);
      });
    });

    group('Discount Management', () {
      test('should apply discount to item', () {
        final product = TestHelper.createTestProduct(price: 20.0);
        cartService.addProduct(product, quantity: 2); // Subtotal: 40.0

        final success = cartService.setItemDiscount(0, 5.0);
        expect(success, true);
        expect(cartService.getTotalDiscount(), 5.0);
      });

      test('should calculate discount per unit correctly', () {
        final product = TestHelper.createTestProduct(price: 10.0);
        cartService.addProduct(product, quantity: 4); // Subtotal: 40.0

        final success = cartService.setItemDiscount(0, 8.0); // 8.0 / 4 = 2.0 per unit
        expect(success, true);
        expect(cartService.items[0].discountPerUnit, 2.0);
        expect(cartService.getTotalDiscount(), 8.0);
      });
    });

    group('Notes Management', () {
      test('should set notes for item', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final success = cartService.setItemNotes(0, 'No onions');
        expect(success, true);
        expect(cartService.items[0].notes, 'No onions');
      });

      test('should clear notes with null', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, notes: 'Extra cheese');

        final success = cartService.setItemNotes(0, null);
        expect(success, true);
        expect(cartService.items[0].notes, null);
      });
    });

    group('Cart Calculations', () {
      test('should calculate subtotal correctly', () {
        final products = TestHelper.createTestProducts(3);
        cartService.addProduct(products[0], quantity: 2); // 2 x 10 = 20
        cartService.addProduct(products[1], quantity: 1); // 1 x 20 = 20
        cartService.addProduct(products[2], quantity: 3); // 3 x 30 = 90

        expect(cartService.getSubtotal(), 130.0);
      });

      test('should calculate subtotal with discounts', () {
        final product = TestHelper.createTestProduct(price: 50.0);
        cartService.addProduct(product, quantity: 2); // Subtotal: 100.0
        cartService.setItemDiscount(0, 10.0); // Discount: 10.0

        expect(cartService.getSubtotal(), 90.0);
        expect(cartService.getTotalDiscount(), 10.0);
      });

      test('should handle multiple items with individual discounts', () {
        final product1 = TestHelper.createTestProduct(name: 'Item 1', price: 20.0);
        final product2 = TestHelper.createTestProduct(name: 'Item 2', price: 30.0);

        cartService.addProduct(product1, quantity: 2); // 40.0
        cartService.addProduct(product2, quantity: 1); // 30.0

        cartService.setItemDiscount(0, 5.0); // Discount item 1
        cartService.setItemDiscount(1, 3.0); // Discount item 2

        expect(cartService.getSubtotal(), 62.0); // (40-5) + (30-3)
        expect(cartService.getTotalDiscount(), 8.0);
      });
    });

    group('Cart Queries', () {
      test('should check if product exists in cart', () {
        final product = TestHelper.createTestProduct();
        expect(cartService.containsProduct(product), false);

        cartService.addProduct(product);
        expect(cartService.containsProduct(product), true);
      });

      test('should get product quantity', () {
        final product = TestHelper.createTestProduct();
        expect(cartService.getProductQuantity(product), 0);

        cartService.addProduct(product, quantity: 3);
        expect(cartService.getProductQuantity(product), 3);
      });

      test('should get item by index', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final item = cartService.getItem(0);
        expect(item, isNotNull);
        expect(item!.product.name, 'Test Product');

        expect(cartService.getItem(-1), null);
        expect(cartService.getItem(99), null);
      });

      test('should provide cart summary', () {
        final product = TestHelper.createTestProduct(price: 15.0);
        cartService.addProduct(product, quantity: 2);

        final summary = cartService.getSummary();
        expect(summary['itemCount'], 2);
        expect(summary['uniqueItemCount'], 1);
        expect(summary['subtotal'], 30.0);
        expect(summary['totalDiscount'], 0.0);
        expect(summary['items'], hasLength(1));
      });
    });

    group('Cart State Management', () {
      test('should clear cart completely', () {
        final products = TestHelper.createTestProducts(3);
        for (final product in products) {
          cartService.addProduct(product);
        }

        expect(cartService.items.length, 3);
        cartService.clearCart();
        expect(cartService.items, isEmpty);
        expect(cartService.itemCount, 0);
      });

      test('should validate cart state', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        expect(cartService.validateCart(), true);

        // Test with empty cart
        cartService.clearCart();
        expect(cartService.validateCart(), true);
      });
    });

    group('Performance Tests', () {
      test('should handle large cart efficiently', () {
        final products = TestHelper.createTestProducts(100);

        final stopwatch = Stopwatch()..start();
        for (final product in products) {
          cartService.addProduct(product);
        }
        stopwatch.stop();

        expect(cartService.items.length, 100);
        expect(cartService.itemCount, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be fast
      });

      test('should handle quantity updates efficiently', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product);

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 100; i++) {
          cartService.updateQuantity(0, i + 1);
        }
        stopwatch.stop();

        expect(cartService.items[0].quantity, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Edge Cases', () {
      test('should handle empty cart operations gracefully', () {
        expect(cartService.removeItem(0), false);
        expect(cartService.updateQuantity(0, 5), false);
        expect(cartService.incrementQuantity(0), false);
        expect(cartService.decrementQuantity(0), false);
        expect(cartService.setItemDiscount(0, 5.0), false);
        expect(cartService.setItemNotes(0, 'test'), false);
        expect(cartService.getItem(0), null);
      });

      test('should handle maximum quantity limits', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 999);

        expect(cartService.incrementQuantity(0), false);
        expect(cartService.updateQuantity(0, 1000), false);
        expect(cartService.items[0].quantity, 999);
      });

      test('should handle zero and negative quantities', () {
        final product = TestHelper.createTestProduct();
        cartService.addProduct(product, quantity: 5);

        expect(cartService.updateQuantity(0, -1), true); // Should remove item
        expect(cartService.items, isEmpty);
      });

      test('should handle very large discounts', () {
        final product = TestHelper.createTestProduct(price: 100.0);
        cartService.addProduct(product);

        // Discount equal to price should be allowed
        expect(cartService.setItemDiscount(0, 100.0), true);
        expect(cartService.getTotalDiscount(), 100.0);
        expect(cartService.getSubtotal(), 0.0);
      });
    });
  });
}