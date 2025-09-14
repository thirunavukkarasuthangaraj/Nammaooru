import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _availableOrders = [];
  List<Order> _activeOrders = [];
  List<Order> _orderHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get availableOrders => _availableOrders;
  List<Order> get activeOrders => _activeOrders;
  List<Order> get orderHistory => _orderHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load available orders for pickup
  Future<void> loadAvailableOrders() async {
    _setLoading(true);

    try {
      final response = await _apiService.getAvailableOrders();
      if (response['success'] == true && response['orders'] != null) {
        _availableOrders = (response['orders'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();
      } else {
        _availableOrders = [];
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load available orders: ${e.toString()}';
      _availableOrders = [];
      if (kDebugMode) {
        print('Load Available Orders Error: $e');
      }
    }

    _setLoading(false);
  }

  // Load active orders (accepted, picked up, in transit)
  Future<void> loadActiveOrders() async {
    _setLoading(true);

    try {
      final response = await _apiService.getActiveOrders();
      if (response['success'] == true && response['orders'] != null) {
        _activeOrders = (response['orders'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();
      } else {
        _activeOrders = [];
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load active orders: ${e.toString()}';
      _activeOrders = [];
      if (kDebugMode) {
        print('Load Active Orders Error: $e');
      }
    }

    _setLoading(false);
  }

  // Load order history
  Future<void> loadOrderHistory() async {
    _setLoading(true);

    try {
      final response = await _apiService.getOrderHistory();
      if (response['success'] == true && response['orders'] != null) {
        _orderHistory = (response['orders'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();
      } else {
        _orderHistory = [];
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load order history: ${e.toString()}';
      _orderHistory = [];
      if (kDebugMode) {
        print('Load Order History Error: $e');
      }
    }

    _setLoading(false);
  }

  // Accept an order
  Future<bool> acceptOrder(String orderId, String preparationTime) async {
    _setLoading(true);

    try {
      // Call API to accept order
      final response = await _apiService.acceptOrder(orderId);

      if (response['success'] == true) {
        // Remove from available orders and add to active orders
        final orderIndex = _availableOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          final order = _availableOrders.removeAt(orderIndex);
          final acceptedOrder = Order(
            id: order.id,
            orderNumber: order.orderNumber,
            customer: order.customer,
            restaurant: order.restaurant,
            items: order.items,
            totalAmount: order.totalAmount,
            deliveryFee: order.deliveryFee,
            status: OrderStatus.accepted,
            createdAt: order.createdAt,
            estimatedDeliveryTime: DateTime.now().add(Duration(
              minutes: int.tryParse(preparationTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 30,
            )),
            deliveryAddress: order.deliveryAddress,
            specialInstructions: order.specialInstructions,
            paymentMethod: order.paymentMethod,
            distance: order.distance,
            estimatedDuration: order.estimatedDuration,
          );

          _activeOrders.insert(0, acceptedOrder);
        }

        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Accept Order Error: $e');
      }
      return false;
    }
  }

  // Reject an order
  Future<bool> rejectOrder(String orderId) async {
    _setLoading(true);
    
    try {
      _availableOrders.removeWhere((order) => order.id == orderId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Reject Order Error: $e');
      }
      return false;
    }
  }

  // Mark order as picked up
  Future<bool> markOrderPickedUp(String orderId) async {
    _setLoading(true);

    try {
      // Call API to update order status to picked up
      final response = await _apiService.updateOrderStatus(orderId, 'PICKED_UP');

      if (response['success'] == true) {
        // Update local order status
        final orderIndex = _activeOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          final order = _activeOrders[orderIndex];
          _activeOrders[orderIndex] = Order(
            id: order.id,
            orderNumber: order.orderNumber,
            customer: order.customer,
            restaurant: order.restaurant,
            items: order.items,
            totalAmount: order.totalAmount,
            deliveryFee: order.deliveryFee,
            status: OrderStatus.pickedUp,
            createdAt: order.createdAt,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            deliveryAddress: order.deliveryAddress,
            specialInstructions: order.specialInstructions,
            paymentMethod: order.paymentMethod,
            distance: order.distance,
            estimatedDuration: order.estimatedDuration,
          );
        }

        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Mark Picked Up Error: $e');
      }
      return false;
    }
  }

  // Mark order as delivered
  Future<bool> markOrderDelivered(String orderId) async {
    _setLoading(true);

    try {
      // Call API to update order status to delivered
      final response = await _apiService.updateOrderStatus(orderId, 'DELIVERED');

      if (response['success'] == true) {
        // Update local order status
        final orderIndex = _activeOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          final order = _activeOrders.removeAt(orderIndex);
          final deliveredOrder = Order(
            id: order.id,
            orderNumber: order.orderNumber,
            customer: order.customer,
            restaurant: order.restaurant,
            items: order.items,
            totalAmount: order.totalAmount,
            deliveryFee: order.deliveryFee,
            status: OrderStatus.delivered,
            createdAt: order.createdAt,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            deliveryAddress: order.deliveryAddress,
            specialInstructions: order.specialInstructions,
            paymentMethod: order.paymentMethod,
            distance: order.distance,
            estimatedDuration: order.estimatedDuration,
          );

          _orderHistory.insert(0, deliveredOrder);
        }

        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Mark Delivered Error: $e');
      }
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}