import 'dart:async';
import 'dart:developer' as developer;

/// Memory management service for FlutterPOS
/// Helps track and dispose of resources to prevent memory leaks
class MemoryManager {
  static MemoryManager? _instance;
  static MemoryManager get instance {
    _instance ??= MemoryManager._();
    return _instance!;
  }

  MemoryManager._();

  final List<_DisposableResource> _resources = [];
  final Map<String, _ResourcePool> _pools = {};
  Timer? _cleanupTimer;

  /// Initialize memory management
  Future<void> initialize() async {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cleanupExpiredResources();
    });

    developer.log('MemoryManager: Initialized');
  }

  /// Dispose of memory management
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    // Dispose all resources
    for (final resource in _resources) {
      resource.dispose();
    }
    _resources.clear();

    // Clear pools
    _pools.clear();

    developer.log('MemoryManager: Disposed');
  }

  /// Register a disposable resource
  void registerResource(
    String id,
    void Function() disposeCallback, {
    Duration? expiry,
  }) {
    _resources.add(_DisposableResource(
      id: id,
      disposeCallback: disposeCallback,
      expiry: expiry,
    ));

    developer.log('MemoryManager: Registered resource $id');
  }

  /// Unregister a resource (call dispose manually)
  void unregisterResource(String id) {
    _resources.removeWhere((resource) => resource.id == id);
    developer.log('MemoryManager: Unregistered resource $id');
  }

  /// Dispose a specific resource
  void disposeResource(String id) {
    final resource = _resources.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Resource $id not found'),
    );

    resource.disposeCallback();
    _resources.remove(resource);

    developer.log('MemoryManager: Disposed resource $id');
  }

  /// Get resource from pool or create new one
  T getFromPool<T>(
    String poolName,
    T Function() factory, {
    Duration? maxAge,
  }) {
    final pool = _pools.putIfAbsent(poolName, () => _ResourcePool<T>());

    final resource = pool.getResource(factory, maxAge: maxAge);
    developer.log('MemoryManager: Retrieved resource from pool $poolName');

    return resource;
  }

  /// Return resource to pool
  void returnToPool<T>(String poolName, T resource) {
    final pool = _pools[poolName];
    if (pool != null) {
      pool.returnResource(resource);
      developer.log('MemoryManager: Returned resource to pool $poolName');
    }
  }

  /// Clear a specific pool
  void clearPool(String poolName) {
    final pool = _pools.remove(poolName);
    if (pool != null) {
      pool.clear();
      developer.log('MemoryManager: Cleared pool $poolName');
    }
  }

  /// Cleanup expired resources
  void cleanupExpiredResources() {
    final now = DateTime.now();
    final expiredResources = _resources.where((resource) =>
      resource.expiry != null && now.isAfter(resource.createdAt.add(resource.expiry!))
    ).toList();

    for (final resource in expiredResources) {
      developer.log('MemoryManager: Cleaning up expired resource ${resource.id}');
      resource.disposeCallback();
      _resources.remove(resource);
    }

    // Cleanup old pool resources
    for (final pool in _pools.values) {
      pool.cleanup();
    }

    if (expiredResources.isNotEmpty) {
      developer.log('MemoryManager: Cleaned up ${expiredResources.length} expired resources');
    }
  }

  /// Get memory statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'registered_resources': _resources.length,
      'active_pools': _pools.length,
      'total_pool_resources': _pools.values.fold(0, (sum, pool) => sum + pool.size),
      'expired_resources': _resources.where((r) =>
        r.expiry != null && DateTime.now().isAfter(r.createdAt.add(r.expiry!))
      ).length,
    };
  }

  /// Force garbage collection hint (for debugging)
  void suggestGC() {
    developer.log('MemoryManager: Suggesting garbage collection');
    // In Flutter, we can't force GC, but we can suggest it
  }
}

/// Disposable resource wrapper
class _DisposableResource {
  final String id;
  final void Function() disposeCallback;
  final Duration? expiry;
  final DateTime createdAt;

  _DisposableResource({
    required this.id,
    required this.disposeCallback,
    this.expiry,
  }) : createdAt = DateTime.now();

  void dispose() {
    try {
      disposeCallback();
    } catch (e) {
      developer.log('MemoryManager: Error disposing resource $id: $e');
    }
  }
}

/// Resource pool for reusing objects
class _ResourcePool<T> {
  final List<_PooledResource<T>> _resources = [];
  static const Duration _defaultMaxAge = Duration(minutes: 10);

  /// Get a resource from the pool
  T getResource(T Function() factory, {Duration? maxAge}) {
    final now = DateTime.now();
    final effectiveMaxAge = maxAge ?? _defaultMaxAge;

    // Find an available resource
    final availableResource = _resources.firstWhere(
      (resource) => !resource.isInUse && now.difference(resource.createdAt) < effectiveMaxAge,
      orElse: () => _PooledResource<T>(
        resource: factory(),
        createdAt: now,
      ),
    );

    availableResource.isInUse = true;
    availableResource.lastUsed = now;

    // Add to pool if not already there
    if (!_resources.contains(availableResource)) {
      _resources.add(availableResource);
    }

    return availableResource.resource;
  }

  /// Return a resource to the pool
  void returnResource(T resource) {
    final pooledResource = _resources.firstWhere(
      (r) => r.resource == resource,
      orElse: () => throw Exception('Resource not found in pool'),
    );

    pooledResource.isInUse = false;
    pooledResource.lastUsed = DateTime.now();
  }

  /// Get pool size
  int get size => _resources.length;

  /// Cleanup old resources
  void cleanup() {
    final now = DateTime.now();
    _resources.removeWhere((resource) =>
      !resource.isInUse && now.difference(resource.lastUsed) > _defaultMaxAge
    );
  }

  /// Clear all resources
  void clear() {
    _resources.clear();
  }
}

/// Pooled resource wrapper
class _PooledResource<T> {
  final T resource;
  final DateTime createdAt;
  DateTime lastUsed;
  bool isInUse;

  _PooledResource({
    required this.resource,
    required this.createdAt,
  }) : lastUsed = createdAt, isInUse = false;
}