import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:extropos/exceptions/myinvois_exception.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/einvoice/einvoice_config.dart';
import 'package:extropos/models/einvoice/einvoice_document.dart';
import 'package:extropos/services/rate_limiter.dart';
import 'package:extropos/services/retry_helper.dart';
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
  final RateLimiter _submitRateLimiter = RateLimiter.forSubmitEndpoint();
  final RateLimiter _queryRateLimiter = RateLimiter.forQueryEndpoint();
  static const RetryHelper _retryHelper = RetryHelper();

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
    await _enforceRateLimit(
      limiter: _queryRateLimiter,
      endpointName: 'TIN validation',
    );

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

      _queryRateLimiter.recordRequest();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw MyInvoisException.fromHttpResponse(
          response,
          defaultMessage: 'TIN validation failed',
        );
      }
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('TIN validation error: $e');
      throw MyInvoisException(
        code: 'ValidateTinError',
        message: 'Unexpected TIN validation error',
        detail: e.toString(),
      );
    }
  }

  /// Submit e-Invoice document(s) to MyInvois
  /// Returns submission result with assigned UUIDs
  Future<Map<String, dynamic>> submitDocuments(
    List<EInvoiceDocument> documents,
  ) async {
    if (documents.isEmpty) {
      throw const MyInvoisException(
        code: 'EmptySubmission',
        message: 'No documents to submit',
      );
    }

    await _enforceRateLimit(
      limiter: _submitRateLimiter,
      endpointName: 'document submission',
    );

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

      final response = await _retryHelper.execute<http.Response>(
        () async {
          final result = await http
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

          _submitRateLimiter.recordRequest();

          if (result.statusCode == 202) {
            return result;
          }

          throw MyInvoisException.fromHttpResponse(
            result,
            defaultMessage: 'Document submission failed',
          );
        },
        operationName: 'MyInvois submitDocuments',
      );

      final result = jsonDecode(response.body);
      log('Submission successful: ${result['submissionUID']}');
      return result;
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('Document submission error: $e');
      throw MyInvoisException(
        code: 'SubmissionError',
        message: 'Unexpected submission error',
        detail: e.toString(),
      );
    }
  }

  /// Get document details by UUID
  Future<Map<String, dynamic>> getDocument(String uuid) async {
    await _enforceRateLimit(
      limiter: _queryRateLimiter,
      endpointName: 'document retrieval',
    );

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

      _queryRateLimiter.recordRequest();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw MyInvoisException.fromHttpResponse(
          response,
          defaultMessage: 'Failed to retrieve document',
        );
      }
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('Get document error: $e');
      throw MyInvoisException(
        code: 'GetDocumentError',
        message: 'Unexpected error retrieving document',
        detail: e.toString(),
      );
    }
  }

  /// Get submission details by submission UID
  Future<Map<String, dynamic>> getSubmission(String submissionUid) async {
    await _enforceRateLimit(
      limiter: _queryRateLimiter,
      endpointName: 'submission retrieval',
    );

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

      _queryRateLimiter.recordRequest();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw MyInvoisException.fromHttpResponse(
          response,
          defaultMessage: 'Failed to retrieve submission',
        );
      }
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('Get submission error: $e');
      throw MyInvoisException(
        code: 'GetSubmissionError',
        message: 'Unexpected error retrieving submission',
        detail: e.toString(),
      );
    }
  }

  /// Cancel a document
  Future<Map<String, dynamic>> cancelDocument(
    String uuid,
    String reason,
  ) async {
    await _enforceRateLimit(
      limiter: _submitRateLimiter,
      endpointName: 'document cancellation',
    );

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

      _submitRateLimiter.recordRequest();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw MyInvoisException.fromHttpResponse(
          response,
          defaultMessage: 'Failed to cancel document',
        );
      }
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('Cancel document error: $e');
      throw MyInvoisException(
        code: 'CancelDocumentError',
        message: 'Unexpected document cancellation error',
        detail: e.toString(),
      );
    }
  }

  /// Search recent documents (last 31 days)
  Future<List<Map<String, dynamic>>> getRecentDocuments({
    int pageSize = 100,
    int pageNo = 1,
    String? submissionDateFrom,
    String? submissionDateTo,
  }) async {
    await _enforceRateLimit(
      limiter: _queryRateLimiter,
      endpointName: 'recent document search',
    );

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

      _queryRateLimiter.recordRequest();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      } else {
        throw MyInvoisException.fromHttpResponse(
          response,
          defaultMessage: 'Failed to get recent documents',
        );
      }
    } on MyInvoisException {
      rethrow;
    } catch (e) {
      log('Get recent documents error: $e');
      throw MyInvoisException(
        code: 'GetRecentDocumentsError',
        message: 'Unexpected error getting recent documents',
        detail: e.toString(),
      );
    }
  }

  Future<void> _enforceRateLimit({
    required RateLimiter limiter,
    required String endpointName,
  }) async {
    if (limiter.canRequest()) {
      return;
    }

    final wait = limiter.waitDuration();
    throw MyInvoisException(
      code: 'RateLimitExceeded',
      message: 'Local rate limit reached for $endpointName',
      detail: 'Please retry after ${wait.inSeconds} second(s)',
      statusCode: 429,
      retryAfterSeconds: wait.inSeconds,
    );
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
