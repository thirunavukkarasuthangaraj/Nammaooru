import '../storage/local_storage.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const String _cachePrefix = 'cache_';

  /// Cache data with expiration
  Future<void> setCache(String key, Map<String, dynamic> data, {Duration? duration}) async {
    duration ??= _defaultCacheDuration;
    
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': DateTime.now().add(duration).millisecondsSinceEpoch,
    };
    
    await LocalStorage.setMap('$_cachePrefix$key', cacheData);
  }

  /// Get cached data if not expired
  Future<Map<String, dynamic>?> getCache(String key) async {
    try {
      final cacheData = await LocalStorage.getMap('$_cachePrefix$key');
      if (cacheData.isEmpty) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final expiry = cacheData['expiry'] as int?;

      if (expiry != null && now > expiry) {
        // Cache expired, remove it
        await clearCache(key);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String key) async {
    final cache = await getCache(key);
    return cache != null;
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    await LocalStorage.remove('$_cachePrefix$key');
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    // This would require getting all keys and filtering by prefix
    // For now, we'll implement a simple approach
    final commonCacheKeys = [
      'featured_shops',
      'recent_orders',
      'user_profile',
      'notification_count',
      'categories',
    ];

    for (final key in commonCacheKeys) {
      await clearCache(key);
    }
  }

  /// Cache shops data
  Future<void> cacheShops(List<dynamic> shops) async {
    await setCache('featured_shops', {'shops': shops}, duration: Duration(minutes: 10));
  }

  /// Get cached shops
  Future<List<dynamic>?> getCachedShops() async {
    final cache = await getCache('featured_shops');
    return cache?['shops'] as List<dynamic>?;
  }

  /// Cache orders data
  Future<void> cacheOrders(List<dynamic> orders) async {
    await setCache('recent_orders', {'orders': orders}, duration: Duration(minutes: 3));
  }

  /// Get cached orders
  Future<List<dynamic>?> getCachedOrders() async {
    final cache = await getCache('recent_orders');
    return cache?['orders'] as List<dynamic>?;
  }

  /// Cache notification count
  Future<void> cacheNotificationCount(int count) async {
    await setCache('notification_count', {'count': count}, duration: Duration(minutes: 1));
  }

  /// Get cached notification count
  Future<int?> getCachedNotificationCount() async {
    final cache = await getCache('notification_count');
    return cache?['count'] as int?;
  }
}