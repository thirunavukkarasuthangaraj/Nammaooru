import '../config/env_config.dart';

class AppConstants {
  static const String appName = 'NammaOoru';
  static const String appVersion = '1.0.0';
  
  // Use environment configuration for base URL
  static String get baseUrl => EnvConfig.fullApiUrl;
  static String get apiBaseUrl => EnvConfig.fullApiUrl;
  
  // For production, uncomment:
  // static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  // static const String baseUrl = 'http://192.168.1.3:8080/api'; // Local development
  // static const String baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator
  
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 80;
  
  static const List<String> supportedLanguages = ['en', 'ta'];
  static const String defaultLanguage = 'en';
  
  static const Map<String, String> userRoles = {
    'CUSTOMER': 'Customer',
    'SHOP_OWNER': 'Shop Owner',
    'DELIVERY_PARTNER': 'Delivery Partner',
  };
  
  static const Map<String, String> orderStatuses = {
    'PENDING': 'Pending',
    'CONFIRMED': 'Confirmed',
    'PREPARING': 'Preparing',
    'READY': 'Ready',
    'COMPLETED': 'Completed',
    'CANCELLED': 'Cancelled',
  };
  
  static const Map<String, String> serviceCategories = {
    'GROCERY': 'Grocery',
    'FOOD': 'Food',
    'PARCEL': 'Parcel',
  };
  
  // API Response Status Codes
  static const String successCode = '0000';
  static const String failureCode = '9999';
  
  // Response Messages
  static const String successMessage = 'Success';
  static const String failureMessage = 'Operation failed';
  
  // Error Status Codes
  static const Map<String, String> errorCodes = {
    // Authentication & Authorization errors (1xxx)
    '1001': 'Unauthorized access',
    '1002': 'Access forbidden',
    '1003': 'Invalid username or password',
    '1004': 'Token has expired',
    '1005': 'Invalid token',
    
    // Validation errors (2xxx)
    '2001': 'Validation error',
    '2002': 'Required field is missing',
    '2003': 'Invalid data format',
    '2004': 'Duplicate entry exists',
    
    // Business logic errors (3xxx)
    '3001': 'Shop not found',
    '3002': 'User not found',
    '3003': 'Document not found',
    '3004': 'Shop is already approved',
    '3005': 'Shop is already rejected',
    
    // File upload errors (4xxx)
    '4001': 'File upload failed',
    '4002': 'File size exceeds limit',
    '4003': 'File type not allowed',
    '4004': 'File not found',
    '4005': 'Image contains inappropriate content',
    
    // Database errors (5xxx)
    '5001': 'Database operation failed',
    '5002': 'Database connection error',
    
    // External service errors (6xxx)
    '6001': 'External service error',
    '6002': 'Request timeout',
    
    // Server errors (7xxx)
    '7001': 'Internal server error',
    '7002': 'Service temporarily unavailable',
    
    // General error
    '9999': 'General error occurred',
  };
}