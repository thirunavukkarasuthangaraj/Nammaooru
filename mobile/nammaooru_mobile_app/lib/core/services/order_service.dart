import '../api/api_client.dart';
import '../models/order_model.dart';
import '../storage/local_storage.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  Future<Map<String, dynamic>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (status != null) 'status': status,
      };

      final response = await ApiClient.get(
        '/customer/orders',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        final ordersResponse = OrdersResponse.fromJson(response.data['data'] ?? {});
        await _cacheOrders(ordersResponse.orders, page);
        
        return {
          'success': true,
          'data': ordersResponse,
          'message': 'Orders loaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load orders',
          'data': OrdersResponse.empty()
        };
      }
    } catch (e) {
      print('Error loading orders: $e');
      
      final cachedOrders = await _getCachedOrders();
      return {
        'success': false,
        'message': 'Using cached orders data',
        'data': OrdersResponse(
          orders: cachedOrders,
          totalPages: 1,
          currentPage: 0,
          totalElements: cachedOrders.length,
          hasNext: false,
          hasPrevious: false,
        ),
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await ApiClient.get('/customer/orders/$orderId');
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        final order = Order.fromJson(response.data['data'] ?? {});
        
        return {
          'success': true,
          'data': order,
          'message': 'Order details loaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load order details'
        };
      }
    } catch (e) {
      print('Error loading order details: $e');
      return {
        'success': false,
        'message': 'Failed to load order details',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await ApiClient.post('/customer/orders', data: orderData);
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        final order = Order.fromJson(response.data['data'] ?? {});
        await _addToOrdersCache(order);
        
        return {
          'success': true,
          'data': order,
          'message': response.data['message'] ?? 'Order placed successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to place order'
        };
      }
    } catch (e) {
      print('Error placing order: $e');
      return {
        'success': false,
        'message': 'Failed to place order. Please try again.',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    try {
      final response = await ApiClient.post(
        '/customer/orders/$orderId/cancel',
        data: {'reason': reason},
      );
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        final order = Order.fromJson(response.data['data'] ?? {});
        await _updateOrderInCache(order);
        
        return {
          'success': true,
          'data': order,
          'message': 'Order cancelled successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to cancel order'
        };
      }
    } catch (e) {
      print('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Failed to cancel order. Please try again.',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      final response = await ApiClient.get('/customer/orders/$orderId/track');
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        final trackingData = response.data['data'] ?? {};
        
        return {
          'success': true,
          'data': trackingData,
          'message': 'Order tracking loaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load tracking information'
        };
      }
    } catch (e) {
      print('Error tracking order: $e');
      return {
        'success': false,
        'message': 'Failed to load tracking information',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> reorderItems(String orderId) async {
    try {
      final response = await ApiClient.post('/customer/orders/$orderId/reorder');
      
      if (response.statusCode == 200 && response.data['statusCode'] == '0000') {
        return {
          'success': true,
          'message': 'Items added to cart successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to add items to cart'
        };
      }
    } catch (e) {
      print('Error reordering: $e');
      return {
        'success': false,
        'message': 'Failed to add items to cart',
        'error': e.toString()
      };
    }
  }

  // Cache management
  Future<void> _cacheOrders(List<Order> orders, int page) async {
    try {
      if (page == 0) {
        // If it's the first page, replace the cache
        await LocalStorage.setList('user_orders', 
            orders.map((order) => _orderToCache(order)).toList());
      } else {
        // If it's a subsequent page, append to cache
        final cachedOrders = await _getCachedOrders();
        cachedOrders.addAll(orders);
        await LocalStorage.setList('user_orders', 
            cachedOrders.map((order) => _orderToCache(order)).toList());
      }
    } catch (e) {
      print('Error caching orders: $e');
    }
  }

  Future<List<Order>> _getCachedOrders() async {
    try {
      final cachedData = await LocalStorage.getList('user_orders');
      return cachedData
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading cached orders: $e');
      return [];
    }
  }

  Future<void> _addToOrdersCache(Order order) async {
    try {
      final cachedOrders = await _getCachedOrders();
      cachedOrders.insert(0, order); // Add to beginning
      await LocalStorage.setList('user_orders', 
          cachedOrders.map((order) => _orderToCache(order)).toList());
    } catch (e) {
      print('Error adding order to cache: $e');
    }
  }

  Future<void> _updateOrderInCache(Order updatedOrder) async {
    try {
      final cachedOrders = await _getCachedOrders();
      final index = cachedOrders.indexWhere((order) => order.id == updatedOrder.id);
      
      if (index >= 0) {
        cachedOrders[index] = updatedOrder;
        await LocalStorage.setList('user_orders', 
            cachedOrders.map((order) => _orderToCache(order)).toList());
      }
    } catch (e) {
      print('Error updating order in cache: $e');
    }
  }

  Map<String, dynamic> _orderToCache(Order order) {
    return {
      'id': order.id,
      'orderNumber': order.orderNumber,
      'orderDate': order.orderDate.toIso8601String(),
      'status': order.status,
      'totalAmount': order.totalAmount,
      'paymentMethod': order.paymentMethod,
      'paymentStatus': order.paymentStatus,
      'items': order.items.map((item) => {
        'id': item.id,
        'productId': item.productId,
        'productName': item.productName,
        'productImage': item.productImage,
        'price': item.price,
        'quantity': item.quantity,
        'totalPrice': item.totalPrice,
        'shopId': item.shopId,
        'shopName': item.shopName,
      }).toList(),
      'deliveryAddress': {
        'name': order.deliveryAddress.name,
        'phone': order.deliveryAddress.phone,
        'addressLine1': order.deliveryAddress.addressLine1,
        'addressLine2': order.deliveryAddress.addressLine2,
        'landmark': order.deliveryAddress.landmark,
        'city': order.deliveryAddress.city,
        'state': order.deliveryAddress.state,
        'pincode': order.deliveryAddress.pincode,
        'type': order.deliveryAddress.type,
      },
      'deliveryInstructions': order.deliveryInstructions,
      'estimatedDeliveryTime': order.estimatedDeliveryTime?.toIso8601String(),
      'statusHistory': order.statusHistory.map((history) => {
        'status': history.status,
        'description': history.description,
        'timestamp': history.timestamp.toIso8601String(),
        'location': history.location,
      }).toList(),
      'trackingUrl': order.trackingUrl,
      'cancellationReason': order.cancellationReason,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> clearOrdersCache() async {
    try {
      await LocalStorage.remove('user_orders');
    } catch (e) {
      print('Error clearing orders cache: $e');
    }
  }
}