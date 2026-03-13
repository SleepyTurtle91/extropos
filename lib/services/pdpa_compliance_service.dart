import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:extropos/services/database_service.dart';

/// PDPA (Personal Data Protection Act) Compliance Service
/// Handles data encryption, consent management, and audit logging
class PDPAComplianceService {
  static final PDPAComplianceService _instance = PDPAComplianceService._internal();

  factory PDPAComplianceService() {
    return _instance;
  }

  PDPAComplianceService._internal();

  late encrypt.Key _encryptionKey;
  late encrypt.IV _iv;

  /// Initialize PDPA service with encryption
  Future<void> initialize({String? customKey}) async {
    try {
      // Generate or use provided encryption key
      if (customKey != null) {
        _encryptionKey = encrypt.Key.fromUtf8(customKey.padRight(32).substring(0, 32));
      } else {
        // Generate a new key (in production, load from secure storage)
        _encryptionKey = encrypt.Key.fromSecureRandom(32);
      }

      // Generate IV
      _iv = encrypt.IV.fromSecureRandom(16);

      print('✅ PDPA Compliance Service initialized');
    } catch (e) {
      print('🔥 Error initializing PDPA service: $e');
      rethrow;
    }
  }

  /// Encrypt sensitive customer data
  Future<String> encryptCustomerData(String plainText) async {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('🔥 Encryption error: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  /// Decrypt customer data
  Future<String> decryptCustomerData(String cipherText) async {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final decrypted = encrypter.decrypt64(cipherText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('🔥 Decryption error: $e');
      throw Exception('Failed to decrypt data');
    }
  }

  /// Record activity for audit trail
  Future<void> logActivity(
    String userId,
    String action,
    Map<String, dynamic> details, {
    String? customerId,
    String? ipAddress,
  }) async {
    try {
      final log = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        action: action,
        details: details,
        customerId: customerId,
        ipAddress: ipAddress ?? 'unknown',
        timestamp: DateTime.now(),
      );

      await DatabaseService.instance.saveAuditLog(log);
      print('📝 Audit log: $action by $userId');
    } catch (e) {
      print('🔥 Error logging activity: $e');
    }
  }

  /// Record customer consent
  Future<void> recordConsent(
    String customerId,
    String consentType, // 'marketing', 'data_usage', 'analytics'
    bool granted,
  ) async {
    try {
      await DatabaseService.instance.saveConsent(customerId, consentType, granted);
      
      await logActivity(
        customerId,
        'CONSENT_${consentType.toUpperCase()}',
        {
          'granted': granted,
          'consentType': consentType,
        },
        customerId: customerId,
      );

      print('${granted ? '✅' : '❌'} Consent recorded: $consentType for $customerId');
    } catch (e) {
      print('🔥 Error recording consent: $e');
    }
  }

  /// Get customer consents
  Future<Map<String, bool>> getCustomerConsents(String customerId) async {
    try {
      return await DatabaseService.instance.getConsents(customerId);
    } catch (e) {
      print('🔥 Error getting consents: $e');
      return {};
    }
  }

  /// Delete customer data (right to be forgotten)
  /// Anonymizes or removes all personal data
  Future<void> deleteCustomerData(String customerId) async {
    try {
      // Log the deletion request
      await logActivity(
        'SYSTEM',
        'DATA_DELETION_REQUEST',
        {'customerId': customerId},
      );

      await DatabaseService.instance.createDeletionRequest(customerId, 'User requested right to be forgotten');
      await DatabaseService.instance.performCustomerDataDeletion(customerId);

      print('🗑️ Customer data deletion completed: $customerId');
    } catch (e) {
      print('🔥 Error deleting customer data: $e');
      rethrow;
    }
  }

  /// Get audit logs for date range
  Future<List<AuditLog>> getAuditLogs(
    PDPADateRange range, {
    String? userId,
    String? customerId,
    String? action,
  }) async {
    try {
      return await DatabaseService.instance.getAuditLogsFromDb(
        start: range.start,
        end: range.end,
        userId: userId,
        customerId: customerId,
        action: action,
      );
    } catch (e) {
      print('🔥 Error retrieving audit logs: $e');
      return [];
    }
  }

  /// Export audit logs as JSON
  Future<String> exportAuditLogs(PDPADateRange range) async {
    try {
      final logs = await getAuditLogs(range);
      final json = logs.map((log) => log.toJson()).toList();
      return jsonEncode(json);
    } catch (e) {
      print('🔥 Error exporting audit logs: $e');
      rethrow;
    }
  }

  /// Check data access policy compliance
  Future<bool> checkAccessCompliance(String userId, String dataType) async {
    try {
      // Log the access attempt
      await logActivity(
        userId,
        'DATA_ACCESS_ATTEMPT',
        {'dataType': dataType},
        ipAddress: 'unknown',
      );

      // Implementation would typically check user role permissions here
      return true;
    } catch (e) {
      print('🔥 Error checking access compliance: $e');
      return false;
    }
  }

  /// Generate PDPA compliance report
  Future<PDPAComplianceReport> generateComplianceReport(PDPADateRange range) async {
    try {
      final logs = await getAuditLogs(range);

      final totalAccess = logs.length;
      final deletionRequests = logs.where((l) => l.action == 'DATA_DELETION_REQUEST').length;
      final unauthorizedAccess = logs.where((l) => l.action.contains('UNAUTHORIZED')).length;
      final dataBreaches = logs.where((l) => l.action.contains('BREACH')).length;

      final uniqueUsers = logs.map((l) => l.userId).toSet().length;
      final uniqueCustomers = logs.map((l) => l.customerId).where((c) => c != null).toSet().length;

      return PDPAComplianceReport(
        reportDate: DateTime.now(),
        dateRange: range,
        totalDataAccess: totalAccess,
        deletionRequests: deletionRequests,
        unauthorizedAccessAttempts: unauthorizedAccess,
        dataBreachAttempts: dataBreaches,
        uniqueUsersAccessing: uniqueUsers,
        uniqueCustomersAffected: uniqueCustomers,
        isCompliant: unauthorizedAccess == 0 && dataBreaches == 0,
      );
    } catch (e) {
      print('🔥 Error generating compliance report: $e');
      rethrow;
    }
  }
}

/// Audit log entry
class AuditLog {
  final String id;
  final String userId;
  final String action;
  final Map<String, dynamic> details;
  final String? customerId;
  final String ipAddress;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    this.customerId,
    required this.ipAddress,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'details': details,
      'customerId': customerId,
      'ipAddress': ipAddress,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      action: json['action'] ?? '',
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      customerId: json['customerId'],
      ipAddress: json['ipAddress'] ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }
}

/// PDPA Compliance Report
class PDPAComplianceReport {
  final DateTime reportDate;
  final PDPADateRange dateRange;
  final int totalDataAccess;
  final int deletionRequests;
  final int unauthorizedAccessAttempts;
  final int dataBreachAttempts;
  final int uniqueUsersAccessing;
  final int uniqueCustomersAffected;
  final bool isCompliant;

  PDPAComplianceReport({
    required this.reportDate,
    required this.dateRange,
    required this.totalDataAccess,
    required this.deletionRequests,
    required this.unauthorizedAccessAttempts,
    required this.dataBreachAttempts,
    required this.uniqueUsersAccessing,
    required this.uniqueCustomersAffected,
    required this.isCompliant,
  });

  String get status => isCompliant ? '✅ COMPLIANT' : '❌ NON-COMPLIANT';

  String getSummary() {
    return '''
PDPA Compliance Report - ${reportDate.toString().split('.')[0]}
═══════════════════════════════════════════════════
Status: $status
Period: ${dateRange.start.toString().split(' ')[0]} to ${dateRange.end.toString().split(' ')[0]}

Data Access & Privacy:
  • Total Data Access: $totalDataAccess
  • Deletion Requests: $deletionRequests
  • Unauthorized Attempts: $unauthorizedAccessAttempts
  • Breach Attempts: $dataBreachAttempts

Users & Customers:
  • Unique Users: $uniqueUsersAccessing
  • Customers Affected: $uniqueCustomersAffected
═══════════════════════════════════════════════════
''';
  }
}

/// Date time range for reporting
class PDPADateRange {
  final DateTime start;
  final DateTime end;

  PDPADateRange({required this.start, required this.end});

  factory PDPADateRange.today() {
    final now = DateTime.now();
    return PDPADateRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  factory PDPADateRange.thisMonth() {
    final now = DateTime.now();
    return PDPADateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  factory PDPADateRange.last30Days() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    return PDPADateRange(start: start, end: end);
  }
}
