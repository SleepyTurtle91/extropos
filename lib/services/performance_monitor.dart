import 'dart:async';
import 'dart:developer' as developer;

/// Performance metrics for operations
class OperationStats {
  final String operationName;
  final int count;
  final double avgMs;
  final double minMs;
  final double maxMs;
  final double medianMs;
  final String performanceRating;

  OperationStats({
    required this.operationName,
    required this.count,
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
    required this.performanceRating,
  });

  @override
  String toString() {
    return '$operationName: ${avgMs.toStringAsFixed(2)}ms avg ($count ops) - $performanceRating';
  }
}

/// Performance monitoring service for FlutterPOS
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance {
    _instance ??= PerformanceMonitor._();
    return _instance!;
  }

  PerformanceMonitor._();

  final Map<String, List<double>> _operationTimes = {};
  final Map<String, Stopwatch> _activeOperations = {};
  static const int _maxSamplesPerOperation = 100;

  /// Start timing an operation
  void startOperation(String operationName) {
    _activeOperations[operationName] = Stopwatch()..start();
  }

  /// Stop timing an operation and record the duration
  void endOperation(String operationName) {
    final stopwatch = _activeOperations.remove(operationName);
    if (stopwatch == null) {
      developer.log('PerformanceMonitor: No active operation found for $operationName');
      return;
    }

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMicroseconds / 1000.0; // Convert to milliseconds with decimal precision

    // Store the timing
    _operationTimes.putIfAbsent(operationName, () => []).add(durationMs);

    // Keep only the most recent samples
    if (_operationTimes[operationName]!.length > _maxSamplesPerOperation) {
      _operationTimes[operationName]!.removeAt(0);
    }

    // Log slow operations
    if (durationMs > 1000) { // > 1 second
      developer.log('PerformanceMonitor: SLOW OPERATION - $operationName took ${durationMs.toStringAsFixed(2)}ms');
    } else if (durationMs > 100) { // > 100ms
      developer.log('PerformanceMonitor: Slow operation - $operationName took ${durationMs.toStringAsFixed(2)}ms', level: 900);
    }
  }

  /// Time an async operation
  Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Time a sync operation
  T timeSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Get statistics for an operation
  OperationStats? getStats(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return null;

    final sortedTimes = List<double>.from(times)..sort();
    final avg = times.reduce((a, b) => a + b) / times.length;
    final min = sortedTimes.first;
    final max = sortedTimes.last;
    final median = sortedTimes.length.isOdd
        ? sortedTimes[sortedTimes.length ~/ 2]
        : (sortedTimes[sortedTimes.length ~/ 2 - 1] + sortedTimes[sortedTimes.length ~/ 2]) / 2;

    // Determine performance rating
    String rating;
    if (avg < 10) {
      rating = 'Excellent';
    } else if (avg < 50) {
      rating = 'Good';
    } else if (avg < 200) {
      rating = 'Fair';
    } else if (avg < 1000) {
      rating = 'Slow';
    } else if (avg < 5000) {
      rating = 'Poor';
    } else {
      rating = 'Critical';
    }

    return OperationStats(
      operationName: operationName,
      count: times.length,
      avgMs: avg,
      minMs: min,
      maxMs: max,
      medianMs: median,
      performanceRating: rating,
    );
  }

  /// Get all operation statistics
  Map<String, OperationStats> getAllStats() {
    final stats = <String, OperationStats>{};
    for (final operationName in _operationTimes.keys) {
      final stat = getStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }
    return stats;
  }

  /// Get operations that exceed threshold
  List<OperationStats> getSlowOperations({double thresholdMs = 100.0}) {
    return getAllStats().values
        .where((stat) => stat.avgMs > thresholdMs)
        .toList()
      ..sort((a, b) => b.avgMs.compareTo(a.avgMs));
  }

  /// Get top N slowest operations
  List<OperationStats> getTopSlowest({int limit = 5}) {
    return getAllStats().values
        .toList()
      ..sort((a, b) => b.avgMs.compareTo(a.avgMs))
      ..take(limit)
      .toList();
  }

  /// Print performance report
  void printReport() {
    developer.log('=== PERFORMANCE REPORT ===');

    final stats = getAllStats();
    if (stats.isEmpty) {
      developer.log('No performance data collected yet');
      return;
    }

    final sortedStats = stats.values.toList()
      ..sort((a, b) => b.avgMs.compareTo(a.avgMs));

    for (final stat in sortedStats) {
      developer.log(stat.toString());
    }

    final slowOps = getSlowOperations();
    if (slowOps.isNotEmpty) {
      developer.log('⚠️  SLOW OPERATIONS DETECTED: ${slowOps.length}');
    }

    developer.log('=== END PERFORMANCE REPORT ===');
  }

  /// Initialize the performance monitor (required for singleton)
  Future<void> initialize() async {
    // No async initialization needed, but keeping for consistency
    developer.log('PerformanceMonitor initialized');
  }

  /// Clear all performance data
  void clear() {
    _operationTimes.clear();
    _activeOperations.clear();
  }

  /// Get memory usage estimate (rough approximation)
  Map<String, dynamic> getMemoryStats() {
    final operationCount = _operationTimes.length;
    final totalSamples = _operationTimes.values.fold(0, (sum, list) => sum + list.length);
    final estimatedMemoryKb = (operationCount * 100) + (totalSamples * 8); // Rough estimate

    return {
      'operations_tracked': operationCount,
      'total_samples': totalSamples,
      'estimated_memory_kb': estimatedMemoryKb,
      'active_operations': _activeOperations.length,
    };
  }
}