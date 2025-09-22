import '../auth/auth_service.dart';
import '../storage/local_storage.dart';
import '../../shared/services/notification_service.dart';
import '../../services/address_api_service.dart';

class PostLoginService {
  static final PostLoginService _instance = PostLoginService._internal();
  factory PostLoginService() => _instance;
  PostLoginService._internal();

  /// Call only essential APIs after successful login
  Future<void> initializePostLogin() async {
    try {
      await Future.wait([
        _loadUserPreferences(),
        _initializeNotifications(),
        _syncOfflineData(),
        // TODO: Enable once backend address endpoints are implemented
        // _loadUserAddresses(),
      ]);
    } catch (e) {
      print('Post-login initialization error: $e');
    }
  }

  /// Load minimal user preferences (location, settings)
  Future<void> _loadUserPreferences() async {
    try {
      // Load cached user preferences from local storage
      final prefs = await LocalStorage.getUserPreferences();
      
      // If no cached preferences, set defaults
      if (prefs.isEmpty) {
        await LocalStorage.setUserPreference('location', 'Tirupattur, Tamil Nadu');
        await LocalStorage.setUserPreference('currency', 'INR');
        await LocalStorage.setUserPreference('language', 'en');
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  /// Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initialize();
      // Get unread notification count without fetching all notifications
      final count = await _getNotificationCount();
      await LocalStorage.setInt('unread_notifications', count);
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Sync any offline data if needed
  Future<void> _syncOfflineData() async {
    try {
      // Check if there's any offline cart data to sync
      final offlineCart = await LocalStorage.getList('offline_cart');
      if (offlineCart.isNotEmpty) {
        // TODO: Sync offline cart with server
        print('Found ${offlineCart.length} offline cart items to sync');
      }
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }

  /// Get notification count without fetching all notifications
  Future<int> _getNotificationCount() async {
    try {
      // This should be a lightweight API call to get just the count
      // TODO: Implement API call to get notification count
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Validate and refresh auth token if needed
  Future<bool> validateAuthToken() async {
    try {
      return await AuthService.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  /// Load user addresses and cache them locally
  Future<void> _loadUserAddresses() async {
    try {
      final result = await AddressApiService.getUserAddresses();
      
      if (result['success']) {
        final addresses = result['data'] as List<dynamic>? ?? [];
        await LocalStorage.setList('user_addresses', addresses);
        print('Cached ${addresses.length} user addresses');
      } else {
        print('Failed to load addresses: ${result['message']}');
        // If API fails, keep existing cached addresses
      }
    } catch (e) {
      print('Error loading user addresses: $e');
      // If there's an error, keep existing cached addresses
    }
  }

  /// Get essential user info (cached if available)
  Future<Map<String, dynamic>> getEssentialUserInfo() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      final userRole = await AuthService.getCurrentUserRole();
      
      return {
        'userId': userId,
        'userRole': userRole,
        'isAuthenticated': true,
      };
    } catch (e) {
      return {
        'userId': null,
        'userRole': null,
        'isAuthenticated': false,
      };
    }
  }
}