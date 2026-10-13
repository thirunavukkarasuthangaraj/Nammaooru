import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';

/// Admin-controlled cart settings, read from the public settings endpoint.
///
/// Same shape as [PostConfigService]: cached in memory, falls back to the defaults
/// below whenever the API is unreachable, so a cart update never depends on the
/// network. Admin edits these under Settings > CART and they reach customers on the
/// next cache refresh, with no app release.
class CartConfigService {
  static CartConfigService? _instance;
  static CartConfigService get instance => _instance ??= CartConfigService._();
  CartConfigService._();

  /// Fallbacks for when the API has never answered. Keep in step with V141.
  static const _defaults = {
    'cart.reminder.delay_minutes': '10',
    'cart.reminder.followup_minutes': '60,1440',
    'cart.reminder.enabled': 'true',
  };

  Map<String, String> _cache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);

  bool get _isCacheValid =>
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration &&
      _cache.isNotEmpty;

  String _value(String key) => _cache[key] ?? _defaults[key]!;

  /// How long the cart must sit untouched before the first reminder fires.
  ///
  /// Clamped to at least a minute: a zero or negative value would schedule the
  /// notification in the past, which the plugin either drops or fires instantly.
  Duration get reminderDelay {
    final minutes = int.tryParse(_value('cart.reminder.delay_minutes')) ?? 10;
    return Duration(minutes: minutes < 1 ? 1 : minutes);
  }

  /// Every reminder for one abandoned cart, first and follow-ups, each measured from
  /// the moment the cart was last changed.
  ///
  /// The number of reminders is just the length of this list, so admin switches between
  /// two and three by editing `cart.reminder.followup_minutes` - a comma-separated list
  /// of minutes ("60,1440" = +1h and +24h). Blanking it leaves a single reminder.
  ///
  /// Garbage entries are dropped rather than rejected wholesale: a stray comma or a typo
  /// in one number must not cost the customer every reminder. Sorted and de-duplicated
  /// so two notifications never land at the same moment, and so the escalating copy in
  /// LocalNotificationService stays in time order whatever order admin typed.
  List<Duration> get reminderDelays {
    final seen = <int>{reminderDelay.inMinutes};

    for (final part in _value('cart.reminder.followup_minutes').split(',')) {
      final minutes = int.tryParse(part.trim());
      if (minutes != null && minutes >= 1) seen.add(minutes);
    }

    final sorted = seen.toList()..sort();
    return sorted.map((m) => Duration(minutes: m)).toList();
  }

  bool get reminderEnabled => _value('cart.reminder.enabled') == 'true';

  /// Load cart config. Returns immediately while the cache is still fresh, so this is
  /// cheap to await on every cart change.
  Future<void> fetch() async {
    if (_isCacheValid) return;

    try {
      final response = await ApiClient.get(
        '/settings/public/category/CART',
        includeAuth: false,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final fetched = Map<String, String>.from(
          (response.data as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
        if (fetched.isNotEmpty) {
          _cache = fetched;
          _cacheTime = DateTime.now();
        }
      }
    } catch (e) {
      // Fall back to defaults / previous cache; never block the cart on this.
      if (kDebugMode) print('Cart config fetch failed: $e');
    }
  }
}
