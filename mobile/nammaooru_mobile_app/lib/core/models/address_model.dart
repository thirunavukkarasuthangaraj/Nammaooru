import 'dart:convert';

class SavedAddress {
  final String id;
  final String name;
  final String lastName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String addressType;
  final bool isDefault;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  SavedAddress({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.addressType,
    this.isDefault = false,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$name $lastName';

  String get fullAddress => [
    addressLine1,
    if (addressLine2.isNotEmpty) addressLine2,
    if (landmark.isNotEmpty) landmark,
    city,
    state,
    pincode,
  ].join(', ');

  String get shortAddress => '$addressLine1, $city';

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    // Handle both mobile app format and backend format
    String firstName = json['name'] ?? '';
    String lastName = json['lastName'] ?? '';
    String phone = json['phone'] ?? json['contactMobileNumber'] ?? '';

    // If backend format (contactPersonName), split it into first and last name
    if (json['contactPersonName'] != null && json['contactPersonName'].toString().isNotEmpty) {
      final fullName = json['contactPersonName'].toString().trim();
      final nameParts = fullName.split(' ');
      if (nameParts.length >= 2) {
        firstName = nameParts.first;
        lastName = nameParts.sublist(1).join(' ');
      } else if (nameParts.length == 1) {
        firstName = nameParts.first;
        lastName = '';
      }
    }

    return SavedAddress(
      id: (json['id'] ?? '').toString(),
      name: firstName,
      lastName: lastName,
      phone: phone,
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? 'Tirupattur',
      state: json['state'] ?? 'Tamil Nadu',
      pincode: json['pincode'] ?? json['postalCode'] ?? '',
      addressType: json['addressType'] ?? 'HOME',
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Mobile app format
      'id': id,
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': addressType,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      // Backend format (for compatibility)
      'contactPersonName': fullName,
      'contactMobileNumber': phone,
      'postalCode': pincode,
    };
  }

  SavedAddress copyWith({
    String? id,
    String? name,
    String? lastName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    String? addressType,
    bool? isDefault,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      addressType: addressType ?? this.addressType,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'SavedAddress(id: $id, name: $fullName, address: $shortAddress, type: $addressType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedAddress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}