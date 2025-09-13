import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../models/profile_model.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user profile
  Future<void> loadProfile() async {
    _setLoading(true);
    
    try {
      // For demo, create mock profile data
      _profile = _createMockProfile();
      _error = null;
    } catch (e) {
      _error = 'Failed to load profile data';
      if (kDebugMode) {
        print('Load Profile Error: $e');
      }
    }
    
    _setLoading(false);
  }

  // Update profile information
  Future<bool> updateProfile(Profile updatedProfile) async {
    _setLoading(true);
    
    try {
      // In real app, make API call to update profile
      final response = await http.put(
        Uri.parse(ApiEndpoints.updateProfile),
        headers: ApiEndpoints.defaultHeaders,
        body: json.encode(updatedProfile.toJson()),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _profile = updatedProfile;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Update Profile Error: $e');
      }
      
      // For demo, always succeed
      _profile = updatedProfile;
      notifyListeners();
      return true;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    _setLoading(true);
    
    try {
      // In real app, upload image and get URL
      final imageUrl = 'https://example.com/profile/image.jpg';
      
      if (_profile != null) {
        final updatedProfile = Profile(
          id: _profile!.id,
          name: _profile!.name,
          email: _profile!.email,
          phoneNumber: _profile!.phoneNumber,
          profileImageUrl: imageUrl,
          address: _profile!.address,
          vehicleInfo: _profile!.vehicleInfo,
          bankDetails: _profile!.bankDetails,
          documents: _profile!.documents,
          stats: _profile!.stats,
          joinedDate: _profile!.joinedDate,
          status: _profile!.status,
          rating: _profile!.rating,
          totalDeliveries: _profile!.totalDeliveries,
          emergencyContactName: _profile!.emergencyContactName,
          emergencyContactNumber: _profile!.emergencyContactNumber,
        );
        
        _profile = updatedProfile;
        notifyListeners();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Upload Image Error: $e');
      }
      return false;
    }
  }

  // Upload document
  Future<bool> uploadDocument(DocumentType type, String filePath) async {
    _setLoading(true);
    
    try {
      // In real app, upload document and create document record
      final newDocument = Document(
        id: 'DOC${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        name: type.displayName,
        fileUrl: 'https://example.com/documents/doc.pdf',
        status: DocumentStatus.pending,
        uploadedDate: DateTime.now(),
        expiryDate: _getDefaultExpiryDate(type),
      );
      
      if (_profile != null) {
        final updatedDocuments = List<Document>.from(_profile!.documents);
        
        // Remove existing document of same type
        updatedDocuments.removeWhere((doc) => doc.type == type);
        
        // Add new document
        updatedDocuments.add(newDocument);
        
        final updatedProfile = Profile(
          id: _profile!.id,
          name: _profile!.name,
          email: _profile!.email,
          phoneNumber: _profile!.phoneNumber,
          profileImageUrl: _profile!.profileImageUrl,
          address: _profile!.address,
          vehicleInfo: _profile!.vehicleInfo,
          bankDetails: _profile!.bankDetails,
          documents: updatedDocuments,
          stats: _profile!.stats,
          joinedDate: _profile!.joinedDate,
          status: _profile!.status,
          rating: _profile!.rating,
          totalDeliveries: _profile!.totalDeliveries,
          emergencyContactName: _profile!.emergencyContactName,
          emergencyContactNumber: _profile!.emergencyContactNumber,
        );
        
        _profile = updatedProfile;
        notifyListeners();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Upload Document Error: $e');
      }
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  DateTime? _getDefaultExpiryDate(DocumentType type) {
    switch (type) {
      case DocumentType.drivingLicense:
        return DateTime.now().add(const Duration(days: 365 * 20)); // 20 years
      case DocumentType.vehicleRC:
        return DateTime.now().add(const Duration(days: 365 * 15)); // 15 years
      case DocumentType.insurance:
        return DateTime.now().add(const Duration(days: 365)); // 1 year
      case DocumentType.puc:
        return DateTime.now().add(const Duration(days: 180)); // 6 months
      default:
        return null;
    }
  }

  // Mock data generation
  Profile _createMockProfile() {
    return Profile(
      id: 'DP001',
      name: 'Rajesh Kumar',
      email: 'rajesh.kumar@email.com',
      phoneNumber: '+91 98765 43210',
      profileImageUrl: 'https://ui-avatars.com/api/?name=Rajesh+Kumar&background=4CAF50&color=fff',
      address: const Address(
        street: '123 HSR Layout',
        area: 'HSR Layout',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560102',
        latitude: 12.9121,
        longitude: 77.6446,
        landmark: 'Near BDA Complex',
      ),
      vehicleInfo: const VehicleInfo(
        vehicleType: 'Motorcycle',
        vehicleNumber: 'KA01AB1234',
        vehicleBrand: 'Honda',
        vehicleModel: 'Activa',
        vehicleYear: 2020,
        vehicleColor: 'Black',
        insuranceNumber: 'INS123456789',
        insuranceExpiry: null,
      ),
      bankDetails: const BankDetails(
        bankName: 'HDFC Bank',
        accountNumber: '50100123456789',
        ifscCode: 'HDFC0001234',
        accountHolderName: 'Rajesh Kumar',
        branchName: 'HSR Layout Branch',
      ),
      documents: _createMockDocuments(),
      stats: const ProfileStats(
        totalEarnings: 45280.0,
        totalOrders: 456,
        averageRating: 4.7,
        completionRate: 96,
        onTimeDeliveries: 432,
        totalOnlineTime: Duration(hours: 320, minutes: 45),
        thisMonthDeliveries: 42,
        thisMonthEarnings: 3850.0,
      ),
      joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      status: ProfileStatus.verified,
      rating: 4.7,
      totalDeliveries: 456,
      emergencyContactName: 'Sunita Kumar',
      emergencyContactNumber: '+91 98765 43211',
    );
  }

  List<Document> _createMockDocuments() {
    return [
      Document(
        id: 'DOC001',
        type: DocumentType.drivingLicense,
        name: 'Driving License',
        fileUrl: 'https://example.com/documents/dl.pdf',
        status: DocumentStatus.approved,
        uploadedDate: DateTime.now().subtract(const Duration(days: 150)),
        expiryDate: DateTime.now().add(const Duration(days: 365 * 10)),
      ),
      Document(
        id: 'DOC002',
        type: DocumentType.aadharCard,
        name: 'Aadhar Card',
        fileUrl: 'https://example.com/documents/aadhar.pdf',
        status: DocumentStatus.approved,
        uploadedDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Document(
        id: 'DOC003',
        type: DocumentType.panCard,
        name: 'PAN Card',
        fileUrl: 'https://example.com/documents/pan.pdf',
        status: DocumentStatus.approved,
        uploadedDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Document(
        id: 'DOC004',
        type: DocumentType.vehicleRC,
        name: 'Vehicle RC',
        fileUrl: 'https://example.com/documents/rc.pdf',
        status: DocumentStatus.approved,
        uploadedDate: DateTime.now().subtract(const Duration(days: 140)),
        expiryDate: DateTime.now().add(const Duration(days: 365 * 5)),
      ),
      Document(
        id: 'DOC005',
        type: DocumentType.insurance,
        name: 'Vehicle Insurance',
        fileUrl: 'https://example.com/documents/insurance.pdf',
        status: DocumentStatus.approved,
        uploadedDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 335)),
      ),
      Document(
        id: 'DOC006',
        type: DocumentType.puc,
        name: 'PUC Certificate',
        fileUrl: 'https://example.com/documents/puc.pdf',
        status: DocumentStatus.pending,
        uploadedDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 175)),
      ),
    ];
  }
}