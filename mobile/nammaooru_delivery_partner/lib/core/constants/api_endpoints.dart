class ApiEndpoints {
  // Base URL - Update this to match your backend
  static const String baseUrl = 'http://localhost:8080/api';
  static const String mobileBaseUrl = '$baseUrl/mobile/delivery-partner';
  
  // Authentication endpoints
  static const String login = '$mobileBaseUrl/login';
  static const String verifyOtp = '$mobileBaseUrl/verify-otp';
  
  // Profile endpoints
  static String profile(String partnerId) => '$mobileBaseUrl/profile/$partnerId';
  static String updateProfile(String partnerId) => '$mobileBaseUrl/profile/$partnerId';
  static String uploadProfileImage(String partnerId) => '$mobileBaseUrl/profile/$partnerId/upload-image';
  
  // Status endpoints
  static String updateStatus(String partnerId) => '$mobileBaseUrl/status/$partnerId';
  
  // Order endpoints
  static String availableOrders(String partnerId) => '$mobileBaseUrl/orders/$partnerId/available';
  static String activeOrders(String partnerId) => '$mobileBaseUrl/orders/$partnerId/active';
  static String acceptOrder(String orderId) => '$mobileBaseUrl/orders/$orderId/accept';
  static String rejectOrder(String orderId) => '$mobileBaseUrl/orders/$orderId/reject';
  static String pickupOrder(String orderId) => '$mobileBaseUrl/orders/$orderId/pickup';
  static String deliverOrder(String orderId) => '$mobileBaseUrl/orders/$orderId/deliver';
  
  // Earnings endpoints
  static String earnings(String partnerId) => '$mobileBaseUrl/earnings/$partnerId';
  
  // Withdrawal endpoints
  static String requestWithdrawal(String partnerId) => '$mobileBaseUrl/withdrawals/$partnerId/request';
  static String withdrawalHistory(String partnerId) => '$mobileBaseUrl/withdrawals/$partnerId/history';
  
  // Document endpoints
  static String uploadDocument(String partnerId) => '$mobileBaseUrl/documents/$partnerId/upload';
  static String getDocuments(String partnerId) => '$mobileBaseUrl/documents/$partnerId';
  
  // Analytics endpoints
  static String stats(String partnerId) => '$mobileBaseUrl/stats/$partnerId';
  static const String leaderboard = '$mobileBaseUrl/leaderboard';
  
  // Location endpoints
  static String updateLocation(String partnerId) => '$mobileBaseUrl/location/$partnerId/update';
  
  // Notification endpoints
  static String notifications(String partnerId) => '$mobileBaseUrl/notifications/$partnerId';
  static String markNotificationRead(String notificationId) => '$mobileBaseUrl/notifications/$notificationId/read';
  
  // Support endpoints
  static String createSupportTicket(String partnerId) => '$mobileBaseUrl/support/$partnerId/ticket';
  
  // Utility methods
  static String replaceId(String endpoint, String id) {
    return endpoint.replaceAll('{id}', id);
  }
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}