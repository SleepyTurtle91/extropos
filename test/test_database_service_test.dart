import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/test_database_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TestDatabaseService', () {
    late TestDatabaseService testService;

    setUp(() {
      testService = TestDatabaseService.instance;
    });

    tearDown(() async {
      // Clean up after each test
      await testService.deleteTestDatabase();
    });

    test('should initialize test database', () async {
      await testService.initializeTestDatabase();

      expect(testService.testDatabase, isNotNull);
      expect(
        testService.isTestMode,
        isTrue,
      ); // Database is initialized and ready
    });

    test('should switch to test database', () async {
      await testService.switchToTestDatabase();

      expect(testService.isTestMode, isTrue);
    });

    test('should populate test data', () async {
      await testService.initializeTestDatabase();
      await testService.populateTestData();

      // Verify categories were inserted
      final categories = await DatabaseService.instance.getCategories();
      expect(categories.length, greaterThan(0));

      // Verify items were inserted
      final items = await DatabaseService.instance.getItems();
      expect(items.length, greaterThan(0));
    });

    test('should clear test data', () async {
      await testService.initializeTestDatabase();
      await testService.populateTestData();

      // Verify data exists
      var categories = await DatabaseService.instance.getCategories();
      expect(categories.length, greaterThan(0));

      // Clear data
      await testService.clearTestData();

      // Verify data is cleared
      categories = await DatabaseService.instance.getCategories();
      expect(categories.length, equals(0));
    });

    test('should reset test database', () async {
      await testService.resetTestDatabase();

      expect(testService.testDatabase, isNotNull);

      // Verify data was populated
      final categories = await DatabaseService.instance.getCategories();
      expect(categories.length, greaterThan(0));
    });

    test('should delete test database', () async {
      await testService.initializeTestDatabase();
      expect(testService.testDatabase, isNotNull);

      await testService.deleteTestDatabase();
      expect(testService.testDatabase, isNull);
      expect(testService.isTestMode, isFalse);
    });
  });
}
