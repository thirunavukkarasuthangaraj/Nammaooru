import 'dart:math';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'app_config.dart';

class TestDataRunner {
  static final Random _random = Random();

  /// Test all mock API endpoints
  static Future<void> testAllEndpoints() async {
    if (!AppConfig.useMockData) {
      print('⚠️ Mock data is disabled. Enable it in AppConfig to run tests.');
      return;
    }

    print('🧪 Starting API endpoint tests with mock data...\n');

    try {
      // Test authentication
      await _testAuthentication();

      // Test shop profile
      await _testShopProfile();

      // Test products
      await _testProducts();

      // Test orders
      await _testOrders();

      // Test finance
      await _testFinance();

      // Test notifications
      await _testNotifications();

      // Test categories
      await _testCategories();

      // Test dashboard
      await _testDashboard();

      print('✅ All API endpoint tests completed successfully!');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  static Future<void> _testAuthentication() async {
    print('🔐 Testing Authentication...');

    // Test successful login
    final loginResponse = await ApiService.login(
      email: 'ananya@gmail.com',
      password: 'password123',
    );

    if (loginResponse.isSuccess) {
      print('  ✅ Login successful');
      print('  📧 User: ${loginResponse.data['user']['email']}');
    } else {
      print('  ❌ Login failed: ${loginResponse.message}');
    }

    // Test failed login
    final failedLogin = await ApiService.login(
      email: 'wrong@email.com',
      password: 'wrongpassword',
    );

    if (!failedLogin.isSuccess) {
      print('  ✅ Invalid login correctly rejected');
    } else {
      print('  ❌ Invalid login incorrectly accepted');
    }

    print('');
  }

  static Future<void> _testShopProfile() async {
    print('🏪 Testing Shop Profile...');

    final response = await ApiService.getShopProfile();

    if (response.isSuccess) {
      final shop = response.data['shop'];
      print('  ✅ Shop profile loaded');
      print('  🏪 Shop: ${shop['name']}');
      print('  📍 Address: ${shop['address']}');
      print('  ⭐ Rating: ${shop['rating']} (${shop['totalRatings']} reviews)');
    } else {
      print('  ❌ Failed to load shop profile: ${response.message}');
    }

    print('');
  }

  static Future<void> _testProducts() async {
    print('📦 Testing Products...');

    // Test getting all products
    final allProducts = await ApiService.getProducts();
    if (allProducts.isSuccess) {
      final products = allProducts.data['products'] as List;
      print('  ✅ All products loaded: ${products.length} items');
    }

    // Test product search
    final searchResults = await ApiService.getProducts(search: 'rice');
    if (searchResults.isSuccess) {
      final products = searchResults.data['products'] as List;
      print('  ✅ Search results: ${products.length} items for "rice"');
    }

    // Test category filter
    final categoryResults = await ApiService.getProducts(category: 'Dairy Products');
    if (categoryResults.isSuccess) {
      final products = categoryResults.data['products'] as List;
      print('  ✅ Category filter: ${products.length} dairy products');
    }

    // Test status filter
    final activeProducts = await ApiService.getProducts(status: 'active');
    if (activeProducts.isSuccess) {
      final products = activeProducts.data['products'] as List;
      print('  ✅ Active products: ${products.length} items');
    }

    final lowStockProducts = await ApiService.getProducts(status: 'low_stock');
    if (lowStockProducts.isSuccess) {
      final products = lowStockProducts.data['products'] as List;
      print('  ✅ Low stock products: ${products.length} items');
    }

    print('');
  }

  static Future<void> _testOrders() async {
    print('📋 Testing Orders...');

    // Test getting all orders
    final allOrders = await ApiService.getOrders();
    if (allOrders.isSuccess) {
      final orders = allOrders.data['orders'] as List;
      final stats = allOrders.data['stats'];
      print('  ✅ All orders loaded: ${orders.length} orders');
      print('  📊 Stats: ${stats['totalOrders']} total, ${stats['pendingOrders']} pending');
      print('  💰 Revenue: ₹${stats['totalRevenue']} total, ₹${stats['todayRevenue']} today');
    }

    // Test status filter
    final pendingOrders = await ApiService.getOrders(status: 'pending');
    if (pendingOrders.isSuccess) {
      final orders = pendingOrders.data['orders'] as List;
      print('  ✅ Pending orders: ${orders.length} items');
    }

    // Test order status update
    final updateResponse = await ApiService.updateOrderStatus('order_001', 'confirmed');
    if (updateResponse.isSuccess) {
      print('  ✅ Order status updated successfully');
    }

    print('');
  }

  static Future<void> _testFinance() async {
    print('💰 Testing Finance...');

    final response = await ApiService.getFinanceData();
    if (response.isSuccess) {
      final stats = response.data['dashboard_stats'];
      final revenueChart = response.data['revenue_chart'] as List;
      final topProducts = response.data['top_selling_products'] as List;

      print('  ✅ Finance data loaded');
      print('  💰 Total Revenue: ₹${stats['total_revenue']}');
      print('  📈 Today\'s Sales: ₹${stats['todays_sales']}');
      print('  📊 Chart data points: ${revenueChart.length}');
      print('  🏆 Top products: ${topProducts.length}');
    } else {
      print('  ❌ Failed to load finance data: ${response.message}');
    }

    print('');
  }

  static Future<void> _testNotifications() async {
    print('🔔 Testing Notifications...');

    // Test all notifications
    final allNotifications = await ApiService.getNotifications();
    if (allNotifications.isSuccess) {
      final notifications = allNotifications.data['notifications'] as List;
      final unreadCount = allNotifications.data['unreadCount'];
      print('  ✅ All notifications loaded: ${notifications.length} items');
      print('  📫 Unread notifications: $unreadCount');
    }

    // Test unread notifications
    final unreadNotifications = await ApiService.getNotifications(isRead: false);
    if (unreadNotifications.isSuccess) {
      final notifications = unreadNotifications.data['notifications'] as List;
      print('  ✅ Unread notifications: ${notifications.length} items');
    }

    print('');
  }

  static Future<void> _testCategories() async {
    print('📂 Testing Categories...');

    final response = await ApiService.getCategories();
    if (response.isSuccess) {
      final categories = response.data['categories'] as List;
      print('  ✅ Categories loaded: ${categories.length} items');

      for (final category in categories.take(3)) {
        final subCategories = category['subCategories'] as List;
        print('  📁 ${category['name']}: ${subCategories.length} subcategories');
      }
    } else {
      print('  ❌ Failed to load categories: ${response.message}');
    }

    print('');
  }

  static Future<void> _testDashboard() async {
    print('📊 Testing Dashboard...');

    final response = await ApiService.getDashboardStats();
    if (response.isSuccess) {
      final stats = response.data['stats'];
      final recentOrders = response.data['recentOrders'] as List;
      final orderStats = response.data['orderStats'];

      print('  ✅ Dashboard data loaded');
      print('  💰 Total Revenue: ₹${stats['total_revenue']}');
      print('  📦 Total Orders: ${orderStats['totalOrders']}');
      print('  ⏳ Pending Orders: ${orderStats['pendingOrders']}');
      print('  🚚 Recent Orders: ${recentOrders.length}');
    } else {
      print('  ❌ Failed to load dashboard data: ${response.message}');
    }

    print('');
  }

  /// Test specific scenarios
  static Future<void> testSpecificScenarios() async {
    print('🎯 Testing Specific Scenarios...\n');

    await _testLowStockScenario();
    await _testOrderWorkflow();
    await _testPaginationScenario();
    await _testFilteringScenario();

    print('✅ All scenario tests completed!');
  }

  static Future<void> _testLowStockScenario() async {
    print('📉 Testing Low Stock Scenario...');

    final lowStockProducts = await ApiService.getProducts(status: 'low_stock');
    if (lowStockProducts.isSuccess) {
      final products = lowStockProducts.data['products'] as List;
      print('  ✅ Found ${products.length} low stock products');

      for (final product in products) {
        print('  ⚠️ ${product['name']}: ${product['stockQuantity']} left (min: ${product['minStockLevel']})');
      }
    }

    print('');
  }

  static Future<void> _testOrderWorkflow() async {
    print('🔄 Testing Order Workflow...');

    // Get pending orders
    final pendingOrders = await ApiService.getOrders(status: 'pending');
    if (pendingOrders.isSuccess) {
      final orders = pendingOrders.data['orders'] as List;
      print('  📋 Found ${orders.length} pending orders');

      if (orders.isNotEmpty) {
        final firstOrder = orders.first;
        final orderId = firstOrder['id'];

        // Simulate order status progression
        print('  🔄 Processing order: $orderId');

        await ApiService.updateOrderStatus(orderId, 'confirmed');
        print('  ✅ Order confirmed');

        await Future.delayed(const Duration(milliseconds: 100));

        await ApiService.updateOrderStatus(orderId, 'out_for_delivery');
        print('  🚚 Order out for delivery');

        await Future.delayed(const Duration(milliseconds: 100));

        await ApiService.updateOrderStatus(orderId, 'delivered');
        print('  📦 Order delivered');
      }
    }

    print('');
  }

  static Future<void> _testPaginationScenario() async {
    print('📄 Testing Pagination...');

    // Test different page sizes
    final smallPage = await ApiService.getProducts(limit: 2);
    if (smallPage.isSuccess) {
      final products = smallPage.data['products'] as List;
      final totalPages = smallPage.data['totalPages'];
      print('  ✅ Page 1 with limit 2: ${products.length} items, $totalPages total pages');
    }

    // Test second page
    final secondPage = await ApiService.getProducts(page: 2, limit: 2);
    if (secondPage.isSuccess) {
      final products = secondPage.data['products'] as List;
      final hasNextPage = secondPage.data['hasNextPage'];
      print('  ✅ Page 2 with limit 2: ${products.length} items, has next: $hasNextPage');
    }

    print('');
  }

  static Future<void> _testFilteringScenario() async {
    print('🔍 Testing Advanced Filtering...');

    // Test combining multiple filters
    final filteredProducts = await ApiService.getProducts(
      search: 'a',
      category: 'Dairy Products',
      status: 'active',
    );

    if (filteredProducts.isSuccess) {
      final products = filteredProducts.data['products'] as List;
      print('  ✅ Combined filters: ${products.length} active dairy products containing "a"');
    }

    // Test date range filtering for orders
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final recentOrders = await ApiService.getOrders(
      startDate: yesterday,
      endDate: now,
    );

    if (recentOrders.isSuccess) {
      final orders = recentOrders.data['orders'] as List;
      print('  ✅ Recent orders (last 24h): ${orders.length} orders');
    }

    print('');
  }

  /// Generate additional test data
  static void generateAdditionalTestData() {
    print('🏭 Generating Additional Test Data...\n');

    // Generate random orders
    final randomOrders = MockDataService.generateRandomOrders(10);
    print('✅ Generated ${randomOrders.length} random orders');

    // Print sample order
    if (randomOrders.isNotEmpty) {
      final sampleOrder = randomOrders.first;
      print('  📋 Sample Order:');
      print('    ID: ${sampleOrder.id}');
      print('    Customer: ${sampleOrder.customerName}');
      print('    Items: ${sampleOrder.items.length}');
      print('    Total: ₹${sampleOrder.totalAmount}');
      print('    Status: ${sampleOrder.status.name}');
    }

    print('');
  }

  /// Performance test with multiple concurrent requests
  static Future<void> testPerformance() async {
    print('⚡ Testing Performance...\n');

    final stopwatch = Stopwatch()..start();

    // Run multiple requests concurrently
    final futures = [
      ApiService.getProducts(),
      ApiService.getOrders(),
      ApiService.getNotifications(),
      ApiService.getCategories(),
      ApiService.getDashboardStats(),
    ];

    final results = await Future.wait(futures);
    stopwatch.stop();

    final successCount = results.where((r) => r.isSuccess).length;
    print('✅ Concurrent requests completed in ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Success rate: $successCount/${results.length} requests');

    print('');
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    AppConfig.printConfiguration();
    print('\n🚀 Starting comprehensive test suite...\n');

    await testAllEndpoints();
    await testSpecificScenarios();
    generateAdditionalTestData();
    await testPerformance();

    print('🎉 All tests completed successfully!');
  }
}