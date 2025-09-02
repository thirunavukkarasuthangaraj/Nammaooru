class ApiEndpoints {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String refreshToken = '$auth/refresh-token';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyOtp = '$auth/verify-otp';
  static const String sendOtp = '$auth/send-otp';
  
  static const String users = '/users';
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile';
  
  static const String products = '/products';
  static const String categories = '/categories';
  static const String shops = '/shops';
  static String shopProducts(String shopId) => '$shops/$shopId/products';
  
  static const String orders = '/orders';
  static String userOrders(String userId) => '$orders/user/$userId';
  static String shopOrders(String shopId) => '$orders/shop/$shopId';
  static String deliveryOrders(String deliveryPartnerId) => '$orders/delivery-partner/$deliveryPartnerId';
  static String orderDetails(String orderId) => '$orders/$orderId';
  static String updateOrderStatus(String orderId) => '$orders/$orderId/status';
  
  static const String cart = '/cart';
  static const String addToCart = '$cart/add';
  static const String removeFromCart = '$cart/remove';
  static const String clearCart = '$cart/clear';
  
  static const String tracking = '/tracking';
  static String orderTracking(String orderId) => '$tracking/order/$orderId';
  static String updateLocation(String deliveryPartnerId) => '$tracking/location/$deliveryPartnerId';
  
  static const String notifications = '/notifications';
  static String userNotifications(String userId) => '$notifications/user/$userId';
  static const String markAsRead = '$notifications/mark-read';
  
  static const String analytics = '/analytics';
  static String shopAnalytics(String shopId) => '$analytics/shop/$shopId';
  static String deliveryAnalytics(String deliveryPartnerId) => '$analytics/delivery-partner/$deliveryPartnerId';
  
  static const String inventory = '/inventory';
  static String shopInventory(String shopId) => '$inventory/shop/$shopId';
  static String updateStock(String productId) => '$inventory/product/$productId/stock';
  
  static const String uploads = '/uploads';
  static const String uploadImage = '$uploads/image';
}