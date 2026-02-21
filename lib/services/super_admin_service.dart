import 'dart:convert';
import 'dart:developer' as developer;

import 'package:extropos/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

/// Service for Super Admin operations
/// Handles tenant database management and other privileged operations
class SuperAdminService {
  static const String _baseUrl = 'https://api.extropos.org/api/v1/superadmin';

  /// Get the super admin API key from secure storage
  static Future<String> _getApiKey() async {
    try {
      final secureStorage = SecureStorageService.instance;
      await secureStorage.init();

      // For now, we'll store a default key if none exists
      // In production, this should be set during app initialization/setup
      const defaultKey = 'super-admin-secret-key-2025-secure-random-string';

      // Try to read existing key
      final storedKey = await secureStorage.getSuperAdminApiKey();
      if (storedKey != null && storedKey.isNotEmpty) {
        return storedKey;
      }

      // If no key exists, store the default and return it
      await secureStorage.storeSuperAdminApiKey(defaultKey);
      developer.log(
        'SuperAdminService: Stored default API key in secure storage',
      );
      return defaultKey;
    } catch (e) {
      developer.log('SuperAdminService: Error accessing secure storage: $e');
      // Fallback to default key if secure storage fails
      return 'super-admin-secret-key-2025-secure-random-string';
    }
  }

  /// Initiate database maintenance access for a specific tenant
  /// Returns true if successful, false otherwise
  static Future<bool> initiateTenantDatabaseAccess(String tenantId) async {
    try {
      developer.log(
        'SuperAdminService: Initiating database access for tenant $tenantId',
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/tenant/$tenantId/db-access'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': await _getApiKey(),
        },
        body: jsonEncode({
          'action': 'INITIATE_MAINTENANCE_ACCESS',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      developer.log(
        'SuperAdminService: POST ${'"'}$_baseUrl/tenant/$tenantId/db-access${'"'}',
        name: 'SuperAdminService',
      );

      if (response.statusCode == 202) {
        // HTTP 202 Accepted - Request accepted for processing
        developer.log(
          'SuperAdminService: Database access initiated successfully for tenant $tenantId',
        );
        return true;
      } else if (response.statusCode == 404) {
        // HTTP 404 Not Found - Endpoint missing on server
        developer.log(
          'SuperAdminService: Endpoint not found for tenant $tenantId - ${response.body}',
        );
        // Try to extract useful message from server JSON
        try {
          final parsed = jsonDecode(response.body);
          throw Exception(
            'Endpoint not found: ${parsed['message'] ?? response.body}',
          );
        } catch (_) {
          throw Exception('Endpoint not found: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        // HTTP 403 Forbidden - Authorization failed
        developer.log(
          'SuperAdminService: Authorization failed for tenant $tenantId',
        );
        throw Exception('Authorization failed: Super Admin access required');
      } else if (response.statusCode == 503) {
        // HTTP 503 Service Unavailable - DB Ops service unavailable
        developer.log(
          'SuperAdminService: DB Ops service unavailable for tenant $tenantId',
        );
        throw Exception(
          'Service unavailable: Database operations service is currently unavailable',
        );
      } else {
        // Other error codes
        developer.log(
          'SuperAdminService: Failed to initiate database access for tenant $tenantId - Status: ${response.statusCode}',
        );
        throw Exception('Failed to initiate database access: ${response.body}');
      }
    } catch (e) {
      developer.log(
        'SuperAdminService: Error initiating database access for tenant $tenantId: $e',
      );
      rethrow;
    }
  }

  /// Get tenant database status
  /// TODO: Implement when backend API supports status queries
  /// This will provide real-time information about tenant database health,
  /// maintenance status, and operational metrics
  static Future<Map<String, dynamic>?> getTenantDatabaseStatus(
    String tenantId,
  ) async {
    // TODO: Implement when backend supports status queries
    developer.log(
      'SuperAdminService: getTenantDatabaseStatus not yet implemented for tenant $tenantId',
    );
    return null;
  }

  /// Cancel tenant database maintenance
  /// TODO: Implement when backend API supports maintenance cancellation
  /// This will allow aborting ongoing database maintenance operations
  /// and restoring normal tenant database access
  static Future<bool> cancelTenantDatabaseMaintenance(String tenantId) async {
    // TODO: Implement when backend supports cancellation
    developer.log(
      'SuperAdminService: cancelTenantDatabaseMaintenance not yet implemented for tenant $tenantId',
    );
    return false;
  }
}
