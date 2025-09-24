import 'package:flutter/material.dart';
import '../models/shop_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ShopProvider extends ChangeNotifier {
  ShopProfile? _shopProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ShopProfile? get shopProfile => _shopProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize with mock data
  Future<void> initialize() async {
    await loadShopProfile();
  }

  // Load shop profile
  Future<void> loadShopProfile() async {
    try {
      _setLoading(true);
      _clearError();

      // Load from API or use mock data
      await _loadMockShopProfile();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load shop profile: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Update shop profile
  Future<bool> updateShopProfile(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await ApiService.updateShopProfile(updates);

      if (response.isSuccess) {
        final updatedProfile = ShopProfile.fromJson(response.data['shop']);
        _shopProfile = updatedProfile;
        await _saveShopProfileToStorage(updatedProfile);
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to update shop profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Update error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update business hours
  Future<bool> updateBusinessHours(BusinessHours businessHours) async {
    try {
      _setLoading(true);
      _clearError();

      final updates = {
        'businessHours': businessHours.toJson(),
      };

      final success = await updateShopProfile(updates);
      return success;
    } catch (e) {
      _setError('Failed to update business hours: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Toggle shop status
  Future<bool> toggleShopStatus() async {
    if (_shopProfile == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final newStatus = !_shopProfile!.isActive;
      final updates = {
        'isActive': newStatus,
      };

      final success = await updateShopProfile(updates);
      return success;
    } catch (e) {
      _setError('Failed to toggle shop status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Load mock shop profile for development
  Future<void> _loadMockShopProfile() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay

    final mockProfile = ShopProfile(
      id: 'shop_456',
      name: 'Thirunavukkarasu',
      description: 'A comprehensive general store offering a wide variety of products including groceries, household items, medicines, and daily essentials.',
      ownerId: 'user_123',
      ownerName: 'thiru278',
      status: 'APPROVED',
      category: 'General Store',
      logo: null,
      images: [],
      address: ShopAddress(
        street: '123 Main Street',
        area: 'Market Area',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        landmark: 'Near City Bus Stand',
        latitude: 12.9716,
        longitude: 77.5946,
      ),
      contact: ShopContact(
        phone: '+919876543210',
        email: 'thiru278@example.com',
        website: 'https://thirunavukkarasu-shop.com',
        socialMedia: {
          'facebook': 'thirunavukkarasu.shop',
          'instagram': '@thirunavukkarasu_store',
        },
      ),
      businessHours: BusinessHours(
        weekdays: {
          'monday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'tuesday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'wednesday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'thursday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'friday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'saturday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          'sunday': DayHours(
            isOpen: true,
            openTime: const TimeOfDay(hour: 10, minute: 0),
            closeTime: const TimeOfDay(hour: 20, minute: 0),
          ),
        },
        isAlwaysOpen: false,
        holidays: ['2024-01-26', '2024-08-15', '2024-10-02'],
      ),
      specializations: ['Groceries', 'Medicines', 'Household Items', 'Electronics'],
      rating: 4.5,
      reviewCount: 127,
      isVerified: true,
      isActive: true,
      registeredAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      settings: {
        'autoAcceptOrders': false,
        'maxOrdersPerHour': 10,
        'deliveryRadius': 5.0,
        'minimumOrderAmount': 100.0,
      },
      metadata: {
        'shopType': 'physical',
        'hasHomeDelivery': true,
        'acceptsOnlinePayments': true,
      },
    );

    _shopProfile = mockProfile;
    await _saveShopProfileToStorage(mockProfile);
    notifyListeners();
  }

  // Save shop profile to local storage
  Future<void> _saveShopProfileToStorage(ShopProfile profile) async {
    try {
      await StorageService.saveString('shop_profile', profile.toJson().toString());
    } catch (e) {
      print('Failed to save shop profile to storage: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Public methods for UI
  bool get isShopOpen => _shopProfile?.isCurrentlyOpen ?? false;
  bool get isShopApproved => _shopProfile?.isApproved ?? false;
  bool get isShopActive => _shopProfile?.isActive ?? false;

  String get shopStatusText {
    if (_shopProfile == null) return 'Unknown';
    if (!_shopProfile!.isActive) return 'Closed';
    if (!_shopProfile!.isApproved) return 'Pending Approval';
    if (!_shopProfile!.isCurrentlyOpen) return 'Closed for the day';
    return 'Open';
  }

  Color get shopStatusColor {
    if (_shopProfile == null || !_shopProfile!.isActive) {
      return Colors.red;
    }
    if (!_shopProfile!.isApproved) {
      return Colors.orange;
    }
    if (!_shopProfile!.isCurrentlyOpen) {
      return Colors.grey;
    }
    return Colors.green;
  }

  // Clear data
  void clear() {
    _shopProfile = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}