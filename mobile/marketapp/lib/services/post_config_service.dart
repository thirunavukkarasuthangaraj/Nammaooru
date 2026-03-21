import '../core/api/api_client.dart';

class PostConfigService {
  static PostConfigService? _instance;
  static PostConfigService get instance => _instance ??= PostConfigService._();
  PostConfigService._();

  // Defaults (fallback when API is unreachable)
  static const _defaults = {
    'post.image.limit': '3',
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

  /// Fetch post config settings from backend. Returns cached values if still fresh.
  Future<void> fetch() async {
    if (_isCacheValid) return;

    try {
      final response = await ApiClient.get(
        '/settings/public/category/POST_CONFIG',
        includeAuth: false,
      );
      if (response.statusCode == 200 && response.data is Map) {
        _cache = Map<String, String>.from(
          (response.data as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
        _cacheTime = DateTime.now();
      }
    } catch (_) {
      // Silently fall back to defaults / previous cache
    }
  }
}
