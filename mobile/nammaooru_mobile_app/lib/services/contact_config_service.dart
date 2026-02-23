import '../core/api/api_client.dart';

class ContactConfigService {
  static ContactConfigService? _instance;
  static ContactConfigService get instance => _instance ??= ContactConfigService._();
  ContactConfigService._();

  // Defaults (fallback when API is unreachable)
  static const _defaults = {
    'support.phone': '6374217724',
    'support.whatsapp': '6374217724',
    'support.email': 'support@nammaooru.com',
    'support.website': 'https://nammaooru.com',
  };

  Map<String, String> _cache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);

  bool get _isCacheValid =>
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration &&
      _cache.isNotEmpty;

  String get phone => _cache['support.phone'] ?? _defaults['support.phone']!;
  String get whatsapp => _cache['support.whatsapp'] ?? _defaults['support.whatsapp']!;
  String get email => _cache['support.email'] ?? _defaults['support.email']!;
  String get website => _cache['support.website'] ?? _defaults['support.website']!;

  /// Fetch contact settings from backend. Returns cached values if still fresh.
  Future<void> fetch() async {
    if (_isCacheValid) return;

    try {
      final response = await ApiClient.get(
        '/settings/public/category/CONTACT',
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
