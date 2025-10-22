import 'package:flutter/material.dart';
import '../../../shared/models/notification_model.dart';
import '../../../services/notification_api_service.dart';
import '../../../services/firebase_notification_service.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationApiService _notificationApi = NotificationApiService.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupFirebaseListener();
  }

  void _setupFirebaseListener() {
    // Listen for new Firebase notifications
    FirebaseNotificationService.addListener((notification) {
      if (mounted) {
        setState(() {
          // Add new notification to the top of the list
          _notifications.insert(0, notification);
          // Keep only latest 100 notifications
          if (_notifications.length > 100) {
            _notifications.removeAt(100);
          }
        });

        // Show snackbar for new notification
        Helpers.showSnackBar(
          context,
          '🔔 ${notification.title}',
          isError: false,
        );
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final response = await _notificationApi.getNotifications(
        page: 0,
        size: 50, // Load more notifications
      );

      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        // response['data'] is now the actual notifications list from backend
        final notificationsData = response['data'];

        if (notificationsData is List) {
          setState(() {
            _notifications = _notificationApi.parseNotifications(notificationsData);

            // Merge with Firebase local notifications (avoid duplicates)
            final firebaseNotifications = FirebaseNotificationService.getLocalNotifications();
            for (final fbNotification in firebaseNotifications) {
              if (!_notifications.any((n) => n.id == fbNotification.id)) {
                _notifications.add(fbNotification);
              }
            }

            // Sort by latest first
            _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
        } else {
          // Fallback to demo data if API response is unexpected
          _loadDemoNotifications();
        }
      } else {
        // Fallback to demo data if API fails
        _loadDemoNotifications();
      }
    } catch (e) {
      // Fallback to demo data on error
      _loadDemoNotifications();

      if (mounted) {
        Helpers.showSnackBar(context, 'Using demo data - API not available', isError: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadDemoNotifications() {
    // Show only Firebase local notifications, no demo data
    final firebaseNotifications = FirebaseNotificationService.getLocalNotifications();
    setState(() {
      _notifications = firebaseNotifications;
      // Sort by newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      // Call API to mark as read
      final response = await _notificationApi.markAsRead(notification.id);

      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: true,
              data: notification.data,
            );
          }
        });

        if (response['statusCode'] != '0000') {
          // Show error message if API call failed but still update UI
          Helpers.showSnackBar(context, 'Marked as read locally', isError: false);
        }
      }
    } catch (e) {
      // Still update UI even if API fails
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: true,
              data: notification.data,
            );
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);

    try {
      // Call API to mark all as read
      final response = await _notificationApi.markAllAsRead();

      if (mounted) {
        setState(() {
          _notifications = _notifications.map((notification) =>
            NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: true,
              data: notification.data,
            )
          ).toList();
        });

        if (response['statusCode'] == '0000') {
          Helpers.showSnackBar(context, 'All notifications marked as read');
        } else {
          Helpers.showSnackBar(context, 'Marked as read locally', isError: false);
        }
      }
    } catch (e) {
      // Still update UI even if API fails
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((notification) =>
            NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: true,
              data: notification.data,
            )
          ).toList();
        });

        Helpers.showSnackBar(context, 'Marked as read locally', isError: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'அறிவிப்புகள் / Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              icon: _isMarkingAllRead
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.done_all, color: Colors.white, size: 20),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
        ? const LoadingWidget()
        : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_outlined,
                  size: 60,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'எந்த அறிவிப்பும் இல்லை / No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! New notifications will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF4CAF50),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead
          ? null
          : Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markAsRead(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getNotificationGradient(notification.type),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getNotificationEmoji(notification.type),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with unread indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Body text
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Time and type badge
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getNotificationGradient(notification.type)[0].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeDisplayName(notification.type),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getNotificationGradient(notification.type)[0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNotificationEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return '📦';
      case 'delivery':
        return '✅';
      case 'shop':
        return '🏪';
      case 'promotion':
        return '💥';
      case 'welcome':
        return '🙏';
      case 'payment':
        return '💳';
      case 'review':
        return '⭐';
      default:
        return '🔔';
    }
  }

  List<Color> _getNotificationGradient(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
      case 'delivery':
        return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
      case 'shop':
        return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
      case 'promotion':
        return [const Color(0xFFFF5722), const Color(0xFFFF8A65)];
      case 'welcome':
        return [const Color(0xFF795548), const Color(0xFFA1887F)];
      case 'payment':
        return [const Color(0xFF607D8B), const Color(0xFF90A4AE)];
      case 'review':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      default:
        return [const Color(0xFF757575), const Color(0xFFBDBDBD)];
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return 'ORDER';
      case 'delivery':
        return 'DELIVERY';
      case 'shop':
        return 'SHOP';
      case 'promotion':
        return 'OFFER';
      case 'welcome':
        return 'WELCOME';
      case 'payment':
        return 'PAYMENT';
      case 'review':
        return 'REVIEW';
      default:
        return 'GENERAL';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}