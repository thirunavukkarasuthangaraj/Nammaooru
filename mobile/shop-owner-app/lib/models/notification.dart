class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String priority;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.priority = 'normal',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'priority': priority,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? priority,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Helper methods for notification provider
  bool get requiresAction => type == 'order' || type == 'payment' || type == 'alert';
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
}

// Type alias for backward compatibility
typedef AppNotification = NotificationModel;

class NotificationSettings {
  final bool enableSound;
  final bool enableVibration;
  final bool enableBanner;
  final Map<String, bool> typeSettings;

  NotificationSettings({
    this.enableSound = true,
    this.enableVibration = true,
    this.enableBanner = true,
    Map<String, bool>? typeSettings,
  }) : typeSettings = typeSettings ?? {
    'order': true,
    'payment': true,
    'alert': true,
    'general': true,
  };

  NotificationSettings copyWith({
    bool? enableSound,
    bool? enableVibration,
    bool? enableBanner,
    Map<String, bool>? typeSettings,
  }) {
    return NotificationSettings(
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableBanner: enableBanner ?? this.enableBanner,
      typeSettings: typeSettings ?? this.typeSettings,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableSound: json['enableSound'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableBanner: json['enableBanner'] ?? true,
      typeSettings: json['typeSettings'] != null
          ? Map<String, bool>.from(json['typeSettings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableBanner': enableBanner,
      'typeSettings': typeSettings,
    };
  }
}

class NotificationAction {
  final String id;
  final String label;
  final String action;

  NotificationAction({
    required this.id,
    required this.label,
    required this.action,
  });
}