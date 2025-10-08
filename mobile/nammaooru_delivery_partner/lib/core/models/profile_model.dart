import 'package:flutter/material.dart';

class Profile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final Address address;
  final VehicleInfo vehicleInfo;
  final BankDetails bankDetails;
  final List<Document> documents;
  final ProfileStats stats;
  final DateTime joinedDate;
  final ProfileStatus status;
  final double rating;
  final int totalDeliveries;
  final String emergencyContactName;
  final String emergencyContactNumber;

  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.address,
    required this.vehicleInfo,
    required this.bankDetails,
    required this.documents,
    required this.stats,
    required this.joinedDate,
    required this.status,
    required this.rating,
    required this.totalDeliveries,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      address: Address.fromJson(json['address'] ?? {}),
      vehicleInfo: VehicleInfo.fromJson(json['vehicleInfo'] ?? {}),
      bankDetails: BankDetails.fromJson(json['bankDetails'] ?? {}),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((doc) => Document.fromJson(doc))
          .toList(),
      stats: ProfileStats.fromJson(json['stats'] ?? {}),
      joinedDate: DateTime.parse(json['joinedDate'] ?? DateTime.now().toIso8601String()),
      status: ProfileStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProfileStatus.pending,
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactNumber: json['emergencyContactNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'address': address.toJson(),
      'vehicleInfo': vehicleInfo.toJson(),
      'bankDetails': bankDetails.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'stats': stats.toJson(),
      'joinedDate': joinedDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
    };
  }

  String get formattedRating {
    return '⭐${rating.toStringAsFixed(1)}';
  }

  String get formattedJoinedDate {
    final now = DateTime.now();
    final difference = now.difference(joinedDate);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}

class VehicleInfo {
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleColor;
  final String? insuranceNumber;
  final DateTime? insuranceExpiry;

  const VehicleInfo({
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    this.insuranceNumber,
    this.insuranceExpiry,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleBrand: json['vehicleBrand'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleYear: json['vehicleYear'] ?? 0,
      vehicleColor: json['vehicleColor'] ?? '',
      insuranceNumber: json['insuranceNumber'],
      insuranceExpiry: json['insuranceExpiry'] != null
          ? DateTime.parse(json['insuranceExpiry'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'insuranceNumber': insuranceNumber,
      'insuranceExpiry': insuranceExpiry?.toIso8601String(),
    };
  }

  String get displayName {
    return '$vehicleBrand $vehicleModel ($vehicleYear)';
  }
}

class Document {
  final String id;
  final DocumentType type;
  final String name;
  final String? fileUrl;
  final DocumentStatus status;
  final DateTime uploadedDate;
  final DateTime? expiryDate;
  final String? remarks;

  const Document({
    required this.id,
    required this.type,
    required this.name,
    this.fileUrl,
    required this.status,
    required this.uploadedDate,
    this.expiryDate,
    this.remarks,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DocumentType.other,
      ),
      name: json['name'] ?? '',
      fileUrl: json['fileUrl'],
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DocumentStatus.pending,
      ),
      uploadedDate: DateTime.parse(json['uploadedDate'] ?? DateTime.now().toIso8601String()),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'fileUrl': fileUrl,
      'status': status.toString().split('.').last,
      'uploadedDate': uploadedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'remarks': remarks,
    };
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }
}

class ProfileStats {
  final double totalEarnings;
  final int totalOrders;
  final double averageRating;
  final int completionRate;
  final int onTimeDeliveries;
  final Duration totalOnlineTime;
  final int thisMonthDeliveries;
  final double thisMonthEarnings;

  const ProfileStats({
    required this.totalEarnings,
    required this.totalOrders,
    required this.averageRating,
    required this.completionRate,
    required this.onTimeDeliveries,
    required this.totalOnlineTime,
    required this.thisMonthDeliveries,
    required this.thisMonthEarnings,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      completionRate: json['completionRate'] ?? 0,
      onTimeDeliveries: json['onTimeDeliveries'] ?? 0,
      totalOnlineTime: Duration(minutes: json['totalOnlineTimeMinutes'] ?? 0),
      thisMonthDeliveries: json['thisMonthDeliveries'] ?? 0,
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'totalOrders': totalOrders,
      'averageRating': averageRating,
      'completionRate': completionRate,
      'onTimeDeliveries': onTimeDeliveries,
      'totalOnlineTimeMinutes': totalOnlineTime.inMinutes,
      'thisMonthDeliveries': thisMonthDeliveries,
      'thisMonthEarnings': thisMonthEarnings,
    };
  }
}

class BankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String? branchName;

  const BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    this.branchName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      branchName: json['branchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'branchName': branchName,
    };
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class Address {
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? landmark;

  const Address({
    required this.street,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.landmark,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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
    final parts = [street, area, city, state, pincode].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String get shortAddress {
    return '$area, $city';
  }
}

enum ProfileStatus {
  pending,
  verified,
  suspended,
  rejected,
}

enum DocumentType {
  drivingLicense,
  aadharCard,
  panCard,
  vehicleRC,
  insurance,
  puc,
  other,
}

enum DocumentStatus {
  pending,
  approved,
  rejected,
  expired,
}

extension ProfileStatusExtension on ProfileStatus {
  String get displayName {
    switch (this) {
      case ProfileStatus.pending:
        return 'Pending Verification';
      case ProfileStatus.verified:
        return 'Verified';
      case ProfileStatus.suspended:
        return 'Suspended';
      case ProfileStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ProfileStatus.pending:
        return Colors.orange;
      case ProfileStatus.verified:
        return Colors.green;
      case ProfileStatus.suspended:
        return Colors.red;
      case ProfileStatus.rejected:
        return Colors.red;
    }
  }
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.aadharCard:
        return 'Aadhar Card';
      case DocumentType.panCard:
        return 'PAN Card';
      case DocumentType.vehicleRC:
        return 'Vehicle RC';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.puc:
        return 'PUC Certificate';
      case DocumentType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.drivingLicense:
        return Icons.credit_card;
      case DocumentType.aadharCard:
        return Icons.fingerprint;
      case DocumentType.panCard:
        return Icons.account_balance;
      case DocumentType.vehicleRC:
        return Icons.directions_car;
      case DocumentType.insurance:
        return Icons.security;
      case DocumentType.puc:
        return Icons.eco;
      case DocumentType.other:
        return Icons.description;
    }
  }
}

extension DocumentStatusExtension on DocumentStatus {
  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending Review';
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.grey;
    }
  }
}