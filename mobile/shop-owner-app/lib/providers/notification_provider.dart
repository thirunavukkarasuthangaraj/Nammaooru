import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> _filteredNotifications = [];
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = '';
  bool? _selectedReadStatus;

  // Getters
  List<AppNotification> get notifications => _filteredNotifications;
  List<AppNotification> get allNotifications => _notifications;
  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedType => _selectedType;
  bool? get selectedReadStatus => _selectedReadStatus;

  // Statistics
  int get totalNotifications => _notifications.length;
  int get unreadNotifications => _notifications.where((n) => !n.isRead).length;
  int get actionRequiredNotifications => _notifications.where((n) => n.requiresAction && !n.isRead).length;
  int get highPriorityNotifications => _notifications.where((n) => n.isHighPriority && !n.isRead).length;

  List<String> get notificationTypes => _notifications
      .map((n) => n.type)
      .toSet()
      .toList()
      ..sort();

  // Initialize with mock data
  Future<void> initialize() async {
    await loadNotificationSettings();
    await loadNotifications();
  }

  // Load notifications
  Future<void> loadNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Load from API or use mock data
      await _loadMockNotifications();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load notification settings
  Future<void> loadNotificationSettings() async {
    try {
      final settingsData = StorageService.getNotificationSettings();
      _settings = NotificationSettings.fromJson(settingsData);
      notifyListeners();
    } catch (e) {
      print('Failed to load notification settings: $e');
      _settings = NotificationSettings(); // Use default settings
    }
  }

  // Save notification settings
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      _settings = settings;
      await StorageService.saveNotificationSettings(settings.toJson());
      notifyListeners();
    } catch (e) {
      _setError('Failed to save notification settings: ${e.toString()}');
    }
  }

  // Filter notifications by type
  void filterByType(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  // Filter notifications by read status
  void filterByReadStatus(bool? isRead) {
    _selectedReadStatus = isRead;
    _applyFilters();
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedType = '';
    _selectedReadStatus = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters to notifications
  void _applyFilters() {
    List<AppNotification> filtered = List.from(_notifications);

    // Apply type filter
    if (_selectedType.isNotEmpty) {
      filtered = filtered.where((n) => n.type == _selectedType).toList();
    }

    // Apply read status filter
    if (_selectedReadStatus != null) {
      filtered = filtered.where((n) => n.isRead == _selectedReadStatus).toList();
    }

    // Sort by creation date (newest first), with unread and high priority first
    filtered.sort((a, b) {
      // Prioritize unread notifications
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1;
      }

      // Then prioritize high priority notifications
      if (a.isHighPriority != b.isHighPriority) {
        return a.isHighPriority ? -1 : 1;
      }

      // Finally sort by creation date
      return b.createdAt.compareTo(a.createdAt);
    });

    _filteredNotifications = filtered;
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.markNotificationAsRead(notificationId);

      if (response.isSuccess) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.error ?? 'Failed to mark notification as read');
        return false;
      }
    } catch (e) {
      _setError('Mark as read error: ${e.toString()}');
      return false;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _setLoading(true);
      _clearError();

      // Mark all unread notifications as read
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }

      _applyFilters();
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to mark all as read: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }

  // Add new notification (for real-time updates)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _applyFilters();
    notifyListeners();
  }

  // Handle notification action
  Future<bool> handleNotificationAction(String notificationId, String actionId) async {
    try {
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      final action = notification.actions.firstWhere((a) => a.id == actionId);

      // Handle different action types
      switch (action.action) {
        case 'ACCEPT_ORDER':
          // Handle order acceptance
          return await _handleOrderAction(notification.orderId!, 'ACCEPT');
        case 'REJECT_ORDER':
          // Handle order rejection
          return await _handleOrderAction(notification.orderId!, 'REJECT');
        case 'CALL_CUSTOMER':
          // Handle customer call
          return await _handleCustomerCall(notification.customerId!);
        case 'VIEW_ORDER':
          // Navigate to order details
          return true;
        default:
          return false;
      }
    } catch (e) {
      _setError('Failed to handle notification action: ${e.toString()}');
      return false;
    }
  }

  // Update notification settings for specific category
  Future<void> updateCategorySetting(String category, bool enabled) async {
    final updatedSettings = _settings.copyWith(
      categorySettings: Map.from(_settings.categorySettings)
        ..[category] = enabled,
    );
    await saveNotificationSettings(updatedSettings);
  }

  // Update sound setting for specific category
  Future<void> updateCategorySound(String category, String soundFile) async {
    final updatedSettings = _settings.copyWith(
      soundSettings: Map.from(_settings.soundSettings)
        ..[category] = soundFile,
    );
    await saveNotificationSettings(updatedSettings);
  }

  // Load mock notifications for development
  Future<void> _loadMockNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockNotifications = [
      AppNotification(
        id: 'notif_001',
        title: '🆕 New Order Received!',
        body: 'Order #ORD175864230918 from Rajesh Kumar - ₹372.5',
        type: 'new_order',
        orderId: 'ORD175864230918',
        customerId: 'cust_002',
        priority: 'HIGH',
        requiresAction: true,
        actions: [
          NotificationAction(
            id: 'accept',
            title: 'Accept',
            action: 'ACCEPT_ORDER',
            style: 'PRIMARY',
            icon: 'check',
          ),
          NotificationAction(
            id: 'reject',
            title: 'Reject',
            action: 'REJECT_ORDER',
            style: 'DANGER',
            icon: 'close',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        sound: 'new_order',
      ),
      AppNotification(
        id: 'notif_002',
        title: '💰 Payment Received',
        body: 'Payment of ₹1072.0 received for Order #ORD175864731730',
        type: 'payment_received',
        orderId: 'ORD175864731730',
        customerId: 'cust_001',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        readAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        sound: 'payment_received',
      ),
      AppNotification(
        id: 'notif_003',
        title: '📞 Customer Message',
        body: 'Thirunavukkarasu User: "Please deliver between 2-4 PM"',
        type: 'customer_message',
        orderId: 'ORD175864731730',
        customerId: 'cust_001',
        priority: 'NORMAL',
        requiresAction: true,
        actions: [
          NotificationAction(
            id: 'call',
            title: 'Call Customer',
            action: 'CALL_CUSTOMER',
            style: 'PRIMARY',
            icon: 'phone',
          ),
          NotificationAction(
            id: 'view',
            title: 'View Order',
            action: 'VIEW_ORDER',
            style: 'SECONDARY',
            icon: 'eye',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        sound: 'message_received',
      ),
      AppNotification(
        id: 'notif_004',
        title: '⭐ New Review Received',
        body: 'Priya Sharma rated your shop 5 stars: "Excellent service!"',
        type: 'review_received',
        customerId: 'cust_003',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        readAt: DateTime.now().subtract(const Duration(hours: 18)),
        sound: 'success_chime',
      ),
      AppNotification(
        id: 'notif_005',
        title: '❌ Order Cancelled',
        body: 'Order #ORD175863900609 has been cancelled by Sneha Reddy',
        type: 'order_cancelled',
        orderId: 'ORD175863900609',
        customerId: 'cust_005',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        readAt: DateTime.now().subtract(const Duration(days: 1, hours: 19)),
        sound: 'order_cancelled',
      ),
      AppNotification(
        id: 'notif_006',
        title: '⏰ Preparation Time Alert',
        body: 'Order #ORD175864010712 preparation time exceeded by 15 minutes',
        type: 'time_alert',
        orderId: 'ORD175864010712',
        priority: 'HIGH',
        requiresAction: true,
        actions: [
          NotificationAction(
            id: 'update_customer',
            title: 'Update Customer',
            action: 'CALL_CUSTOMER',
            style: 'PRIMARY',
            icon: 'phone',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        sound: 'urgent_alert',
      ),
      AppNotification(
        id: 'notif_007',
        title: '📦 Low Stock Alert',
        body: 'Potato Chips stock is running low (5 remaining)',
        type: 'low_stock',
        productId: 'prod_1',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        readAt: DateTime.now().subtract(const Duration(hours: 5)),
        sound: 'low_stock',
      ),
      AppNotification(
        id: 'notif_008',
        title: '✅ Order Delivered',
        body: 'Order #ORD175864120815 has been successfully delivered to Priya Sharma',
        type: 'order_delivered',
        orderId: 'ORD175864120815',
        customerId: 'cust_003',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        readAt: DateTime.now().subtract(const Duration(hours: 22)),
        sound: 'success_chime',
      ),
    ];

    _notifications = mockNotifications;
  }

  // Handle order actions from notifications
  Future<bool> _handleOrderAction(String orderId, String action) async {
    try {
      // This would integrate with OrderProvider
      // For now, just mark the notification as handled
      return true;
    } catch (e) {
      _setError('Failed to handle order action: ${e.toString()}');
      return false;
    }
  }

  // Handle customer call action
  Future<bool> _handleCustomerCall(String customerId) async {
    try {
      // This would open the phone app
      // For now, just return success
      return true;
    } catch (e) {
      _setError('Failed to handle customer call: ${e.toString()}');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Get notification by ID
  AppNotification? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get high priority notifications
  List<AppNotification> getHighPriorityNotifications() {
    return _notifications.where((n) => n.isHighPriority).toList();
  }

  // Get notifications requiring action
  List<AppNotification> getActionRequiredNotifications() {
    return _notifications.where((n) => n.requiresAction && !n.isRead).toList();
  }

  // Check if category is enabled
  bool isCategoryEnabled(String category) {
    return _settings.isCategoryEnabled(category);
  }

  // Get sound for category
  String getSoundForCategory(String category) {
    return _settings.getSoundForCategory(category);
  }

  // Clear data
  void clear() {
    _notifications.clear();
    _filteredNotifications.clear();
    _settings = NotificationSettings();
    _selectedType = '';
    _selectedReadStatus = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}