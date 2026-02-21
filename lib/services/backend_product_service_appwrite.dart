import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:extropos/models/backend_product_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/audit_service.dart';

/// Backend Product Service - Appwrite Implementation
/// Manages products in centralized backend for multi-location sync
class BackendProductServiceAppwrite {
  final AppwritePhase1Service _appwriteService;
  final AuditService _auditService;
  
  // Cache
  List<BackendProductModel>? _cachedProducts;
  DateTime? _lastCacheRefresh;
  final Duration _cacheExpiry = const Duration(minutes: 5);

  BackendProductServiceAppwrite({
    AppwritePhase1Service? appwriteService,
    AuditService? auditService,
  })  : _appwriteService = appwriteService ?? AppwritePhase1Service(),
        _auditService = auditService ?? AuditService();

  /// Collection ID for products
  static const String productsCollectionId = 'items';

  /// Test mode detection
  bool get _isTestMode {
    return const bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Fetch all products from backend
  Future<List<BackendProductModel>> fetchProducts({
    bool forceRefresh = false,
  }) async {
    // Test mode: return empty list
    if (_isTestMode) {
      print('📦 Test mode: returning empty product list');
      return [];
    }

    // Check cache first
    if (!forceRefresh && _cachedProducts != null && !_isCacheExpired()) {
      print('📦 Returning ${_cachedProducts!.length} products from cache');
      return _cachedProducts!;
    }

    try {
      print('🔄 Fetching products from Appwrite...');
      
      final response = await _appwriteService.listDocuments(
        collectionId: productsCollectionId,
        limit: 100,
      );

      final products = response
          .map((data) => BackendProductModel.fromMap(data))
          .toList();

      _cachedProducts = products;
      _lastCacheRefresh = DateTime.now();

      print('✅ Fetched ${products.length} products from backend');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      
      // Return cached data if available
      if (_cachedProducts != null) {
        print('📦 Returning stale cache (${_cachedProducts!.length} products)');
        return _cachedProducts!;
      }
      
      rethrow;
    }
  }

  /// Get products by category
  Future<List<BackendProductModel>> fetchProductsByCategory(String categoryId) async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty product list for category');
      return [];
    }

    try {
      print('🔄 Fetching products for category: $categoryId');
      
      final response = await _appwriteService.listDocuments(
        collectionId: productsCollectionId,
        queries: [
          Query.equal('categoryId', categoryId),
        ],
        limit: 100,
      );

      final products = response
          .map((data) => BackendProductModel.fromMap(data))
          .toList();

      print('✅ Fetched ${products.length} products for category $categoryId');
      return products;
    } catch (e) {
      print('❌ Error fetching products by category: $e');
      rethrow;
    }
  }

  /// Get active products only
  Future<List<BackendProductModel>> fetchActiveProducts() async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty active product list');
      return [];
    }

    try {
      print('🔄 Fetching active products...');
      
      final response = await _appwriteService.listDocuments(
        collectionId: productsCollectionId,
        queries: [
          Query.equal('isActive', true),
        ],
        limit: 100,
      );

      final products = response
          .map((data) => BackendProductModel.fromMap(data))
          .toList();

      print('✅ Fetched ${products.length} active products');
      return products;
    } catch (e) {
      print('❌ Error fetching active products: $e');
      rethrow;
    }
  }

  /// Search products by name or SKU
  Future<List<BackendProductModel>> searchProducts(String searchTerm) async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty search results');
      return [];
    }

    try {
      print('🔍 Searching products: "$searchTerm"');
      
      final response = await _appwriteService.listDocuments(
        collectionId: productsCollectionId,
        queries: [
          Query.search('name', searchTerm),
        ],
        limit: 100,
      );

      final products = response
          .map((data) => BackendProductModel.fromMap(data))
          .toList();

      print('✅ Found ${products.length} products matching "$searchTerm"');
      return products;
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }

  /// Get single product by ID
  Future<BackendProductModel> getProductById(String productId) async {
    if (_isTestMode) {
      throw Exception('Product not found in test mode');
    }

    try {
      print('🔄 Fetching product: $productId');
      
      final data = await _appwriteService.getDocument(
        collectionId: productsCollectionId,
        documentId: productId,
      );

      final product = BackendProductModel.fromMap(data);
      print('✅ Fetched product: ${product.name}');
      return product;
    } catch (e) {
      print('❌ Error fetching product: $e');
      rethrow;
    }
  }

  /// Create a new product
  Future<BackendProductModel> createProduct(
    BackendProductModel product, {
    String? currentUserId,
  }) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating product creation');
      return product.copyWith(
        id: 'test_product_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    try {
      print('➕ Creating product: ${product.name}');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final productData = product.copyWith(
        createdAt: now,
        updatedAt: now,
        createdBy: currentUserId,
        updatedBy: currentUserId,
      ).toMap();

      final data = await _appwriteService.createDocument(
        collectionId: productsCollectionId,
        documentId: ID.unique(),
        data: productData,
      );

      final createdProduct = BackendProductModel.fromMap(data);
      
      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'CREATE',
        resourceType: 'PRODUCT',
        resourceId: createdProduct.id,
        resourceName: createdProduct.name,
      );

      print('✅ Created product: ${createdProduct.id}');
      return createdProduct;
    } catch (e) {
      print('❌ Error creating product: $e');
      rethrow;
    }
  }

  /// Update an existing product
  Future<BackendProductModel> updateProduct(
    BackendProductModel product, {
    String? currentUserId,
  }) async {
    if (product.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    if (_isTestMode) {
      print('📦 Test mode: simulating product update');
      return product;
    }

    try {
      print('✏️  Updating product: ${product.id}');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final productData = product.copyWith(
        updatedAt: now,
        updatedBy: currentUserId,
      ).toMap();

      final data = await _appwriteService.updateDocument(
        collectionId: productsCollectionId,
        documentId: product.id!,
        data: productData,
      );

      final updatedProduct = BackendProductModel.fromMap(data);
      
      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'UPDATE',
        resourceType: 'PRODUCT',
        resourceId: updatedProduct.id,
        resourceName: updatedProduct.name,
      );

      print('✅ Updated product: ${updatedProduct.id}');
      return updatedProduct;
    } catch (e) {
      print('❌ Error updating product: $e');
      rethrow;
    }
  }

  /// Delete a product (soft delete by setting isActive = false)
  Future<void> deleteProduct(String productId, {String? currentUserId}) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating product deletion');
      return;
    }

    try {
      print('🗑️  Deleting product: $productId');
      
      final product = await getProductById(productId);
      await updateProduct(
        product.copyWith(isActive: false),
        currentUserId: currentUserId,
      );

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'DELETE',
        resourceType: 'PRODUCT',
        resourceId: productId,
        resourceName: product.name,
      );

      print('✅ Deleted product: $productId');
    } catch (e) {
      print('❌ Error deleting product: $e');
      rethrow;
    }
  }

  /// Hard delete a product (permanent deletion)
  Future<void> hardDeleteProduct(String productId, {String? currentUserId}) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating product hard deletion');
      return;
    }

    try {
      print('🗑️  Hard deleting product: $productId');
      
      await _appwriteService.deleteDocument(
        collectionId: productsCollectionId,
        documentId: productId,
      );

      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'DELETE',
        resourceType: 'PRODUCT',
        resourceId: productId,
      );

      print('✅ Hard deleted product: $productId');
    } catch (e) {
      print('❌ Error hard deleting product: $e');
      rethrow;
    }
  }

  /// Refresh cache
  Future<void> refreshCache() async {
    await fetchProducts(forceRefresh: true);
  }

  /// Clear cache
  void _clearCache() {
    _cachedProducts = null;
    _lastCacheRefresh = null;
    print('🗑️  Product cache cleared');
  }

  /// Check if cache is expired
  bool _isCacheExpired() {
    if (_lastCacheRefresh == null) return true;
    final now = DateTime.now();
    return now.difference(_lastCacheRefresh!).compareTo(_cacheExpiry) > 0;
  }

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'hasCachedProducts': _cachedProducts != null,
      'cachedCount': _cachedProducts?.length ?? 0,
      'lastRefresh': _lastCacheRefresh?.toIso8601String(),
      'isExpired': _isCacheExpired(),
      'expiryDuration': _cacheExpiry.inMinutes,
    };
  }
}
