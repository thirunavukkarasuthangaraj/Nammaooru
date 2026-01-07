import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ScrollController _scrollController = ScrollController();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isMarkingAllRead = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupFirebaseListener();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
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
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
    });

    try {
      final response = await _notificationApi.getNotifications(
        page: 0,
        size: _pageSize,
      );

      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        final notificationsData = response['data'];

        if (notificationsData is List) {
          setState(() {
            _notifications = _notificationApi.parseNotifications(notificationsData);
            _hasMoreData = notificationsData.length >= _pageSize;

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

          await _applyStoredReadStatus();
        } else {
          _loadDemoNotifications();
        }
      } else {
        _loadDemoNotifications();
      }
    } catch (e) {
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

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _notificationApi.getNotifications(
        page: nextPage,
        size: _pageSize,
      );

      if (mounted && response['statusCode'] == '0000' && response['data'] != null) {
        final notificationsData = response['data'];

        if (notificationsData is List && notificationsData.isNotEmpty) {
          final newNotifications = _notificationApi.parseNotifications(notificationsData);

          setState(() {
            _currentPage = nextPage;
            _hasMoreData = notificationsData.length >= _pageSize;

            // Add only non-duplicate notifications
            for (final notification in newNotifications) {
              if (!_notifications.any((n) => n.id == notification.id)) {
                _notifications.add(notification);
              }
            }

            // Sort by latest first
            _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });

          await _applyStoredReadStatus();
        } else {
          setState(() => _hasMoreData = false);
        }
      } else {
        setState(() => _hasMoreData = false);
      }
    } catch (e) {
      // Silently fail for load more
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _loadDemoNotifications() async {
    // Show only Firebase local notifications, no demo data
    final firebaseNotifications = FirebaseNotificationService.getLocalNotifications();
    setState(() {
      _notifications = firebaseNotifications;
      // Sort by newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    // Apply stored read status for Firebase notifications
    await _applyStoredReadStatus();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    // Check if this is a backend notification (numeric ID) or Firebase-only notification
    final isBackendNotification = _isNumericId(notification.id);

    try {
      // Only call backend API for notifications with numeric IDs
      if (isBackendNotification) {
        final response = await _notificationApi.markAsRead(notification.id);

        if (mounted) {
          if (response['statusCode'] == '0000') {
            // Reload notifications from backend to get updated status
            await _loadNotifications();
          } else {
            // If API call failed, just update UI locally
            setState(() {
              _updateNotificationReadStatus(notification.id, true);
            });
            Helpers.showSnackBar(context, 'Marked as read locally', isError: false);
          }
        }
      } else {
        // Firebase-only notification - update UI locally and persist to shared preferences
        if (mounted) {
          setState(() {
            _updateNotificationReadStatus(notification.id, true);
          });
          // Store in shared preferences for persistence
          await _saveReadNotificationId(notification.id);
        }
      }
    } catch (e) {
      // Still update UI even if API fails
      if (mounted) {
        setState(() {
          _updateNotificationReadStatus(notification.id, true);
        });
        if (!isBackendNotification) {
          await _saveReadNotificationId(notification.id);
        }
      }
    }
  }

  bool _isNumericId(String id) {
    if (id.isEmpty) return false;
    return int.tryParse(id) != null;
  }

  void _updateNotificationReadStatus(String notificationId, bool isRead) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        createdAt: _notifications[index].createdAt,
        isRead: isRead,
        data: _notifications[index].data,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);

    try {
      // Check if there are any backend notifications (with numeric IDs)
      final hasBackendNotifications = _notifications.any((n) => _isNumericId(n.id) && !n.isRead);
      final hasFirebaseNotifications = _notifications.any((n) => !_isNumericId(n.id) && !n.isRead);

      // Call API to mark all backend notifications as read
      if (hasBackendNotifications) {
        final response = await _notificationApi.markAllAsRead();

        if (mounted) {
          if (response['statusCode'] == '0000') {
            // Save Firebase notification IDs to shared preferences
            if (hasFirebaseNotifications) {
              for (var notification in _notifications) {
                if (!_isNumericId(notification.id)) {
                  await _saveReadNotificationId(notification.id);
                }
              }
            }
            // Reload notifications to get updated status from backend
            await _loadNotifications();
            Helpers.showSnackBar(context, 'All notifications marked as read');
          } else {
            // If API failed, update UI locally
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
        }
      } else if (hasFirebaseNotifications) {
        // Only Firebase notifications - update UI locally and persist
        if (mounted) {
          for (var notification in _notifications) {
            if (!_isNumericId(notification.id)) {
              await _saveReadNotificationId(notification.id);
            }
          }
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
          Helpers.showSnackBar(context, 'All notifications marked as read');
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

  // Save Firebase notification ID as read in shared preferences
  Future<void> _saveReadNotificationId(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];
      if (!readIds.contains(notificationId)) {
        readIds.add(notificationId);
        await prefs.setStringList('read_notification_ids', readIds);
      }
    } catch (e) {
      // Ignore errors in saving to shared preferences
    }
  }

  // Get list of read Firebase notification IDs from shared preferences
  Future<Set<String>> _getReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];
      return readIds.toSet();
    } catch (e) {
      return {};
    }
  }

  // Apply stored read status to Firebase notifications
  Future<void> _applyStoredReadStatus() async {
    final readIds = await _getReadNotificationIds();
    if (readIds.isNotEmpty) {
      setState(() {
        _notifications = _notifications.map((notification) {
          if (readIds.contains(notification.id)) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: true,
              data: notification.data,
            );
          }
          return notification;
        }).toList();
      });
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
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            // Loading indicator at bottom
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                        strokeWidth: 2,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
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