import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:extropos/services/license_service.dart';

class TenantService {
  static final TenantService instance = TenantService._internal();
  TenantService._internal();

  Client? _client;
  Databases? _databases;
  String? _databaseId;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  Databases? get databases => _databases;
  String? get databaseId => _databaseId;

  Future<void> initialize() async {
    final license = LicenseService.instance;
    if (!license.isTenantActivated) {
      throw Exception('Tenant not activated');
    }

    _client = Client()
        .setEndpoint(license.tenantEndpoint)
        .setProject('689965770017299bd5a5');

    _databases = Databases(_client!);
    _isConnected = true;
  }

  Future<void> disconnect() async {
    _client = null;
    _databases = null;
    _isConnected = false;
  }

  Future<void> initializeWithCredentials(
    String endpoint,
    String apiKey,
    String tenantId,
  ) async {
    _client = Client().setEndpoint(endpoint).setProject('689965770017299bd5a5');

    _databases = Databases(_client!);
    _databaseId = tenantId;
    _isConnected = true;
  }

  Future<bool> testConnection() async {
    if (!_isConnected) await initialize();

    try {
      // Test connection by trying to get account info (requires authentication)
      // For now, just check if client is initialized
      return _client != null && _databases != null;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<List<String>> getAvailableCounters() async {
    if (!_isConnected) await initialize();

    try {
      final license = LicenseService.instance;
      if (license.tenantId.isNotEmpty) {
        // Query counters collection in tenant database
        final response = await _databases!.listDocuments(
          databaseId: _databaseId!,
          collectionId: 'counters',
        );

        return response.documents.map((doc) => doc.$id).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> assignCounter(String counterId) async {
    await LicenseService.instance.setCounterId(counterId);
  }

  // ==================== PRODUCTS CRUD ====================

  /// Create a new product
  Future<models.Document> createProduct(
    Map<String, dynamic> productData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.createDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: ID.unique(),
        data: productData,
      );

      developer.log('TenantService: Product created: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to create product: $e');
      rethrow;
    }
  }

  /// Get all products
  Future<List<models.Document>> getProducts({int limit = 100}) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'products',
        queries: [Query.limit(limit)],
      );

      return response.documents;
    } catch (e) {
      developer.log('TenantService: Failed to get products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<models.Document?> getProduct(String documentId) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.getDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: documentId,
      );

      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to get product: $e');
      return null;
    }
  }

  /// Update product
  Future<models.Document> updateProduct(
    String documentId,
    Map<String, dynamic> productData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.updateDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: documentId,
        data: productData,
      );

      developer.log('TenantService: Product updated: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to update product: $e');
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String documentId) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      await _databases!.deleteDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: documentId,
      );

      developer.log('TenantService: Product deleted: $documentId');
    } catch (e) {
      developer.log('TenantService: Failed to delete product: $e');
      rethrow;
    }
  }

  /// Batch create products
  Future<List<models.Document>> batchCreateProducts(
    List<Map<String, dynamic>> productsData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    final results = <models.Document>[];

    for (final productData in productsData) {
      try {
        final doc = await createProduct(productData);
        results.add(doc);
      } catch (e) {
        developer.log('TenantService: Failed to create product in batch: $e');
      }
    }

    developer.log(
      'TenantService: Batch created ${results.length}/${productsData.length} products',
    );
    return results;
  }

  // ==================== CATEGORIES CRUD ====================

  /// Create a new category
  Future<models.Document> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.createDocument(
        databaseId: _databaseId!,
        collectionId: 'categories',
        documentId: ID.unique(),
        data: categoryData,
      );

      developer.log('TenantService: Category created: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to create category: $e');
      rethrow;
    }
  }

  /// Get all categories
  Future<List<models.Document>> getCategories({int limit = 100}) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'categories',
        queries: [Query.limit(limit)],
      );

      return response.documents;
    } catch (e) {
      developer.log('TenantService: Failed to get categories: $e');
      return [];
    }
  }

  /// Update category
  Future<models.Document> updateCategory(
    String documentId,
    Map<String, dynamic> categoryData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.updateDocument(
        databaseId: _databaseId!,
        collectionId: 'categories',
        documentId: documentId,
        data: categoryData,
      );

      developer.log('TenantService: Category updated: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to update category: $e');
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String documentId) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      await _databases!.deleteDocument(
        databaseId: _databaseId!,
        collectionId: 'categories',
        documentId: documentId,
      );

      developer.log('TenantService: Category deleted: $documentId');
    } catch (e) {
      developer.log('TenantService: Failed to delete category: $e');
      rethrow;
    }
  }

  // ==================== MODIFIERS CRUD ====================

  /// Create a new modifier group
  Future<models.Document> createModifierGroup(
    Map<String, dynamic> modifierGroupData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.createDocument(
        databaseId: _databaseId!,
        collectionId: 'modifier_groups',
        documentId: ID.unique(),
        data: modifierGroupData,
      );

      developer.log('TenantService: Modifier group created: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to create modifier group: $e');
      rethrow;
    }
  }

  /// Get all modifier groups
  Future<List<models.Document>> getModifierGroups({int limit = 100}) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'modifier_groups',
        queries: [Query.limit(limit)],
      );

      return response.documents;
    } catch (e) {
      developer.log('TenantService: Failed to get modifier groups: $e');
      return [];
    }
  }

  /// Update modifier group
  Future<models.Document> updateModifierGroup(
    String documentId,
    Map<String, dynamic> modifierGroupData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.updateDocument(
        databaseId: _databaseId!,
        collectionId: 'modifier_groups',
        documentId: documentId,
        data: modifierGroupData,
      );

      developer.log('TenantService: Modifier group updated: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to update modifier group: $e');
      rethrow;
    }
  }

  /// Delete modifier group
  Future<void> deleteModifierGroup(String documentId) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      await _databases!.deleteDocument(
        databaseId: _databaseId!,
        collectionId: 'modifier_groups',
        documentId: documentId,
      );

      developer.log('TenantService: Modifier group deleted: $documentId');
    } catch (e) {
      developer.log('TenantService: Failed to delete modifier group: $e');
      rethrow;
    }
  }

  // ==================== ORDERS CRUD ====================

  /// Get orders within date range
  Future<List<models.Document>> getOrders({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final queries = <String>[Query.limit(limit)];

      if (startDate != null) {
        queries.add(
          Query.greaterThan('created_at', startDate.toIso8601String()),
        );
      }

      if (endDate != null) {
        queries.add(Query.lessThan('created_at', endDate.toIso8601String()));
      }

      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'orders',
        queries: queries,
      );

      return response.documents;
    } catch (e) {
      developer.log('TenantService: Failed to get orders: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<models.Document?> getOrder(String documentId) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.getDocument(
        databaseId: _databaseId!,
        collectionId: 'orders',
        documentId: documentId,
      );

      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to get order: $e');
      return null;
    }
  }

  // ==================== BUSINESS INFO ====================

  /// Get business information
  Future<models.Document?> getBusinessInfo() async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'business_info',
        queries: [Query.limit(1)],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }

      return null;
    } catch (e) {
      developer.log('TenantService: Failed to get business info: $e');
      return null;
    }
  }

  /// Update business information
  Future<models.Document> updateBusinessInfo(
    String documentId,
    Map<String, dynamic> businessData,
  ) async {
    if (!_isConnected || _databaseId == null) {
      throw Exception('Not connected to tenant database');
    }

    try {
      final doc = await _databases!.updateDocument(
        databaseId: _databaseId!,
        collectionId: 'business_info',
        documentId: documentId,
        data: businessData,
      );

      developer.log('TenantService: Business info updated: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('TenantService: Failed to update business info: $e');
      rethrow;
    }
  }
}
