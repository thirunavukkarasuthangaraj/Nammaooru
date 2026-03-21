import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheManager {
  static const String _cacheKey = 'nammaooru_images';
  static const Duration _maxAge = Duration(days: 7);
  static const int _maxCacheObjects = 200;

  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _maxAge,
        maxNrOfCacheObjects: _maxCacheObjects,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Get optimized image widget with caching
  static Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
  }) {
    // Return placeholder for empty URLs
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: instance,
      memCacheWidth: _getOptimalCacheSize(width),
      memCacheHeight: _getOptimalCacheSize(height),
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  /// Get optimal cache size based on screen density
  static int? _getOptimalCacheSize(double? size) {
    if (size == null) return null;

    // Get device pixel ratio
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    return (size * pixelRatio).round();
  }

  /// Build shimmer loading placeholder
  static Widget _buildShimmerPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Build error widget
  static Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  /// Preload images for better performance
  static Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await instance.getSingleFile(url);
        } catch (e) {
          debugPrint('Failed to preload image: $url - $e');
        }
      }
    }
  }

  /// Clear cache
  static Future<void> clearCache() async {
    await instance.emptyCache();
    debugPrint('Image cache cleared');
  }

  /// Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final cacheDir = await getTemporaryDirectory();
    final cachePath = path.join(cacheDir.path, _cacheKey);
    final cacheDirectory = Directory(cachePath);

    if (!await cacheDirectory.exists()) {
      return {
        'size': 0,
        'fileCount': 0,
        'sizeMB': 0.0,
      };
    }

    int totalSize = 0;
    int fileCount = 0;

    await for (final entity in cacheDirectory.list(recursive: true)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileCount++;
        } catch (e) {
          // Ignore files we can't read
        }
      }
    }

    return {
      'size': totalSize,
      'fileCount': fileCount,
      'sizeMB': (totalSize / (1024 * 1024)),
    };
  }

  /// Clean old cache files
  static Future<void> cleanOldCache() async {
    try {
      final cutoff = DateTime.now().subtract(_maxAge);
      final cacheDir = await getTemporaryDirectory();
      final cachePath = path.join(cacheDir.path, _cacheKey);
      final cacheDirectory = Directory(cachePath);

      if (!await cacheDirectory.exists()) return;

      await for (final entity in cacheDirectory.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoff)) {
              await entity.delete();
            }
          } catch (e) {
            // Ignore files we can't delete
          }
        }
      }

      debugPrint('Old cache files cleaned');
    } catch (e) {
      debugPrint('Error cleaning old cache: $e');
    }
  }

  /// Optimize image URL for better performance
  static String optimizeImageUrl(String originalUrl, {int? width, int? height, int quality = 80}) {
    if (originalUrl.isEmpty) return originalUrl;

    // If it's already optimized, return as is
    if (originalUrl.contains('?')) return originalUrl;

    final buffer = StringBuffer(originalUrl);
    buffer.write('?');

    if (width != null) {
      buffer.write('w=$width');
    }

    if (height != null) {
      if (width != null) buffer.write('&');
      buffer.write('h=$height');
    }

    if (width != null || height != null) {
      buffer.write('&');
    }
    buffer.write('q=$quality');

    return buffer.toString();
  }

  /// Smart image widget that automatically optimizes based on container size
  static Widget smartImage({
    required String imageUrl,
    required BuildContext context,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : null;

        final optimizedUrl = optimizeImageUrl(
          imageUrl,
          width: width?.round(),
          height: height?.round(),
        );

        return getOptimizedImage(
          imageUrl: optimizedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
        );
      },
    );
  }
}