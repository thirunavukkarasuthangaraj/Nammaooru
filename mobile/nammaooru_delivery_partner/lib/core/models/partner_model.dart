import 'package:geolocator/geolocator.dart';

class Partner {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String? profileImage;
  final double rating;
  final int totalDeliveries;
  final DateTime joinDate;
  final String vehicleType;
  final String licenseNumber;
  final BankDetails bankDetails;
  final bool isOnline;
  final Position? currentLocation;
  final DocumentVerification? documentVerification;
  final PerformanceMetrics? performanceMetrics;

  const Partner({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.profileImage,
    required this.rating,
    required this.totalDeliveries,
    required this.joinDate,
    required this.vehicleType,
    required this.licenseNumber,
    required this.bankDetails,
    required this.isOnline,
    this.currentLocation,
    this.documentVerification,
    this.performanceMetrics,
  });

  Partner copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? profileImage,
    double? rating,
    int? totalDeliveries,
    DateTime? joinDate,
    String? vehicleType,
    String? licenseNumber,
    BankDetails? bankDetails,
    bool? isOnline,
    Position? currentLocation,
    DocumentVerification? documentVerification,
    PerformanceMetrics? performanceMetrics,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      joinDate: joinDate ?? this.joinDate,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bankDetails: bankDetails ?? this.bankDetails,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      documentVerification: documentVerification ?? this.documentVerification,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
    );
  }

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      vehicleType: json['vehicleType'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      bankDetails: BankDetails.fromJson(json['bankDetails'] ?? {}),
      isOnline: json['isOnline'] ?? false,
      currentLocation: json['currentLocation'] != null 
          ? Position.fromMap(json['currentLocation']) 
          : null,
      documentVerification: json['documentVerification'] != null
          ? DocumentVerification.fromJson(json['documentVerification'])
          : null,
      performanceMetrics: json['performanceMetrics'] != null
          ? PerformanceMetrics.fromJson(json['performanceMetrics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImage': profileImage,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'joinDate': joinDate.toIso8601String(),
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'bankDetails': bankDetails.toJson(),
      'isOnline': isOnline,
      'currentLocation': currentLocation?.toJson(),
      'documentVerification': documentVerification?.toJson(),
      'performanceMetrics': performanceMetrics?.toJson(),
    };
  }
}

class BankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;

  const BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
    };
  }
}

class DocumentVerification {
  final bool aadhaarVerified;
  final bool panVerified;
  final bool licenseVerified;
  final bool vehicleRcVerified;

  const DocumentVerification({
    required this.aadhaarVerified,
    required this.panVerified,
    required this.licenseVerified,
    required this.vehicleRcVerified,
  });

  factory DocumentVerification.fromJson(Map<String, dynamic> json) {
    return DocumentVerification(
      aadhaarVerified: json['aadhaarVerified'] ?? false,
      panVerified: json['panVerified'] ?? false,
      licenseVerified: json['licenseVerified'] ?? false,
      vehicleRcVerified: json['vehicleRcVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aadhaarVerified': aadhaarVerified,
      'panVerified': panVerified,
      'licenseVerified': licenseVerified,
      'vehicleRcVerified': vehicleRcVerified,
    };
  }
}

class PerformanceMetrics {
  final double acceptanceRate;
  final double onTimeDeliveryRate;
  final double cancellationRate;
  final int completedDeliveries;
  final Duration totalOnlineTime;

  const PerformanceMetrics({
    required this.acceptanceRate,
    required this.onTimeDeliveryRate,
    required this.cancellationRate,
    required this.completedDeliveries,
    required this.totalOnlineTime,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      acceptanceRate: (json['acceptanceRate'] ?? 0.0).toDouble(),
      onTimeDeliveryRate: (json['onTimeDeliveryRate'] ?? 0.0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0.0).toDouble(),
      completedDeliveries: json['completedDeliveries'] ?? 0,
      totalOnlineTime: Duration(seconds: json['totalOnlineTimeSeconds'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acceptanceRate': acceptanceRate,
      'onTimeDeliveryRate': onTimeDeliveryRate,
      'cancellationRate': cancellationRate,
      'completedDeliveries': completedDeliveries,
      'totalOnlineTimeSeconds': totalOnlineTime.inSeconds,
    };
  }
}