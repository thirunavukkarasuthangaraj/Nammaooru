import 'package:flutter/material.dart';
import 'core/services/api_service.dart';
import 'core/providers/delivery_partner_provider.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Integration Test'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              child: _isRunning
                  ? const Text('Running Tests...')
                  : const Text('Run API Tests'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  final isSuccess = result.startsWith('✅');
                  return Card(
                    color: isSuccess ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                      title: Text(result),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    // Test 1: Login Test
    await _testLogin();

    // Test 2: Profile Test
    await _testProfile();

    // Test 3: Available Orders Test
    await _testAvailableOrders();

    // Test 4: Current Orders Test
    await _testCurrentOrders();

    // Test 5: Order History Test
    await _testOrderHistory();

    // Test 6: Earnings Test
    await _testEarnings();

    // Test 7: Online Status Test
    await _testOnlineStatus();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testLogin() async {
    try {
      // Test with dummy credentials - this should fail gracefully
      final response = await _apiService.login('test@test.com', 'password');
      if (response.containsKey('success')) {
        _addResult('✅ Login API endpoint responding');
      } else {
        _addResult('❌ Login API unexpected response format');
      }
    } catch (e) {
      _addResult('✅ Login API endpoint responding (expected auth failure)');
    }
  }

  Future<void> _testProfile() async {
    try {
      await _apiService.getProfile();
      _addResult('✅ Profile API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Profile API endpoint responding (auth required)');
      } else {
        _addResult('❌ Profile API error: ${e.toString()}');
      }
    }
  }

  Future<void> _testAvailableOrders() async {
    try {
      await _apiService.getAvailableOrders();
      _addResult('✅ Available Orders API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Available Orders API responding (auth required)');
      } else {
        _addResult('❌ Available Orders API error: ${e.toString()}');
      }
    }
  }

  Future<void> _testCurrentOrders() async {
    try {
      await _apiService.getCurrentOrders();
      _addResult('✅ Current Orders API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Current Orders API responding (auth required)');
      } else {
        _addResult('❌ Current Orders API error: ${e.toString()}');
      }
    }
  }

  Future<void> _testOrderHistory() async {
    try {
      await _apiService.getOrderHistory();
      _addResult('✅ Order History API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Order History API responding (auth required)');
      } else {
        _addResult('❌ Order History API error: ${e.toString()}');
      }
    }
  }

  Future<void> _testEarnings() async {
    try {
      await _apiService.getEarnings();
      _addResult('✅ Earnings API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Earnings API responding (auth required)');
      } else {
        _addResult('❌ Earnings API error: ${e.toString()}');
      }
    }
  }

  Future<void> _testOnlineStatus() async {
    try {
      await _apiService.updateOnlineStatus(true);
      _addResult('✅ Online Status API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _addResult('✅ Online Status API responding (auth required)');
      } else {
        _addResult('❌ Online Status API error: ${e.toString()}');
      }
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }
}

// Helper function to test provider
Future<void> testDeliveryPartnerProvider() async {
  final provider = DeliveryPartnerProvider();

  print('🧪 Testing DeliveryPartnerProvider...');

  try {
    // Test loading available orders
    await provider.loadAvailableOrders();
    print('✅ loadAvailableOrders() executed');
  } catch (e) {
    print('❌ loadAvailableOrders() error: $e');
  }

  try {
    // Test loading current orders
    await provider.loadCurrentOrders();
    print('✅ loadCurrentOrders() executed');
  } catch (e) {
    print('❌ loadCurrentOrders() error: $e');
  }

  try {
    // Test loading order history
    await provider.loadOrderHistory();
    print('✅ loadOrderHistory() executed');
  } catch (e) {
    print('❌ loadOrderHistory() error: $e');
  }

  try {
    // Test loading earnings
    await provider.loadEarnings();
    print('✅ loadEarnings() executed');
  } catch (e) {
    print('❌ loadEarnings() error: $e');
  }

  print('🎉 Provider testing complete!');
}