import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../models/earnings_model.dart';

class EarningsProvider with ChangeNotifier {
  Earnings? _earnings;
  List<WithdrawalRequest> _withdrawalHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Earnings? get earnings => _earnings;
  List<WithdrawalRequest> get withdrawalHistory => _withdrawalHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load earnings for a specific period
  Future<void> loadEarnings(EarningsPeriod period) async {
    _setLoading(true);
    
    try {
      // For demo, create mock earnings data
      _earnings = _createMockEarnings(period);
      _error = null;
    } catch (e) {
      _error = 'Failed to load earnings data';
      if (kDebugMode) {
        print('Load Earnings Error: $e');
      }
    }
    
    _setLoading(false);
  }

  // Load withdrawal history
  Future<void> loadWithdrawalHistory() async {
    _setLoading(true);
    
    try {
      // For demo, create mock withdrawal history
      _withdrawalHistory = _createMockWithdrawalHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to load withdrawal history';
      if (kDebugMode) {
        print('Load Withdrawal History Error: $e');
      }
    }
    
    _setLoading(false);
  }

  // Request withdrawal
  Future<bool> requestWithdrawal(double amount) async {
    _setLoading(true);
    
    try {
      // In real app, make API call to request withdrawal
      final response = await http.post(
        Uri.parse(ApiEndpoints.withdrawEarnings),
        headers: ApiEndpoints.defaultHeaders,
        body: json.encode({
          'amount': amount,
          'bankAccountId': 'default',
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        // Add new withdrawal request to history
        final newRequest = WithdrawalRequest(
          id: 'WD${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          requestDate: DateTime.now(),
          status: WithdrawalStatus.pending,
          bankDetails: const BankDetails(
            bankName: 'HDFC Bank',
            accountNumber: '****1234',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'Rajesh Kumar',
          ),
        );
        
        _withdrawalHistory.insert(0, newRequest);
        
        // Update available earnings (subtract withdrawn amount)
        if (_earnings != null) {
          _earnings = Earnings(
            totalEarnings: _earnings!.totalEarnings - amount,
            baseEarnings: _earnings!.baseEarnings,
            distanceBonus: _earnings!.distanceBonus,
            customerTips: _earnings!.customerTips,
            totalDeliveries: _earnings!.totalDeliveries,
            onlineTime: _earnings!.onlineTime,
            efficiency: _earnings!.efficiency,
            recentDeliveries: _earnings!.recentDeliveries,
            bankDetails: _earnings!.bankDetails,
            period: _earnings!.period,
          );
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Request Withdrawal Error: $e');
      }
      
      // For demo, always succeed
      final newRequest = WithdrawalRequest(
        id: 'WD${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        requestDate: DateTime.now(),
        status: WithdrawalStatus.pending,
        bankDetails: const BankDetails(
          bankName: 'HDFC Bank',
          accountNumber: '****1234',
          ifscCode: 'HDFC0001234',
          accountHolderName: 'Rajesh Kumar',
        ),
      );
      
      _withdrawalHistory.insert(0, newRequest);
      notifyListeners();
      
      return true;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Mock data generation
  Earnings _createMockEarnings(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return Earnings(
          totalEarnings: 640.0,
          baseEarnings: 520.0,
          distanceBonus: 75.0,
          customerTips: 45.0,
          totalDeliveries: 8,
          onlineTime: const Duration(hours: 6, minutes: 30),
          efficiency: 92.0,
          recentDeliveries: _createMockTodayDeliveries(),
          bankDetails: const BankDetails(
            bankName: 'HDFC Bank',
            accountNumber: '****1234',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'Rajesh Kumar',
          ),
          period: period,
        );
        
      case EarningsPeriod.week:
        return Earnings(
          totalEarnings: 3850.0,
          baseEarnings: 3200.0,
          distanceBonus: 425.0,
          customerTips: 225.0,
          totalDeliveries: 42,
          onlineTime: const Duration(hours: 32, minutes: 15),
          efficiency: 89.0,
          recentDeliveries: _createMockWeekDeliveries(),
          bankDetails: const BankDetails(
            bankName: 'HDFC Bank',
            accountNumber: '****1234',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'Rajesh Kumar',
          ),
          period: period,
        );
        
      case EarningsPeriod.month:
        return Earnings(
          totalEarnings: 18640.0,
          baseEarnings: 15200.0,
          distanceBonus: 2140.0,
          customerTips: 1300.0,
          totalDeliveries: 186,
          onlineTime: const Duration(hours: 148, minutes: 30),
          efficiency: 91.0,
          recentDeliveries: _createMockMonthDeliveries(),
          bankDetails: const BankDetails(
            bankName: 'HDFC Bank',
            accountNumber: '****1234',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'Rajesh Kumar',
          ),
          period: period,
        );
        
      case EarningsPeriod.all:
        return Earnings(
          totalEarnings: 45280.0,
          baseEarnings: 38400.0,
          distanceBonus: 4320.0,
          customerTips: 2560.0,
          totalDeliveries: 456,
          onlineTime: const Duration(hours: 320, minutes: 45),
          efficiency: 90.0,
          recentDeliveries: _createMockAllTimeDeliveries(),
          bankDetails: const BankDetails(
            bankName: 'HDFC Bank',
            accountNumber: '****1234',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'Rajesh Kumar',
          ),
          period: period,
        );
    }
  }

  List<DeliveryEarning> _createMockTodayDeliveries() {
    return [
      DeliveryEarning(
        orderId: 'ORD12345',
        orderNumber: 'ORD12345',
        restaurantName: 'Pizza Palace',
        deliveryArea: 'HSR Layout',
        earnings: 85.0,
        deliveryTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        rating: 4.8,
      ),
      DeliveryEarning(
        orderId: 'ORD12344',
        orderNumber: 'ORD12344',
        restaurantName: 'KFC',
        deliveryArea: 'Jayanagar',
        earnings: 75.0,
        deliveryTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        rating: 4.9,
      ),
      DeliveryEarning(
        orderId: 'ORD12343',
        orderNumber: 'ORD12343',
        restaurantName: 'McDonald\'s',
        deliveryArea: 'BTM Layout',
        earnings: 90.0,
        deliveryTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
        rating: 4.6,
      ),
      DeliveryEarning(
        orderId: 'ORD12342',
        orderNumber: 'ORD12342',
        restaurantName: 'Subway',
        deliveryArea: 'Koramangala',
        earnings: 70.0,
        deliveryTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
        rating: 4.7,
      ),
      DeliveryEarning(
        orderId: 'ORD12341',
        orderNumber: 'ORD12341',
        restaurantName: 'Pizza Hut',
        deliveryArea: 'Indiranagar',
        earnings: 95.0,
        deliveryTime: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
        rating: 4.8,
      ),
    ];
  }

  List<DeliveryEarning> _createMockWeekDeliveries() {
    // Similar structure but with more deliveries across the week
    return _createMockTodayDeliveries();
  }

  List<DeliveryEarning> _createMockMonthDeliveries() {
    // Similar structure but with deliveries across the month
    return _createMockTodayDeliveries();
  }

  List<DeliveryEarning> _createMockAllTimeDeliveries() {
    // Similar structure but with deliveries across all time
    return _createMockTodayDeliveries();
  }

  List<WithdrawalRequest> _createMockWithdrawalHistory() {
    return [
      WithdrawalRequest(
        id: 'WD001',
        amount: 2500.0,
        requestDate: DateTime.now().subtract(const Duration(days: 3)),
        status: WithdrawalStatus.completed,
        bankDetails: const BankDetails(
          bankName: 'HDFC Bank',
          accountNumber: '****1234',
          ifscCode: 'HDFC0001234',
          accountHolderName: 'Rajesh Kumar',
        ),
        transactionId: 'TXN123456789',
        processedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WithdrawalRequest(
        id: 'WD002',
        amount: 1800.0,
        requestDate: DateTime.now().subtract(const Duration(days: 8)),
        status: WithdrawalStatus.completed,
        bankDetails: const BankDetails(
          bankName: 'HDFC Bank',
          accountNumber: '****1234',
          ifscCode: 'HDFC0001234',
          accountHolderName: 'Rajesh Kumar',
        ),
        transactionId: 'TXN123456788',
        processedDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}