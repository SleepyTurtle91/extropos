import 'dart:convert';

import 'package:extropos/models/business_info_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// MyInvois service for government e-invoice integration
/// Handles submission, tracking, and QR code generation
class MyInvoiceService {
  static const String _sandbox = 'https://sandbox.myinvois.gov.my/api/v1';
  static const String _production = 'https://api.myinvois.gov.my/api/v1';

  /// Defaults to BusinessInfo.instance unless overridden.
  MyInvoiceService({bool? useSandboxOverride})
      : useSandbox = useSandboxOverride ?? BusinessInfo.instance.useMyInvoisSandbox;

  bool useSandbox; // Toggle for testing
  String? _apiToken;
  DateTime? _tokenExpiry;

  /// Get API base URL
  String get _apiUrl => useSandbox ? _sandbox : _production;

  /// Validate SST registration with MyInvois
  /// Returns true if registration is valid
  Future<bool> validateSSTRegistration(String registrationNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/taxpayers/$registrationNumber'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final success = response.statusCode == 200;
      print('${success ? '✅' : '❌'} SST validation: $registrationNumber');
      return success;
    } catch (e) {
      print('🔥 SST validation error: $e');
      return false;
    }
  }

  /// Submit transaction as invoice to MyInvois
  /// Returns document UUID if successful
  Future<String?> submitInvoice(Map<String, dynamic> transactionData) async {
    try {
      // Generate invoice number: INV-YYYYMMDD-XXXX
      final invoiceNumber = await _generateInvoiceNumber();

      // Format transaction for MyInvois API
      final invoiceData = _formatInvoiceData(transactionData, invoiceNumber);

      print('📤 Submitting invoice to MyInvois: $invoiceNumber');

      final response = await http.post(
        Uri.parse('$_apiUrl/documents'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(invoiceData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('MyInvois submission failed: ${response.body}');
      }

      final result = jsonDecode(response.body);
      final documentUUID = result['uuid'] as String? ?? result['id'] as String?;

      if (documentUUID == null) {
        throw Exception('No document UUID in response');
      }

      print('✅ Invoice submitted: $invoiceNumber (UUID: $documentUUID)');
      return documentUUID;
    } catch (e) {
      print('🔥 Error submitting invoice: $e');
      // Queue for manual submission
      await _queueForManualSubmission(transactionData);
      return null;
    }
  }

  /// Get invoice status from MyInvois
  Future<InvoiceStatus?> getInvoiceStatus(String documentUUID) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/documents/$documentUUID'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to get invoice status');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return InvoiceStatus.fromJson(data);
    } catch (e) {
      print('❌ Error getting invoice status: $e');
      return null;
    }
  }

  /// Resubmit rejected invoice with corrections
  Future<bool> resubmitRejectedInvoice(
    String documentUUID,
    Map<String, dynamic> correctedData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/documents/$documentUUID'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(correctedData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Invoice resubmitted: $documentUUID');
        return true;
      }
      return false;
    } catch (e) {
      print('🔥 Error resubmitting invoice: $e');
      return false;
    }
  }

  /// Generate unique invoice number: INV-YYYYMMDD-XXXX
  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

    // Get sequence number from preferences or database
    final sequence = await _getNextSequenceNumber(dateStr);

    return 'INV-$dateStr-${sequence.toString().padLeft(4, '0')}';
  }

  /// Get next sequence number for the day
  Future<int> _getNextSequenceNumber(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'myinvois_seq_$dateKey';
    final currentSeq = prefs.getInt(key) ?? 0;
    final nextSeq = currentSeq + 1;
    await prefs.setInt(key, nextSeq);
    return nextSeq;
  }

  /// Format transaction data for MyInvois API
  Map<String, dynamic> _formatInvoiceData(
    Map<String, dynamic> transactionData,
    String invoiceNumber,
  ) {
    final info = BusinessInfo.instance;

    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': DateTime.now().toIso8601String(),
      'environment': useSandbox ? 'sandbox' : 'production',
      'seller': {
        'name': info.businessName,
        'taxId': info.sstRegistrationNumber ?? '',
        'address': info.address,
        'email': info.email,
        'phone': info.phone,
      },
      'buyer': {
        'name': 'Walk-in Customer',
        'taxId': '',
      },
      'items': transactionData['items'] ?? [],
      'subtotal': (transactionData['subtotal'] ?? 0.0).toString(),
      'tax': {
        'amount': (transactionData['taxAmount'] ?? 0.0).toString(),
        'rate': info.isTaxEnabled ? '${(info.taxRate * 100).toStringAsFixed(0)}%' : '0%',
      },
      'serviceCharge': {
        'amount': (transactionData['serviceChargeAmount'] ?? 0.0).toString(),
        'rate': info.isServiceChargeEnabled
            ? '${(info.serviceChargeRate * 100).toStringAsFixed(0)}%'
            : '0%',
      },
      'total': (transactionData['totalAmount'] ?? 0.0).toString(),
      'paymentMethod': transactionData['paymentMethod'] ?? 'CASH',
      'currency': info.currencySymbol,
    };
  }

  /// Map internal payment method to MyInvois format
  // ignore: unused_element
  String _mapPaymentMethod(String method) {
    const mapping = {
      'cash': 'CASH',
      'card': 'CARD',
      'cheque': 'CHEQUE',
      'touchngo': 'EWALLET',
      'grabpay': 'EWALLET',
      'boost': 'EWALLET',
      'bank_transfer': 'BANK_TRANSFER',
    };
    return mapping[method.toLowerCase()] ?? 'CASH';
  }

  /// Get authentication token (implement with OAuth/API key)
  Future<String> _getToken() async {
    // Check if cached token is still valid
    if (_apiToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _apiToken!;
    }

    try {
      // TODO: Implement actual token retrieval (OAuth 2.0 or API key)
      // This is a placeholder - implement based on MyInvois requirements
      _apiToken = 'placeholder_token';
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      return _apiToken!;
    } catch (e) {
      print('🔥 Error getting API token: $e');
      throw Exception('Failed to authenticate with MyInvois');
    }
  }

  /// Queue transaction for manual submission if auto-submit fails
  Future<void> _queueForManualSubmission(Map<String, dynamic> transactionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'myinvois_queue';
      final existingQueue = prefs.getStringList(queueKey) ?? [];
      
      // Add transaction with timestamp
      final queuedItem = jsonEncode({
        'transactionData': transactionData,
        'queuedAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      });
      
      existingQueue.add(queuedItem);
      await prefs.setStringList(queueKey, existingQueue);
      
      print('⚠️ Transaction queued for manual MyInvois submission (${existingQueue.length} in queue)');
    } catch (e) {
      print('❌ Failed to queue transaction: $e');
    }
  }
  
  /// Get queued transactions for manual submission
  Future<List<Map<String, dynamic>>> getQueuedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'myinvois_queue';
      final existingQueue = prefs.getStringList(queueKey) ?? [];
      
      return existingQueue.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return decoded;
      }).toList();
    } catch (e) {
      print('❌ Failed to get queued transactions: $e');
      return [];
    }
  }
  
  /// Retry queued submissions
  Future<int> retryQueuedSubmissions() async {
    try {
      final queued = await getQueuedTransactions();
      int successCount = 0;
      final List<String> remainingQueue = [];
      
      for (final item in queued) {
        final transactionData = item['transactionData'] as Map<String, dynamic>;
        final retryCount = (item['retryCount'] as int?) ?? 0;
        
        // Skip if too many retries
        if (retryCount >= 3) {
          remainingQueue.add(jsonEncode(item));
          continue;
        }
        
        try {
          final result = await submitInvoice(transactionData);
          if (result != null) {
            successCount++;
            print('✅ Queued transaction submitted successfully');
          } else {
            // Re-queue with incremented retry count
            item['retryCount'] = retryCount + 1;
            remainingQueue.add(jsonEncode(item));
          }
        } catch (e) {
          // Re-queue with incremented retry count
          item['retryCount'] = retryCount + 1;
          remainingQueue.add(jsonEncode(item));
        }
      }
      
      // Save remaining queue
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('myinvois_queue', remainingQueue);
      
      print('🔄 Retry complete: $successCount successful, ${remainingQueue.length} remaining');
      return successCount;
    } catch (e) {
      print('❌ Failed to retry queued submissions: $e');
      return 0;
    }
  }
  
  /// Clear all queued transactions
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('myinvois_queue');
    print('🗑️ MyInvois queue cleared');
  }
}

/// Represents MyInvois invoice status
class InvoiceStatus {
  final String uuid;
  final String status; // submitted, accepted, rejected, pending
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? acceptedAt;

  InvoiceStatus({
    required this.uuid,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.acceptedAt,
  });

  factory InvoiceStatus.fromJson(Map<String, dynamic> json) {
    return InvoiceStatus(
      uuid: json['uuid'] ?? json['id'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
    );
  }

  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'submitted';
}
