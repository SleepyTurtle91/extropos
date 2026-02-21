import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Image optimization service for product images
/// Handles caching, resizing, and memory management
class ImageOptimizationService {
  static ImageOptimizationService? _instance;
  static ImageOptimizationService get instance {
    _instance ??= ImageOptimizationService._();
    return _instance!;
  }

  ImageOptimizationService._();

  static const int _maxCacheSize = 50; // Maximum cached images

  // Memory cache
  final Map<String, _ImageCacheEntry> _memoryCache = {};
  final List<String> _accessOrder = []; // LRU tracking

  // Disk cache
  Directory? _cacheDir;
  static const String _cacheSubDir = 'optimized_images';

  /// Initialize the service
  Future<void> initialize() async {
    if (_cacheDir != null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory('${tempDir.path}/$_cacheSubDir');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      developer.log('ImageOptimizationService: Initialized cache at ${_cacheDir!.path}');
    } catch (e) {
      developer.log('ImageOptimizationService: Failed to initialize cache: $e');
    }
  }

  /// Load and optimize an image
  Future<ui.Image?> loadOptimizedImage(
    String imageUrl, {
    double maxWidth = 200,
    double maxHeight = 200,
    bool useCache = true,
  }) async {
    await initialize();

    final cacheKey = _generateCacheKey(imageUrl, maxWidth, maxHeight);

    // Check memory cache first
    if (useCache) {
      final memoryEntry = _memoryCache[cacheKey];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _updateAccessOrder(cacheKey);
        return memoryEntry.image;
      }
    }

    // Check disk cache
    if (useCache && _cacheDir != null) {
      final diskImage = await _loadFromDiskCache(cacheKey);
      if (diskImage != null) {
        // Store in memory cache
        _storeInMemoryCache(cacheKey, diskImage);
        return diskImage;
      }
    }

    // Load and optimize from network/asset
    try {
      final originalImage = await _loadOriginalImage(imageUrl);
      if (originalImage == null) return null;

      final optimizedImage = await _optimizeImage(originalImage, maxWidth, maxHeight);

      // Cache the result
      if (useCache) {
        await _storeInDiskCache(cacheKey, optimizedImage);
        _storeInMemoryCache(cacheKey, optimizedImage);
      }

      return optimizedImage;
    } catch (e) {
      developer.log('ImageOptimizationService: Failed to load image $imageUrl: $e');
      return null;
    }
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls, {
    double maxWidth = 200,
    double maxHeight = 200,
  }) async {
    await initialize();

    final futures = imageUrls.map((url) => loadOptimizedImage(
      url,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    ));

    await Future.wait(futures);
    developer.log('ImageOptimizationService: Preloaded ${imageUrls.length} images');
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    _accessOrder.clear();
    developer.log('ImageOptimizationService: Memory cache cleared');
  }

  /// Clear disk cache
  Future<void> clearDiskCache() async {
    if (_cacheDir == null) return;

    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
      developer.log('ImageOptimizationService: Disk cache cleared');
    } catch (e) {
      developer.log('ImageOptimizationService: Failed to clear disk cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalSize = _memoryCache.values.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
    final expiredCount = _memoryCache.values.where((entry) => entry.isExpired).length;

    return {
      'memory_cache_entries': _memoryCache.length,
      'memory_cache_size_kb': totalSize ~/ 1024,
      'expired_entries': expiredCount,
      'disk_cache_initialized': _cacheDir != null,
    };
  }

  /// Generate cache key for image
  String _generateCacheKey(String imageUrl, double maxWidth, double maxHeight) {
    final keyData = utf8.encode('$imageUrl${maxWidth}x$maxHeight');
    return sha256.convert(keyData).toString().substring(0, 16);
  }

  /// Load original image from URL or asset
  Future<ui.Image?> _loadOriginalImage(String imageUrl) async {
    // For demo purposes, create a placeholder image
    // In real implementation, this would load from network or assets
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.grey[300]!;

    canvas.drawRect(Rect.fromLTWH(0, 0, 100, 100), paint);

    final picture = recorder.endRecording();
    return picture.toImage(100, 100);
  }

  /// Optimize image by resizing
  Future<ui.Image> _optimizeImage(
    ui.Image original,
    double maxWidth,
    double maxHeight,
  ) async {
    // Calculate new dimensions maintaining aspect ratio
    final aspectRatio = original.width / original.height;
    double newWidth = maxWidth;
    double newHeight = maxHeight;

    if (original.width > original.height) {
      newHeight = newWidth / aspectRatio;
      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = newHeight * aspectRatio;
      }
    } else {
      newWidth = newHeight * aspectRatio;
      if (newWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = newWidth / aspectRatio;
      }
    }

    // Create a new image with the calculated dimensions
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the original image scaled
    final srcRect = Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, newWidth, newHeight);

    canvas.drawImageRect(original, srcRect, dstRect, Paint());

    final picture = recorder.endRecording();
    return picture.toImage(newWidth.toInt(), newHeight.toInt());
  }

  /// Store image in memory cache
  void _storeInMemoryCache(String cacheKey, ui.Image image) {
    // Estimate memory usage (rough approximation)
    final sizeBytes = image.width * image.height * 4; // RGBA

    _memoryCache[cacheKey] = _ImageCacheEntry(
      image: image,
      sizeBytes: sizeBytes,
      timestamp: DateTime.now(),
    );

    _updateAccessOrder(cacheKey);

    // Enforce cache size limit
    while (_memoryCache.length > _maxCacheSize) {
      final lruKey = _accessOrder.removeAt(0);
      _memoryCache.remove(lruKey);
    }
  }

  /// Load image from disk cache
  Future<ui.Image?> _loadFromDiskCache(String cacheKey) async {
    if (_cacheDir == null) return null;

    try {
      final file = File('${_cacheDir!.path}/$cacheKey.png');
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      return frame.image;
    } catch (e) {
      developer.log('ImageOptimizationService: Failed to load from disk cache: $e');
      return null;
    }
  }

  /// Store image in disk cache
  Future<void> _storeInDiskCache(String cacheKey, ui.Image image) async {
    if (_cacheDir == null) return;

    try {
      final file = File('${_cacheDir!.path}/$cacheKey.png');

      // Convert image to bytes (simplified - in real implementation would use proper encoding)
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      developer.log('ImageOptimizationService: Failed to store in disk cache: $e');
    }
  }

  /// Update access order for LRU cache
  void _updateAccessOrder(String cacheKey) {
    _accessOrder.remove(cacheKey);
    _accessOrder.add(cacheKey);
  }
}

/// Memory cache entry
class _ImageCacheEntry {
  final ui.Image image;
  final int sizeBytes;
  final DateTime timestamp;

  static const Duration _cacheExpiry = Duration(minutes: 10);

  _ImageCacheEntry({
    required this.image,
    required this.sizeBytes,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > _cacheExpiry;
}