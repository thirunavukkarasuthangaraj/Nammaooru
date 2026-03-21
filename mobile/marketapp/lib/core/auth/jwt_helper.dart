import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';

class JwtHelper {
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      return Jwt.parseJwt(token);
    } catch (e) {
      print('Error decoding JWT: $e');
      return null;
    }
  }
  
  static bool isTokenExpired(String token) {
    try {
      return Jwt.isExpired(token);
    } catch (e) {
      print('Error checking token expiry: $e');
      return true;
    }
  }
  
  static String? getUserRole(String token) {
    final payload = decodeToken(token);
    return payload?['role'] as String?;
  }
  
  static String? getUserId(String token) {
    final payload = decodeToken(token);
    return payload?['sub'] as String? ?? payload?['userId'] as String?;
  }
  
  static String? getUserEmail(String token) {
    final payload = decodeToken(token);
    return payload?['email'] as String?;
  }
  
  static String? getUserName(String token) {
    final payload = decodeToken(token);
    return payload?['name'] as String?;
  }
  
  static DateTime? getTokenExpiry(String token) {
    try {
      return Jwt.getExpiryDate(token);
    } catch (e) {
      print('Error getting token expiry: $e');
      return null;
    }
  }
  
  static bool isValidToken(String token) {
    try {
      final payload = decodeToken(token);
      if (payload == null) return false;
      
      if (isTokenExpired(token)) return false;
      
      // Only require 'sub' and 'exp' fields - role comes from API response, not JWT
      final requiredFields = ['sub', 'exp'];
      for (final field in requiredFields) {
        if (!payload.containsKey(field)) return false;
      }
      
      return true;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }
}