import 'dart:convert';

import 'package:http/http.dart' as http;

class MyInvoisException implements Exception {
  final String code;
  final String message;
  final String? detail;
  final int? statusCode;
  final dynamic originalResponse;
  final int? retryAfterSeconds;

  const MyInvoisException({
    required this.code,
    required this.message,
    this.detail,
    this.statusCode,
    this.originalResponse,
    this.retryAfterSeconds,
  });

  bool get isRetryable =>
      code == 'DuplicateSubmission' ||
      code == 'RateLimitExceeded' ||
      statusCode == 429 ||
      statusCode == 503;

  int get retryDelaySeconds =>
      retryAfterSeconds ?? (code == 'DuplicateSubmission' ? 10 : 5);

  factory MyInvoisException.fromHttpResponse(
    http.Response response, {
    String? defaultMessage,
  }) {
    final parsedBody = _tryParseJson(response.body);
    final errorMap =
        parsedBody is Map<String, dynamic> && parsedBody['error'] is Map
            ? Map<String, dynamic>.from(parsedBody['error'] as Map)
            : <String, dynamic>{};

    final rawCode = (errorMap['code'] ?? '').toString();
    final code = rawCode.isNotEmpty ? rawCode : _defaultCodeForStatus(response.statusCode);
    final message = (errorMap['message'] ?? defaultMessage ?? 'MyInvois request failed')
        .toString();
    final detail = errorMap['target']?.toString();
    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');

    return MyInvoisException(
      code: code,
      message: message,
      detail: detail,
      statusCode: response.statusCode,
      originalResponse: parsedBody,
      retryAfterSeconds: retryAfter,
    );
  }

  static dynamic _tryParseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String _defaultCodeForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'BadStructure';
      case 403:
        return 'IncorrectSubmitter';
      case 422:
        return 'DuplicateSubmission';
      case 429:
        return 'RateLimitExceeded';
      case 500:
        return 'InternalServerError';
      case 503:
        return 'ServiceUnavailable';
      default:
        return 'Http$statusCode';
    }
  }

  @override
  String toString() {
    if (detail == null || detail!.isEmpty) {
      return 'MyInvoisException($code): $message';
    }
    return 'MyInvoisException($code): $message [$detail]';
  }
}
