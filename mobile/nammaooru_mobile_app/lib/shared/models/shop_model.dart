import 'package:flutter/material.dart';

class ShopModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final String phoneNumber;
  final String email;
  final String category;
  final List<String> serviceTypes;
  final ShopAddress address;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final Map<String, OpeningHours> openingHours;
  final double deliveryRadius;
  final double minOrderAmount;
  final double deliveryFee;
  final int estimatedDeliveryTime;
  final List<String> paymentMethods;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.phoneNumber,
    required this.email,
    required this.category,
    required this.serviceTypes,
    required this.address,
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.openingHours = const {},
    this.deliveryRadius = 5.0,
    this.minOrderAmount = 0.0,
    this.deliveryFee = 0.0,
    this.estimatedDeliveryTime = 30,
    this.paymentMethods = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      address: ShopAddress.fromJson(json['address'] ?? {}),
      images: List<String>.from(json['images'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      openingHours: (json['openingHours'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, OpeningHours.fromJson(value))),
      deliveryRadius: (json['deliveryRadius'] ?? 5.0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] ?? 30,
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'category': category,
      'serviceTypes': serviceTypes,
      'address': address.toJson(),
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'openingHours': openingHours.map((key, value) => MapEntry(key, value.toJson())),
      'deliveryRadius': deliveryRadius,
      'minOrderAmount': minOrderAmount,
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'paymentMethods': paymentMethods,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  bool isOpenAt(DateTime dateTime) {
    final dayName = _getDayName(dateTime.weekday);
    final hours = openingHours[dayName];
    
    if (hours == null || !hours.isOpen) return false;
    
    final currentTime = TimeOfDay.fromDateTime(dateTime);
    return _isTimeBetween(currentTime, hours.openTime, hours.closeTime);
  }
  
  String _getDayName(int weekday) {
    const days = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday];
  }
  
  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

class ShopAddress {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? landmark;
  
  ShopAddress({
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });
  
  factory ShopAddress.fromJson(Map<String, dynamic> json) {
    return ShopAddress(
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      landmark: json['landmark'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
    };
  }
  
  String get fullAddress {
    final parts = [street, area, city, state, pincode];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }
}

class OpeningHours {
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  
  OpeningHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });
  
  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      isOpen: json['isOpen'] ?? false,
      openTime: _parseTimeOfDay(json['openTime'] ?? '09:00'),
      closeTime: _parseTimeOfDay(json['closeTime'] ?? '21:00'),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': _formatTimeOfDay(openTime),
      'closeTime': _formatTimeOfDay(closeTime),
    };
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
}