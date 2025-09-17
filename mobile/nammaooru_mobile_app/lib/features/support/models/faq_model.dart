class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> tags;
  final int viewCount;
  final bool isHelpful;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? videoUrl;
  final List<String> relatedFAQs;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.tags,
    required this.viewCount,
    required this.isHelpful,
    required this.createdAt,
    this.updatedAt,
    this.videoUrl,
    required this.relatedFAQs,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] ?? 0,
      isHelpful: json['isHelpful'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      videoUrl: json['videoUrl'],
      relatedFAQs: List<String>.from(json['relatedFAQs'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'tags': tags,
      'viewCount': viewCount,
      'isHelpful': isHelpful,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'videoUrl': videoUrl,
      'relatedFAQs': relatedFAQs,
    };
  }
}

class FAQCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int faqCount;
  final int order;

  FAQCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.faqCount,
    required this.order,
  });

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      faqCount: json['faqCount'] ?? 0,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'faqCount': faqCount,
      'order': order,
    };
  }
}

class ContactMethod {
  final String id;
  final String name;
  final String type; // phone, email, whatsapp, chat
  final String value;
  final String description;
  final String icon;
  final bool isAvailable;
  final String? availableHours;
  final int responseTime; // in minutes
  final int order;

  ContactMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.description,
    required this.icon,
    required this.isAvailable,
    this.availableHours,
    required this.responseTime,
    required this.order,
  });

  factory ContactMethod.fromJson(Map<String, dynamic> json) {
    return ContactMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      availableHours: json['availableHours'],
      responseTime: json['responseTime'] ?? 60,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'description': description,
      'icon': icon,
      'isAvailable': isAvailable,
      'availableHours': availableHours,
      'responseTime': responseTime,
      'order': order,
    };
  }
}