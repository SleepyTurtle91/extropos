import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:extropos/models/backend_category_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/audit_service.dart';

/// Backend Category Service - Appwrite Implementation
/// Manages categories in centralized backend for multi-location sync
class BackendCategoryServiceAppwrite {
  final AppwritePhase1Service _appwriteService;
  final AuditService _auditService;
  
  // Cache
  List<BackendCategoryModel>? _cachedCategories;
  DateTime? _lastCacheRefresh;
  final Duration _cacheExpiry = const Duration(minutes: 5);

  BackendCategoryServiceAppwrite({
    AppwritePhase1Service? appwriteService,
    AuditService? auditService,
  })  : _appwriteService = appwriteService ?? AppwritePhase1Service(),
        _auditService = auditService ?? AuditService();

  /// Collection ID for categories
  static const String categoriesCollectionId = 'categories';

  /// Test mode detection
  bool get _isTestMode {
    return const bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Fetch all categories from backend
  Future<List<BackendCategoryModel>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    // Test mode: return empty list
    if (_isTestMode) {
      print('📦 Test mode: returning empty category list');
      return [];
    }

    // Check cache first
    if (!forceRefresh && _cachedCategories != null && !_isCacheExpired()) {
      print('📦 Returning ${_cachedCategories!.length} categories from cache');
      return _cachedCategories!;
    }

    try {
      print('🔄 Fetching categories from Appwrite...');
      
      final response = await _appwriteService.listDocuments(
        collectionId: categoriesCollectionId,
        queries: [
          Query.orderAsc('sortOrder'),
        ],
        limit: 100,
      );

      final categories = response
          .map((data) => BackendCategoryModel.fromMap(data))
          .toList();

      _cachedCategories = categories;
      _lastCacheRefresh = DateTime.now();

      print('✅ Fetched ${categories.length} categories from backend');
      return categories;
    } catch (e) {
      print('❌ Error fetching categories: $e');
      
      // Return cached data if available
      if (_cachedCategories != null) {
        print('📦 Returning stale cache (${_cachedCategories!.length} categories)');
        return _cachedCategories!;
      }
      
      rethrow;
    }
  }

  /// Get active categories only
  Future<List<BackendCategoryModel>> fetchActiveCategories() async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty active category list');
      return [];
    }

    try {
      print('🔄 Fetching active categories...');
      
      final response = await _appwriteService.listDocuments(
        collectionId: categoriesCollectionId,
        queries: [
          Query.equal('isActive', true),
          Query.orderAsc('sortOrder'),
        ],
        limit: 100,
      );

      final categories = response
          .map((data) => BackendCategoryModel.fromMap(data))
          .toList();

      print('✅ Fetched ${categories.length} active categories');
      return categories;
    } catch (e) {
      print('❌ Error fetching active categories: $e');
      rethrow;
    }
  }

  /// Get root categories (no parent)
  Future<List<BackendCategoryModel>> fetchRootCategories() async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty root category list');
      return [];
    }

    try {
      print('🔄 Fetching root categories...');
      
      final response = await _appwriteService.listDocuments(
        collectionId: categoriesCollectionId,
        queries: [
          Query.isNull('parentCategoryId'),
          Query.orderAsc('sortOrder'),
        ],
        limit: 100,
      );

      final categories = response
          .map((data) => BackendCategoryModel.fromMap(data))
          .toList();

      print('✅ Fetched ${categories.length} root categories');
      return categories;
    } catch (e) {
      print('❌ Error fetching root categories: $e');
      rethrow;
    }
  }

  /// Get subcategories of a parent category
  Future<List<BackendCategoryModel>> fetchSubcategories(String parentCategoryId) async {
    if (_isTestMode) {
      print('📦 Test mode: returning empty subcategory list');
      return [];
    }

    try {
      print('🔄 Fetching subcategories for: $parentCategoryId');
      
      final response = await _appwriteService.listDocuments(
        collectionId: categoriesCollectionId,
        queries: [
          Query.equal('parentCategoryId', parentCategoryId),
          Query.orderAsc('sortOrder'),
        ],
        limit: 100,
      );

      final categories = response
          .map((data) => BackendCategoryModel.fromMap(data))
          .toList();

      print('✅ Fetched ${categories.length} subcategories');
      return categories;
    } catch (e) {
      print('❌ Error fetching subcategories: $e');
      rethrow;
    }
  }

  /// Get single category by ID
  Future<BackendCategoryModel> getCategoryById(String categoryId) async {
    if (_isTestMode) {
      throw Exception('Category not found in test mode');
    }

    try {
      print('🔄 Fetching category: $categoryId');
      
      final data = await _appwriteService.getDocument(
        collectionId: categoriesCollectionId,
        documentId: categoryId,
      );

      final category = BackendCategoryModel.fromMap(data);
      print('✅ Fetched category: ${category.name}');
      return category;
    } catch (e) {
      print('❌ Error fetching category: $e');
      rethrow;
    }
  }

  /// Create a new category
  Future<BackendCategoryModel> createCategory(
    BackendCategoryModel category, {
    String? currentUserId,
  }) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating category creation');
      return category.copyWith(
        id: 'test_category_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    try {
      print('➕ Creating category: ${category.name}');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final categoryData = category.copyWith(
        createdAt: now,
        updatedAt: now,
        createdBy: currentUserId,
        updatedBy: currentUserId,
      ).toMap();

      final data = await _appwriteService.createDocument(
        collectionId: categoriesCollectionId,
        documentId: ID.unique(),
        data: categoryData,
      );

      final createdCategory = BackendCategoryModel.fromMap(data);
      
      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'CREATE',
        resourceType: 'CATEGORY',
        resourceId: createdCategory.id,
        resourceName: createdCategory.name,
      );

      print('✅ Created category: ${createdCategory.id}');
      return createdCategory;
    } catch (e) {
      print('❌ Error creating category: $e');
      rethrow;
    }
  }

  /// Update an existing category
  Future<BackendCategoryModel> updateCategory(
    BackendCategoryModel category, {
    String? currentUserId,
  }) async {
    if (category.id == null) {
      throw ArgumentError('Category ID is required for update');
    }

    if (_isTestMode) {
      print('📦 Test mode: simulating category update');
      return category;
    }

    try {
      print('✏️  Updating category: ${category.id}');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final categoryData = category.copyWith(
        updatedAt: now,
        updatedBy: currentUserId,
      ).toMap();

      final data = await _appwriteService.updateDocument(
        collectionId: categoriesCollectionId,
        documentId: category.id!,
        data: categoryData,
      );

      final updatedCategory = BackendCategoryModel.fromMap(data);
      
      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'UPDATE',
        resourceType: 'CATEGORY',
        resourceId: updatedCategory.id,
        resourceName: updatedCategory.name,
      );

      print('✅ Updated category: ${updatedCategory.id}');
      return updatedCategory;
    } catch (e) {
      print('❌ Error updating category: $e');
      rethrow;
    }
  }

  /// Delete a category (soft delete by setting isActive = false)
  Future<void> deleteCategory(String categoryId, {String? currentUserId}) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating category deletion');
      return;
    }

    try {
      print('🗑️  Deleting category: $categoryId');
      
      final category = await getCategoryById(categoryId);
      await updateCategory(
        category.copyWith(isActive: false),
        currentUserId: currentUserId,
      );

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'DELETE',
        resourceType: 'CATEGORY',
        resourceId: categoryId,
        resourceName: category.name,
      );

      print('✅ Deleted category: $categoryId');
    } catch (e) {
      print('❌ Error deleting category: $e');
      rethrow;
    }
  }

  /// Hard delete a category (permanent deletion)
  Future<void> hardDeleteCategory(String categoryId, {String? currentUserId}) async {
    if (_isTestMode) {
      print('📦 Test mode: simulating category hard deletion');
      return;
    }

    try {
      print('🗑️  Hard deleting category: $categoryId');
      
      await _appwriteService.deleteDocument(
        collectionId: categoriesCollectionId,
        documentId: categoryId,
      );

      // Clear cache to force refresh
      _clearCache();

      // Audit log
      await _auditService.logActivity(
        userId: currentUserId ?? 'system',
        userName: currentUserId ?? 'system',
        action: 'DELETE',
        resourceType: 'CATEGORY',
        resourceId: categoryId,
      );

      print('✅ Hard deleted category: $categoryId');
    } catch (e) {
      print('❌ Error hard deleting category: $e');
      rethrow;
    }
  }

  /// Refresh cache
  Future<void> refreshCache() async {
    await fetchCategories(forceRefresh: true);
  }

  /// Clear cache
  void _clearCache() {
    _cachedCategories = null;
    _lastCacheRefresh = null;
    print('🗑️  Category cache cleared');
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
      'hasCachedCategories': _cachedCategories != null,
      'cachedCount': _cachedCategories?.length ?? 0,
      'lastRefresh': _lastCacheRefresh?.toIso8601String(),
      'isExpired': _isCacheExpired(),
      'expiryDuration': _cacheExpiry.inMinutes,
    };
  }
}
