import '../core/services/api_service.dart';
import '../core/utils/logger.dart';

class OrderApiService {
  final ApiService _apiService = ApiService();

  // Place Order
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    required String deliverySlot,
    String? deliveryInstructions,
    required double subtotal,
    required double deliveryFee,
    required double taxAmount,
    double promoDiscount = 0.0,
    required double total,
  }) async {
    try {
      Logger.order('Placing order - items: ${items.length}, total: $total');
      
      final response = await _apiService.post(
        '/customer/orders',
        data: {
          'items': items,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'deliverySlot': deliverySlot,
          'deliveryInstructions': deliveryInstructions,
          'subtotal': subtotal,
          'deliveryFee': deliveryFee,
          'taxAmount': taxAmount,
          'promoDiscount': promoDiscount,
          'total': total,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to place order', 'ORDER', e);
      rethrow;
    }
  }

  // Get Customer Orders
  Future<Map<String, dynamic>> getCustomerOrders({
    int page = 0,
    int size = 10,
    String? status,
  }) async {
    try {
      Logger.order('Fetching customer orders - page: $page, status: $status');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      
      final response = await _apiService.get(
        '/customer/orders',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch customer orders', 'ORDER', e);
      rethrow;
    }
  }

  // Get Order by ID
  Future<Map<String, dynamic>> getOrderById(int orderId) async {
    try {
      Logger.order('Fetching order: $orderId');
      
      final response = await _apiService.get('/orders/$orderId');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch order', 'ORDER', e);
      rethrow;
    }
  }

  // Get Order by Number
  Future<Map<String, dynamic>> getOrderByNumber(String orderNumber) async {
    try {
      Logger.order('Fetching order by number: $orderNumber');
      
      final response = await _apiService.get('/orders/number/$orderNumber');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch order by number', 'ORDER', e);
      rethrow;
    }
  }

  // Get Shop Orders (for shop owners)
  Future<Map<String, dynamic>> getShopOrders({
    required String shopId,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      Logger.order('Fetching shop orders - shopId: $shopId, page: $page, status: $status');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sortBy': sortBy,
        'sortDir': sortDir,
      };
      
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      
      final response = await _apiService.get(
        '/shops/$shopId/orders',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch shop orders', 'ORDER', e);
      rethrow;
    }
  }

  // Accept Order (shop owner)
  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      Logger.order('Accepting order: $orderId');
      
      final response = await _apiService.post(
        '/orders/$orderId/accept',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to accept order', 'ORDER', e);
      rethrow;
    }
  }

  // Reject Order (shop owner)
  Future<Map<String, dynamic>> rejectOrder(int orderId, {String? reason}) async {
    try {
      Logger.order('Rejecting order: $orderId, reason: $reason');
      
      final response = await _apiService.post(
        '/orders/$orderId/reject',
        data: reason != null ? {'reason': reason} : null,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to reject order', 'ORDER', e);
      rethrow;
    }
  }

  // Start Preparing Order (shop owner)
  Future<Map<String, dynamic>> startPreparingOrder(int orderId) async {
    try {
      Logger.order('Starting preparation for order: $orderId');
      
      final response = await _apiService.post(
        '/orders/$orderId/prepare',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to start preparing order', 'ORDER', e);
      rethrow;
    }
  }

  // Mark Order Ready (shop owner)
  Future<Map<String, dynamic>> markOrderReady(int orderId) async {
    try {
      Logger.order('Marking order ready: $orderId');
      
      final response = await _apiService.post(
        '/orders/$orderId/ready',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to mark order ready', 'ORDER', e);
      rethrow;
    }
  }

  // Cancel Order
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    required String reason,
  }) async {
    try {
      Logger.order('Cancelling order: $orderId, reason: $reason');

      final response = await _apiService.post(
        '/customer/orders/$orderId/cancel',
        data: {
          'reason': reason,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to cancel order', 'ORDER', e);
      rethrow;
    }
  }

  // Get Order Tracking
  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    try {
      Logger.order('Fetching order tracking: $orderId');
      
      final response = await _apiService.get('/orders/$orderId/tracking');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch order tracking', 'ORDER', e);
      rethrow;
    }
  }

  // Get Order Status Timeline
  Future<Map<String, dynamic>> getOrderStatusTimeline(int orderId) async {
    try {
      Logger.order('Fetching order timeline: $orderId');
      
      final response = await _apiService.get('/orders/$orderId/status-timeline');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch order timeline', 'ORDER', e);
      rethrow;
    }
  }

  // Get Delivery Partner Info
  Future<Map<String, dynamic>> getDeliveryPartnerInfo(int orderId) async {
    try {
      Logger.order('Fetching delivery partner info: $orderId');
      
      final response = await _apiService.get('/orders/$orderId/delivery-partner');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch delivery partner info', 'ORDER', e);
      rethrow;
    }
  }

  // Rate Order
  Future<Map<String, dynamic>> rateOrder({
    required int orderId,
    required double rating,
    String? review,
    double? deliveryRating,
    String? deliveryReview,
  }) async {
    try {
      Logger.order('Rating order: $orderId, rating: $rating');
      
      final response = await _apiService.post(
        '/orders/$orderId/rate',
        data: {
          'rating': rating,
          'review': review,
          'deliveryRating': deliveryRating,
          'deliveryReview': deliveryReview,
        },
      );

      return response;
    } catch (e) {
      Logger.e('Failed to rate order', 'ORDER', e);
      rethrow;
    }
  }

  // Reorder
  Future<Map<String, dynamic>> reorder(int orderId) async {
    try {
      Logger.order('Reordering: $orderId');
      
      final response = await _apiService.post('/orders/$orderId/reorder');
      return response;
    } catch (e) {
      Logger.e('Failed to reorder', 'ORDER', e);
      rethrow;
    }
  }

  // Get Invoice
  Future<Map<String, dynamic>> getInvoice(int orderId) async {
    try {
      Logger.order('Fetching invoice: $orderId');
      
      final response = await _apiService.get('/orders/$orderId/invoice');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch invoice', 'ORDER', e);
      rethrow;
    }
  }

  // Get Order Statuses
  Future<Map<String, dynamic>> getOrderStatuses() async {
    try {
      Logger.order('Fetching order statuses');
      
      final response = await _apiService.get('/orders/statuses');
      return response;
    } catch (e) {
      Logger.e('Failed to fetch order statuses', 'ORDER', e);
      rethrow;
    }
  }
}