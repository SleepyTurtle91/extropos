import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/performance_monitor.dart';

/// Lazy loading service for products and categories
/// Implements pagination and caching for better performance
class LazyLoadingService {
  static LazyLoadingService? _instance;
  static LazyLoadingService get instance {
    _instance ??= LazyLoadingService._();
    return _instance!;
  }

  LazyLoadingService._();

  static const int _defaultPageSize = 50;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Cache for products
  final Map<String, _CacheEntry<List<Item>>> _productCache = {};
  final Map<String, int> _productTotalCounts = {};

  // Cache for categories
  _CacheEntry<List<Category>>? _categoriesCache;

  /// Load products with pagination and caching
  Future<List<Item>> loadProducts({
    String? categoryId,
    String? searchQuery,
    int page = 0,
    int pageSize = _defaultPageSize,
    bool forceRefresh = false,
  }) async {
    return PerformanceMonitor.instance.timeAsync('loadProducts', () async {
      final cacheKey = _buildProductCacheKey(categoryId, searchQuery, page, pageSize);

      // Check cache first
      if (!forceRefresh) {
        final cached = _productCache[cacheKey];
        if (cached != null && !cached.isExpired) {
          developer.log('LazyLoadingService: Using cached products for $cacheKey');
          return cached.data;
        }
      }

      // Load from database
      final allItems = await DatabaseService.instance.getItems(categoryId: categoryId);
      // Apply search filter if provided
      var filteredItems = allItems;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filteredItems = allItems.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.sku?.toLowerCase().contains(query) == true
        ).toList();
      }
      // Apply pagination
      final startIndex = page * pageSize;
      final endIndex = startIndex + pageSize;
      final items = filteredItems.length > startIndex
        ? filteredItems.sublist(
            startIndex,
            endIndex > filteredItems.length ? filteredItems.length : endIndex
          )
        : <Item>[];

      // Cache the result
      _productCache[cacheKey] = _CacheEntry(data: items, timestamp: DateTime.now());

      // Clean up old cache entries periodically
      if (_productCache.length > 100) {
        _cleanupExpiredCache(_productCache);
      }

      developer.log('LazyLoadingService: Loaded ${items.length} items for $cacheKey');
      return items;
    });
  }

  /// Get total count of products (cached)
  Future<int> getProductCount({
    String? categoryId,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCountCacheKey(categoryId, searchQuery);

    if (!forceRefresh && _productTotalCounts.containsKey(cacheKey)) {
      return _productTotalCounts[cacheKey]!;
    }

    final allItems = await DatabaseService.instance.getItems(categoryId: categoryId);
    // Apply search filter if provided
    var filteredItems = allItems;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredItems = allItems.where((item) =>
        item.name.toLowerCase().contains(query) ||
        item.sku?.toLowerCase().contains(query) == true
      ).toList();
    }

    final count = filteredItems.length;

    _productTotalCounts[cacheKey] = count;
    return count;
  }

  /// Load all categories with caching
  Future<List<Category>> loadCategories({bool forceRefresh = false}) async {
    return PerformanceMonitor.instance.timeAsync('loadCategories', () async {
      // Check cache first
      if (!forceRefresh && _categoriesCache != null && !_categoriesCache!.isExpired) {
        developer.log('LazyLoadingService: Using cached categories');
        return _categoriesCache!.data;
      }

      // Load from database
      final categories = await DatabaseService.instance.getCategories();

      // Cache the result
      _categoriesCache = _CacheEntry(data: categories, timestamp: DateTime.now());

      developer.log('LazyLoadingService: Loaded ${categories.length} categories');
      return categories;
    });
  }

  /// Preload popular categories and their products
  Future<void> preloadPopularData() async {
    return PerformanceMonitor.instance.timeAsync('preloadPopularData', () async {
      developer.log('LazyLoadingService: Starting preload of popular data');

      try {
        // Load categories first
        await loadCategories();

        // Load first page of all products
        await loadProducts(page: 0, pageSize: _defaultPageSize);

        // Load products for first few categories (if any)
        final categories = _categoriesCache?.data ?? [];
        if (categories.isNotEmpty) {
          final preloadCount = categories.length < 3 ? categories.length : 3;
          for (int i = 0; i < preloadCount; i++) {
            await loadProducts(
              categoryId: categories[i].id,
              page: 0,
              pageSize: _defaultPageSize ~/ 2, // Smaller page for categories
            );
          }
        }

        developer.log('LazyLoadingService: Preload completed successfully');
      } catch (e) {
        developer.log('LazyLoadingService: Preload failed: $e');
        // Don't rethrow - preload failure shouldn't break the app
      }
    });
  }

  /// Clear all caches
  void clearCache() {
    _productCache.clear();
    _productTotalCounts.clear();
    _categoriesCache = null;
    developer.log('LazyLoadingService: Cache cleared');
  }

  /// Initialize the lazy loading service (required for singleton)
  Future<void> initialize() async {
    // No async initialization needed, but keeping for consistency
    developer.log('LazyLoadingService initialized');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'product_cache_entries': _productCache.length,
      'category_cache_entries': _categoriesCache != null ? 1 : 0,
      'total_count_cache_entries': _productTotalCounts.length,
      'cache_memory_estimate_kb': (_productCache.length * 200) + (_productTotalCounts.length * 50), // Rough estimate
    };
  }

  /// Build cache key for products
  String _buildProductCacheKey(String? categoryId, String? searchQuery, int page, int pageSize) {
    return 'products_cat:${categoryId ?? 'all'}_search:${searchQuery ?? 'none'}_page:$pageSize';
  }

  /// Build cache key for counts
  String _buildCountCacheKey(String? categoryId, String? searchQuery) {
    return 'count_cat:${categoryId ?? 'all'}_search:${searchQuery ?? 'none'}';
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache<T>(Map<String, _CacheEntry<T>> cache) {
    final now = DateTime.now();
    final expiredKeys = cache.entries
        .where((entry) => now.difference(entry.value.timestamp) > _cacheExpiry)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      developer.log('LazyLoadingService: Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }
}

/// Cache entry with timestamp
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});

  bool get isExpired => DateTime.now().difference(timestamp) > LazyLoadingService._cacheExpiry;
}