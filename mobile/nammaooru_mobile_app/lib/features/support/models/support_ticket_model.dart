class SupportTicket {
  final String id;
  final String userId;
  final String userType; // customer, delivery_partner, shop_owner
  final String title;
  final String description;
  final SupportCategory category;
  final SupportPriority priority;
  final SupportStatus status;
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.metadata,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: SupportCategory.fromString(json['category'] ?? 'general'),
      priority: SupportPriority.fromString(json['priority'] ?? 'medium'),
      status: SupportStatus.fromString(json['status'] ?? 'open'),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => SupportMessage.fromJson(msg))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      assignedTo: json['assignedTo'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'title': title,
      'description': description,
      'category': category.value,
      'priority': priority.value,
      'status': status.value,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'metadata': metadata,
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userType,
    String? title,
    String? description,
    SupportCategory? category,
    SupportPriority? priority,
    SupportStatus? status,
    List<SupportMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    Map<String, dynamic>? metadata,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      metadata: metadata ?? this.metadata,
    );
  }
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType; // user, agent, system
  final String message;
  final List<String> attachments;
  final DateTime createdAt;
  final bool isRead;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.attachments,
    required this.createdAt,
    required this.isRead,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? 'user',
      message: json['message'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

enum SupportCategory {
  general,
  orderIssue,
  paymentIssue,
  deliveryIssue,
  accountIssue,
  technicalIssue,
  feedback,
  featureRequest;

  static SupportCategory fromString(String value) {
    return SupportCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => SupportCategory.general,
    );
  }

  String get value {
    switch (this) {
      case SupportCategory.general:
        return 'general';
      case SupportCategory.orderIssue:
        return 'order_issue';
      case SupportCategory.paymentIssue:
        return 'payment_issue';
      case SupportCategory.deliveryIssue:
        return 'delivery_issue';
      case SupportCategory.accountIssue:
        return 'account_issue';
      case SupportCategory.technicalIssue:
        return 'technical_issue';
      case SupportCategory.feedback:
        return 'feedback';
      case SupportCategory.featureRequest:
        return 'feature_request';
    }
  }

  String get displayName {
    switch (this) {
      case SupportCategory.general:
        return 'General Inquiry';
      case SupportCategory.orderIssue:
        return 'Order Issue';
      case SupportCategory.paymentIssue:
        return 'Payment Issue';
      case SupportCategory.deliveryIssue:
        return 'Delivery Issue';
      case SupportCategory.accountIssue:
        return 'Account Issue';
      case SupportCategory.technicalIssue:
        return 'Technical Issue';
      case SupportCategory.feedback:
        return 'Feedback';
      case SupportCategory.featureRequest:
        return 'Feature Request';
    }
  }
}

enum SupportPriority {
  low,
  medium,
  high,
  urgent;

  static SupportPriority fromString(String value) {
    return SupportPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => SupportPriority.medium,
    );
  }

  String get value {
    switch (this) {
      case SupportPriority.low:
        return 'low';
      case SupportPriority.medium:
        return 'medium';
      case SupportPriority.high:
        return 'high';
      case SupportPriority.urgent:
        return 'urgent';
    }
  }

  String get displayName {
    switch (this) {
      case SupportPriority.low:
        return 'Low';
      case SupportPriority.medium:
        return 'Medium';
      case SupportPriority.high:
        return 'High';
      case SupportPriority.urgent:
        return 'Urgent';
    }
  }
}

enum SupportStatus {
  open,
  inProgress,
  waitingForUser,
  resolved,
  closed;

  static SupportStatus fromString(String value) {
    return SupportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SupportStatus.open,
    );
  }

  String get value {
    switch (this) {
      case SupportStatus.open:
        return 'open';
      case SupportStatus.inProgress:
        return 'in_progress';
      case SupportStatus.waitingForUser:
        return 'waiting_for_user';
      case SupportStatus.resolved:
        return 'resolved';
      case SupportStatus.closed:
        return 'closed';
    }
  }

  String get displayName {
    switch (this) {
      case SupportStatus.open:
        return 'Open';
      case SupportStatus.inProgress:
        return 'In Progress';
      case SupportStatus.waitingForUser:
        return 'Waiting for Response';
      case SupportStatus.resolved:
        return 'Resolved';
      case SupportStatus.closed:
        return 'Closed';
    }
  }
}