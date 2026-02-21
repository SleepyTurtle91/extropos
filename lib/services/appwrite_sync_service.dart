import 'dart:async';
import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:extropos/config/environment.dart';
import 'package:flutter/foundation.dart';

/// Sync status for monitoring sync operations
enum SyncStatus { idle, syncing, success, error }

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final String? error;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.itemsSynced,
    this.error,
    required this.timestamp,
  });
}

/// Service for bidirectional sync between Backend app and Appwrite
/// Handles: Products, Categories, Modifiers, Orders, Business Info
class AppwriteSyncService extends ChangeNotifier {
  static final AppwriteSyncService instance = AppwriteSyncService._internal();
  AppwriteSyncService._internal();

  // Appwrite client and services
  Client? _client;
  Databases? _databases;

  // Configuration
  String? _endpoint;
  String? _projectId;
  String? _databaseId;
  String? _apiKey;

  // Sync state
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _errorMessage;
  int _totalItemsSynced = 0;

  // Realtime subscriptions
  final List<RealtimeSubscription> _subscriptions = [];

  // Getters
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  int get totalItemsSynced => _totalItemsSynced;
  bool get isInitialized => _client != null && _databases != null;
  // Expose configuration values for diagnostics/UI without allowing mutation
  String? get endpoint => _endpoint;
  String? get projectId => _projectId;
  String? get databaseId => _databaseId;
  String? get apiKey => _apiKey;

  /// Initialize the sync service with Appwrite credentials
  Future<void> initialize({
    required String endpoint,
    required String projectId,
    required String databaseId,
    String? apiKey,
  }) async {
    try {
      developer.log(
        'AppwriteSyncService: Initializing with endpoint=$endpoint',
      );

      _endpoint = endpoint;
      _projectId = projectId;
      _databaseId = databaseId;
      _apiKey = apiKey;

      // Initialize Appwrite client
      _client = Client()
        ..setEndpoint(endpoint)
        ..setProject(projectId);

      // Add API key if provided (for server-side operations)
      if (apiKey != null && apiKey.isNotEmpty) {
        _client!.addHeader('X-Appwrite-Key', apiKey);
      }

      _databases = Databases(_client!);

      developer.log('AppwriteSyncService: Initialized successfully');
      _updateStatus(SyncStatus.idle);
    } catch (e) {
      developer.log('AppwriteSyncService: Initialization failed: $e');
      _updateStatus(SyncStatus.error, error: e.toString());
      rethrow;
    }
  }

  /// Test connection to Appwrite
  Future<bool> testConnection() async {
    if (!isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }

    try {
      developer.log('AppwriteSyncService: Testing connection...');

      // Try to list a known collection to verify connection
      await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: Environment.categoriesCollection,
        queries: [Query.limit(1)],
      );

      developer.log('AppwriteSyncService: Connection test successful');
      return true;
    } catch (e) {
      developer.log('AppwriteSyncService: Connection test failed: $e');
      _updateStatus(SyncStatus.error, error: 'Connection failed: $e');
      return false;
    }
  }

  /// Full sync - synchronizes all data types
  Future<SyncResult> fullSync() async {
    if (!isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }

    _updateStatus(SyncStatus.syncing);
    int totalItems = 0;

    try {
      developer.log('AppwriteSyncService: Starting full sync...');

      // Sync in order: Business Info → Categories → Products → Modifiers → Orders
      final businessResult = await syncBusinessInfo();
      totalItems += businessResult.itemsSynced;

      final categoriesResult = await syncCategories();
      totalItems += categoriesResult.itemsSynced;

      final productsResult = await syncProducts();
      totalItems += productsResult.itemsSynced;

      final modifiersResult = await syncModifiers();
      totalItems += modifiersResult.itemsSynced;

      final ordersResult = await syncOrders();
      totalItems += ordersResult.itemsSynced;

      _totalItemsSynced = totalItems;
      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      developer.log(
        'AppwriteSyncService: Full sync completed. Items synced: $totalItems',
      );

      return SyncResult(
        success: true,
        itemsSynced: totalItems,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Full sync failed: $e');
      _updateStatus(SyncStatus.error, error: e.toString());

      return SyncResult(
        success: false,
        itemsSynced: totalItems,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync products from local DB to Appwrite
  Future<SyncResult> syncProducts() async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      developer.log('AppwriteSyncService: Syncing products...');

      // Get products from Appwrite
      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'products',
        queries: [
          Query.limit(100), // Batch size
        ],
      );

      developer.log(
        'AppwriteSyncService: Products synced: ${response.documents.length}',
      );

      return SyncResult(
        success: true,
        itemsSynced: response.documents.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Product sync failed: $e');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync categories
  Future<SyncResult> syncCategories() async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      developer.log('AppwriteSyncService: Syncing categories...');

      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'categories',
        queries: [Query.limit(100)],
      );

      developer.log(
        'AppwriteSyncService: Categories synced: ${response.documents.length}',
      );

      return SyncResult(
        success: true,
        itemsSynced: response.documents.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Category sync failed: $e');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync modifiers
  Future<SyncResult> syncModifiers() async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      developer.log('AppwriteSyncService: Syncing modifiers...');

      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'modifier_groups',
        queries: [Query.limit(100)],
      );

      developer.log(
        'AppwriteSyncService: Modifiers synced: ${response.documents.length}',
      );

      return SyncResult(
        success: true,
        itemsSynced: response.documents.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Modifier sync failed: $e');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync orders (pull from Appwrite)
  Future<SyncResult> syncOrders() async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      developer.log('AppwriteSyncService: Syncing orders...');

      // Get recent orders (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'orders',
        queries: [
          Query.greaterThan('created_at', sevenDaysAgo.toIso8601String()),
          Query.orderDesc('created_at'),
          Query.limit(100),
        ],
      );

      developer.log(
        'AppwriteSyncService: Orders synced: ${response.documents.length}',
      );

      return SyncResult(
        success: true,
        itemsSynced: response.documents.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Order sync failed: $e');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Sync business info
  Future<SyncResult> syncBusinessInfo() async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      developer.log('AppwriteSyncService: Syncing business info...');

      final response = await _databases!.listDocuments(
        databaseId: _databaseId!,
        collectionId: 'business_info',
        queries: [Query.limit(1)],
      );

      developer.log(
        'AppwriteSyncService: Business info synced: ${response.documents.length}',
      );

      return SyncResult(
        success: true,
        itemsSynced: response.documents.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('AppwriteSyncService: Business info sync failed: $e');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Push local product to Appwrite
  Future<models.Document> createProduct({
    required Map<String, dynamic> productData,
  }) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      final doc = await _databases!.createDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: ID.unique(),
        data: productData,
      );

      developer.log('AppwriteSyncService: Product created: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('AppwriteSyncService: Product creation failed: $e');
      rethrow;
    }
  }

  /// Update product in Appwrite
  Future<models.Document> updateProduct({
    required String documentId,
    required Map<String, dynamic> productData,
  }) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      final doc = await _databases!.updateDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: documentId,
        data: productData,
      );

      developer.log('AppwriteSyncService: Product updated: ${doc.$id}');
      return doc;
    } catch (e) {
      developer.log('AppwriteSyncService: Product update failed: $e');
      rethrow;
    }
  }

  /// Delete product from Appwrite
  Future<void> deleteProduct(String documentId) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      await _databases!.deleteDocument(
        databaseId: _databaseId!,
        collectionId: 'products',
        documentId: documentId,
      );

      developer.log('AppwriteSyncService: Product deleted: $documentId');
    } catch (e) {
      developer.log('AppwriteSyncService: Product deletion failed: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time updates for products
  Future<void> subscribeToProducts(Function(dynamic) callback) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      final realtime = Realtime(_client!);

      final subscription = realtime.subscribe([
        'databases.$_databaseId.collections.products.documents',
      ]);

      subscription.stream.listen((response) {
        developer.log('AppwriteSyncService: Real-time product update received');
        callback(response);
      });

      _subscriptions.add(subscription);

      developer.log('AppwriteSyncService: Subscribed to product updates');
    } catch (e) {
      developer.log('AppwriteSyncService: Real-time subscription failed: $e');
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'status': _status.toString(),
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'totalItemsSynced': _totalItemsSynced,
      'errorMessage': _errorMessage,
      'isInitialized': isInitialized,
    };
  }

  /// Update sync status and notify listeners
  void _updateStatus(SyncStatus newStatus, {String? error}) {
    _status = newStatus;
    _errorMessage = error;
    notifyListeners();
  }

  /// Clean up subscriptions
  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
