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
  /// Provides real-time information about tenant database health and maintenance status
  static Future<Map<String, dynamic>?> getTenantDatabaseStatus(
    String tenantId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tenant/$tenantId/db-status'),
        headers: {
          'X-API-Key': await _getApiKey(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('SuperAdminService: Error getting status: $e');
      return null;
    }
  }

  /// Cancel tenant database maintenance
  /// Allows aborting ongoing database maintenance operations
  static Future<bool> cancelTenantDatabaseMaintenance(String tenantId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tenant/$tenantId/db-access/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': await _getApiKey(),
        },
        body: jsonEncode({
          'action': 'CANCEL_MAINTENANCE',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      developer.log('SuperAdminService: Error canceling maintenance: $e');
      return false;
    }
  }
}
