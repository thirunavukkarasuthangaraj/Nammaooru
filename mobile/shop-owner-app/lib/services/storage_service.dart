import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyNotificationSettings = 'notification_settings';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Alias for init() - for consistency with other services
  static Future<void> initialize() async {
    await init();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Check if service is initialized
  static bool get isInitialized => _prefs != null;

  // Token management
  static Future<void> saveToken(String token) async {
    await prefs.setString(_keyToken, token);
  }

  static Future<void> setToken(String token) async {
    await saveToken(token);
  }

  static String? getToken() {
    if (_prefs == null) {
      // Try to reinitialize if not initialized
      // This handles edge cases like app returning from background
      return null;
    }
    return _prefs!.getString(_keyToken);
  }

  // Safe token getter that won't throw
  static String? getTokenSafe() {
    try {
      return _prefs?.getString(_keyToken);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static String? getRefreshToken() {
    return prefs.getString(_keyRefreshToken);
  }

  // User data management
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final userJson = json.encode(user);
    await prefs.setString(_keyUser, userJson);
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    await saveUser(user);
  }

  static Map<String, dynamic>? getUser() {
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      return json.decode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Shop data management
  static Future<void> saveShop(Map<String, dynamic> shop) async {
    final shopJson = json.encode(shop);
    await prefs.setString('shop_data', shopJson);
  }

  static Map<String, dynamic>? getShop() {
    final shopJson = prefs.getString('shop_data');
    if (shopJson != null) {
      return json.decode(shopJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Login state management
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  static bool isLoggedIn() {
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // FCM Token management
  static Future<void> saveFcmToken(String fcmToken) async {
    await prefs.setString(_keyFcmToken, fcmToken);
  }

  static String? getFcmToken() {
    return prefs.getString(_keyFcmToken);
  }

  // Notification settings
  static Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    final settingsJson = json.encode(settings);
    await prefs.setString(_keyNotificationSettings, settingsJson);
  }

  static Map<String, dynamic> getNotificationSettings() {
    final settingsJson = prefs.getString(_keyNotificationSettings);
    if (settingsJson != null) {
      return json.decode(settingsJson) as Map<String, dynamic>;
    }
    return {
      'newOrder': true,
      'paymentReceived': true,
      'orderCancelled': true,
      'orderModified': true,
      'reviewReceived': true,
      'customerMessage': true,
      'timeAlert': true,
      'sound': true,
      'vibration': true,
    };
  }

  // Generic storage methods
  static Future<void> saveString(String key, String value) async {
    await prefs.setString(key, value);
  }

  static String? getString(String key) {
    return prefs.getString(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> saveInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return prefs.getInt(key) ?? defaultValue;
  }

  static Future<void> saveDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    return prefs.getDouble(key) ?? defaultValue;
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    await prefs.setStringList(key, value);
  }

  static List<String> getStringList(String key) {
    return prefs.getStringList(key) ?? [];
  }

  // Clear specific data
  static Future<void> clearToken() async {
    await prefs.remove(_keyToken);
  }

  static Future<void> clearRefreshToken() async {
    await prefs.remove(_keyRefreshToken);
  }

  static Future<void> clearUser() async {
    await prefs.remove(_keyUser);
  }

  static Future<void> clearAuthData() async {
    await Future.wait([
      clearToken(),
      clearRefreshToken(),
      clearUser(),
      setLoggedIn(false),
    ]);
  }

  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await prefs.clear();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  // Get all keys
  static Set<String> getAllKeys() {
    return prefs.getKeys();
  }
}