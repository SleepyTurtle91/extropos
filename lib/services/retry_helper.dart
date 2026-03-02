import 'dart:async';

import 'package:extropos/exceptions/myinvois_exception.dart';

class RetryHelper {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryHelper({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2,
    this.maxDelay = const Duration(seconds: 30),
  });

  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    Duration delay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } on MyInvoisException catch (error) {
        if (!error.isRetryable || attempt == maxAttempts) {
          rethrow;
        }

        final wait = error.retryAfterSeconds != null
            ? Duration(seconds: error.retryAfterSeconds!)
            : delay;

        final effectiveDelay =
            wait > maxDelay ? maxDelay : wait;

        if (operationName != null && operationName.isNotEmpty) {
          // ignore: avoid_print
          print(
            'Retrying $operationName in ${effectiveDelay.inSeconds}s '
            '(attempt $attempt/$maxAttempts)',
          );
        }

        await Future<void>.delayed(effectiveDelay);

        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );
      }
    }

    throw const MyInvoisException(
      code: 'MaxRetriesExceeded',
      message: 'Operation failed after maximum retry attempts',
    );
  }
}
