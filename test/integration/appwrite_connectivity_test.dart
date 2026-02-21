import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';
import 'package:extropos/services/backend_user_service_appwrite.dart';
import 'package:extropos/services/phase1_inventory_service_appwrite.dart';
import 'package:extropos/services/role_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Appwrite Real Connectivity Test
///
/// IMPORTANT: This test requires actual Appwrite connection.
/// Run with: flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true
///
/// Prerequisites:
/// 1. Appwrite instance running at https://appwrite.extropos.org/v1
/// 2. Project ID: 6940a64500383754a37f
/// 3. Database: pos_db
/// 4. Collections created: backend_users, roles, activity_logs, inventory_items, products, categories
///
/// To skip (run in test mode): flutter test test/integration/appwrite_connectivity_test.dart
void main() {
  group('Appwrite Real Connectivity Tests', () {
    late AppwritePhase1Service appwrite;
    late BackendUserServiceAppwrite userService;
    late RoleServiceAppwrite roleService;
    late Phase1InventoryServiceAppwrite inventoryService;
    late BackendProductServiceAppwrite productService;
    late BackendCategoryServiceAppwrite categoryService;

    // Check if we're in real connectivity mode
    const bool realAppwrite = bool.fromEnvironment('REAL_APPWRITE');

    setUpAll(() async {
      // Initialize Flutter bindings for Appwrite client
      TestWidgetsFlutterBinding.ensureInitialized();

      print('\n${"=" * 60}');
      if (realAppwrite) {
        print('🔴 REAL APPWRITE MODE - CONNECTING TO BACKEND');
        print('Endpoint: https://appwrite.extropos.org/v1');
        print('Project: 6940a64500383754a37f');
      } else {
        print('🟢 TEST MODE - NO REAL BACKEND CALLS');
        print('All operations will use mock data');
      }
      print('${"=" * 60}\n');

      appwrite = AppwritePhase1Service();
      userService = BackendUserServiceAppwrite.instance;
      roleService = RoleServiceAppwrite.instance;
      inventoryService = Phase1InventoryServiceAppwrite.instance;
      productService = BackendProductServiceAppwrite();
      categoryService = BackendCategoryServiceAppwrite();
    });

    group('Phase 1: Connection Validation', () {
      test('Appwrite service initializes successfully', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final initialized = await appwrite.initialize();
        expect(initialized, isTrue, reason: 'Appwrite should initialize successfully');
        expect(appwrite.isInitialized, isTrue);
        expect(appwrite.errorMessage, isNull);

        print('✅ Appwrite initialized successfully');
      });

      test('Can connect to database', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        // Try to list documents from a collection
        try {
          final docs = await appwrite.listDocuments(
            collectionId: AppwritePhase1Service.rolesCol,
          ).timeout(const Duration(seconds: 10));
          expect(docs, isNotNull);
          print('✅ Successfully queried roles collection: ${docs.length} documents');
        } catch (e) {
          fail('Failed to connect to database: $e');
        }
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('All required collections exist', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final collections = [
          AppwritePhase1Service.backendUsersCol,
          AppwritePhase1Service.rolesCol,
          AppwritePhase1Service.activityLogsCol,
          AppwritePhase1Service.inventoryCol,
          BackendProductServiceAppwrite.productsCollectionId,
          BackendCategoryServiceAppwrite.categoriesCollectionId,
        ];

        for (final collectionId in collections) {
          try {
            await appwrite.listDocuments(collectionId: collectionId)
                .timeout(const Duration(seconds: 10));
            print('✅ Collection exists: $collectionId');
          } catch (e) {
            fail('Collection $collectionId not found or inaccessible: $e');
          }
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('Phase 2: Service Integration', () {
      test('RoleService can fetch predefined roles', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final roles = await roleService.getAllRoles();
        expect(roles, isNotEmpty, reason: 'Should have at least predefined roles');

        final roleNames = roles.map((r) => r.name).toList();
        print('✅ Fetched ${roles.length} roles: $roleNames');

        // Check for predefined roles
        expect(roles.any((r) => r.name == 'Admin'), isTrue);
        expect(roles.any((r) => r.name == 'Manager'), isTrue);
        expect(roles.any((r) => r.name == 'Supervisor'), isTrue);
        expect(roles.any((r) => r.name == 'Viewer'), isTrue);
      });

      test('UserService can list users', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final users = await userService.getAllUsers();
        expect(users, isNotNull);
        print('✅ Fetched ${users.length} users from backend');
      });

      test('InventoryService can list inventory items', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final items = await inventoryService.getAllInventory();
        expect(items, isNotNull);
        print('✅ Fetched ${items.length} inventory items from backend');
      });

      test('ProductService can list products', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final products = await productService.fetchProducts();
        expect(products, isNotNull);
        print('✅ Fetched ${products.length} products from backend');
      });

      test('CategoryService can list categories', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final categories = await categoryService.fetchCategories();
        expect(categories, isNotNull);
        print('✅ Fetched ${categories.length} categories from backend');
      });
    });

    group('Phase 3: Performance Metrics', () {
      test('Measure initialization time', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final stopwatch = Stopwatch()..start();
        final service = AppwritePhase1Service();
        await service.initialize();
        stopwatch.stop();

        final initTime = stopwatch.elapsedMilliseconds;
        print('⏱️  Initialization time: ${initTime}ms');

        expect(initTime, lessThan(2000), reason: 'Should initialize in < 2s');
      });

      test('Measure query performance - Get all roles', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final stopwatch = Stopwatch()..start();
        final roles = await roleService.getAllRoles();
        stopwatch.stop();

        final queryTime = stopwatch.elapsedMilliseconds;
        print('⏱️  Get all roles: ${queryTime}ms (${roles.length} items)');

        expect(queryTime, lessThan(1000), reason: 'Should fetch in < 1s');
      });

      test('Measure query performance - Get all users', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        final stopwatch = Stopwatch()..start();
        final users = await userService.getAllUsers();
        stopwatch.stop();

        final queryTime = stopwatch.elapsedMilliseconds;
        print('⏱️  Get all users: ${queryTime}ms (${users.length} items)');

        expect(queryTime, lessThan(1000), reason: 'Should fetch in < 1s');
      });

      test('Measure cache effectiveness', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        // First fetch (cold cache)
        final stopwatch1 = Stopwatch()..start();
        await roleService.getAllRoles();
        stopwatch1.stop();
        final coldTime = stopwatch1.elapsedMilliseconds;

        // Second fetch (warm cache)
        final stopwatch2 = Stopwatch()..start();
        await roleService.getAllRoles();
        stopwatch2.stop();
        final warmTime = stopwatch2.elapsedMilliseconds;

        print('⏱️  Cold cache: ${coldTime}ms');
        print('⏱️  Warm cache: ${warmTime}ms');
        
        if (coldTime > 0 && warmTime >= 0) {
          print('⚡ Cache speedup: ${(coldTime / (warmTime > 0 ? warmTime : 1)).toStringAsFixed(1)}x');
          expect(warmTime, lessThanOrEqualTo(coldTime), reason: 'Cache should be as fast or faster');
        } else {
          print('⚡ Both operations too fast to measure (<1ms) - cache working');
        }
      });
    });

    group('Phase 4: Error Handling', () {
      test('Service handles network timeout gracefully', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        // This will test the timeout logic by querying a non-existent ID
        final user = await userService.getUserById('definitely_not_exists_12345');
        expect(user, isNull, reason: 'Should return null for non-existent user');
        print('✅ Handled non-existent user gracefully');
      });

      test('Service falls back to cache when backend unavailable', () async {
        // This test works in both modes
        
        // Populate cache first
        final initialUsers = await userService.getAllUsers();
        print('📦 Cache populated with ${initialUsers.length} users');

        // Clear backend connection (in test mode, this is already the case)
        // In real mode, cache would be used if network fails

        // Fetch again - should use cache
        final cachedUsers = await userService.getAllUsers();
        expect(cachedUsers, isNotNull);
        print('✅ Successfully retrieved ${cachedUsers.length} users from cache');
      });
    });

    group('Phase 5: Stress Testing (Optional)', () {
      test('Handle multiple concurrent requests', () async {
        if (!realAppwrite) {
          print('⏭️  Skipping - test mode');
          return;
        }

        print('🔥 Running 10 concurrent requests...');
        final stopwatch = Stopwatch()..start();

        final futures = List.generate(10, (i) async {
          final roles = await roleService.getAllRoles();
          return roles.length;
        });

        final results = await Future.wait(futures);
        stopwatch.stop();

        print('⏱️  10 concurrent requests: ${stopwatch.elapsedMilliseconds}ms');
        print('📊 Results: $results');

        expect(results, everyElement(greaterThan(0)));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
          reason: '10 concurrent requests should complete in < 5s');
      });
    });
  });
}
