class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final bool requiresAction;
  final bool isHighPriority;
  final Map<String, dynamic>? data;
  final String? imageUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.requiresAction = false,
    this.isHighPriority = false,
    this.data,
    this.imageUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      requiresAction: json['requiresAction'] ?? false,
      isHighPriority: json['isHighPriority'] ?? false,
      data: json['data'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'requiresAction': requiresAction,
      'isHighPriority': isHighPriority,
      'data': data,
      'imageUrl': imageUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    bool? requiresAction,
    bool? isHighPriority,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      requiresAction: requiresAction ?? this.requiresAction,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}