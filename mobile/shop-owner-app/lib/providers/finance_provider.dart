import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class FinanceProvider extends ChangeNotifier {
  FinanceSummary? _financeSummary;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedTransactionType = '';
  String _selectedPaymentMethod = '';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Getters
  FinanceSummary? get financeSummary => _financeSummary;
  List<Transaction> get transactions => _filteredTransactions;
  List<Transaction> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedTransactionType => _selectedTransactionType;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;

  // Statistics from summary
  double get totalRevenue => _financeSummary?.totalRevenue ?? 0.0;
  double get todayRevenue => _financeSummary?.todayRevenue ?? 0.0;
  double get monthRevenue => _financeSummary?.monthRevenue ?? 0.0;
  double get yearRevenue => _financeSummary?.yearRevenue ?? 0.0;
  double get totalExpenses => _financeSummary?.totalExpenses ?? 0.0;
  double get pendingAmount => _financeSummary?.pendingAmount ?? 0.0;
  double get commission => _financeSummary?.commission ?? 0.0;
  double get netRevenue => _financeSummary?.netRevenue ?? 0.0;
  double get growthRate => _financeSummary?.growthRate ?? 0.0;
  int get totalOrders => _financeSummary?.totalOrders ?? 0;
  int get todayOrders => _financeSummary?.todayOrders ?? 0;
  double get averageOrderValue => _financeSummary?.averageOrderValue ?? 0.0;

  Map<String, double> get paymentMethodBreakdown =>
      _financeSummary?.paymentMethodBreakdown ?? {};
  Map<String, double> get monthlyRevenue => _financeSummary?.monthlyRevenue ?? {};

  // Transaction types and payment methods
  List<String> get transactionTypes => [
    'ORDER',
    'EXPENSE',
    'COMMISSION',
    'REFUND',
    'ADJUSTMENT'
  ];

  List<String> get paymentMethods => [
    'UPI',
    'Card',
    'Cash',
    'Net Banking',
    'Wallet'
  ];

  // Initialize with mock data
  Future<void> initialize() async {
    await loadFinanceData();
    await loadTransactions();
  }

  // Load finance summary data
  Future<void> loadFinanceData() async {
    try {
      _setLoading(true);
      _clearError();

      // Load from API or use mock data
      await _loadMockFinanceData();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load finance data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load transactions
  Future<void> loadTransactions({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Load from API or use mock data
      await _loadMockTransactions();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load transactions: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Filter transactions by type
  void filterByTransactionType(String type) {
    _selectedTransactionType = type;
    _applyFilters();
    notifyListeners();
  }

  // Filter transactions by payment method
  void filterByPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    _applyFilters();
    notifyListeners();
  }

  // Filter transactions by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedTransactionType = '';
    _selectedPaymentMethod = '';
    _selectedStartDate = null;
    _selectedEndDate = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters to transactions
  void _applyFilters() {
    List<Transaction> filtered = List.from(_transactions);

    // Apply transaction type filter
    if (_selectedTransactionType.isNotEmpty) {
      filtered = filtered.where((t) => t.type == _selectedTransactionType).toList();
    }

    // Apply payment method filter
    if (_selectedPaymentMethod.isNotEmpty) {
      filtered = filtered.where((t) => t.paymentMethod == _selectedPaymentMethod).toList();
    }

    // Apply date range filter
    if (_selectedStartDate != null) {
      filtered = filtered.where((t) =>
          t.createdAt.isAfter(_selectedStartDate!) ||
          t.createdAt.isAtSameMomentAs(_selectedStartDate!)).toList();
    }

    if (_selectedEndDate != null) {
      filtered = filtered.where((t) =>
          t.createdAt.isBefore(_selectedEndDate!.add(const Duration(days: 1)))).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredTransactions = filtered;
  }

  // Get transactions by date range
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) =>
        t.createdAt.isAfter(start.subtract(const Duration(days: 1))) &&
        t.createdAt.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  // Get revenue for specific period
  double getRevenueForPeriod(DateTime start, DateTime end) {
    return getTransactionsByDateRange(start, end)
        .where((t) => t.isCredit && t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get expenses for specific period
  double getExpensesForPeriod(DateTime start, DateTime end) {
    return getTransactionsByDateRange(start, end)
        .where((t) => t.isDebit && t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get daily revenue for chart
  Map<DateTime, double> getDailyRevenue(int days) {
    final Map<DateTime, double> dailyRevenue = {};
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dayRevenue = _transactions
          .where((t) =>
              t.isCredit &&
              t.isCompleted &&
              t.createdAt.year == date.year &&
              t.createdAt.month == date.month &&
              t.createdAt.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      dailyRevenue[date] = dayRevenue;
    }

    return dailyRevenue;
  }

  // Load mock finance data
  Future<void> _loadMockFinanceData() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockFinanceSummary = FinanceSummary(
      totalRevenue: 2184.0,
      todayRevenue: 1460.0,
      monthRevenue: 15680.0,
      yearRevenue: 98420.0,
      totalExpenses: 1250.0,
      pendingAmount: 200.0,
      commission: 218.4, // 10% of total revenue
      totalOrders: 125,
      todayOrders: 8,
      averageOrderValue: 724.0,
      paymentMethodBreakdown: {
        'Card': 1200.0,
        'Cash': 684.0,
        'UPI': 300.0,
      },
      monthlyRevenue: {
        'Jan': 8420.0,
        'Feb': 9200.0,
        'Mar': 8950.0,
        'Apr': 9680.0,
        'May': 10200.0,
        'Jun': 11580.0,
        'Jul': 12450.0,
        'Aug': 13200.0,
        'Sep': 15680.0,
      },
      lastUpdated: DateTime.now(),
    );

    _financeSummary = mockFinanceSummary;
  }

  // Load mock transactions
  Future<void> _loadMockTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final mockTransactions = [
      Transaction(
        id: 'txn_001',
        type: 'ORDER',
        amount: 1072.0,
        currency: 'INR',
        description: 'Order #ORD175864731730 - Thirunavukkarasu User',
        status: 'COMPLETED',
        orderId: 'ORD175864731730',
        customerId: 'cust_001',
        customerName: 'Thirunavukkarasu User',
        paymentMethod: 'UPI',
        paymentId: 'upi_pay_001',
        referenceId: 'REF001',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        metadata: {
          'paymentApp': 'PhonePe',
          'transactionId': 'PHONEPE123456',
        },
      ),
      Transaction(
        id: 'txn_002',
        type: 'ORDER',
        amount: 125.0,
        currency: 'INR',
        description: 'Order #ORD175864120815 - Priya Sharma',
        status: 'COMPLETED',
        orderId: 'ORD175864120815',
        customerId: 'cust_003',
        customerName: 'Priya Sharma',
        paymentMethod: 'Card',
        paymentId: 'card_pay_002',
        referenceId: 'REF002',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 20)),
        completedAt: DateTime.now().subtract(const Duration(hours: 20)),
        metadata: {
          'cardType': 'Debit',
          'bankName': 'SBI',
        },
      ),
      Transaction(
        id: 'txn_003',
        type: 'ORDER',
        amount: 605.0,
        currency: 'INR',
        description: 'Order #ORD175864010712 - Amit Patel',
        status: 'COMPLETED',
        orderId: 'ORD175864010712',
        customerId: 'cust_004',
        customerName: 'Amit Patel',
        paymentMethod: 'UPI',
        paymentId: 'upi_pay_003',
        referenceId: 'REF003',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 40)),
        metadata: {
          'paymentApp': 'GooglePay',
          'transactionId': 'GPAY789012',
        },
      ),
      Transaction(
        id: 'txn_004',
        type: 'EXPENSE',
        amount: 150.0,
        currency: 'INR',
        description: 'Inventory purchase - Wholesale supplier',
        status: 'COMPLETED',
        paymentMethod: 'Cash',
        referenceId: 'EXP001',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        completedAt: DateTime.now().subtract(const Duration(hours: 6)),
        metadata: {
          'category': 'Inventory',
          'supplier': 'ABC Wholesales',
        },
      ),
      Transaction(
        id: 'txn_005',
        type: 'COMMISSION',
        amount: 107.2,
        currency: 'INR',
        description: 'Platform commission - Order #ORD175864731730',
        status: 'COMPLETED',
        orderId: 'ORD175864731730',
        paymentMethod: 'Auto Deduct',
        referenceId: 'COM001',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        metadata: {
          'commissionRate': '10%',
          'orderAmount': '1072.0',
        },
      ),
      Transaction(
        id: 'txn_006',
        type: 'REFUND',
        amount: 657.5,
        currency: 'INR',
        description: 'Refund for cancelled order #ORD175863900609',
        status: 'COMPLETED',
        orderId: 'ORD175863900609',
        customerId: 'cust_005',
        customerName: 'Sneha Reddy',
        paymentMethod: 'Card',
        paymentId: 'refund_001',
        referenceId: 'REF005',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 19)),
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 19)),
        metadata: {
          'refundReason': 'Customer requested cancellation',
          'originalTransactionId': 'txn_original_005',
        },
      ),
      Transaction(
        id: 'txn_007',
        type: 'ORDER',
        amount: 300.0,
        currency: 'INR',
        description: 'Cash on Delivery - Order #ORD175864230918',
        status: 'PENDING',
        orderId: 'ORD175864230918',
        customerId: 'cust_002',
        customerName: 'Rajesh Kumar',
        paymentMethod: 'Cash',
        referenceId: 'COD001',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        metadata: {
          'paymentType': 'COD',
          'deliveryAddress': '789 Another Street, Bangalore',
        },
      ),
      Transaction(
        id: 'txn_008',
        type: 'EXPENSE',
        amount: 80.0,
        currency: 'INR',
        description: 'Electricity bill payment',
        status: 'COMPLETED',
        paymentMethod: 'Net Banking',
        referenceId: 'BILL001',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        metadata: {
          'category': 'Utilities',
          'billMonth': 'September 2024',
        },
      ),
    ];

    _transactions = mockTransactions;
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

  // Get transaction by ID
  Transaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((transaction) => transaction.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get transactions by order ID
  List<Transaction> getTransactionsByOrderId(String orderId) {
    return _transactions.where((t) => t.orderId == orderId).toList();
  }

  // Get recent transactions
  List<Transaction> getRecentTransactions({int limit = 10}) {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  // Calculate profit margin
  double get profitMargin {
    if (totalRevenue <= 0) return 0.0;
    return ((netRevenue / totalRevenue) * 100);
  }

  // Get target completion percentage
  double getTargetCompletion(double monthlyTarget) {
    if (monthlyTarget <= 0) return 0.0;
    return (monthRevenue / monthlyTarget) * 100;
  }

  // Refresh all finance data
  Future<void> refresh() async {
    await Future.wait([
      loadFinanceData(),
      loadTransactions(),
    ]);
  }

  // Clear data
  void clear() {
    _financeSummary = null;
    _transactions.clear();
    _filteredTransactions.clear();
    _selectedTransactionType = '';
    _selectedPaymentMethod = '';
    _selectedStartDate = null;
    _selectedEndDate = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}