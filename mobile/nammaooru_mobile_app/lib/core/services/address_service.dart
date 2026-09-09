import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import '../../services/address_api_service.dart';

class AddressService {
  static AddressService? _instance;
  static AddressService get instance => _instance ??= AddressService._();
  AddressService._();

  static const String _addressesKey = 'saved_addresses';

  Future<List<SavedAddress>> getSavedAddresses() async {
    try {
      // First try to get addresses from API
      final apiResult = await AddressApiService.getUserAddresses();

      if (apiResult['success'] == true && apiResult['data'] is List) {
        final List<dynamic> apiAddresses = apiResult['data'];

        print('🔍 API returned ${apiAddresses.length} addresses');
        if (apiAddresses.isNotEmpty) {
          print('🔍 First address data: ${apiAddresses.first}');
        }

        // Convert API addresses to SavedAddress objects using fromJson which handles backend format
        final List<SavedAddress> addresses = apiAddresses.map((addr) {
          // Use fromJson to properly handle contactPersonName and contactMobileNumber from backend
          final savedAddr = SavedAddress.fromJson(addr);
          print('🔍 Parsed address: name=${savedAddr.name}, lastName=${savedAddr.lastName}, phone=${savedAddr.phone}');
          return savedAddr;
        }).toList();

        // Sort: default first, then alphabetically
        addresses.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return a.addressType.compareTo(b.addressType);
        });

        return addresses;
      }

      // Fallback to local storage if API fails
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_addressesKey);

      if (addressesJson == null || addressesJson.isEmpty) {
        return [];
      }

      final List<dynamic> addressesList = json.decode(addressesJson);
      return addressesList
          .map((json) => SavedAddress.fromJson(json))
          .toList()
        ..sort((a, b) {
          // Default address first, then by creation date (newest first)
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
    } catch (e) {
      print('Error getting saved addresses: $e');
      return [];
    }
  }

  Future<bool> saveAddress(SavedAddress address) async {
    try {
      final addresses = await getSavedAddresses();

      // If this is set as default, make all others non-default
      if (address.isDefault) {
        for (int i = 0; i < addresses.length; i++) {
          addresses[i] = addresses[i].copyWith(isDefault: false);
        }
      }

      // Check if address already exists (update) or add new
      final existingIndex = addresses.indexWhere((a) => a.id == address.id);
      if (existingIndex != -1) {
        addresses[existingIndex] = address;
      } else {
        addresses.add(address);
      }

      return await _saveAddressList(addresses);
    } catch (e) {
      print('Error saving address: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      addresses.removeWhere((address) => address.id == addressId);
      return await _saveAddressList(addresses);
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final addresses = await getSavedAddresses();

      for (int i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(
          isDefault: addresses[i].id == addressId,
        );
      }

      return await _saveAddressList(addresses);
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }

  Future<SavedAddress?> getDefaultAddress() async {
    try {
      final addresses = await getSavedAddresses();
      return addresses.where((address) => address.isDefault).firstOrNull;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  Future<SavedAddress?> getAddressById(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      return addresses.where((address) => address.id == addressId).firstOrNull;
    } catch (e) {
      print('Error getting address by id: $e');
      return null;
    }
  }

  Future<bool> _saveAddressList(List<SavedAddress> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(
        addresses.map((address) => address.toJson()).toList(),
      );
      return await prefs.setString(_addressesKey, addressesJson);
    } catch (e) {
      print('Error saving addresses list: $e');
      return false;
    }
  }

  Future<bool> clearAllAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_addressesKey);
    } catch (e) {
      print('Error clearing addresses: $e');
      return false;
    }
  }

  String generateAddressId() {
    return 'addr_${DateTime.now().millisecondsSinceEpoch}';
  }
}