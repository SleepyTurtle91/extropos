import 'dart:collection';

class RateLimiter {
  final int maxRequestsPerMinute;
  final Queue<DateTime> _timestamps = Queue<DateTime>();

  RateLimiter(this.maxRequestsPerMinute);

  factory RateLimiter.forSubmitEndpoint() => RateLimiter(100);

  factory RateLimiter.forQueryEndpoint() => RateLimiter(12);

  bool canRequest() {
    _evictExpired();
    return _timestamps.length < maxRequestsPerMinute;
  }

  void recordRequest() {
    _evictExpired();
    _timestamps.add(DateTime.now());
  }

  Duration waitDuration() {
    _evictExpired();
    if (_timestamps.length < maxRequestsPerMinute || _timestamps.isEmpty) {
      return Duration.zero;
    }
    final oldest = _timestamps.first;
    final elapsed = DateTime.now().difference(oldest);
    final remaining = const Duration(minutes: 1) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _evictExpired() {
    final now = DateTime.now();
    while (_timestamps.isNotEmpty &&
        now.difference(_timestamps.first).inSeconds >= 60) {
      _timestamps.removeFirst();
    }
  }
}
