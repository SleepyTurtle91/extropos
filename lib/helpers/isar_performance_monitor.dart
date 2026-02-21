import 'dart:async';

/// Performance monitoring utility for Isar database operations.
/// 
/// Tracks operation durations to identify slow queries and optimize performance.
/// Useful for development and production monitoring.
class IsarPerformanceMonitor {
  static final Map<String, List<Duration>> _operationTimes = {};
  static final Map<String, int> _operationCounts = {};
  
  /// Time a database operation and record its duration.
  /// 
  /// Usage:
  /// ```dart
  /// final products = await IsarPerformanceMonitor.timeOperation(
  ///   'getAllProducts',
  ///   () => IsarDatabaseService.getAllProducts(),
  /// );
  /// ```
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordOperation(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation('$operationName (ERROR)', stopwatch.elapsed);
      rethrow;
    }
  }
  
  /// Time a synchronous operation.
  static T timeOperationSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      _recordOperation(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation('$operationName (ERROR)', stopwatch.elapsed);
      rethrow;
    }
  }
  
  /// Record an operation's duration.
  static void _recordOperation(String operationName, Duration duration) {
    _operationTimes.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }
  
  /// Get statistics for a specific operation.
  static OperationStats? getStats(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return null;
    
    final count = times.length;
    final totalMs = times.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / count;
    
    final sortedTimes = List<Duration>.from(times)..sort((a, b) => a.compareTo(b));
    final minMs = sortedTimes.first.inMilliseconds;
    final maxMs = sortedTimes.last.inMilliseconds;
    final medianMs = sortedTimes[count ~/ 2].inMilliseconds;
    
    return OperationStats(
      operationName: operationName,
      count: count,
      totalMs: totalMs,
      avgMs: avgMs,
      minMs: minMs,
      maxMs: maxMs,
      medianMs: medianMs,
    );
  }
  
  /// Get all recorded operation statistics.
  static Map<String, OperationStats> getAllStats() {
    final stats = <String, OperationStats>{};
    
    for (final operationName in _operationTimes.keys) {
      final opStats = getStats(operationName);
      if (opStats != null) {
        stats[operationName] = opStats;
      }
    }
    
    return stats;
  }
  
  /// Print performance report to console.
  static void printStats({String? operationName}) {
    if (operationName != null) {
      final stats = getStats(operationName);
      if (stats == null) {
        print('No stats for operation: $operationName');
        return;
      }
      print(stats.toString());
    } else {
      final allStats = getAllStats();
      if (allStats.isEmpty) {
        print('No operations recorded yet.');
        return;
      }
      
      print('\n=== Isar Performance Report ===');
      print('Total operations: ${allStats.length}');
      print('');
      
      final sortedStats = allStats.values.toList()
        ..sort((a, b) => b.avgMs.compareTo(a.avgMs));
      
      for (final stats in sortedStats) {
        print(stats.toString());
      }
      
      print('\n==============================\n');
    }
  }
  
  /// Get top N slowest operations by average time.
  static List<OperationStats> getTopSlowest({int limit = 10}) {
    final allStats = getAllStats();
    final sortedStats = allStats.values.toList()
      ..sort((a, b) => b.avgMs.compareTo(a.avgMs));
    
    return sortedStats.take(limit).toList();
  }
  
  /// Get top N most frequent operations.
  static List<OperationStats> getTopFrequent({int limit = 10}) {
    final allStats = getAllStats();
    final sortedStats = allStats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    
    return sortedStats.take(limit).toList();
  }
  
  /// Clear all recorded statistics.
  static void clear() {
    _operationTimes.clear();
    _operationCounts.clear();
  }
  
  /// Clear statistics for a specific operation.
  static void clearOperation(String operationName) {
    _operationTimes.remove(operationName);
    _operationCounts.remove(operationName);
  }
  
  /// Check if any operation exceeds a threshold.
  static List<String> getSlowOperations({int thresholdMs = 100}) {
    final slowOps = <String>[];
    
    for (final entry in getAllStats().entries) {
      if (entry.value.avgMs > thresholdMs) {
        slowOps.add('${entry.key}: ${entry.value.avgMs.toStringAsFixed(1)}ms avg');
      }
    }
    
    return slowOps;
  }
}

/// Statistics for a database operation.
class OperationStats {
  final String operationName;
  final int count;
  final int totalMs;
  final double avgMs;
  final int minMs;
  final int maxMs;
  final int medianMs;
  
  OperationStats({
    required this.operationName,
    required this.count,
    required this.totalMs,
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
  });
  
  @override
  String toString() {
    return '''
$operationName:
  Count: $count
  Total: ${totalMs}ms
  Avg: ${avgMs.toStringAsFixed(2)}ms
  Min: ${minMs}ms
  Max: ${maxMs}ms
  Median: ${medianMs}ms
''';
  }
  
  /// Get performance rating: 'Excellent', 'Good', 'Acceptable', 'Slow', 'Poor'
  String get performanceRating {
    if (avgMs < 10) return 'Excellent';
    if (avgMs < 50) return 'Good';
    if (avgMs < 100) return 'Acceptable';
    if (avgMs < 500) return 'Slow';
    return 'Poor';
  }
}
