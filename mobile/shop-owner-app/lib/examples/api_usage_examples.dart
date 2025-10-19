// This file demonstrates how to use the implemented API methods
// These are example functions showing the proper usage patterns

import '../services/api_service.dart';
import '../models/api_response.dart';

class ApiUsageExamples {
  // Authentication Examples
  static Future<void> loginExample() async {
    final response = await ApiService.login(
      username: 'shopowner@example.com',
      password: 'password123',
    );

    if (response.success) {
      final data = response.data['data'];
      print('Login successful: ${data['accessToken']}');
    } else {
      print('Login failed: ${response.error}');
    }
  }

  static Future<void> registerExample() async {
    final response = await ApiService.register(
      username: 'newshop@example.com',
      email: 'newshop@example.com',
      password: 'password123',
      firstName: 'John',
      lastName: 'Doe',
      phone: '9876543210',
    );

    if (response.success) {
      print('Registration successful');
    } else {
      print('Registration failed: ${response.error}');
    }
  }

  static Future<void> otpLoginExample() async {
    // Send OTP
    final sendOtpResponse = await ApiService.sendOtp(
      email: 'shopowner@example.com',
      purpose: 'LOGIN',
    );

    if (sendOtpResponse.success) {
      print('OTP sent successfully');

      // Verify OTP
      final verifyResponse = await ApiService.verifyOtp(
        email: 'shopowner@example.com',
        otp: '123456',
        purpose: 'LOGIN',
      );

      if (verifyResponse.success) {
        print('OTP verification successful');
      }
    }
  }

  // Shop Management Examples
  static Future<void> shopProfileExample() async {
    // Get my shop
    final response = await ApiService.getMyShop();

    if (response.success) {
      final shopData = response.data['data'];
      print('Shop name: ${shopData['name']}');
    }
  }

  static Future<void> createShopExample() async {
    final shopData = {
      'name': 'My Store',
      'description': 'Best store in town',
      'businessType': 'RETAIL',
      'phoneNumber': '9876543210',
      'email': 'store@example.com',
      'address': {
        'street': '123 Main St',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'zipCode': '600001',
        'country': 'India'
      },
      'location': {
        'latitude': 13.0827,
        'longitude': 80.2707
      },
      'gstNumber': '29ABCDE1234F1Z5',
      'panNumber': 'ABCDE1234F',
      'bankDetails': {
        'accountName': 'My Store',
        'accountNumber': '12345678901234',
        'bankName': 'State Bank',
        'ifscCode': 'SBIN0001234'
      }
    };

    final response = await ApiService.createShop(shopData);

    if (response.success) {
      print('Shop created successfully');
    }
  }

  // Business Hours Examples
  static Future<void> businessHoursExample() async {
    // Get business hours
    final getResponse = await ApiService.getShopBusinessHours('1');

    if (getResponse.success) {
      print('Business hours retrieved');
    }

    // Create business hours
    final businessHours = {
      'shopId': 1,
      'dayOfWeek': 'MONDAY',
      'openTime': '09:00',
      'closeTime': '21:00',
      'isOpen': true,
      'is24Hours': false,
      'breakStartTime': '13:00',
      'breakEndTime': '14:00',
      'specialNote': 'Lunch break 1-2 PM'
    };

    final createResponse = await ApiService.createBusinessHours(businessHours);

    if (createResponse.success) {
      print('Business hours created');
    }

    // Bulk update business hours
    final weeklySchedule = [
      {
        'dayOfWeek': 'MONDAY',
        'openTime': '09:00',
        'closeTime': '21:00',
        'isOpen': true
      },
      {
        'dayOfWeek': 'TUESDAY',
        'openTime': '09:00',
        'closeTime': '21:00',
        'isOpen': true
      }
    ];

    final bulkResponse = await ApiService.bulkUpdateBusinessHours('1', weeklySchedule);

    if (bulkResponse.success) {
      print('Business hours bulk updated');
    }

    // Check if shop is open
    final isOpenResponse = await ApiService.checkShopIsOpen('1');
    if (isOpenResponse.success) {
      print('Shop is currently open: ${isOpenResponse.data['data']}');
    }
  }

  // Product Management Examples
  static Future<void> productManagementExample() async {
    // Get my products
    final getProductsResponse = await ApiService.getMyProducts(
      page: 0,
      size: 10,
      sortBy: 'updatedAt',
      sortDirection: 'DESC',
    );

    if (getProductsResponse.success) {
      final products = getProductsResponse.data['data']['content'];
      print('Retrieved ${products.length} products');
    }

    // Create a new product
    final productData = {
      'masterProductId': 123,
      'customName': 'Special Rice - 5kg',
      'customDescription': 'Premium quality basmati rice',
      'price': 250.00,
      'mrp': 300.00,
      'stockQuantity': 100,
      'minOrderQuantity': 1,
      'maxOrderQuantity': 10,
      'unit': 'KG',
      'isActive': true,
      'isFeatured': false,
      'discount': 10.5
    };

    final createResponse = await ApiService.createShopProduct(productData);

    if (createResponse.success) {
      print('Product created successfully');
    }

    // Update product
    final updateData = {
      'customName': 'Updated Product Name',
      'price': 275.00,
      'stockQuantity': 150,
      'isActive': true
    };

    final updateResponse = await ApiService.updateShopProduct('1', updateData);

    if (updateResponse.success) {
      print('Product updated successfully');
    }

    // Update inventory
    final inventoryResponse = await ApiService.updateInventory('1', 50, 'ADD');

    if (inventoryResponse.success) {
      print('Inventory updated successfully');
    }

    // Get low stock products
    final lowStockResponse = await ApiService.getLowStockProducts();

    if (lowStockResponse.success) {
      print('Low stock products retrieved');
    }

    // Get product statistics
    final statsResponse = await ApiService.getProductStatistics();

    if (statsResponse.success) {
      print('Product statistics retrieved');
    }

    // Browse available master products
    final masterProductsResponse = await ApiService.getAvailableMasterProducts(
      search: 'rice',
      categoryId: '1',
      page: 0,
      size: 12,
    );

    if (masterProductsResponse.success) {
      print('Master products retrieved');
    }
  }

  // Dashboard Examples
  static Future<void> dashboardExample() async {
    // Get today's revenue
    final revenueResponse = await ApiService.getTodaysRevenue();
    if (revenueResponse.success) {
      print('Today\'s revenue: Rs.${revenueResponse.data['data']}');
    }

    // Get today's orders
    final ordersResponse = await ApiService.getTodaysOrders();
    if (ordersResponse.success) {
      print('Today\'s orders: ${ordersResponse.data['data']}');
    }

    // Get product count
    final productCountResponse = await ApiService.getProductCount();
    if (productCountResponse.success) {
      print('Total products: ${productCountResponse.data['data']}');
    }

    // Get low stock count
    final lowStockCountResponse = await ApiService.getLowStockCount();
    if (lowStockCountResponse.success) {
      print('Low stock products: ${lowStockCountResponse.data['data']}');
    }

    // Get customer count
    final customerCountResponse = await ApiService.getCustomerCount();
    if (customerCountResponse.success) {
      print('Total customers: ${customerCountResponse.data['data']}');
    }

    // Get new customers
    final newCustomersResponse = await ApiService.getNewCustomers();
    if (newCustomersResponse.success) {
      print('New customers (30 days): ${newCustomersResponse.data['data']}');
    }

    // Get recent orders
    final recentOrdersResponse = await ApiService.getRecentOrders(limit: 5);
    if (recentOrdersResponse.success) {
      final orders = recentOrdersResponse.data['data'];
      print('Recent orders: ${orders.length}');
    }

    // Get dashboard low stock products
    final dashboardLowStockResponse = await ApiService.getDashboardLowStockProducts(limit: 10);
    if (dashboardLowStockResponse.success) {
      final products = dashboardLowStockResponse.data['data'];
      print('Dashboard low stock: ${products.length}');
    }

    // Get comprehensive dashboard stats
    final dashboardStatsResponse = await ApiService.getDashboardStats();
    if (dashboardStatsResponse.success) {
      print('Dashboard stats retrieved');
    }
  }

  // Order Management Examples
  static Future<void> orderManagementExample() async {
    // Get shop orders
    final ordersResponse = await ApiService.getShopOrders(
      '1',
      page: 0,
      size: 20,
      sortBy: 'createdAt',
      sortDir: 'desc',
      status: 'PENDING',
    );

    if (ordersResponse.success) {
      print('Orders retrieved');
    }

    // Update order status
    final updateStatusResponse = await ApiService.updateOrderStatus('1', 'CONFIRMED');

    if (updateStatusResponse.success) {
      print('Order status updated');
    }

    // Reject order
    final rejectResponse = await ApiService.rejectOrder('1', 'Product out of stock');

    if (rejectResponse.success) {
      print('Order rejected');
    }
  }

  // Notification Examples
  static Future<void> notificationExample() async {
    // Get my notifications
    final response = await ApiService.getMyNotifications(
      page: 0,
      size: 20,
    );

    if (response.success) {
      final notifications = response.data['data']['content'];
      print('Retrieved ${notifications.length} notifications');
    }

    // Mark notification as read
    final markReadResponse = await ApiService.markNotificationAsRead('1');

    if (markReadResponse.success) {
      print('Notification marked as read');
    }
  }

  // FCM Token Example
  static Future<void> fcmTokenExample() async {
    final response = await ApiService.submitFcmToken(
      token: 'fcm_device_token_here',
      deviceType: 'MOBILE',
    );

    if (response.success) {
      print('FCM token submitted successfully');
    }
  }

  // Shop Availability Example
  static Future<void> shopAvailabilityExample() async {
    final response = await ApiService.getShopAvailability('1');

    if (response.success) {
      print('Shop availability checked');
    }
  }
}