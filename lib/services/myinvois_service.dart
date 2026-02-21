import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:extropos/services/einvoice_service.dart';
import 'package:extropos/services/myinvois_platform_service.dart';

/// Unified MyInvois Service Facade
/// Provides convenient access to both e-Invoice API and Platform API
/// 
/// **e-Invoice API**: Core document submission and management
/// **Platform API**: System integration, notifications, advanced search
/// 
/// Reference:
/// - e-Invoice: https://sdk.myinvois.hasil.gov.my/einvoicingapi/
/// - Platform: https://sdk.myinvois.hasil.gov.my/api/
class MyInvoisService {
  static final MyInvoisService instance = MyInvoisService._internal();
  MyInvoisService._internal();

  /// Core e-Invoice API (document submission)
  final einvoice = EInvoiceService.instance;

  /// Platform API (system integration)
  final platform = MyInvoisPlatformService.instance;

  /// Initialize both services
  Future<void> init() async {
    await einvoice.init();
  }

  /// Get current configuration
  EInvoiceConfig? get config => einvoice.config;

  /// Check if services are enabled
  bool get isEnabled => einvoice.isEnabled;

  bool get isConfigured => einvoice.isConfigured;

  /// ==================== UNIFIED WORKFLOWS ====================

  /// Complete document submission workflow with status tracking
  Future<Map<String, dynamic>> submitAndTrackDocument(
    EInvoiceDocument document,
  ) async {
    // 1. Submit document via e-Invoice API
    final submitResult = await einvoice.submitDocuments([document]);
    final submissionUid = submitResult['submissionUID'];

    // 2. Wait briefly for processing
    await Future.delayed(const Duration(seconds: 2));

    // 3. Get detailed status via Platform API
    final status = await platform.getSubmissionStatus(submissionUid);

    return {
      'submissionUID': submissionUid,
      'acceptedDocuments': submitResult['acceptedDocuments'],
      'rejectedDocuments': submitResult['rejectedDocuments'],
      'status': status,
    };
  }

  /// Search documents with both APIs (fallback if one fails)
  Future<List<Map<String, dynamic>>> searchDocumentsRobust({
    required String submissionDateFrom,
    required String submissionDateTo,
    String? status,
    String? documentType,
    int pageSize = 100,
  }) async {
    try {
      // Try Platform API first (more features)
      final result = await platform.searchDocuments(
        submissionDateFrom: submissionDateFrom,
        submissionDateTo: submissionDateTo,
        status: status,
        documentType: documentType,
        pageSize: pageSize,
      );
      return List<Map<String, dynamic>>.from(result['result'] ?? []);
    } catch (e) {
      // Fallback to e-Invoice API (recent documents only)
      return await einvoice.getRecentDocuments(
        pageSize: pageSize,
        submissionDateFrom: submissionDateFrom,
        submissionDateTo: submissionDateTo,
      );
    }
  }

  /// Get complete document information (consolidated view)
  Future<Map<String, dynamic>> getCompleteDocumentInfo(String uuid) async {
    // Try Platform API for consolidated view first
    try {
      return await platform.getConsolidatedDocument(uuid);
    } catch (e) {
      // Fallback to e-Invoice API raw document
      return await einvoice.getDocument(uuid);
    }
  }

  /// Validate TIN with extended information
  Future<Map<String, dynamic>> validateTin(
    String tin, {
    bool extended = true,
  }) async {
    if (extended) {
      try {
        return await platform.validateTinExtended(tin);
      } catch (e) {
        // Fallback to basic validation
        return await einvoice.validateTin(tin);
      }
    } else {
      return await einvoice.validateTin(tin);
    }
  }

  /// ==================== NOTIFICATION MANAGEMENT ====================

  /// Get pending notifications (inbox view)
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    return await platform.getNotifications(status: 'pending', pageSize: 50);
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String notificationId) async {
    return await platform.markNotificationRead(notificationId);
  }

  /// Get unread notification count (for badge display)
  Future<int> getUnreadCount() async {
    return await platform.getUnreadNotificationCount();
  }

  /// ==================== SYSTEM HEALTH ====================

  /// Check overall system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    final results = <String, dynamic>{};

    // Test e-Invoice API
    try {
      final authSuccess = await einvoice.testConnection();
      results['einvoiceAPI'] = authSuccess ? 'OK' : 'AUTH_FAILED';
    } catch (e) {
      results['einvoiceAPI'] = 'ERROR: $e';
    }

    // Test Platform API
    try {
      final platformAvailable = await platform.isPlatformAvailable();
      results['platformAPI'] = platformAvailable ? 'OK' : 'UNAVAILABLE';
    } catch (e) {
      results['platformAPI'] = 'ERROR: $e';
    }

    // Get API version
    try {
      final version = await platform.getApiVersion();
      results['apiVersion'] = version;
    } catch (e) {
      results['apiVersion'] = 'UNKNOWN';
    }

    results['timestamp'] = DateTime.now().toIso8601String();
    results['overallStatus'] = results['einvoiceAPI'] == 'OK' &&
            results['platformAPI'] == 'OK'
        ? 'HEALTHY'
        : 'DEGRADED';

    return results;
  }

  /// ==================== REFERENCE DATA ====================

  /// Get document types (for dropdown/selection)
  Future<List<Map<String, dynamic>>> getDocumentTypes() async {
    return await platform.getDocumentTypes();
  }

  /// Get classification codes (item classes, units, etc.)
  Future<List<Map<String, dynamic>>> getClassificationCodes({
    String? codeType,
  }) async {
    return await platform.getClassificationCodes(codeType: codeType);
  }

  /// ==================== CONVENIENCE METHODS ====================

  /// Test complete system connectivity
  Future<bool> testFullConnection() async {
    final health = await getSystemHealth();
    return health['overallStatus'] == 'HEALTHY';
  }

  /// Clear all tokens and logout
  Future<void> logout() async {
    await einvoice.clearToken();
  }

  /// Get service summary (for diagnostics)
  Map<String, dynamic> getServiceInfo() {
    return {
      'enabled': isEnabled,
      'configured': isConfigured,
      'environment': config?.isProduction == true ? 'Production' : 'Sandbox',
      'identityUrl': config?.identityServiceUrl ?? 'Not configured',
      'apiUrl': config?.apiServiceUrl ?? 'Not configured',
      'clientId': config?.clientId != null ? '***${config!.clientId.substring(config!.clientId.length - 4)}' : 'Not set',
      'tin': config?.tin ?? 'Not set',
      'businessName': config?.businessName ?? 'Not set',
    };
  }
}
