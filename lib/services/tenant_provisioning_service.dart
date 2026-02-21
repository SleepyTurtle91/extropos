import 'dart:convert';
import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:extropos/config/environment.dart';
import 'package:http/http.dart' as http;

/// Service for automated multi-tenant provisioning
/// Handles creating tenant databases, collections, and initial setup
class TenantProvisioningService {
  static final TenantProvisioningService instance =
      TenantProvisioningService._internal();
  TenantProvisioningService._internal();

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    _isInitialized = true;
    developer.log('TenantProvisioningService: Service initialized');
  }

  /// Make authenticated API request to Appwrite
  Future<http.Response> _apiRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${Environment.appwritePublicEndpoint}$path');
    final headers = {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': Environment.appwriteProjectId,
      'X-Appwrite-Key': Environment.appwriteApiKey,
    };

    final requestBody = body != null ? jsonEncode(body) : null;

    try {
      late http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: requestBody);
          break;
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};
        throw Exception(
          'API request failed: ${response.statusCode} - ${errorBody['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('TenantProvisioningService: API request failed: $e');
      rethrow;
    }
  }

  /// Create a new tenant with isolated database and collections
  /// Returns the tenant ID on success
  Future<String> createTenant({
    required String tenantName,
    required String ownerEmail,
    required String ownerName,
    String? customDomain,
  }) async {
    await _ensureInitialized();

    try {
      // Generate unique tenant ID
      final tenantId = 'tenant_${DateTime.now().millisecondsSinceEpoch}';

      developer.log(
        'TenantProvisioningService: Creating tenant $tenantId for $tenantName',
      );

      // 1. Create tenant database
      await _createTenantDatabase(tenantId, tenantName);

      // 2. Create all required collections
      await _createTenantCollections(tenantId);

      // 3. Create storage buckets
      await _createTenantBuckets(tenantId);

      // 4. Initialize default data
      await _initializeTenantData(tenantId, ownerEmail, ownerName, tenantName);

      developer.log(
        'TenantProvisioningService: Tenant $tenantId created successfully',
      );

      return tenantId;
    } catch (e) {
      developer.log('TenantProvisioningService: Failed to create tenant: $e');
      rethrow;
    }
  }

  /// Create the tenant database
  Future<void> _createTenantDatabase(String tenantId, String tenantName) async {
    try {
      await _apiRequest(
        'POST',
        '/v1/databases',
        body: {'databaseId': tenantId, 'name': '$tenantName Database'},
      );
      developer.log('TenantProvisioningService: Database $tenantId created');
    } catch (e) {
      developer.log('TenantProvisioningService: Failed to create database: $e');
      rethrow;
    }
  }

  /// Create all required collections for the tenant
  Future<void> _createTenantCollections(String tenantId) async {
    final collections = [
      {'id': Environment.categoriesCollection, 'name': 'Categories'},
      {'id': Environment.itemsCollection, 'name': 'Items'},
      {'id': Environment.ordersCollection, 'name': 'Orders'},
      {'id': Environment.orderItemsCollection, 'name': 'Order Items'},
      {'id': Environment.usersCollection, 'name': 'Users'},
      {'id': Environment.tablesCollection, 'name': 'Tables'},
      {'id': Environment.paymentMethodsCollection, 'name': 'Payment Methods'},
      {'id': Environment.customersCollection, 'name': 'Customers'},
      {'id': Environment.transactionsCollection, 'name': 'Transactions'},
      {'id': Environment.printersCollection, 'name': 'Printers'},
      {
        'id': Environment.customerDisplaysCollection,
        'name': 'Customer Displays',
      },
      {'id': Environment.receiptSettingsCollection, 'name': 'Receipt Settings'},
      {'id': Environment.modifierGroupsCollection, 'name': 'Modifier Groups'},
      {'id': Environment.modifierItemsCollection, 'name': 'Modifier Items'},
      {'id': Environment.businessInfoCollection, 'name': 'Business Info'},
    ];

    for (final collection in collections) {
      try {
        await _apiRequest(
          'POST',
          '/v1/databases/$tenantId/collections',
          body: {
            'collectionId': collection['id'],
            'name': collection['name'],
            'permissions': [
              'read("any")',
              'write("any")',
              'create("any")',
              'update("any")',
              'delete("any")',
            ],
          },
        );
        developer.log(
          'TenantProvisioningService: Collection ${collection['id']} created',
        );
      } catch (e) {
        developer.log(
          'TenantProvisioningService: Failed to create collection ${collection['id']}: $e',
        );
        rethrow;
      }
    }
  }

  /// Create storage buckets for the tenant
  Future<void> _createTenantBuckets(String tenantId) async {
    final buckets = [
      {'id': Environment.receiptImagesBucket, 'name': 'Receipt Images'},
      {'id': Environment.productImagesBucket, 'name': 'Product Images'},
      {'id': Environment.logoImagesBucket, 'name': 'Logo Images'},
      {'id': Environment.reportsBucket, 'name': 'Reports'},
    ];

    for (final bucket in buckets) {
      try {
        await _apiRequest(
          'POST',
          '/v1/storage/buckets',
          body: {
            'bucketId': '${bucket['id']}_$tenantId',
            'name': '${bucket['name']} - $tenantId',
            'permissions': [
              'read("any")',
              'write("any")',
              'create("any")',
              'update("any")',
              'delete("any")',
            ],
          },
        );
        developer.log(
          'TenantProvisioningService: Bucket ${bucket['id']}_$tenantId created',
        );
      } catch (e) {
        developer.log(
          'TenantProvisioningService: Failed to create bucket ${bucket['id']}: $e',
        );
        rethrow;
      }
    }
  }

  /// Initialize default data for the tenant
  Future<void> _initializeTenantData(
    String tenantId,
    String ownerEmail,
    String ownerName,
    String tenantName,
  ) async {
    try {
      // Create default business info
      await _apiRequest(
        'POST',
        '/v1/databases/$tenantId/collections/${Environment.businessInfoCollection}/documents',
        body: {
          'documentId': ID.unique(),
          'data': {
            'business_name': tenantName,
            'owner_name': ownerName,
            'email': ownerEmail,
            'phone': '+60123456789',
            'address': '123 Main Street',
            'city': 'Kuala Lumpur',
            'state': 'Wilayah Persekutuan',
            'postcode': '50000',
            'country': 'Malaysia',
            'tax_rate': 0.10, // 10% default
            'is_tax_enabled': true,
            'service_charge_rate': 0.05, // 5% default
            'is_service_charge_enabled': false,
            'currency': 'MYR',
            'currency_symbol': 'RM',
            'receipt_header_font_size': 2,
            'receipt_header_bold': true,
            'receipt_header_centered': true,
            'selected_business_mode': 'retail', // Default to retail mode
            'is_happy_hour_enabled': false,
            'happy_hour_discount_percent': 0.0,
            'created_at': DateTime.now().toIso8601String(),
          },
        },
      );

      // Create default categories
      final defaultCategories = [
        {'name': 'Food', 'sort_order': 1, 'is_active': true},
        {'name': 'Beverages', 'sort_order': 2, 'is_active': true},
        {'name': 'Desserts', 'sort_order': 3, 'is_active': true},
      ];

      for (final category in defaultCategories) {
        await _apiRequest(
          'POST',
          '/v1/databases/$tenantId/collections/${Environment.categoriesCollection}/documents',
          body: {'documentId': ID.unique(), 'data': category},
        );
      }

      developer.log(
        'TenantProvisioningService: Default data initialized for tenant $tenantId',
      );
    } catch (e) {
      developer.log(
        'TenantProvisioningService: Failed to initialize default data: $e',
      );
      // Don't rethrow - tenant is still created successfully
    }
  }

  /// Delete a tenant and all associated data
  Future<void> deleteTenant(String tenantId) async {
    await _ensureInitialized();

    try {
      developer.log('TenantProvisioningService: Deleting tenant $tenantId');

      // Delete storage buckets first
      final buckets = [
        '${Environment.receiptImagesBucket}_$tenantId',
        '${Environment.productImagesBucket}_$tenantId',
        '${Environment.logoImagesBucket}_$tenantId',
        '${Environment.reportsBucket}_$tenantId',
      ];

      for (final bucketId in buckets) {
        try {
          await _apiRequest('DELETE', '/v1/storage/buckets/$bucketId');
          developer.log('TenantProvisioningService: Bucket $bucketId deleted');
        } catch (e) {
          developer.log(
            'TenantProvisioningService: Failed to delete bucket $bucketId: $e',
          );
          // Continue with other deletions
        }
      }

      // Delete database (this will delete all collections and documents)
      await _apiRequest('DELETE', '/v1/databases/$tenantId');
      developer.log('TenantProvisioningService: Database $tenantId deleted');
    } catch (e) {
      developer.log(
        'TenantProvisioningService: Failed to delete tenant $tenantId: $e',
      );
      rethrow;
    }
  }

  /// Get tenant database info
  Future<Map<String, dynamic>?> getTenantInfo(String tenantId) async {
    await _ensureInitialized();

    try {
      final response = await _apiRequest('GET', '/v1/databases/$tenantId');
      final data = jsonDecode(response.body);
      return {
        'id': data['\$id'],
        'name': data['name'],
        'created_at': data['\$createdAt'],
        'updated_at': data['\$updatedAt'],
      };
    } catch (e) {
      developer.log(
        'TenantProvisioningService: Failed to get tenant info for $tenantId: $e',
      );
      return null;
    }
  }
}
