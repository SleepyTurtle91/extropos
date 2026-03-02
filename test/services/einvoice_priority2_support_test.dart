import 'package:extropos/exceptions/myinvois_exception.dart';
import 'package:extropos/services/rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('MyInvoisException', () {
    test('fromHttpResponse maps known status and retry-after header', () {
      final response = http.Response(
        '{"error":{"code":"RateLimitExceeded","message":"Too many requests"}}',
        429,
        headers: {'retry-after': '12'},
      );

      final exception = MyInvoisException.fromHttpResponse(response);

      expect(exception.code, 'RateLimitExceeded');
      expect(exception.message, 'Too many requests');
      expect(exception.statusCode, 429);
      expect(exception.retryAfterSeconds, 12);
      expect(exception.isRetryable, isTrue);
    });

    test('uses default code when body has no error block', () {
      final response = http.Response('unexpected', 422);

      final exception = MyInvoisException.fromHttpResponse(
        response,
        defaultMessage: 'Submission failed',
      );

      expect(exception.code, 'DuplicateSubmission');
      expect(exception.message, 'Submission failed');
    });
  });

  group('RateLimiter', () {
    test('blocks when request quota is exhausted', () {
      final limiter = RateLimiter(2);

      expect(limiter.canRequest(), isTrue);
      limiter.recordRequest();
      expect(limiter.canRequest(), isTrue);
      limiter.recordRequest();

      expect(limiter.canRequest(), isFalse);
      expect(limiter.waitDuration().inSeconds, greaterThan(0));
    });
  });
}
