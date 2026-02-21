import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendProductServiceAppwrite Tests', () {
    late BackendProductServiceAppwrite service;

    setUp(() {
      service = BackendProductServiceAppwrite();
    });

    group('Test Mode Behavior', () {
      test('fetchProducts returns empty list in test mode', () async {
        final products = await service.fetchProducts();
        expect(products, isEmpty);
        expect(products, isA<List<BackendProductModel>>());
      });

      test('fetchProductsByCategory returns empty list in test mode', () async {
        final products = await service.fetchProductsByCategory('test_category');
        expect(products, isEmpty);
      });

      test('fetchActiveProducts returns empty list in test mode', () async {
        final products = await service.fetchActiveProducts();
        expect(products, isEmpty);
      });

      test('searchProducts returns empty list in test mode', () async {
        final products = await service.searchProducts('test');
        expect(products, isEmpty);
      });

      test('getProductById throws exception in test mode', () async {
        expect(
          () => service.getProductById('test_id'),
          throwsException,
        );
      });

      test('createProduct returns product with test ID in test mode', () async {
        final product = BackendProductModel(
          name: 'Test Product',
          basePrice: 10.0,
          categoryId: 'test_category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final created = await service.createProduct(product);
        expect(created.id, isNotNull);
        expect(created.id, contains('test_product_'));
        expect(created.name, equals('Test Product'));
      });

      test('updateProduct returns same product in test mode', () async {
        final product = BackendProductModel(
          id: 'test_id',
          name: 'Test Product',
          basePrice: 10.0,
          categoryId: 'test_category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final updated = await service.updateProduct(product);
        expect(updated, equals(product));
      });

      test('deleteProduct completes without error in test mode', () async {
        await expectLater(
          service.deleteProduct('test_id'),
          completes,
        );
      });

      test('hardDeleteProduct completes without error in test mode', () async {
        await expectLater(
          service.hardDeleteProduct('test_id'),
          completes,
        );
      });
    });

    group('Cache Management', () {
      test('cache is initially empty', () {
        final status = service.getCacheStatus();
        expect(status['hasCachedProducts'], isFalse);
        expect(status['cachedCount'], equals(0));
        expect(status['isExpired'], isTrue);
      });

      test('cache expiry duration is 5 minutes', () {
        final status = service.getCacheStatus();
        expect(status['expiryDuration'], equals(5));
      });

      test('refreshCache completes without error in test mode', () async {
        await expectLater(
          service.refreshCache(),
          completes,
        );
      });

      test('cache status structure is correct', () {
        final status = service.getCacheStatus();
        expect(status, containsPair('hasCachedProducts', anything));
        expect(status, containsPair('cachedCount', anything));
        expect(status, containsPair('lastRefresh', anything));
        expect(status, containsPair('isExpired', anything));
        expect(status, containsPair('expiryDuration', anything));
      });
    });

    group('Product Creation', () {
      test('creates product with all fields', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final product = BackendProductModel(
          name: 'Premium Coffee',
          description: 'Best coffee in town',
          sku: 'COFFEE-001',
          basePrice: 15.50,
          costPrice: 8.0,
          categoryId: 'beverages',
          categoryName: 'Beverages',
          isActive: true,
          trackInventory: true,
          variantIds: ['size-small', 'size-large'],
          modifierGroupIds: ['milk-options', 'sweeteners'],
          imageUrl: 'https://example.com/coffee.jpg',
          customFields: {'origin': 'Colombia', 'roast': 'medium'},
          createdAt: now,
          updatedAt: now,
          createdBy: 'user_123',
        );

        final created = await service.createProduct(product, currentUserId: 'user_123');
        expect(created.id, isNotNull);
        expect(created.name, equals('Premium Coffee'));
        expect(created.basePrice, equals(15.50));
        expect(created.costPrice, equals(8.0));
        expect(created.variantIds, hasLength(2));
        expect(created.modifierGroupIds, hasLength(2));
      });

      test('creates minimal product with required fields only', () async {
        final product = BackendProductModel(
          name: 'Simple Product',
          basePrice: 5.0,
          categoryId: 'general',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final created = await service.createProduct(product);
        expect(created.name, equals('Simple Product'));
        expect(created.basePrice, equals(5.0));
        expect(created.description, isEmpty);
        expect(created.isActive, isTrue);
        expect(created.trackInventory, isTrue);
      });
    });

    group('Product Update', () {
      test('updateProduct requires product ID', () async {
        final product = BackendProductModel(
          name: 'Test Product',
          basePrice: 10.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(
          () => service.updateProduct(product),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('updates product successfully in test mode', () async {
        final product = BackendProductModel(
          id: 'test_id',
          name: 'Updated Product',
          basePrice: 20.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final updated = await service.updateProduct(product, currentUserId: 'user_123');
        expect(updated.name, equals('Updated Product'));
        expect(updated.basePrice, equals(20.0));
      });
    });

    group('Error Handling', () {
      test('handles missing product ID for update', () {
        final product = BackendProductModel(
          name: 'No ID Product',
          basePrice: 10.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(
          () => service.updateProduct(product),
          throwsA(
            predicate((e) =>
                e is ArgumentError &&
                e.message == 'Product ID is required for update'),
          ),
        );
      });

      test('getProductById throws in test mode', () {
        expect(
          () => service.getProductById('nonexistent'),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Product not found in test mode')),
          ),
        );
      });
    });

    group('Performance', () {
      test('multiple operations complete quickly', () async {
        final stopwatch = Stopwatch()..start();

        await Future.wait([
          service.fetchProducts(),
          service.fetchActiveProducts(),
          service.fetchProductsByCategory('test'),
          service.searchProducts('test'),
        ]);

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        print('⏱️  4 operations completed in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('cache operations are instant', () {
        final stopwatch = Stopwatch()..start();

        service.getCacheStatus();
        service.getCacheStatus();
        service.getCacheStatus();

        stopwatch.stop();
        expect(stopwatch.elapsedMicroseconds, lessThan(1000));
        print('⏱️  3 cache reads: ${stopwatch.elapsedMicroseconds}µs');
      });
    });

    group('Data Validation', () {
      test('product profit margin calculation', () {
        final product = BackendProductModel(
          name: 'Test',
          basePrice: 100.0,
          costPrice: 60.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(product.getProfitMargin(), equals(40.0));
      });

      test('product profit margin is null without cost price', () {
        final product = BackendProductModel(
          name: 'Test',
          basePrice: 100.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(product.getProfitMargin(), isNull);
      });

      test('product has variants check', () {
        final productWithVariants = BackendProductModel(
          name: 'Test',
          basePrice: 10.0,
          categoryId: 'test',
          variantIds: ['v1', 'v2'],
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final productWithoutVariants = BackendProductModel(
          name: 'Test',
          basePrice: 10.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(productWithVariants.hasVariants, isTrue);
        expect(productWithoutVariants.hasVariants, isFalse);
      });

      test('product has modifiers check', () {
        final productWithModifiers = BackendProductModel(
          name: 'Test',
          basePrice: 10.0,
          categoryId: 'test',
          modifierGroupIds: ['m1', 'm2'],
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final productWithoutModifiers = BackendProductModel(
          name: 'Test',
          basePrice: 10.0,
          categoryId: 'test',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(productWithModifiers.hasModifiers, isTrue);
        expect(productWithoutModifiers.hasModifiers, isFalse);
      });
    });
  });
}
