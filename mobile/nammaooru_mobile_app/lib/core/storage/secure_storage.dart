import 'local_storage.dart';

class SecureStorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
  static const String biometricEnabled = 'biometric_enabled';
}

class SecureStorage {
  static Future<void> saveAuthToken(String token) async {
    await LocalStorage.setSecureString(SecureStorageKeys.authToken, token);
  }
  
  static Future<String?> getAuthToken() async {
    return await LocalStorage.getSecureString(SecureStorageKeys.authToken);
  }
  
  static Future<void> saveRefreshToken(String token) async {
    await LocalStorage.setSecureString(SecureStorageKeys.refreshToken, token);
  }
  
  static Future<String?> getRefreshToken() async {
    return await LocalStorage.getSecureString(SecureStorageKeys.refreshToken);
  }
  
  static Future<void> saveUserRole(String role) async {
    await LocalStorage.setSecureString(SecureStorageKeys.userRole, role);
  }
  
  static Future<String?> getUserRole() async {
    return await LocalStorage.getSecureString(SecureStorageKeys.userRole);
  }
  
  static Future<void> saveUserId(String userId) async {
    await LocalStorage.setSecureString(SecureStorageKeys.userId, userId);
  }
  
  static Future<String?> getUserId() async {
    return await LocalStorage.getSecureString(SecureStorageKeys.userId);
  }
  
  static Future<void> setBiometricEnabled(bool enabled) async {
    await LocalStorage.setSecureString(
      SecureStorageKeys.biometricEnabled, 
      enabled.toString(),
    );
  }
  
  static Future<bool> isBiometricEnabled() async {
    final value = await LocalStorage.getSecureString(SecureStorageKeys.biometricEnabled);
    return value == 'true';
  }
  
  static Future<void> clearAuthData() async {
    await LocalStorage.removeSecureString(SecureStorageKeys.authToken);
    await LocalStorage.removeSecureString(SecureStorageKeys.refreshToken);
    await LocalStorage.removeSecureString(SecureStorageKeys.userRole);
    await LocalStorage.removeSecureString(SecureStorageKeys.userId);
  }
}