import 'package:flutter/material.dart';

// Alias for compatibility with existing code
typedef Shop = ShopProfile;

class ShopProfile {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final String status;
  final String category;
  final String? logo;
  final List<String> images;
  final ShopAddress address;
  final ShopContact contact;
  final BusinessHours businessHours;
  final List<String> specializations;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  ShopProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.category,
    this.logo,
    this.images = const [],
    required this.address,
    required this.contact,
    required this.businessHours,
    this.specializations = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.registeredAt,
    required this.updatedAt,
    this.settings,
    this.metadata,
  });

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      status: json['status'] ?? 'PENDING',
      category: json['category'] ?? '',
      logo: json['logo'],
      images: List<String>.from(json['images'] ?? []),
      address: ShopAddress.fromJson(json['address'] ?? {}),
      contact: ShopContact.fromJson(json['contact'] ?? {}),
      businessHours: BusinessHours.fromJson(json['businessHours'] ?? {}),
      specializations: List<String>.from(json['specializations'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      registeredAt: DateTime.parse(
        json['registeredAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      settings: json['settings'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': status,
      'category': category,
      'logo': logo,
      'images': images,
      'address': address.toJson(),
      'contact': contact.toJson(),
      'businessHours': businessHours.toJson(),
      'specializations': specializations,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'registeredAt': registeredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'settings': settings,
      'metadata': metadata,
    };
  }

  ShopProfile copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? ownerName,
    String? status,
    String? category,
    String? logo,
    List<String>? images,
    ShopAddress? address,
    ShopContact? contact,
    BusinessHours? businessHours,
    List<String>? specializations,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isActive,
    DateTime? registeredAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ShopProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      category: category ?? this.category,
      logo: logo ?? this.logo,
      images: images ?? this.images,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      businessHours: businessHours ?? this.businessHours,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  bool get isCurrentlyOpen => businessHours.isCurrentlyOpen();

  @override
  String toString() {
    return 'ShopProfile(id: $id, name: $name, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopProfile && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

class ShopAddress {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  ShopAddress({
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory ShopAddress.fromJson(Map<String, dynamic> json) {
    return ShopAddress(
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      landmark: json['landmark'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddress {
    final parts = [street, area, landmark, city, state, pincode, country];
    return parts.where((part) => part != null && part.isNotEmpty).join(', ');
  }

  @override
  String toString() {
    return fullAddress;
  }
}

class ShopContact {
  final String phone;
  final String? alternatePhone;
  final String email;
  final String? website;
  final Map<String, String> socialMedia;

  ShopContact({
    required this.phone,
    this.alternatePhone,
    required this.email,
    this.website,
    this.socialMedia = const {},
  });

  factory ShopContact.fromJson(Map<String, dynamic> json) {
    return ShopContact(
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'],
      email: json['email'] ?? '',
      website: json['website'],
      socialMedia: Map<String, String>.from(json['socialMedia'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'website': website,
      'socialMedia': socialMedia,
    };
  }

  @override
  String toString() {
    return 'ShopContact(phone: $phone, email: $email)';
  }
}

class BusinessHours {
  final Map<String, DayHours> weekdays;
  final bool isAlwaysOpen;
  final List<String> holidays;
  final String timezone;

  BusinessHours({
    required this.weekdays,
    this.isAlwaysOpen = false,
    this.holidays = const [],
    this.timezone = 'Asia/Kolkata',
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    final weekdaysJson = json['weekdays'] as Map<String, dynamic>? ?? {};
    final weekdays = <String, DayHours>{};

    for (final entry in weekdaysJson.entries) {
      weekdays[entry.key] = DayHours.fromJson(entry.value);
    }

    return BusinessHours(
      weekdays: weekdays,
      isAlwaysOpen: json['isAlwaysOpen'] ?? false,
      holidays: List<String>.from(json['holidays'] ?? []),
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() {
    final weekdaysJson = <String, dynamic>{};
    for (final entry in weekdays.entries) {
      weekdaysJson[entry.key] = entry.value.toJson();
    }

    return {
      'weekdays': weekdaysJson,
      'isAlwaysOpen': isAlwaysOpen,
      'holidays': holidays,
      'timezone': timezone,
    };
  }

  bool isCurrentlyOpen() {
    if (isAlwaysOpen) return true;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = weekdays[dayName];

    if (todayHours == null || !todayHours.isOpen) {
      return false;
    }

    final currentTime = TimeOfDay.fromDateTime(now);
    return todayHours.isWithinHours(currentTime);
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  @override
  String toString() {
    return 'BusinessHours(isAlwaysOpen: $isAlwaysOpen, weekdays: $weekdays)';
  }
}

class DayHours {
  final bool isOpen;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final List<TimeSlot> breaks;

  DayHours({
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breaks = const [],
  });

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] != null
          ? _parseTimeOfDay(json['openTime'])
          : null,
      closeTime: json['closeTime'] != null
          ? _parseTimeOfDay(json['closeTime'])
          : null,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((breakSlot) => TimeSlot.fromJson(breakSlot))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime != null ? _formatTimeOfDay(openTime!) : null,
      'closeTime': closeTime != null ? _formatTimeOfDay(closeTime!) : null,
      'breaks': breaks.map((breakSlot) => breakSlot.toJson()).toList(),
    };
  }

  bool isWithinHours(TimeOfDay time) {
    if (!isOpen || openTime == null || closeTime == null) {
      return false;
    }

    final timeMinutes = time.hour * 60 + time.minute;
    final openMinutes = openTime!.hour * 60 + openTime!.minute;
    final closeMinutes = closeTime!.hour * 60 + closeTime!.minute;

    return timeMinutes >= openMinutes && timeMinutes <= closeMinutes;
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    if (!isOpen) return 'Closed';
    return '${_formatTimeOfDay(openTime!)} - ${_formatTimeOfDay(closeTime!)}';
  }
}

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DayHours._parseTimeOfDay(json['startTime']),
      endTime: DayHours._parseTimeOfDay(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': DayHours._formatTimeOfDay(startTime),
      'endTime': DayHours._formatTimeOfDay(endTime),
    };
  }

  @override
  String toString() {
    return '${DayHours._formatTimeOfDay(startTime)} - ${DayHours._formatTimeOfDay(endTime)}';
  }
}