import 'dart:developer' as developer;
import 'package:flutter/material.dart';

/// Error severity levels
enum ErrorSeverity {
  low,      // Minor issues, user can continue
  medium,   // Significant issues, may need user action
  high,     // Critical issues, may prevent operation
  critical  // System-breaking issues
}

/// Error categories for better organization
enum ErrorCategory {
  database,
  network,
  hardware,
  validation,
  businessLogic,
  ui,
  unknown
}

/// Comprehensive error handling service for FlutterPOS
class ErrorHandler {
  static final List<ErrorRecord> _errorHistory = [];
  static const int _maxHistorySize = 100;

  /// Handle and display errors to users
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? userMessage,
    VoidCallback? retryAction,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.unknown,
    bool showToUser = true,
  }) {
    // Log the error
    _logError(error, severity, category, userMessage);

    // Store in history
    _addToHistory(error, severity, category, userMessage);

    if (!showToUser) return;

    // Show user-friendly message
    final message = userMessage ?? _getDefaultMessage(error, category);

    switch (severity) {
      case ErrorSeverity.low:
        _showSnackBar(context, message, retryAction: retryAction);
        break;
      case ErrorSeverity.medium:
        _showSnackBar(context, message, retryAction: retryAction, duration: 5000);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        _showErrorDialog(context, message, retryAction: retryAction);
        break;
    }
  }

  /// Handle async operations with error recovery
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? userMessage,
    VoidCallback? retryAction,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.unknown,
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        final isLastAttempt = attempt == maxRetries;

        if (isLastAttempt) {
          handleError(
            context,
            error,
            userMessage: userMessage,
            retryAction: retryAction,
            severity: severity,
            category: category,
          );
          return null;
        }

        // Wait before retry
        await Future.delayed(retryDelay * (attempt + 1));
      }
    }
    return null;
  }

  /// Show loading dialog with error handling
  static Future<T?> showLoadingDialog<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String loadingMessage = 'Loading...',
    String? errorMessage,
    VoidCallback? retryAction,
    ErrorCategory category = ErrorCategory.unknown,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(loadingMessage),
          ],
        ),
      ),
    );

    try {
      final result = await operation();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      return result;
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        handleError(
          context,
          error,
          userMessage: errorMessage,
          retryAction: retryAction,
          category: category,
        );
      }
      return null;
    }
  }

  /// Get error history for debugging
  static List<ErrorRecord> getErrorHistory() => List.unmodifiable(_errorHistory);

  /// Clear error history
  static void clearErrorHistory() => _errorHistory.clear();

  /// Get recent errors by category
  static List<ErrorRecord> getErrorsByCategory(ErrorCategory category) {
    return _errorHistory.where((error) => error.category == category).toList();
  }

  /// Get error statistics
  static Map<String, int> getErrorStats() {
    final stats = <String, int>{};
    for (final error in _errorHistory) {
      final key = error.category.toString();
      stats[key] = (stats[key] ?? 0) + 1;
    }
    return stats;
  }

  /// Log error without showing to user (for background operations)
  static void logError(
    dynamic error, {
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.unknown,
    String? message,
  }) {
    _logError(error, severity, category, message);
    _addToHistory(error, severity, category, message);
  }

  static void _logError(
    dynamic error,
    ErrorSeverity severity,
    ErrorCategory category,
    String? userMessage,
  ) {
    final logMessage = '''
ErrorHandler: [$severity] [$category]
User Message: ${userMessage ?? 'None'}
Error: $error
Stack Trace: ${StackTrace.current}
''';

    switch (severity) {
      case ErrorSeverity.low:
        developer.log(logMessage, name: 'error_handler');
        break;
      case ErrorSeverity.medium:
        developer.log(logMessage, name: 'error_handler', level: 900);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        developer.log(logMessage, name: 'error_handler', level: 1000, error: error);
        break;
    }
  }

  static void _addToHistory(
    dynamic error,
    ErrorSeverity severity,
    ErrorCategory category,
    String? userMessage,
  ) {
    final record = ErrorRecord(
      error: error,
      severity: severity,
      category: category,
      userMessage: userMessage,
      timestamp: DateTime.now(),
      stackTrace: StackTrace.current,
    );

    _errorHistory.add(record);

    // Keep history size manageable
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  static String _getDefaultMessage(dynamic error, ErrorCategory category) {
    switch (category) {
      case ErrorCategory.database:
        return 'Database error occurred. Please try again.';
      case ErrorCategory.network:
        return 'Network connection issue. Please check your internet.';
      case ErrorCategory.hardware:
        return 'Hardware device error. Please check connections.';
      case ErrorCategory.validation:
        return 'Invalid input. Please check your data.';
      case ErrorCategory.businessLogic:
        return 'Operation failed. Please try again.';
      case ErrorCategory.ui:
        return 'Display error occurred. Please restart the app.';
      case ErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? retryAction,
    int duration = 3000,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: duration),
        action: retryAction != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: retryAction,
              )
            : null,
      ),
    );
  }

  static void _showErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? retryAction,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (retryAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                retryAction();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Error record for history tracking
class ErrorRecord {
  final dynamic error;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final String? userMessage;
  final DateTime timestamp;
  final StackTrace stackTrace;

  const ErrorRecord({
    required this.error,
    required this.severity,
    required this.category,
    this.userMessage,
    required this.timestamp,
    required this.stackTrace,
  });

  @override
  String toString() {
    return 'ErrorRecord(severity: $severity, category: $category, '
           'timestamp: $timestamp, error: $error)';
  }
}