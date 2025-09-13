import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
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
      // For demo, create mock orders
      _availableOrders = _createMockAvailableOrders();
      _error = null;
    } catch (e) {
      _error = 'Failed to load available orders';
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
      // For demo, create mock active orders
      _activeOrders = _createMockActiveOrders();
      _error = null;
    } catch (e) {
      _error = 'Failed to load active orders';
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
      // For demo, create mock order history
      _orderHistory = _createMockOrderHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to load order history';
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

  // Mock data generation methods
  List<Order> _createMockAvailableOrders() {
    return [
      Order(
        id: 'ORD001',
        orderNumber: 'ORD001',
        customer: const Customer(
          id: 'CUST001',
          name: 'Suresh Kumar',
          phoneNumber: '+91 98765 43210',
          rating: 4.5,
        ),
        restaurant: const Restaurant(
          id: 'REST001',
          name: 'Pizza Palace',
          phoneNumber: '+91 80 12345678',
          address: Address(
            street: '123 MG Road',
            area: 'MG Road',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560001',
          ),
        ),
        items: const [
          OrderItem(id: 'ITEM001', name: 'Margherita Pizza', quantity: 2, price: 180.0),
          OrderItem(id: 'ITEM002', name: 'Coke', quantity: 1, price: 60.0),
        ],
        totalAmount: 450.0,
        deliveryFee: 30.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        deliveryAddress: const Address(
          street: '456 HSR Layout',
          area: 'HSR Layout',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560102',
        ),
        paymentMethod: PaymentMethod.cash,
        distance: 2.3,
        estimatedDuration: const Duration(minutes: 18),
      ),
      Order(
        id: 'ORD002',
        orderNumber: 'ORD002',
        customer: const Customer(
          id: 'CUST002',
          name: 'Priya Sharma',
          phoneNumber: '+91 87654 32109',
          rating: 4.8,
        ),
        restaurant: const Restaurant(
          id: 'REST002',
          name: 'KFC',
          phoneNumber: '+91 80 23456789',
          address: Address(
            street: '789 Koramangala',
            area: 'Koramangala',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560034',
          ),
        ),
        items: const [
          OrderItem(id: 'ITEM003', name: 'Chicken Burger', quantity: 1, price: 150.0),
          OrderItem(id: 'ITEM004', name: 'Fries', quantity: 1, price: 80.0),
        ],
        totalAmount: 380.0,
        deliveryFee: 25.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        deliveryAddress: const Address(
          street: '321 BTM Layout',
          area: 'BTM Layout',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560076',
        ),
        paymentMethod: PaymentMethod.upi,
        distance: 1.8,
        estimatedDuration: const Duration(minutes: 15),
      ),
    ];
  }

  List<Order> _createMockActiveOrders() {
    return [
      Order(
        id: 'ORD003',
        orderNumber: 'ORD003',
        customer: const Customer(
          id: 'CUST003',
          name: 'Vikash Patel',
          phoneNumber: '+91 67890 12345',
          rating: 4.2,
        ),
        restaurant: const Restaurant(
          id: 'REST001',
          name: 'Pizza Palace',
          phoneNumber: '+91 80 12345678',
          address: Address(
            street: '123 MG Road',
            area: 'MG Road',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560001',
          ),
        ),
        items: const [
          OrderItem(id: 'ITEM005', name: 'Margherita Pizza', quantity: 3, price: 180.0),
          OrderItem(id: 'ITEM006', name: 'Coke', quantity: 2, price: 60.0),
        ],
        totalAmount: 720.0,
        deliveryFee: 40.0,
        status: OrderStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 10)),
        deliveryAddress: const Address(
          street: '654 Indiranagar',
          area: 'Indiranagar',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560038',
        ),
        paymentMethod: PaymentMethod.card,
        distance: 3.1,
        estimatedDuration: const Duration(minutes: 25),
      ),
    ];
  }

  List<Order> _createMockOrderHistory() {
    return [
      // Add delivered orders here for history
    ];
  }
}