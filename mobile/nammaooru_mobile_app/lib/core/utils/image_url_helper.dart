import '../config/env_config.dart';

class ImageUrlHelper {
  /// Constructs full image URL from relative path
  /// If imageUrl is already a full URL, returns as-is
  /// If imageUrl is relative, prepends the base URL
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'https://via.placeholder.com/300x300/f0f0f0/cccccc?text=No+Image';
    }

    // If it's already a full URL, return as-is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Fix port mismatch for legacy URLs
      if (imageUrl.contains(':8082/')) {
        return imageUrl.replaceAll(':8082/', ':8080/');
      }
      return imageUrl;
    }

    // If it's a relative path, prepend base URL
    String baseUrl = EnvConfig.baseUrl;

    // Ensure imageUrl starts with /
    if (!imageUrl.startsWith('/')) {
      imageUrl = '/$imageUrl';
    }

    return '$baseUrl$imageUrl';
  }

  /// Extracts relative path from full URL
  /// This is useful when saving to database - store only the relative part
  static String getRelativePath(String fullUrl) {
    if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
      // Extract path after domain:port
      final uri = Uri.tryParse(fullUrl);
      if (uri != null) {
        return uri.path;
      }
    }

    // If it's already relative, return as-is
    return fullUrl.startsWith('/') ? fullUrl : '/$fullUrl';
  }
}