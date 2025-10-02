class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle both backend format (message/status) and Firebase format (body/isRead)
    final String bodyText = json['body'] ?? json['message'] ?? '';

    // Convert status enum to boolean (UNREAD/READ -> false/true)
    bool isReadStatus = false;
    if (json.containsKey('status')) {
      final status = json['status'].toString().toUpperCase();
      isReadStatus = status == 'READ';
    } else if (json.containsKey('isRead')) {
      isReadStatus = json['isRead'] ?? false;
    }

    // Convert type enum to lowercase string
    final String typeStr = json['type']?.toString().toLowerCase() ?? 'general';

    // Parse createdAt from various formats
    DateTime createdTime;
    try {
      createdTime = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      createdTime = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: bodyText,
      type: typeStr,
      createdAt: createdTime,
      isRead: isReadStatus,
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}