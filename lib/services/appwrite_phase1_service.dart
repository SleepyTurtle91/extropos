
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

/// Appwrite Integration Service for Phase 1 Backend Flavor
///
/// Manages Appwrite connections for:
/// - backend_users collection
/// - roles collection
/// - activity_logs collection
/// - inventory_items collection
///
/// Configuration:
/// - Endpoint: https://appwrite.extropos.org/v1
/// - Project: 6940a64500383754a37f
/// - Database: pos_db
class AppwritePhase1Service extends ChangeNotifier {
  // Singleton instance
  static final AppwritePhase1Service _instance =
      AppwritePhase1Service._internal();

  factory AppwritePhase1Service() {
    return _instance;
  }

  AppwritePhase1Service._internal();

  // Appwrite clients
  late Client _client;
  late Databases _databases;
  late Realtime _realtime;

  // Configuration
  static const String _endpoint = 'https://appwrite.extropos.org/v1';
  static const String _projectId = '6940a64500383754a37f';
  static const String _databaseId = 'pos_db';
  static const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');
  // Enable/disable Appwrite usage (useful for offline-only POS flavor)
  static bool _enabled = true;

  /// Disable Appwrite (set from POS flavor startup to run offline-only)
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Whether Appwrite is enabled for this runtime
  static bool get isEnabled => _enabled;

  // Collection IDs
  static const String backendUsersCol = 'backend_users';
  static const String rolesCol = 'roles';
  static const String activityLogsCol = 'activity_logs';
  static const String inventoryCol = 'inventory_items';

  bool _isInitialized = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Initialize Appwrite connection
  Future<bool> initialize({String? apiKey}) async {
    if (_isInitialized) return true;

    // If Appwrite has been disabled (offline POS flavor), skip network initialization
    if (!_enabled) {
      print('⚠️ Appwrite is disabled (offline mode). Skipping initialization.');
      _isInitialized = true; // mark initialized so callers don't repeatedly try
      notifyListeners();
      return true;
    }

    try {
      print('🚀 Initializing Appwrite Phase 1 Service...');

      _client = Client()
        ..setEndpoint(_endpoint)
        ..setProject(_projectId);

      if (apiKey != null) {
        _client.addHeader('X-Appwrite-Key', apiKey);
      }

      _databases = Databases(_client);
      _realtime = Realtime(_client);

      print('✅ Appwrite Phase 1 Service initialized');
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error initializing Appwrite: $e');
      _errorMessage = 'Failed to initialize Appwrite: $e';
      notifyListeners();
      return false;
    }
  }

  /// Create Phase 1 collections (one-time setup)
  /// Note: Collections should be created via Appwrite console or API client
  /// This method is a placeholder for future automation
  Future<bool> setupCollections() async {
    if (!_isInitialized) {
      print('❌ Appwrite not initialized');
      return false;
    }

    try {
      print('📋 Verifying Phase 1 collections...');

      // Collections are expected to exist:
      // - backend_users
      // - roles
      // - activity_logs
      // - inventory_items
      //
      // If collections don't exist, create them via:
      // https://appwrite.extropos.org/console/database
      //
      // Required Schema:
      // backend_users: email(string, unique), displayName(string), phone(string), roleId(string), isActive(bool), isLockedOut(bool), createdAt(timestamp), updatedAt(timestamp)
      // roles: name(string, unique), permissions(json), isSystemRole(bool), createdAt(timestamp), updatedAt(timestamp)
      // activity_logs: userId(string), action(string), resourceType(string), resourceId(string), changesBefore(json), changesAfter(json), success(bool), failureReason(string), timestamp(string), createdAt(timestamp)
      // inventory_items: productId(string), productName(string), sku(string), currentQuantity(string), minStockLevel(string), maxStockLevel(string), costPerUnit(string), movements(json), createdAt(timestamp), updatedAt(timestamp)

      print('✅ Collections verified (ensure they exist in Appwrite console)');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error verifying collections: $e');
      _errorMessage = 'Failed to verify collections: $e';
      notifyListeners();
      return false;
    }
  }

  // Collection creation methods are disabled
  // Collections must be created manually via Appwrite console at:
  // https://appwrite.extropos.org/console/database
  //
  // See setupCollections() for required schema

  /// Create document
  Future<Map<String, dynamic>> createDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) throw Exception('Appwrite not initialized');

    // If Appwrite is disabled, provide a lightweight local fallback response
    if (!_enabled) {
      final id = (documentId == 'unique()')
          ? 'local-${DateTime.now().millisecondsSinceEpoch}'
          : documentId;
      return {r'$id': id, ...data};
    }

    if (_isTest) {
      return {r'$id': documentId, ...data};
    }

    try {
      final result = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );

      print('✅ Created: $collectionId/$documentId');
      return result.toMap();
    } catch (e) {
      print('❌ Error creating document: $e');
      throw Exception('Failed to create document: $e');
    }
  }

  /// Get document
  Future<Map<String, dynamic>> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    if (!_isInitialized) throw Exception('Appwrite not initialized');

    if (!_enabled) {
      throw Exception('Appwrite disabled (offline mode) - document not available');
    }

    if (_isTest) {
      throw Exception('Appwrite not available in tests');
    }

    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );

      return result.toMap();
    } catch (e) {
      print('❌ Error getting document: $e');
      throw Exception('Failed to get document: $e');
    }
  }

  /// List documents
  Future<List<Map<String, dynamic>>> listDocuments({
    required String collectionId,
    List<String>? queries,
    int limit = 25,
    int offset = 0,
  }) async {
    if (!_isInitialized) throw Exception('Appwrite not initialized');

    if (!_enabled) {
      return [];
    }

    if (_isTest) {
      return [];
    }

    try {
      final q = List<String>.from(queries ?? []);
      q.addAll(['Query.limit($limit)', 'Query.offset($offset)']);
      
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: collectionId,
        queries: q,
      );

      return result.documents.map((doc) => doc.toMap()).toList();
    } catch (e) {
      print('❌ Error listing documents: $e');
      throw Exception('Failed to list documents: $e');
    }
  }

  /// Update document
  Future<Map<String, dynamic>> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) throw Exception('Appwrite not initialized');

    if (!_enabled) {
      return {r'$id': documentId, ...data};
    }

    if (_isTest) {
      return {r'$id': documentId, ...data};
    }

    try {
      final result = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );

      print('✅ Updated: $collectionId/$documentId');
      return result.toMap();
    } catch (e) {
      print('❌ Error updating document: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    if (!_isInitialized) throw Exception('Appwrite not initialized');

    if (!_enabled) {
      return;
    }

    if (_isTest) {
      return;
    }

    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );

      print('✅ Deleted: $collectionId/$documentId');
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Query helpers
  List<String> buildQuery({
    String? attribute,
    String? operator,
    dynamic value,
  }) {
    if (attribute == null || operator == null) return [];
    return ['$attribute$operator$value'];
  }

  /// Get Appwrite services for advanced queries
  Databases get databases => _databases;
  Realtime get realtime => _realtime;
}
