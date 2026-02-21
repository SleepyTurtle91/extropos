import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendCategoryServiceAppwrite Tests', () {
    late BackendCategoryServiceAppwrite service;

    setUp(() {
      service = BackendCategoryServiceAppwrite();
    });

    group('Test Mode Behavior', () {
      test('fetchCategories returns empty list in test mode', () async {
        final categories = await service.fetchCategories();
        expect(categories, isEmpty);
        expect(categories, isA<List<BackendCategoryModel>>());
      });

      test('fetchActiveCategories returns empty list in test mode', () async {
        final categories = await service.fetchActiveCategories();
        expect(categories, isEmpty);
      });

      test('fetchRootCategories returns empty list in test mode', () async {
        final categories = await service.fetchRootCategories();
        expect(categories, isEmpty);
      });

      test('fetchSubcategories returns empty list in test mode', () async {
        final categories = await service.fetchSubcategories('parent_id');
        expect(categories, isEmpty);
      });

      test('getCategoryById throws exception in test mode', () async {
        expect(
          () => service.getCategoryById('test_id'),
          throwsException,
        );
      });

      test('createCategory returns category with test ID in test mode', () async {
        final category = BackendCategoryModel(
          name: 'Test Category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final created = await service.createCategory(category);
        expect(created.id, isNotNull);
        expect(created.id, contains('test_category_'));
        expect(created.name, equals('Test Category'));
      });

      test('updateCategory returns same category in test mode', () async {
        final category = BackendCategoryModel(
          id: 'test_id',
          name: 'Test Category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final updated = await service.updateCategory(category);
        expect(updated, equals(category));
      });

      test('deleteCategory completes without error in test mode', () async {
        await expectLater(
          service.deleteCategory('test_id'),
          completes,
        );
      });

      test('hardDeleteCategory completes without error in test mode', () async {
        await expectLater(
          service.hardDeleteCategory('test_id'),
          completes,
        );
      });
    });

    group('Cache Management', () {
      test('cache is initially empty', () {
        final status = service.getCacheStatus();
        expect(status['hasCachedCategories'], isFalse);
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
        expect(status, containsPair('hasCachedCategories', anything));
        expect(status, containsPair('cachedCount', anything));
        expect(status, containsPair('lastRefresh', anything));
        expect(status, containsPair('isExpired', anything));
        expect(status, containsPair('expiryDuration', anything));
      });
    });

    group('Category Creation', () {
      test('creates category with all fields', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final category = BackendCategoryModel(
          name: 'Beverages',
          description: 'All beverage products',
          parentCategoryId: null,
          sortOrder: 1,
          isActive: true,
          iconName: 'local_drink',
          colorHex: '#FF5733',
          defaultTaxRate: 0.10,
          customFields: {'display': 'grid', 'columns': 3},
          createdAt: now,
          updatedAt: now,
          createdBy: 'user_123',
        );

        final created = await service.createCategory(category, currentUserId: 'user_123');
        expect(created.id, isNotNull);
        expect(created.name, equals('Beverages'));
        expect(created.sortOrder, equals(1));
        expect(created.iconName, equals('local_drink'));
        expect(created.colorHex, equals('#FF5733'));
        expect(created.defaultTaxRate, equals(0.10));
      });

      test('creates minimal category with required fields only', () async {
        final category = BackendCategoryModel(
          name: 'Simple Category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final created = await service.createCategory(category);
        expect(created.name, equals('Simple Category'));
        expect(created.description, isEmpty);
        expect(created.sortOrder, equals(0));
        expect(created.isActive, isTrue);
      });

      test('creates subcategory with parent', () async {
        final subcategory = BackendCategoryModel(
          name: 'Hot Beverages',
          parentCategoryId: 'beverages_root',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final created = await service.createCategory(subcategory);
        expect(created.parentCategoryId, equals('beverages_root'));
        expect(created.isSubcategory, isTrue);
        expect(created.isRootCategory, isFalse);
      });
    });

    group('Category Update', () {
      test('updateCategory requires category ID', () async {
        final category = BackendCategoryModel(
          name: 'Test Category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(
          () => service.updateCategory(category),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('updates category successfully in test mode', () async {
        final category = BackendCategoryModel(
          id: 'test_id',
          name: 'Updated Category',
          sortOrder: 5,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final updated = await service.updateCategory(category, currentUserId: 'user_123');
        expect(updated.name, equals('Updated Category'));
        expect(updated.sortOrder, equals(5));
      });
    });

    group('Category Hierarchy', () {
      test('root category has no parent', () {
        final rootCategory = BackendCategoryModel(
          name: 'Root',
          parentCategoryId: null,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(rootCategory.isRootCategory, isTrue);
        expect(rootCategory.isSubcategory, isFalse);
      });

      test('subcategory has parent', () {
        final subcategory = BackendCategoryModel(
          name: 'Sub',
          parentCategoryId: 'parent_123',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(subcategory.isRootCategory, isFalse);
        expect(subcategory.isSubcategory, isTrue);
      });

      test('empty parent ID is treated as root', () {
        final category = BackendCategoryModel(
          name: 'Test',
          parentCategoryId: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(category.isRootCategory, isTrue);
      });
    });

    group('Error Handling', () {
      test('handles missing category ID for update', () {
        final category = BackendCategoryModel(
          name: 'No ID Category',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(
          () => service.updateCategory(category),
          throwsA(
            predicate((e) =>
                e is ArgumentError &&
                e.message == 'Category ID is required for update'),
          ),
        );
      });

      test('getCategoryById throws in test mode', () {
        expect(
          () => service.getCategoryById('nonexistent'),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Category not found in test mode')),
          ),
        );
      });
    });

    group('Performance', () {
      test('multiple operations complete quickly', () async {
        final stopwatch = Stopwatch()..start();

        await Future.wait([
          service.fetchCategories(),
          service.fetchActiveCategories(),
          service.fetchRootCategories(),
          service.fetchSubcategories('test'),
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
      test('category copyWith creates new instance', () {
        final original = BackendCategoryModel(
          id: 'cat_1',
          name: 'Original',
          sortOrder: 1,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final copy = original.copyWith(name: 'Modified');

        expect(copy.id, equals(original.id));
        expect(copy.name, equals('Modified'));
        expect(copy.sortOrder, equals(original.sortOrder));
        expect(copy, isNot(same(original)));
      });

      test('category equality check', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final cat1 = BackendCategoryModel(
          id: 'cat_1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final cat2 = BackendCategoryModel(
          id: 'cat_1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final cat3 = BackendCategoryModel(
          id: 'cat_2',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        expect(cat1, equals(cat2));
        expect(cat1, isNot(equals(cat3)));
      });

      test('category toString includes key fields', () {
        final category = BackendCategoryModel(
          id: 'cat_1',
          name: 'Test Category',
          sortOrder: 5,
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final str = category.toString();
        expect(str, contains('cat_1'));
        expect(str, contains('Test Category'));
        expect(str, contains('5'));
        expect(str, contains('true'));
      });
    });
  });
}
