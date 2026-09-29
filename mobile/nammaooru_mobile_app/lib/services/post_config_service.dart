import '../core/api/api_client.dart';

class PostConfigService {
  static PostConfigService? _instance;
  static PostConfigService get instance => _instance ??= PostConfigService._();
  PostConfigService._();

  // Defaults (fallback when API is unreachable)
  static const _defaults = {
    'post.image.limit': '3',
    'banner.enabled': 'true',
  };

  Map<String, String> _cache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);

  bool get _isCacheValid =>
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration &&
      _cache.isNotEmpty;

  int get imageLimit {
    final val = _cache['post.image.limit'] ?? _defaults['post.image.limit']!;
    return int.tryParse(val) ?? 3;
  }

  /// Whether the "Feature as Banner" paid option should show on post-creation
  /// forms. Admin controls this from Post Limits > Banner Pricing.
  bool get bannerEnabled {
    final val = _cache['banner.enabled'] ?? _defaults['banner.enabled']!;
    return val == 'true';
  }

  /// Fetch post config settings from backend. Returns cached values if still fresh.
  Future<void> fetch() async {
    if (_isCacheValid) return;

    try {
      final responses = await Future.wait([
        ApiClient.get('/settings/public/category/POST_CONFIG', includeAuth: false),
        ApiClient.get('/settings/public/category/PAID_POSTS', includeAuth: false),
      ]);
      final merged = <String, String>{};
      for (final response in responses) {
        if (response.statusCode == 200 && response.data is Map) {
          merged.addAll(Map<String, String>.from(
            (response.data as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
          ));
        }
      }
      if (merged.isNotEmpty) {
        _cache = merged;
        _cacheTime = DateTime.now();
      }
    } catch (_) {
      // Silently fall back to defaults / previous cache
    }
  }
}
