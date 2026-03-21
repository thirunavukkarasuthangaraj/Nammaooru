class DeliveryFeeCalculation {
  final bool success;
  final double distance;
  final double deliveryFee;
  final double partnerCommission;
  final String? message;

  DeliveryFeeCalculation({
    required this.success,
    required this.distance,
    required this.deliveryFee,
    required this.partnerCommission,
    this.message,
  });

  factory DeliveryFeeCalculation.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeCalculation(
      success: json['success'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      partnerCommission: (json['partnerCommission'] ?? 0.0).toDouble(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'distance': distance,
      'deliveryFee': deliveryFee,
      'partnerCommission': partnerCommission,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'DeliveryFeeCalculation{success: $success, distance: ${distance.toStringAsFixed(2)}km, deliveryFee: ₹${deliveryFee.toStringAsFixed(0)}, partnerCommission: ₹${partnerCommission.toStringAsFixed(0)}}';
  }
}

class DeliveryFeeRange {
  final int? id;
  final double minDistanceKm;
  final double maxDistanceKm;
  final double deliveryFee;
  final double partnerCommission;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeliveryFeeRange({
    this.id,
    required this.minDistanceKm,
    required this.maxDistanceKm,
    required this.deliveryFee,
    required this.partnerCommission,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryFeeRange.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeRange(
      id: json['id'],
      minDistanceKm: (json['minDistanceKm'] ?? 0.0).toDouble(),
      maxDistanceKm: (json['maxDistanceKm'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      partnerCommission: (json['partnerCommission'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minDistanceKm': minDistanceKm,
      'maxDistanceKm': maxDistanceKm,
      'deliveryFee': deliveryFee,
      'partnerCommission': partnerCommission,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get distanceRangeText {
    if (maxDistanceKm >= 999) {
      return '${minDistanceKm.toStringAsFixed(0)}+ km';
    }
    return '${minDistanceKm.toStringAsFixed(0)} - ${maxDistanceKm.toStringAsFixed(0)} km';
  }

  @override
  String toString() {
    return 'DeliveryFeeRange{$distanceRangeText: ₹${deliveryFee.toStringAsFixed(0)}}';
  }
}

class CustomerLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  CustomerLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  factory CustomerLocation.fromJson(Map<String, dynamic> json) {
    return CustomerLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'CustomerLocation{lat: $latitude, lng: $longitude, address: $address}';
  }
}