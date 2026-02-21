import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appwrite Core Service for POS Counter to Backend Connection
/// Handles automatic discovery, registration, and connection of POS counters to backends
class AppwriteCoreService {
  static final AppwriteCoreService instance = AppwriteCoreService._internal();
  AppwriteCoreService._internal();

  // Core Appwrite configuration (central server)
  static const String _coreEndpoint = 'https://cloud.appwrite.io/v1';
  static const String _coreProjectId =
      '689965770017299bd5a5'; // Your main project
  static const String _coreDatabaseId = 'main';

  // Collection IDs for core database
  static const String _backendsCollection = 'backends';
  static const String _countersCollection = 'counters';
  static const String _registrationsCollection = 'counter_registrations';

  Client? _coreClient;
  Databases? _coreDatabases;
  bool _isCoreInitialized = false;

  // Current connection details
  String? _connectedBackendId;
  String? _counterId;
  Map<String, dynamic>? _backendConfig;

  // Getters
  bool get isConnected => _connectedBackendId != null && _counterId != null;
  String? get connectedBackendId => _connectedBackendId;
  String? get counterId => _counterId;
  Map<String, dynamic>? get backendConfig => _backendConfig;

  /// Initialize the core service
  Future<void> initialize() async {
    if (_isCoreInitialized) return;

    try {
      _coreClient = Client()
          .setEndpoint(_coreEndpoint)
          .setProject(_coreProjectId);

      _coreDatabases = Databases(_coreClient!);
      _isCoreInitialized = true;

      developer.log('AppwriteCoreService: Core service initialized');

      // Try to restore previous connection
      await _restoreConnection();
    } catch (e) {
      developer.log('AppwriteCoreService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Restore previous connection from shared preferences
  Future<void> _restoreConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backendId = prefs.getString('connected_backend_id');
      final counterId = prefs.getString('counter_id');

      if (backendId != null && counterId != null) {
        // Verify the connection is still valid
        final backend = await _getBackendDetails(backendId);
        if (backend != null) {
          _connectedBackendId = backendId;
          _counterId = counterId;
          _backendConfig = backend.data;
          developer.log(
            'AppwriteCoreService: Restored connection to backend $backendId as counter $counterId',
          );
        }
      }
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to restore connection: $e');
    }
  }

  /// Discover available backends
  Future<List<Map<String, dynamic>>> discoverBackends() async {
    if (!_isCoreInitialized) await initialize();

    try {
      final response = await _coreDatabases!.listDocuments(
        databaseId: _coreDatabaseId,
        collectionId: _backendsCollection,
        queries: [Query.equal('status', 'active')],
      );

      return response.documents
          .map(
            (doc) => {
              'id': doc.$id,
              'name': doc.data['name'] ?? 'Unknown Backend',
              'description': doc.data['description'] ?? '',
              'endpoint': doc.data['endpoint'],
              'projectId': doc.data['projectId'],
              'status': doc.data['status'] ?? 'unknown',
              'lastSeen': doc.data['lastSeen'],
            },
          )
          .toList();
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to discover backends: $e');
      return [];
    }
  }

  /// Register a new backend in the core system
  Future<String?> registerBackend({
    required String name,
    required String description,
    required String endpoint,
    required String projectId,
    required String apiKey,
  }) async {
    if (!_isCoreInitialized) await initialize();

    try {
      final document = await _coreDatabases!.createDocument(
        databaseId: _coreDatabaseId,
        collectionId: _backendsCollection,
        documentId: ID.unique(),
        data: {
          'name': name,
          'description': description,
          'endpoint': endpoint,
          'projectId': projectId,
          'apiKey': apiKey, // In production, this should be encrypted
          'status': 'active',
          'registeredAt': DateTime.now().toIso8601String(),
          'lastSeen': DateTime.now().toIso8601String(),
        },
      );

      developer.log(
        'AppwriteCoreService: Backend registered with ID: ${document.$id}',
      );
      return document.$id;
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to register backend: $e');
      return null;
    }
  }

  /// Get or generate a unique device ID
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    return deviceId;
  }

  /// Connect POS counter to a backend
  Future<Map<String, String>?> connectToBackend({
    required String backendId,
    required String counterName,
    String? counterDescription,
  }) async {
    if (!_isCoreInitialized) await initialize();

    try {
      // Get backend details
      final backend = await _getBackendDetails(backendId);
      if (backend == null) {
        throw Exception('Backend not found');
      }

      // Generate tenant-specific counter ID
      // Format: TENANT-{backendId}-{deviceId}-{timestamp}
      final deviceId = await _getDeviceId();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final counterId =
          'TENANT-${backendId.substring(0, 8)}-${deviceId.substring(0, 8)}-${timestamp.substring(timestamp.length - 6)}';

      // Register counter with backend
      await _coreDatabases!.createDocument(
        databaseId: _coreDatabaseId,
        collectionId: _countersCollection,
        documentId: counterId,
        data: {
          'backendId': backendId,
          'name': counterName,
          'description': counterDescription ?? '',
          'deviceId': deviceId,
          'tenantId': backendId, // Counter ID contains tenant identification
          'status': 'active',
          'registeredAt': DateTime.now().toIso8601String(),
          'lastSeen': DateTime.now().toIso8601String(),
        },
      );

      // Create registration record
      await _coreDatabases!.createDocument(
        databaseId: _coreDatabaseId,
        collectionId: _registrationsCollection,
        documentId: ID.unique(),
        data: {
          'backendId': backendId,
          'counterId': counterId,
          'connectedAt': DateTime.now().toIso8601String(),
          'status': 'active',
        },
      );

      // Store connection details
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_backend_id', backendId);
      await prefs.setString('counter_id', counterId);

      _connectedBackendId = backendId;
      _counterId = counterId;
      _backendConfig = backend.data;

      developer.log(
        'AppwriteCoreService: Counter $counterId connected to backend $backendId',
      );

      // Return connection details for license service
      return {
        'counterId': counterId,
        'tenantId': backendId,
        'endpoint': backend.data['endpoint'] ?? '',
        'apiKey': backend.data['apiKey'] ?? '',
      };
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to connect counter: $e');
      return null;
    }
  }

  /// Get backend details by ID
  Future<Document?> _getBackendDetails(String backendId) async {
    try {
      return await _coreDatabases!.getDocument(
        databaseId: _coreDatabaseId,
        collectionId: _backendsCollection,
        documentId: backendId,
      );
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to get backend details: $e');
      return null;
    }
  }

  /// Get connected counters for a backend
  Future<List<Map<String, dynamic>>> getConnectedCounters(
    String backendId,
  ) async {
    if (!_isCoreInitialized) await initialize();

    try {
      final response = await _coreDatabases!.listDocuments(
        databaseId: _coreDatabaseId,
        collectionId: _countersCollection,
        queries: [
          Query.equal('backendId', backendId),
          Query.equal('status', 'active'),
        ],
      );

      return response.documents
          .map(
            (doc) => {
              'id': doc.$id,
              'name': doc.data['name'] ?? 'Unknown Counter',
              'description': doc.data['description'] ?? '',
              'status': doc.data['status'] ?? 'unknown',
              'lastSeen': doc.data['lastSeen'],
              'registeredAt': doc.data['registeredAt'],
            },
          )
          .toList();
    } catch (e) {
      developer.log(
        'AppwriteCoreService: Failed to get connected counters: $e',
      );
      return [];
    }
  }

  /// Update counter heartbeat (call periodically to show counter is active)
  Future<void> updateCounterHeartbeat() async {
    if (_counterId == null || !_isCoreInitialized) return;

    try {
      await _coreDatabases!.updateDocument(
        databaseId: _coreDatabaseId,
        collectionId: _countersCollection,
        documentId: _counterId!,
        data: {'lastSeen': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to update heartbeat: $e');
    }
  }

  /// Disconnect counter from backend
  Future<void> disconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('connected_backend_id');
      await prefs.remove('counter_id');

      _connectedBackendId = null;
      _counterId = null;
      _backendConfig = null;

      developer.log('AppwriteCoreService: Counter disconnected');
    } catch (e) {
      developer.log('AppwriteCoreService: Failed to disconnect: $e');
    }
  }

  /// Get backend connection details for direct Appwrite access
  Future<Map<String, String>?> getBackendConnectionDetails() async {
    if (_backendConfig == null) return null;

    return {
      'endpoint': _backendConfig!['endpoint'],
      'projectId': _backendConfig!['projectId'],
      'databaseId': _connectedBackendId!, // Use backend ID as database ID
    };
  }

  /// Test connection to connected backend
  Future<bool> testBackendConnection() async {
    if (_backendConfig == null) return false;

    try {
      final client = Client()
          .setEndpoint(_backendConfig!['endpoint'])
          .setProject(_backendConfig!['projectId']);

      final databases = Databases(client);

      // Try a simple query to test connection
      await databases.listDocuments(
        databaseId: _connectedBackendId!,
        collectionId: 'categories', // Test with categories collection
        queries: [Query.limit(1)],
      );

      return true;
    } catch (e) {
      developer.log('AppwriteCoreService: Backend connection test failed: $e');
      return false;
    }
  }

  /// Get core client for advanced operations
  Client? get coreClient => _coreClient;

  /// Get backend details by counter ID
  Future<Map<String, dynamic>?> getBackendByCounterId(String counterId) async {
    if (!_isCoreInitialized) await initialize();

    try {
      // Extract tenant ID from counter ID
      final tenantId = _extractTenantIdFromCounterId(counterId);
      if (tenantId == null) return null;

      final backend = await _getBackendDetails(tenantId);
      return backend?.data;
    } catch (e) {
      developer.log(
        'AppwriteCoreService: Failed to get backend by counter ID: $e',
      );
      return null;
    }
  }

  /// Extract tenant ID from counter ID format: TENANT-{backendId}-{deviceId}-{timestamp}
  String? _extractTenantIdFromCounterId(String counterId) {
    if (!counterId.startsWith('TENANT-')) return null;

    final parts = counterId.split('-');
    if (parts.length < 2) return null;

    return parts[1];
  }
}
