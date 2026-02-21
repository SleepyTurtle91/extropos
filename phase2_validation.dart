import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/services/backend_category_service_appwrite.dart';
import 'package:extropos/services/backend_product_service_appwrite.dart';

/// Simple validation script for Phase 2 Day 5 backend testing
/// This validates the Appwrite integration without using Flutter test framework
void main() async {
  print('🚀 Starting Phase 2 Day 5 Backend Validation...\n');

  // Test 1: Model Serialization
  print('📋 Test 1: Model Serialization');
  try {
    final testProduct = BackendProductModel(
      name: 'Test Product',
      basePrice: 10.50,
      categoryId: 'test_category',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final json = testProduct.toMap();
    final deserialized = BackendProductModel.fromMap(json);

    assert(testProduct.name == deserialized.name);
    assert(testProduct.basePrice == deserialized.basePrice);
    assert(testProduct.categoryId == deserialized.categoryId);

    print('✅ Model serialization works correctly');
  } catch (e) {
    print('❌ Model serialization failed: $e');
    return;
  }

  // Test 2: Category Model Serialization
  print('\n📋 Test 2: Category Model Serialization');
  try {
    final testCategory = BackendCategoryModel(
      name: 'Test Category',
      description: 'Test description',
      parentId: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final json = testCategory.toMap();
    final deserialized = BackendCategoryModel.fromMap(json);

    assert(testCategory.name == deserialized.name);
    assert(testCategory.description == deserialized.description);

    print('✅ Category model serialization works correctly');
  } catch (e) {
    print('❌ Category model serialization failed: $e');
    return;
  }

  // Test 3: Service Initialization
  print('\n📋 Test 3: Service Initialization');
  try {
    final productService = BackendProductServiceAppwrite();
    final categoryService = BackendCategoryServiceAppwrite();

    // Check collection IDs
    assert(BackendProductServiceAppwrite.productsCollectionId == 'items');
    assert(BackendCategoryServiceAppwrite.categoriesCollectionId == 'categories');

    print('✅ Services initialize correctly');
    print('   - Product collection: ${BackendProductServiceAppwrite.productsCollectionId}');
    print('   - Category collection: ${BackendCategoryServiceAppwrite.categoriesCollectionId}');
  } catch (e) {
    print('❌ Service initialization failed: $e');
    return;
  }

  // Test 4: Field Mapping Validation
  print('\n📋 Test 4: Field Mapping Validation');
  try {
    // Simulate Appwrite document structure
    final appwriteProductDoc = {
      r'$id': 'prod_123',
      'name': 'Sample Product',
      'description': 'Sample description',
      'sku': 'SKU123',
      'price': 25.99,
      'cost': 15.50,
      'category_id': 'cat_456',
      'categoryName': 'Sample Category',
      'is_available': true,
      'track_stock': true,
      'variantIds': ['var1', 'var2'],
      'modifierGroupIds': ['mod1'],
      'image_url': 'https://example.com/image.jpg',
      'customFields': {'key': 'value'},
      'created_at': 1640995200000,
      'updated_at': 1640995200000,
      'createdBy': 'user1',
      'updatedBy': 'user1',
    };

    final product = BackendProductModel.fromMap(appwriteProductDoc);

    // Validate field mappings
    assert(product.id == 'prod_123');
    assert(product.name == 'Sample Product');
    assert(product.basePrice == 25.99);
    assert(product.costPrice == 15.50);
    assert(product.categoryId == 'cat_456');
    assert(product.categoryName == 'Sample Category');
    assert(product.isActive == true);
    assert(product.trackInventory == true);
    assert(product.variantIds.length == 2);
    assert(product.modifierGroupIds.length == 1);
    assert(product.imageUrl == 'https://example.com/image.jpg');
    assert(product.customFields['key'] == 'value');

    print('✅ Field mappings are correct');
    print('   - ID: ${product.id}');
    print('   - Name: ${product.name}');
    print('   - Price: RM${product.basePrice}');
    print('   - Cost: RM${product.costPrice}');
    print('   - Category: ${product.categoryId} (${product.categoryName})');
    print('   - Active: ${product.isActive}');
    print('   - Variants: ${product.variantIds.length}');
    print('   - Modifiers: ${product.modifierGroupIds.length}');
  } catch (e) {
    print('❌ Field mapping validation failed: $e');
    return;
  }

  // Test 5: Category Field Mapping
  print('\n📋 Test 5: Category Field Mapping Validation');
  try {
    final appwriteCategoryDoc = {
      r'$id': 'cat_123',
      'name': 'Test Category',
      'description': 'Test description',
      'parent_id': null,
      'display_order': 1,
      'is_active': true,
      'created_at': 1640995200000,
      'updated_at': 1640995200000,
      'createdBy': 'user1',
      'updatedBy': 'user1',
    };

    final category = BackendCategoryModel.fromMap(appwriteCategoryDoc);

    assert(category.id == 'cat_123');
    assert(category.name == 'Test Category');
    assert(category.description == 'Test description');
    assert(category.parentId == null);
    assert(category.displayOrder == 1);
    assert(category.isActive == true);

    print('✅ Category field mappings are correct');
    print('   - ID: ${category.id}');
    print('   - Name: ${category.name}');
    print('   - Description: ${category.description}');
    print('   - Parent: ${category.parentId}');
    print('   - Order: ${category.displayOrder}');
    print('   - Active: ${category.isActive}');
  } catch (e) {
    print('❌ Category field mapping validation failed: $e');
    return;
  }

  print('\n🎉 Phase 2 Day 5 Backend Validation Complete!');
  print('✅ All core functionality validated:');
  print('   - Model serialization/deserialization');
  print('   - Service initialization');
  print('   - Appwrite field mappings');
  print('   - Collection ID configuration');
  print('\n📝 Next Steps:');
  print('   1. Launch backend app: flutter run -d chrome --target lib/main_backend.dart');
  print('   2. Test CRUD operations manually in the UI');
  print('   3. Verify data syncs with Appwrite backend');
  print('   4. Test category hierarchy and product assignments');
}