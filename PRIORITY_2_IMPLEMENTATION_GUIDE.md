# Priority 2 Implementation Guide - Error Handling & Rate Limiting

**Status**: Ready for implementation after Priority 1 sandbox testing  
**Estimated Effort**: 4-6 hours  
**Complexity**: Medium

---

## Overview

Priority 2 focuses on production-hardening by implementing:
1. **Specific MyInvois API error handling**
2. **Rate limiting & request throttling**
3. **Retry logic with exponential backoff**
4. **Comprehensive error reporting**

---

## 1. Custom Exception Class

**File to create**: `lib/exceptions/myinvois_exception.dart`

```dart
/// Custom exception for MyInvois API errors
/// Maps official API error codes to user-friendly messages
class MyInvoisException implements Exception {
  /// Official MyInvois error code (BadStructure, MaximumSizeExceeded, etc.)
  final String code;
  
  /// User-friendly error message
  final String message;
  
  /// Additional technical details
  final String? detail;
  
  /// HTTP status code if applicable
  final int? statusCode;
  
  /// Original response body for debugging
  final dynamic originalResponse;
  
  /// Retry-After header value (in seconds) from API
  final int? retryAfterSeconds;

  MyInvoisException({
    required this.code,
    required this.message,
    this.detail,
    this.statusCode,
    this.originalResponse,
    this.retryAfterSeconds,
  });

  @override
  String toString() => 'MyInvoisException($code): $message${detail != null ? '\n$detail' : ''}';
  
  /// Check if error is retryable
  bool get isRetryable => 
    code == 'DuplicateSubmission' || 
    code == 'TemporarilyUnavailable' ||
    statusCode == 429; // Too Many Requests
  
  /// Get recommended retry delay in seconds
  int get retryDelaySeconds => retryAfterSeconds ?? 
    (code == 'DuplicateSubmission' ? 10 : 5);
}

/// Enum for all official MyInvois error codes
enum MyInvoisErrorCode {
  badStructure,           // 400
  maximumSizeExceeded,    // 400
  incorrectSubmitter,     // 403
  duplicateSubmission,    // 422
  rateLimitExceeded,      // 429
  internalServerError,    // 500
  serviceUnavailable,     // 503
  unknown,
}
```

---

## 2. Error Handler Enhancement

**File to update**: `lib/services/einvoice_service.dart`

**Add these methods:**

```dart
/// Enhanced error handling for submit documents
Future<Map<String, dynamic>> submitDocuments(
  List<EInvoiceDocument> documents,
) async {
  if (documents.isEmpty) {
    throw MyInvoisException(
      code: 'EmptySubmission',
      message: 'No documents to submit',
    );
  }

  final token = await authenticate();

  try {
    final submission = _prepareSubmission(documents);
    
    final url = Uri.parse('${_config!.apiServiceUrl}/api/v1.0/documentsubmissions/');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(submission),
    ).timeout(const Duration(seconds: 60));

    // ✅ Handle specific error codes
    return _handleSubmissionResponse(response);
    
  } on MyInvoisException {
    rethrow;
  } catch (e) {
    throw MyInvoisException(
      code: 'UnknownError',
      message: 'Unexpected error during submission',
      detail: e.toString(),
    );
  }
}

/// Handle response from submit documents API
Map<String, dynamic> _handleSubmissionResponse(http.Response response) {
  if (response.statusCode == 202) {
    // Success
    return jsonDecode(response.body);
  }
  
  final errorBody = jsonDecode(response.body);
  final errorInfo = errorBody['error'] as Map?;
  final errorCode = errorInfo?['code'] as String? ?? 'UnknownError';
  final errorMessage = errorInfo?['message'] as String? ?? 'Unknown error';
  
  // ✅ Handle specific error codes
  switch (response.statusCode) {
    case 400:
      if (errorCode == 'BadStructure') {
        throw MyInvoisException(
          code: 'BadStructure',
          message: 'Invalid document structure',
          detail: 'One or more documents do not match UBL 2.1 schema',
          statusCode: 400,
          originalResponse: errorBody,
        );
      } else if (errorCode == 'MaximumSizeExceeded') {
        final maxSize = errorInfo?['maxSize'] ?? '5 MB';
        throw MyInvoisException(
          code: 'MaximumSizeExceeded',
          message: 'Submission exceeds maximum size limit',
          detail: 'Maximum allowed: $maxSize. Please submit in smaller batches.',
          statusCode: 400,
          originalResponse: errorBody,
        );
      }
      break;
      
    case 403:
      if (errorCode == 'IncorrectSubmitter') {
        throw MyInvoisException(
          code: 'IncorrectSubmitter',
          message: 'Not authorized to submit these documents',
          detail: 'Either incorrect TIN or insufficient permissions',
          statusCode: 403,
          originalResponse: errorBody,
        );
      }
      break;
      
    case 422:
      if (errorCode == 'DuplicateSubmission') {
        final retryAfter = response.headers['retry-after'];
        final retrySeconds = retryAfter != null ? int.tryParse(retryAfter) : null;
        
        throw MyInvoisException(
          code: 'DuplicateSubmission',
          message: 'Identical submission detected',
          detail: 'Duplicate submissions are detected within 10 minutes. '
              'Please retry after ${retrySeconds ?? 10} seconds.',
          statusCode: 422,
          originalResponse: errorBody,
          retryAfterSeconds: retrySeconds,
        );
      }
      break;
      
    case 429:
      final retryAfter = response.headers['retry-after'];
      final retrySeconds = retryAfter != null ? int.tryParse(retryAfter) : null;
      
      throw MyInvoisException(
        code: 'RateLimitExceeded',
        message: 'Too many requests',
        detail: 'Rate limit exceeded (100 RPM). Please wait before retrying.',
        statusCode: 429,
        originalResponse: errorBody,
        retryAfterSeconds: retrySeconds ?? 60,
      );
      
    case 500:
      throw MyInvoisException(
        code: 'InternalServerError',
        message: 'MyInvois server error',
        detail: 'The system encountered an internal error. Please try again later.',
        statusCode: 500,
        originalResponse: errorBody,
      );
      
    case 503:
      throw MyInvoisException(
        code: 'ServiceUnavailable',
        message: 'MyInvois service temporarily unavailable',
        detail: 'The service is under maintenance. Please try again shortly.',
        statusCode: 503,
        originalResponse: errorBody,
      );
      
    default:
      throw MyInvoisException(
        code: errorCode,
        message: errorMessage,
        statusCode: response.statusCode,
        originalResponse: errorBody,
      );
  }
  
  throw MyInvoisException(
    code: 'UnhandledError',
    message: errorMessage,
    statusCode: response.statusCode,
    originalResponse: errorBody,
  );
}
```

---

## 3. Retry Logic Implementation

**File to create**: `lib/services/retry_helper.dart`

```dart
import 'package:extropos/exceptions/myinvois_exception.dart';

/// Retry logic with exponential backoff for API calls
class RetryHelper {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  RetryHelper({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 60),
  });

  /// Execute function with retry logic
  Future<T> execute<T>(
    Future<T> Function() fn, {
    String? operationName,
  }) async {
    Duration delay = initialDelay;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } on MyInvoisException catch (e) {
        // Don't retry non-retryable errors
        if (!e.isRetryable) rethrow;
        
        // Don't retry on last attempt
        if (attempt == maxAttempts) rethrow;
        
        // Use Retry-After if provided by API
        if (e.retryAfterSeconds != null) {
          delay = Duration(seconds: e.retryAfterSeconds!);
        }
        
        print('Retrying $operationName (Attempt $attempt/$maxAttempts) '
            'after ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
        
        // Exponential backoff for next attempt
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );
        
        if (delay > maxDelay) delay = maxDelay;
      } catch (e) {
        // Don't retry other exceptions
        rethrow;
      }
    }
    
    throw MyInvoisException(
      code: 'MaxRetriesExceeded',
      message: 'Operation failed after $maxAttempts attempts',
    );
  }
}
```

---

## 4. Rate Limiter Implementation

**File to create**: `lib/services/rate_limiter.dart`

```dart
import 'dart:collection';

/// Rate limiter for MyInvois API calls
/// Enforces limits: 100 RPM for submissions, 12 RPM for searches
class RateLimiter {
  final int maxRequestsPerMinute;
  final Queue<DateTime> requestTimestamps = Queue();
  
  /// Track different endpoints separately
  final Map<String, Queue<DateTime>> endpointTimestamps = {};

  RateLimiter(this.maxRequestsPerMinute);

  factory RateLimiter.forSubmitEndpoint() {
    return RateLimiter(100); // 100 requests per minute
  }

  factory RateLimiter.forSearchEndpoint() {
    return RateLimiter(12); // 12 requests per minute
  }

  /// Check if request can be made
  bool canRequest({String? endpoint}) {
    final now = DateTime.now();
    final queue = endpoint != null 
        ? (endpointTimestamps[endpoint] ??= Queue())
        : requestTimestamps;
    
    // Remove requests older than 1 minute
    while (queue.isNotEmpty && 
           now.difference(queue.first).inSeconds > 60) {
      queue.removeFirst();
    }

    return queue.length < maxRequestsPerMinute;
  }

  /// Record a made request
  void recordRequest({String? endpoint}) {
    final queue = endpoint != null 
        ? (endpointTimestamps[endpoint] ??= Queue())
        : requestTimestamps;
    queue.add(DateTime.now());
  }

  /// Get time to wait before next request is allowed
  Duration getWaitDuration({String? endpoint}) {
    final now = DateTime.now();
    final queue = endpoint != null 
        ? (endpointTimestamps[endpoint] ?? Queue())
        : requestTimestamps;
    
    if (queue.isEmpty || queue.length < maxRequestsPerMinute) {
      return Duration.zero;
    }

    final oldestRequest = queue.first;
    final ageSeconds = now.difference(oldestRequest).inSeconds;
    final waitSeconds = 60 - ageSeconds + 1;
    
    return Duration(seconds: waitSeconds);
  }

  /// Get current request count in this minute
  int getCurrentRequestCount({String? endpoint}) {
    final now = DateTime.now();
    final queue = endpoint != null 
        ? (endpointTimestamps[endpoint] ?? Queue())
        : requestTimestamps;
    
    // Remove requests older than 1 minute
    while (queue.isNotEmpty && 
           now.difference(queue.first).inSeconds > 60) {
      queue.removeFirst();
    }

    return queue.length;
  }
}
```

---

## 5. UI Error Display Integration

**Update ConsolidateScreen**:

```dart
void _handleConsolidate() async {
  setState(() => _isSyncing = true);
  try {
    // Validate batch before submitting
    final validationErrors = 
        EInvoiceBusinessLogicService.validateSubmissionBatch(
          _unconsolidatedReceipts,
        );
    
    if (validationErrors.isNotEmpty) {
      _showValidationErrorDialog(validationErrors);
      return;
    }

    // Attempt submission with retry
    final retryHelper = RetryHelper();
    await retryHelper.execute(
      () => _einvoiceService.submitDocuments([...]),
      operationName: 'Receipt Consolidation',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Receipts submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  } on MyInvoisException catch (e) {
    _showMyInvoisErrorDialog(e);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }
}

void _showMyInvoisErrorDialog(MyInvoisException error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Submission Error'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: ${error.code}'),
          const SizedBox(height: 8),
          Text(error.message, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (error.detail != null) ...[
            const SizedBox(height: 8),
            Text(error.detail!, style: const TextStyle(fontSize: 12)),
          ],
          if (error.isRetryable) ...[
            const SizedBox(height: 12),
            Text(
              'This error is retryable. Try again after '
              '${error.retryDelaySeconds} seconds.',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ],
      ),
      actions: [
        if (error.isRetryable)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleConsolidate(); // Retry
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showValidationErrorDialog(List<String> errors) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Submission Validation Failed'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please fix the following issues:'),
            const SizedBox(height: 12),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(error, style: const TextStyle(fontSize: 12))),
                ],
              ),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 6. Testing Priority 2 Features

**File**: `test/services/error_handling_test.dart`

```dart
void main() {
  group('MyInvoisException', () {
    test('DuplicateSubmission is retryable', () {
      final exception = MyInvoisException(
        code: 'DuplicateSubmission',
        message: 'Duplicate detected',
        statusCode: 422,
      );
      expect(exception.isRetryable, isTrue);
      expect(exception.retryDelaySeconds, equals(10));
    });

    test('IncorrectSubmitter is not retryable', () {
      final exception = MyInvoisException(
        code: 'IncorrectSubmitter',
        message: 'Not authorized',
        statusCode: 403,
      );
      expect(exception.isRetryable, isFalse);
    });
  });

  group('RateLimiter', () {
    test('tracks requests per minute', () {
      final limiter = RateLimiter(10);
      
      // Make 10 requests
      for (int i = 0; i < 10; i++) {
        expect(limiter.canRequest(), isTrue);
        limiter.recordRequest();
      }
      
      // 11th request should fail
      expect(limiter.canRequest(), isFalse);
    });

    test('resets after 1 minute', () async {
      final limiter = RateLimiter(1);
      
      expect(limiter.canRequest(), isTrue);
      limiter.recordRequest();
      expect(limiter.canRequest(), isFalse);
      
      // Simulate time passing (in real app, would wait 60 seconds)
      // This is a limitation of unit tests - integration tests needed
    });
  });

  group('RetryHelper', () {
    test('retries on retriable errors', () async {
      var attempts = 0;
      final helper = RetryHelper(maxAttempts: 3);
      
      Future<String> failingFunction() async {
        attempts++;
        if (attempts < 3) {
          throw MyInvoisException(
            code: 'DuplicateSubmission',
            message: 'Retry me',
          );
        }
        return 'success';
      }
      
      final result = await helper.execute(failingFunction);
      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('does not retry non-retriable errors', () async {
      var attempts = 0;
      final helper = RetryHelper();
      
      Future<String> failingFunction() async {
        attempts++;
        throw MyInvoisException(
          code: 'IncorrectSubmitter',
          message: 'Cannot retry',
        );
      }
      
      expect(
        () => helper.execute(failingFunction),
        throwsA(isA<MyInvoisException>()),
      );
      expect(attempts, equals(1)); // Only one attempt
    });
  });
}
```

---

## Implementation Checklist

- [ ] Create `lib/exceptions/myinvois_exception.dart`
- [ ] Create `lib/services/retry_helper.dart`
- [ ] Create `lib/services/rate_limiter.dart`
- [ ] Update `lib/services/einvoice_service.dart` with error handling
- [ ] Update screen dialogs for error display
- [ ] Add unit tests for error handling
- [ ] Test against MyInvois sandbox with various error scenarios
- [ ] Document error codes and recovery procedures
- [ ] Train support team on error messages

---

## Success Criteria

✅ **After Priority 2 Implementation:**
- Specific MyInvois error codes handled
- Automatic retry on transient failures
- Rate limiting prevents API throttling
- User-friendly error messages displayed
- Clear recovery instructions for each error type
- **Compliance Score Target: 90/100**

---

## Estimated Timeline

- **Planning**: 30 minutes
- **Implementation**: 2-3 hours
- **Testing**: 1-2 hours
- **Documentation**: 30 minutes
- **Total**: 4-6 hours

