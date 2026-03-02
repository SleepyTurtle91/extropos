import 'package:extropos/models/einvoice/lhdn_config.dart';
import 'package:extropos/models/einvoice/submission.dart';
import 'package:extropos/models/einvoice/unconsolidated_receipt.dart';

/// E-Invoice Business Logic Service (Layer A)
/// Pure Dart service handling all e-invoice calculations and data operations
/// No Flutter dependencies - fully unit testable
class EInvoiceBusinessLogicService {
  static final EInvoiceBusinessLogicService _instance =
      EInvoiceBusinessLogicService._internal();

  factory EInvoiceBusinessLogicService() {
    return _instance;
  }

  EInvoiceBusinessLogicService._internal();

  /// Filter submissions by search query
  static List<Submission> filterSubmissions(
    List<Submission> submissions,
    String query,
  ) {
    if (query.isEmpty) return submissions;

    final lowerQuery = query.toLowerCase();
    return submissions
        .where((submission) =>
            submission.uin.toLowerCase().contains(lowerQuery) ||
            submission.buyer.toLowerCase().contains(lowerQuery) ||
            submission.id.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Calculate total amount from unconsolidated receipts
  static double calculateTotalAmount(
    List<UnconsolidatedReceipt> receipts,
  ) {
    return receipts.fold(0.0, (sum, receipt) => sum + receipt.total);
  }

  /// Calculate tax amount (6% for Malaysia)
  /// Returns tax amount from the total (tax-inclusive)
  static double calculateTaxAmount(double totalAmount) {
    // If totalAmount is 106 (100 + 6% tax), tax is 6
    return totalAmount * 0.06 / 1.06;
  }

  /// Calculate subtotal amount (excluding tax)
  static double calculateSubtotalAmount(double totalAmount) {
    return totalAmount - calculateTaxAmount(totalAmount);
  }

  /// Get submission status color (for UI display)
  static String getStatusColor(String status) {
    switch (status) {
      case 'Validated':
        return 'green';
      case 'Rejected':
      case 'Failed':
        return 'red';
      case 'Pending':
      case 'Processing':
        return 'yellow';
      default:
        return 'gray';
    }
  }

  /// Get submission status icon name (for UI display)
  static String getStatusIcon(String status) {
    switch (status) {
      case 'Validated':
        return 'check_circle';
      case 'Rejected':
      case 'Failed':
        return 'error';
      case 'Pending':
      case 'Processing':
        return 'schedule';
      default:
        return 'help';
    }
  }

  /// Validate LHDN configuration completeness
  static bool isConfigValid(LhdnConfig config) {
    return config.businessName.isNotEmpty &&
        config.tin.isNotEmpty &&
        config.regNo.isNotEmpty &&
        config.clientId.isNotEmpty &&
        config.clientSecret.isNotEmpty;
  }

  /// Validate TIN format (C + 10 digits for Malaysia)
  static bool isValidTin(String tin) {
    return RegExp(r'^C\d{10}$').hasMatch(tin);
  }

  /// Validate Business Registration Number format (Malaysian BRN)
  static bool isValidBrn(String brn) {
    return RegExp(r'^\d{12}$').hasMatch(brn);
  }

  /// Format currency value for display
  static String formatCurrency(double amount, {String currency = 'RM'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Sort submissions by date (newest first)
  static List<Submission> sortSubmissionsByDate(
    List<Submission> submissions,
  ) {
    final sorted = [...submissions];
    sorted.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        return 0;
      }
    });
    return sorted;
  }

  /// Get submission summary statistics
  static Map<String, dynamic> getSubmissionsSummary(
    List<Submission> submissions,
  ) {
    final total = submissions.length;
    final validated = submissions
        .where((s) => s.status == 'Validated')
        .length;
    final rejected = submissions
        .where((s) => s.status == 'Rejected')
        .length;
    final pending = submissions
        .where((s) => s.status == 'Pending')
        .length;

    final totalAmount = submissions.fold<double>(
      0.0,
      (sum, s) => sum + s.total,
    );

    return {
      'totalCount': total,
      'validatedCount': validated,
      'rejectedCount': rejected,
      'pendingCount': pending,
      'totalAmount': totalAmount,
      'successRate': total > 0 ? (validated / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  /// Get receipts summary statistics
  static Map<String, dynamic> getReceiptsSummary(
    List<UnconsolidatedReceipt> receipts,
  ) {
    final totalAmount = calculateTotalAmount(receipts);
    final taxAmount = calculateTaxAmount(totalAmount);
    final subtotalAmount = calculateSubtotalAmount(totalAmount);

    return {
      'count': receipts.length,
      'totalAmount': totalAmount,
      'subtotalAmount': subtotalAmount,
      'taxAmount': taxAmount,
      'totalItemsCount': receipts.fold<int>(0, (sum, r) => sum + r.itemsCount),
    };
  }
}
    /// Validate submission batch against MyInvois API limits
    /// Returns empty list if valid, or list of validation error messages
    ///
    /// MyInvois Limits:
    /// - Maximum 100 documents per submission
    /// - Maximum 5 MB total submission size
    /// - Maximum 300 KB per individual document
    List<String> validateSubmissionBatch(
      List<UnconsolidatedReceipt> receipts,
    ) {
      final errors = <String>[];

      // Check document count
      if (receipts.isEmpty) {
        errors.add('No documents selected for submission');
      } else if (receipts.length > 100) {
        errors.add(
          'Maximum 100 documents per submission. '
          'You have ${receipts.length} documents. '
          'Please split into multiple submissions.',
        );
      }

      // Estimate total submission size
      double totalSize = 0;
      for (var receipt in receipts) {
        final docSize = _estimateDocumentSize(receipt);
      
        // Check individual document size (300 KB)
        if (docSize > 300 * 1024) {
          errors.add(
            'Document ${receipt.invoiceCodeNumber ?? receipt.id} '
            'exceeds 300 KB limit (${(docSize / 1024).toStringAsFixed(1)} KB)',
          );
        }
        totalSize += docSize;
      }

      // Check total submission size (5 MB)
      if (totalSize > 5 * 1024 * 1024) {
        errors.add(
          'Total submission size (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB) '
          'exceeds 5 MB limit. Split into smaller batches.',
        );
      }

      return errors;
    }

    /// Estimate document size in bytes based on JSON structure
    /// This is a rough estimation as actual size depends on serialization
    double _estimateDocumentSize(UnconsolidatedReceipt receipt) {
      // Conservative estimate: JSON fields roughly 1.5x the data size
      final dataSize = (receipt.invoiceCodeNumber?.length ?? 0) +
          (receipt.buyerName?.length ?? 0) +
          (receipt.buyerTin?.length ?? 0) +
          (receipt.date.length) +
          receipt.itemsCount * 100 + // Rough estimate for line items
          100; // Overhead
      return dataSize * 1.5;
    }

    /// Check if submission would trigger rate limiting warnings
    bool shouldWarnAboutRateLimit(int documentCount) {
      // Warn if submitting > 50 documents (conservative threshold for 100 RPM limit)
      return documentCount > 50;
    }
