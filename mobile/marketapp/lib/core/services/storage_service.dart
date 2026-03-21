import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import 'storage_service_impl.dart';

class StorageService {
  // Storage keys
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserEmail = 'user_email';

  // Delegate to platform-specific implementation
  static Future<void> saveAuthData(AuthResponse authResponse) =>
      StorageServiceImpl.saveAuthData(authResponse);

  static Future<String?> getAccessToken() =>
      StorageServiceImpl.getAccessToken();

  static Future<void> saveUserData(User user) =>
      StorageServiceImpl.saveUserData(user);

  static Future<User?> getUserData() =>
      StorageServiceImpl.getUserData();

  static Future<bool> isLoggedIn() =>
      StorageServiceImpl.isLoggedIn();

  // Save remember me preference
  static Future<void> saveRememberMe(bool remember, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, remember);
      if (remember) {
        await prefs.setString(_keyUserEmail, email);
      } else {
        await prefs.remove(_keyUserEmail);
      }
    } catch (e) {
      throw Exception('Failed to save remember me preference: $e');
    }
  }

  // Get remember me preference
  static Future<Map<String, dynamic>> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_keyRememberMe) ?? false;
      final email = prefs.getString(_keyUserEmail) ?? '';
      
      return {
        'remember': remember,
        'email': email,
      };
    } catch (e) {
      return {
        'remember': false,
        'email': '',
      };
    }
  }

  // Save registration email for OTP verification
  static Future<void> saveRegistrationEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registration_email', email);
    } catch (e) {
      throw Exception('Failed to save registration email: $e');
    }
  }

  // Get registration email
  static Future<String?> getRegistrationEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('registration_email');
    } catch (e) {
      return null;
    }
  }

  // Clear registration email
  static Future<void> clearRegistrationEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_email');
    } catch (e) {
      // Ignore error
    }
  }

  static Future<void> clearAuthData() =>
      StorageServiceImpl.clearAuthData();

  static Future<void> clearAllData() =>
      StorageServiceImpl.clearAllData();
}