import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = '';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Getters
  List<Order> get orders => _filteredOrders;
  List<Order> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;

  // Statistics
  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((o) => o.status == 'PENDING').length;
  int get activeOrders => _orders.where((o) => ['CONFIRMED', 'PREPARING'].contains(o.status)).length;
  int get completedOrders => _orders.where((o) => o.status == 'DELIVERED').length;
  int get cancelledOrders => _orders.where((o) => o.status == 'CANCELLED').length;

  double get totalRevenue => _orders
      .where((o) => ['DELIVERED', 'COMPLETED'].contains(o.status))
      .fold(0.0, (sum, order) => sum + order.total);

  double get todayRevenue {
    final today = DateTime.now();
    return _orders
        .where((o) =>
            ['DELIVERED', 'COMPLETED'].contains(o.status) &&
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  List<String> get availableStatuses => [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'READY_FOR_PICKUP',
    'DELIVERED',
    'CANCELLED'
  ];

  // Initialize with mock data
  Future<void> initialize() async {
    await loadOrders();
  }

  // Load orders
  Future<void> loadOrders({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Get shop ID from storage
      final shopData = await StorageService.getShop();
      if (shopData == null) {
        print('⚠️ No shop data found in storage');
        _orders = [];
        _applyFilters();
        _setLoading(false);
        return;
      }

      final shopId = shopData['shopId'] ?? shopData['id']?.toString();
      if (shopId == null) {
        print('⚠️ No shop ID found');
        _orders = [];
        _applyFilters();
        _setLoading(false);
        return;
      }

      print('📡 Loading orders for shop: $shopId');

      // Call API to load orders
      final response = await ApiService.getShopOrders(
        shopId: shopId,
        page: page - 1, // Backend uses 0-based pagination
        size: limit,
        status: _selectedStatus.isNotEmpty ? _selectedStatus : null,
        dateFrom: _selectedStartDate?.toIso8601String(),
        dateTo: _selectedEndDate?.toIso8601String(),
      );

      if (response.isSuccess) {
        final data = response.data;
        print('✅ Orders loaded successfully: ${data}');

        // Parse orders from response
        final ordersData = data['data'] ?? data['orders'] ?? data['content'] ?? [];
        _orders = (ordersData as List).map((orderJson) => Order.fromJson(orderJson)).toList();

        print('📦 Parsed ${_orders.length} orders');
      } else {
        print('❌ Failed to load orders: ${response.error}');
        _setError(response.error ?? 'Failed to load orders');
      }

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      print('❌ Error loading orders: $e');
      _setError('Failed to load orders: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Filter orders by status
  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  // Filter orders by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedStatus = '';
    _selectedStartDate = null;
    _selectedEndDate = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    List<Order> filtered = List.from(_orders);

    // Apply status filter
    if (_selectedStatus.isNotEmpty) {
      filtered = filtered.where((order) => order.status == _selectedStatus).toList();
    }

    // Apply date range filter
    if (_selectedStartDate != null) {
      filtered = filtered.where((order) =>
          order.createdAt.isAfter(_selectedStartDate!) ||
          order.createdAt.isAtSameMomentAs(_selectedStartDate!)).toList();
    }

    if (_selectedEndDate != null) {
      filtered = filtered.where((order) =>
          order.createdAt.isBefore(_selectedEndDate!.add(const Duration(days: 1)))).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredOrders = filtered;
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await ApiService.updateOrderStatus(orderId, status);

      if (response.isSuccess) {
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: status,
            updatedAt: DateTime.now(),
            acceptedAt: status == 'CONFIRMED' ? DateTime.now() : _orders[orderIndex].acceptedAt,
            preparedAt: status == 'PREPARING' ? DateTime.now() : _orders[orderIndex].preparedAt,
            deliveredAt: status == 'DELIVERED' ? DateTime.now() : _orders[orderIndex].deliveredAt,
          );
          _applyFilters();
          notifyListeners();
        }
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to update order status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Update order error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Accept order
  Future<bool> acceptOrder(String orderId, {int? preparationTime}) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      if (!order.canBeAccepted) {
        _setError('Order cannot be accepted in current status');
        return false;
      }

      final success = await updateOrderStatus(orderId, 'CONFIRMED');
      if (success && preparationTime != null) {
        // Update preparation time if provided
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            estimatedPreparationTime: preparationTime,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to accept order: ${e.toString()}');
      return false;
    }
  }

  // Reject/Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      if (!order.canBeCancelled) {
        _setError('Order cannot be cancelled in current status');
        return false;
      }

      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          status: 'CANCELLED',
          cancellationReason: reason,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to cancel order: ${e.toString()}');
      return false;
    }
  }

  // Mark order as ready
  Future<bool> markOrderReady(String orderId) async {
    return await updateOrderStatus(orderId, 'READY_FOR_PICKUP');
  }

  // Mark order as delivered
  Future<bool> markOrderDelivered(String orderId) async {
    return await updateOrderStatus(orderId, 'DELIVERED');
  }

  // Load mock orders for development
  Future<void> _loadMockOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockOrders = [
      Order(
        id: 'ORD175864731730',
        customerId: 'cust_001',
        customerName: 'Thirunavukkarasu User',
        customerPhone: '+919876543210',
        customerEmail: 'customer@example.com',
        deliveryAddress: OrderAddress(
          street: '456 Customer Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560002',
          landmark: 'Near Park',
        ),
        items: [
          OrderItem(
            productId: 'prod_4',
            productName: 'Coffee',
            quantity: 4,
            unitPrice: 10.0,
            total: 40.0,
            price: 10.0,
            image: '☕',
          ),
          OrderItem(
            productId: 'prod_2',
            productName: 'Cough Syrup',
            quantity: 7,
            unitPrice: 100.0,
            total: 700.0,
            price: 100.0,
            image: '💊',
          ),
          OrderItem(
            productId: 'prod_5',
            productName: 'ABC',
            quantity: 3,
            unitPrice: 100.0,
            total: 300.0,
            price: 100.0,
            image: '🏠',
          ),
        ],
        subtotal: 1040.0,
        tax: 52.0,
        deliveryFee: 30.0,
        discount: 50.0,
        total: 1072.0,
        totalAmount: 1072.0,
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
        paymentMethod: 'UPI',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        estimatedPreparationTime: 30,
        notes: 'Please deliver between 2-4 PM',
      ),
      Order(
        id: 'ORD175864230918',
        customerId: 'cust_002',
        customerName: 'Rajesh Kumar',
        customerPhone: '+919876543211',
        customerEmail: 'rajesh@example.com',
        deliveryAddress: OrderAddress(
          street: '789 Another Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560003',
          landmark: 'Near Mall',
        ),
        items: [
          OrderItem(
            productId: 'prod_1',
            productName: 'Potato Chips',
            quantity: 2,
            unitPrice: 100.0,
            total: 200.0,
            price: 100.0,
            image: '🥔',
          ),
          OrderItem(
            productId: 'prod_3',
            productName: 'Magliavan',
            quantity: 1,
            unitPrice: 150.0,
            total: 150.0,
            price: 150.0,
            image: '🌶️',
          ),
        ],
        subtotal: 350.0,
        tax: 17.5,
        deliveryFee: 25.0,
        discount: 20.0,
        total: 372.5,
        totalAmount: 372.5,
        status: 'PENDING',
        paymentStatus: 'PENDING',
        paymentMethod: 'COD',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        notes: 'Call before delivery',
      ),
      Order(
        id: 'ORD175864120815',
        customerId: 'cust_003',
        customerName: 'Priya Sharma',
        customerPhone: '+919876543212',
        customerEmail: 'priya@example.com',
        deliveryAddress: OrderAddress(
          street: '321 Third Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560004',
          landmark: 'Near School',
        ),
        items: [
          OrderItem(
            productId: 'prod_2',
            productName: 'Cough Syrup',
            quantity: 1,
            unitPrice: 100.0,
            total: 100.0,
            price: 100.0,
            image: '💊',
          ),
        ],
        subtotal: 100.0,
        tax: 5.0,
        deliveryFee: 20.0,
        discount: 0.0,
        total: 125.0,
        totalAmount: 125.0,
        status: 'DELIVERED',
        paymentStatus: 'PAID',
        paymentMethod: 'Card',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 20)),
        acceptedAt: DateTime.now().subtract(const Duration(hours: 23)),
        preparedAt: DateTime.now().subtract(const Duration(hours: 22)),
        deliveredAt: DateTime.now().subtract(const Duration(hours: 20)),
        estimatedPreparationTime: 15,
      ),
      Order(
        id: 'ORD175864010712',
        customerId: 'cust_004',
        customerName: 'Amit Patel',
        customerPhone: '+919876543213',
        customerEmail: 'amit@example.com',
        deliveryAddress: OrderAddress(
          street: '654 Fourth Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560005',
          landmark: 'Near Hospital',
        ),
        items: [
          OrderItem(
            productId: 'prod_4',
            productName: 'Coffee',
            quantity: 10,
            unitPrice: 10.0,
            total: 100.0,
            price: 10.0,
            image: '☕',
          ),
          OrderItem(
            productId: 'prod_1',
            productName: 'Potato Chips',
            quantity: 5,
            unitPrice: 100.0,
            total: 500.0,
            price: 100.0,
            image: '🥔',
          ),
        ],
        subtotal: 600.0,
        tax: 30.0,
        deliveryFee: 35.0,
        discount: 60.0,
        total: 605.0,
        totalAmount: 605.0,
        status: 'PREPARING',
        paymentStatus: 'PAID',
        paymentMethod: 'UPI',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        acceptedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
        preparedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        estimatedPreparationTime: 45,
        notes: 'Extra packaging required',
      ),
      Order(
        id: 'ORD175863900609',
        customerId: 'cust_005',
        customerName: 'Sneha Reddy',
        customerPhone: '+919876543214',
        customerEmail: 'sneha@example.com',
        deliveryAddress: OrderAddress(
          street: '987 Fifth Street',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560006',
          landmark: 'Near Temple',
        ),
        items: [
          OrderItem(
            productId: 'prod_5',
            productName: 'ABC',
            quantity: 2,
            unitPrice: 100.0,
            total: 200.0,
            price: 100.0,
            image: '🏠',
          ),
          OrderItem(
            productId: 'prod_3',
            productName: 'Magliavan',
            quantity: 3,
            unitPrice: 150.0,
            total: 450.0,
            price: 150.0,
            image: '🌶️',
          ),
        ],
        subtotal: 650.0,
        tax: 32.5,
        deliveryFee: 40.0,
        discount: 65.0,
        total: 657.5,
        totalAmount: 657.5,
        status: 'CANCELLED',
        paymentStatus: 'REFUNDED',
        paymentMethod: 'Card',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        cancellationReason: 'Customer requested cancellation',
      ),
    ];

    _orders = mockOrders.cast<Order>();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Get order by ID
  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get recent orders
  List<Order> getRecentOrders({int limit = 10}) {
    final sorted = List<Order>.from(_orders);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  // Clear data
  void clear() {
    _orders.clear();
    _filteredOrders.clear();
    _selectedStatus = '';
    _selectedStartDate = null;
    _selectedEndDate = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Find driver for order (shop owner retry assignment)
  Future<Map<String, dynamic>> findDriverForOrder(String orderNumber) async {
    try {
      print('🔍 Finding driver for order: $orderNumber');

      final response = await ApiService.findDriverForOrder(orderNumber);

      if (response.isSuccess) {
        final data = response.data['data'] ?? response.data;
        print('✅ Find driver result: $data');
        return data;
      } else {
        print('❌ Find driver failed: ${response.error}');
        return {
          'success': false,
          'message': response.error ?? 'Failed to find driver',
        };
      }
    } catch (e) {
      print('❌ Error finding driver: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}