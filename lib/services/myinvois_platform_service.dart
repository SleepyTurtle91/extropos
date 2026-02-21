import 'dart:convert';
import 'dart:developer';

import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:http/http.dart' as http;

/// MyInvois Platform API Service
/// Handles ERP system integration, notifications, and platform management
/// Reference: https://sdk.myinvois.hasil.gov.my/api/
class MyInvoisPlatformService {
  static final MyInvoisPlatformService instance =
      MyInvoisPlatformService._internal();
  MyInvoisPlatformService._internal();

  final _einvoiceService = EInvoiceService.instance;

  EInvoiceConfig? get _config => _einvoiceService.config;

  /// ==================== NOTIFICATION ENDPOINTS ====================

  /// Get all notifications
  /// Retrieves system notifications for the taxpayer
  Future<List<Map<String, dynamic>>> getNotifications({
    int pageNo = 1,
    int pageSize = 50,
    String? dateFrom,
    String? dateTo,
    String? status, // 'pending', 'read'
    String? channel, // 'email', 'push'
  }) async {
    final token = await _einvoiceService.authenticate();

    try {
      final queryParams = {
        'pageNo': pageNo.toString(),
        'pageSize': pageSize.toString(),
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
        if (status != null) 'status': status,
        if (channel != null) 'channel': channel,
      };

      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/notifications',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      log('Get notifications error: $e');
      rethrow;
    }
  }

  /// Get notification by ID
  Future<Map<String, dynamic>> getNotification(String notificationId) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/notifications/$notificationId',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Notification not found: ${response.statusCode}');
      }
    } catch (e) {
      log('Get notification error: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String notificationId) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/notifications/$notificationId/read',
      );

      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      log('Mark notification read error: $e');
      return false;
    }
  }

  /// ==================== DOCUMENT SEARCH ENDPOINTS ====================

  /// Search documents with advanced filters
  /// Platform API provides enhanced search beyond recent documents
  Future<Map<String, dynamic>> searchDocuments({
    required String submissionDateFrom,
    required String submissionDateTo,
    int pageNo = 1,
    int pageSize = 100,
    String? issuerTin,
    String? issuerName,
    String? receiverTin,
    String? receiverName,
    String? receiverIdType, // 'NRIC', 'PASSPORT', 'BRN', 'ARMY'
    String? receiverId,
    String? status, // 'Valid', 'Invalid', 'Cancelled', 'Submitted'
    String? documentType, // '01' (Invoice), '02' (Credit Note), etc.
    String? invoiceNumber,
    double? totalAmountFrom,
    double? totalAmountTo,
  }) async {
    final token = await _einvoiceService.authenticate();

    try {
      final queryParams = {
        'submissionDateFrom': submissionDateFrom,
        'submissionDateTo': submissionDateTo,
        'pageNo': pageNo.toString(),
        'pageSize': pageSize.toString(),
        if (issuerTin != null) 'issuerTin': issuerTin,
        if (issuerName != null) 'issuerName': issuerName,
        if (receiverTin != null) 'receiverTin': receiverTin,
        if (receiverName != null) 'receiverName': receiverName,
        if (receiverIdType != null) 'receiverIdType': receiverIdType,
        if (receiverId != null) 'receiverId': receiverId,
        if (status != null) 'status': status,
        if (documentType != null) 'documentType': documentType,
        if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
        if (totalAmountFrom != null)
          'totalAmountFrom': totalAmountFrom.toString(),
        if (totalAmountTo != null) 'totalAmountTo': totalAmountTo.toString(),
      };

      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/search',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Document search failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Document search error: $e');
      rethrow;
    }
  }

  /// Get document details (consolidated view)
  Future<Map<String, dynamic>> getDocumentDetails(String uuid) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/$uuid/details',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get document: ${response.statusCode}');
      }
    } catch (e) {
      log('Get document details error: $e');
      rethrow;
    }
  }

  /// ==================== DOCUMENT TYPE & CODE ENDPOINTS ====================

  /// Get all document types
  /// Returns list of supported document types (01-Invoice, 02-Credit Note, etc.)
  Future<List<Map<String, dynamic>>> getDocumentTypes() async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documenttypes',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      } else {
        throw Exception('Failed to get document types: ${response.statusCode}');
      }
    } catch (e) {
      log('Get document types error: $e');
      rethrow;
    }
  }

  /// Get document type by version
  Future<Map<String, dynamic>> getDocumentTypeByVersion(
    String documentTypeCode,
    String versionNumber,
  ) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documenttypes/$documentTypeCode/versions/$versionNumber',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Document type not found: ${response.statusCode}');
      }
    } catch (e) {
      log('Get document type error: $e');
      rethrow;
    }
  }

  /// ==================== ERP INTEGRATION ENDPOINTS ====================

  /// Get consolidated document (for ERP sync)
  /// Returns document in format optimized for ERP system integration
  Future<Map<String, dynamic>> getConsolidatedDocument(String uuid) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/$uuid/consolidated',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to get consolidated document: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Get consolidated document error: $e');
      rethrow;
    }
  }

  /// Reject document (for received invoices)
  /// Allows taxpayer to reject documents received from other parties
  Future<Map<String, dynamic>> rejectDocument(
    String uuid,
    String reason,
  ) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/$uuid/reject',
      );

      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'reason': reason}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to reject document: ${response.statusCode}');
      }
    } catch (e) {
      log('Reject document error: $e');
      rethrow;
    }
  }

  /// ==================== SUBMISSION STATUS ENDPOINTS ====================

  /// Get submission status (with detailed validation errors)
  Future<Map<String, dynamic>> getSubmissionStatus(String submissionUid) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/submissions/$submissionUid/status',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Submission not found: ${response.statusCode}');
      }
    } catch (e) {
      log('Get submission status error: $e');
      rethrow;
    }
  }

  /// ==================== VALIDATION ENDPOINTS ====================

  /// Validate TIN (enhanced validation with address details)
  Future<Map<String, dynamic>> validateTinExtended(String tin) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/taxpayer/validate/$tin/extended',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('TIN not found or not registered');
      } else {
        throw Exception('Validation failed: ${response.statusCode}');
      }
    } catch (e) {
      log('TIN extended validation error: $e');
      rethrow;
    }
  }

  /// Validate MSIC code (Malaysian Standard Industrial Classification)
  Future<Map<String, dynamic>> validateMsic(String msicCode) async {
    final token = await _einvoiceService.authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/codes/msic/$msicCode',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('MSIC code not found: ${response.statusCode}');
      }
    } catch (e) {
      log('MSIC validation error: $e');
      rethrow;
    }
  }

  /// ==================== CLASSIFICATION CODES ENDPOINTS ====================

  /// Get classification codes (item categories, measurement units, etc.)
  Future<List<Map<String, dynamic>>> getClassificationCodes({
    String? codeType, // 'CLASS', 'UNIT', 'COUNTRY', 'STATE', 'CURRENCY'
    int pageNo = 1,
    int pageSize = 100,
  }) async {
    final token = await _einvoiceService.authenticate();

    try {
      final queryParams = {
        'pageNo': pageNo.toString(),
        'pageSize': pageSize.toString(),
        if (codeType != null) 'codeType': codeType,
      };

      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/codes/classifications',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      } else {
        throw Exception(
          'Failed to get classification codes: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Get classification codes error: $e');
      rethrow;
    }
  }

  /// ==================== SYSTEM STATUS ENDPOINTS ====================

  /// Get system status (API health check)
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/status',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('System status check failed: ${response.statusCode}');
      }
    } catch (e) {
      log('System status error: $e');
      rethrow;
    }
  }

  /// Get API version information
  Future<Map<String, dynamic>> getApiVersion() async {
    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/version',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Version check failed: ${response.statusCode}');
      }
    } catch (e) {
      log('API version error: $e');
      rethrow;
    }
  }

  /// ==================== HELPERS ====================

  /// Check if platform service is available
  Future<bool> isPlatformAvailable() async {
    try {
      await getSystemStatus();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications =
          await getNotifications(status: 'pending', pageSize: 1);
      // Platform API typically returns total count in metadata
      return notifications.length;
    } catch (e) {
      log('Get unread count error: $e');
      return 0;
    }
  }
}
