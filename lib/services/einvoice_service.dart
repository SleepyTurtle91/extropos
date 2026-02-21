import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// MyInvois e-Invoice Service for Malaysian Tax Payers
/// Implements OAuth 2.0 authentication and document submission
class EInvoiceService {
  static final EInvoiceService instance = EInvoiceService._internal();
  EInvoiceService._internal();

  EInvoiceConfig? _config;
  String? _accessToken;
  DateTime? _tokenExpiry;
  SharedPreferences? _prefs;

  bool get _isProduction => !BusinessInfo.instance.useMyInvoisSandbox;

  static const String _keyConfig = 'einvoice_config';
  static const String _keyToken = 'einvoice_token';
  static const String _keyTokenExpiry = 'einvoice_token_expiry';

  /// Initialize service and load configuration
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConfig();
    await _loadToken();
  }

  /// Load configuration from SharedPreferences
  Future<void> _loadConfig() async {
    final configJson = _prefs?.getString(_keyConfig);
    if (configJson != null) {
      try {
        _config = EInvoiceConfig.fromJson(jsonDecode(configJson));
      } catch (e) {
        log('Error loading e-Invoice config: $e');
      }
    }
  }

  /// Load saved access token
  Future<void> _loadToken() async {
    _accessToken = _prefs?.getString(_keyToken);
    final expiryString = _prefs?.getString(_keyTokenExpiry);
    if (expiryString != null) {
      try {
        _tokenExpiry = DateTime.parse(expiryString);
        // Clear expired token
        if (_tokenExpiry!.isBefore(DateTime.now())) {
          _accessToken = null;
          _tokenExpiry = null;
        }
      } catch (e) {
        log('Error parsing token expiry: $e');
      }
    }
  }

  /// Save configuration
  Future<void> saveConfig(EInvoiceConfig config) async {
    _config = config;
    await _prefs?.setString(_keyConfig, jsonEncode(config.toJson()));
  }

  /// Get current configuration
  EInvoiceConfig? get config => _config;

  /// Check if service is configured and enabled
  bool get isEnabled => _config?.isEnabled ?? false;

  bool get isConfigured => _config?.isConfigured ?? false;

  /// Authenticate with MyInvois using OAuth 2.0 Client Credentials flow
  /// Returns access token valid for 1 hour
  Future<String> authenticate({bool forceRefresh = false}) async {
    if (_config == null || !_config!.isConfigured) {
      throw Exception(
        'e-Invoice not configured. Please configure in Settings.',
      );
    }

    // Return cached token if still valid (with 5 minute buffer)
    if (!forceRefresh &&
        _accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return _accessToken!;
    }

    try {
      final url = Uri.parse('${_config!.identityServiceUrl}/connect/token');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'X-Environment': _isProduction ? 'production' : 'sandbox',
            },
            body: {
              'client_id': _config!.clientId,
              'client_secret': _config!.clientSecret,
              'grant_type': 'client_credentials',
              'scope': 'InvoicingAPI',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Authentication timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] ?? 3600; // Default 1 hour

        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        // Save token
        await _prefs?.setString(_keyToken, _accessToken!);
        await _prefs?.setString(
          _keyTokenExpiry,
          _tokenExpiry!.toIso8601String(),
        );

        log(
          'MyInvois authentication successful [${_isProduction ? 'production' : 'sandbox'}]. Token expires at: $_tokenExpiry',
        );
        return _accessToken!;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Authentication failed: ${errorData['error_description'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      log('Authentication error: $e');
      rethrow;
    }
  }

  /// Validate Tax Identification Number (TIN)
  Future<Map<String, dynamic>> validateTin(String tin) async {
    final token = await authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/taxpayer/validate/$tin',
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
        throw Exception('TIN not found');
      } else {
        throw Exception('Validation failed: ${response.statusCode}');
      }
    } catch (e) {
      log('TIN validation error: $e');
      rethrow;
    }
  }

  /// Submit e-Invoice document(s) to MyInvois
  /// Returns submission result with assigned UUIDs
  Future<Map<String, dynamic>> submitDocuments(
    List<EInvoiceDocument> documents,
  ) async {
    if (documents.isEmpty) {
      throw Exception('No documents to submit');
    }

    final token = await authenticate();

    try {
      // Prepare submission payload
      final submission = {
        'environment': _isProduction ? 'production' : 'sandbox',
        'documents': documents.map((doc) {
          final documentBase64 = doc.toBase64();
          final documentHash = _calculateSHA256(documentBase64);

          return {
            'format': 'JSON',
            'document': documentBase64,
            'documentHash': documentHash,
            'codeNumber': doc.invoiceCodeNumber,
          };
        }).toList(),
      };

      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documentsubmissions/',
      );

      log('Submitting ${documents.length} document(s) to MyInvois...');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(submission),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 202) {
        // Accepted - documents submitted successfully
        final result = jsonDecode(response.body);
        log('Submission successful: ${result['submissionUID']}');
        return result;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Invalid submission: ${error['error']}');
      } else if (response.statusCode == 422) {
        throw Exception(
          'Duplicate submission detected. Please wait before retrying.',
        );
      } else {
        throw Exception('Submission failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Document submission error: $e');
      rethrow;
    }
  }

  /// Get document details by UUID
  Future<Map<String, dynamic>> getDocument(String uuid) async {
    final token = await authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/$uuid/raw',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'X-Environment': _isProduction ? 'production' : 'sandbox',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Document not found');
      } else {
        throw Exception('Failed to retrieve document: ${response.statusCode}');
      }
    } catch (e) {
      log('Get document error: $e');
      rethrow;
    }
  }

  /// Get submission details by submission UID
  Future<Map<String, dynamic>> getSubmission(String submissionUid) async {
    final token = await authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documentsubmissions/$submissionUid',
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
        throw Exception('Submission not found');
      } else {
        throw Exception(
          'Failed to retrieve submission: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Get submission error: $e');
      rethrow;
    }
  }

  /// Cancel a document
  Future<Map<String, dynamic>> cancelDocument(
    String uuid,
    String reason,
  ) async {
    final token = await authenticate();

    try {
      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/state/$uuid/state',
      );

      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'status': 'cancelled', 'reason': reason}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to cancel document: ${response.statusCode}');
      }
    } catch (e) {
      log('Cancel document error: $e');
      rethrow;
    }
  }

  /// Search recent documents (last 31 days)
  Future<List<Map<String, dynamic>>> getRecentDocuments({
    int pageSize = 100,
    int pageNo = 1,
    String? submissionDateFrom,
    String? submissionDateTo,
  }) async {
    final token = await authenticate();

    try {
      final queryParams = {
        'pageSize': pageSize.toString(),
        'pageNo': pageNo.toString(),
        if (submissionDateFrom != null)
          'submissionDateFrom': submissionDateFrom,
        if (submissionDateTo != null) 'submissionDateTo': submissionDateTo,
      };

      final url = Uri.parse(
        '${_config!.apiServiceUrl}/api/v1.0/documents/recent',
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
        throw Exception('Failed to get documents: ${response.statusCode}');
      }
    } catch (e) {
      log('Get recent documents error: $e');
      rethrow;
    }
  }

  /// Calculate SHA256 hash for document
  String _calculateSHA256(String input) {
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Clear authentication token (logout)
  Future<void> clearToken() async {
    _accessToken = null;
    _tokenExpiry = null;
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyTokenExpiry);
  }

  /// Test connection to MyInvois
  Future<bool> testConnection() async {
    try {
      await authenticate(forceRefresh: true);
      return true;
    } catch (e) {
      log('Connection test failed: $e');
      return false;
    }
  }
}
