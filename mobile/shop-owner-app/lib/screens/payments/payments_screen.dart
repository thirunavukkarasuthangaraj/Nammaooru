import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/app_config.dart';

class PaymentsScreen extends StatefulWidget {
  final String token;

  const PaymentsScreen({super.key, required this.token});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _todayOrders = []; // Store today's orders separately
  bool _isLoading = true;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedPaymentStatus = 'ALL'; // ALL, PAID, UNPAID

  double _todayTotal = 0.0;
  int _todayOrderCount = 0;
  double _todayCollected = 0.0; // Today's paid amount
  double _totalPaid = 0.0;
  double _totalUnpaid = 0.0;
  int _paidCount = 0;
  int _unpaidCount = 0;

  // Weekly summary data (last 7 days)
  List<Map<String, dynamic>> _weeklyData = [];

  // Commission tracking
  double _platformCommission = 0.0;
  double _shopOwnerEarnings = 0.0;
  final double _commissionPercent = 0.0; // 0% commission (FREE period) - will be updated later

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now();
    _selectedEndDate = DateTime.now();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.token;

      // Step 1: Get shop ID
      final myShopResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/my-shop'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (myShopResponse.statusCode != 200) {
        print('Failed to fetch shop: ${myShopResponse.body}');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final myShopData = jsonDecode(myShopResponse.body);
      if (myShopData['statusCode'] != '0000' || myShopData['data'] == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final shopId = myShopData['data']['shopId'];

      // Step 2: Fetch all orders
      final ordersResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/shops/$shopId/orders?page=0&size=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (ordersResponse.statusCode == 200) {
        final ordersData = jsonDecode(ordersResponse.body);

        if (ordersData['statusCode'] == '0000' && ordersData['data'] != null) {
          final allOrders = ordersData['data']['orders'] ?? [];
          _processOrders(allOrders);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching payment data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processOrders(List<dynamic> allOrders) {
    // Filter orders by date range
    List<dynamic> filteredOrders = allOrders.where((order) {
      final orderDate = DateTime.parse(order['createdAt']);
      if (_selectedStartDate != null && _selectedEndDate != null) {
        final startOfDay = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
        final endOfDay = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day, 23, 59, 59);
        return orderDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               orderDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();

    // Filter by payment status
    if (_selectedPaymentStatus != 'ALL') {
      filteredOrders = filteredOrders.where((order) {
        final isPaid = order['paymentStatus'] == 'PAID' ||
                       order['paymentStatus'] == 'COMPLETED' ||
                       order['status'] == 'DELIVERED';
        return _selectedPaymentStatus == 'PAID' ? isPaid : !isPaid;
      }).toList();
    }

    // Calculate totals
    double todayTotal = 0.0;
    int todayOrderCount = 0;
    double todayCollected = 0.0;
    double totalPaid = 0.0;
    double totalUnpaid = 0.0;
    int paidCount = 0;
    int unpaidCount = 0;
    List<dynamic> todayOrders = [];

    // Use selected date range for "today" calculations instead of actual today
    final selectedStart = _selectedStartDate ?? DateTime.now();
    final startOfToday = DateTime(selectedStart.year, selectedStart.month, selectedStart.day);
    final selectedEnd = _selectedEndDate ?? DateTime.now();
    final endOfToday = DateTime(selectedEnd.year, selectedEnd.month, selectedEnd.day, 23, 59, 59);

    // Calculate weekly data (last 7 days)
    List<Map<String, dynamic>> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final dayDate = DateTime.now().subtract(Duration(days: i));
      final startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final endOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59);

      int dayOrderCount = 0;
      double dayTotal = 0.0;
      double dayCollected = 0.0;

      for (var order in allOrders) {
        final orderDate = DateTime.parse(order['createdAt']);
        if (orderDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            orderDate.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          final amount = (order['totalAmount'] ?? 0).toDouble();
          final isPaid = order['paymentStatus'] == 'PAID' ||
                         order['paymentStatus'] == 'COMPLETED' ||
                         order['status'] == 'DELIVERED';

          dayOrderCount++;
          dayTotal += amount;
          if (isPaid) {
            dayCollected += amount;
          }
        }
      }

      weeklyData.add({
        'date': startOfDay,
        'dayName': DateFormat('EEEE').format(startOfDay), // Full day name (Monday, Tuesday, etc.)
        'shortDayName': DateFormat('EEE').format(startOfDay), // Short name for display
        'orderCount': dayOrderCount,
        'total': dayTotal,
        'collected': dayCollected,
      });
    }

    for (var order in filteredOrders) {
      final amount = (order['totalAmount'] ?? 0).toDouble();
      final orderDate = DateTime.parse(order['createdAt']);
      final isPaid = order['paymentStatus'] == 'PAID' ||
                     order['paymentStatus'] == 'COMPLETED' ||
                     order['status'] == 'DELIVERED';

      // Check if order is from today
      final isToday = orderDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
                      orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));

      // Calculate today's totals
      if (isToday) {
        todayTotal += amount;
        todayOrderCount++;
        todayOrders.add(order);
        if (isPaid) {
          todayCollected += amount;
        }
      }

      // Calculate paid/unpaid totals
      if (isPaid) {
        totalPaid += amount;
        paidCount++;
      } else {
        totalUnpaid += amount;
        unpaidCount++;
      }
    }

    // Calculate platform commission and shop owner earnings
    final commission = totalPaid * (_commissionPercent / 100);
    final earnings = totalPaid - commission;

    setState(() {
      _orders = filteredOrders;
      _todayOrders = todayOrders;
      _todayTotal = todayTotal;
      _todayOrderCount = todayOrderCount;
      _todayCollected = todayCollected;
      _totalPaid = totalPaid;
      _totalUnpaid = totalUnpaid;
      _paidCount = paidCount;
      _unpaidCount = unpaidCount;
      _platformCommission = commission;
      _shopOwnerEarnings = earnings;
      _weeklyData = weeklyData;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _fetchPaymentData();
    }
  }

  void _resetFilter() {
    setState(() {
      _selectedStartDate = DateTime.now();
      _selectedEndDate = DateTime.now();
      _selectedPaymentStatus = 'ALL';
    });
    _fetchPaymentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Payments & Settlements',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1F36),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPaymentData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Today's Summary - Clean Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _isToday() ? Icons.today : Icons.calendar_today,
                                      color: const Color(0xFF4F46E5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getSummaryTitle(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1F36),
                                        ),
                                      ),
                                      Text(
                                        _getSummaryDateText(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Orders',
                                      '$_todayOrderCount',
                                      Icons.shopping_bag_outlined,
                                      const Color(0xFF4F46E5),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: Colors.grey[200],
                                  ),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Collected',
                                      '₹${_todayCollected.toStringAsFixed(0)}',
                                      Icons.account_balance_wallet_outlined,
                                      const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Paid/Unpaid Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Paid',
                              '₹${_totalPaid.toStringAsFixed(0)}',
                              '$_paidCount orders',
                              const Color(0xFF10B981),
                              Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Unpaid',
                              '₹${_totalUnpaid.toStringAsFixed(0)}',
                              '$_unpaidCount orders',
                              const Color(0xFFF59E0B),
                              Icons.pending_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedStartDate != null && _selectedEndDate != null
                                      ? '${DateFormat('dd MMM').format(_selectedStartDate!)} - ${DateFormat('dd MMM').format(_selectedEndDate!)}'
                                      : 'Select Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _selectDateRange,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Orders List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          Text(
                            '${_orders.length} orders',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Orders List
                    if (_orders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Transactions will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final isPaid = order['paymentStatus'] == 'PAID' ||
                                       order['paymentStatus'] == 'COMPLETED' ||
                                       order['status'] == 'DELIVERED';
                          final amount = (order['totalAmount'] ?? 0).toDouble();
                          final orderDate = DateTime.parse(order['createdAt']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPaid ? Icons.check_circle : Icons.pending,
                                  color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                order['customerName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1A1F36),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${order['orderNumber']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(orderDate),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isPaid ? const Color(0xFF10B981) : const Color(0xFF1A1F36),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPaid ? 'Paid' : 'Unpaid',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F36),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, String subtitle, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Payments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('All', 'ALL', setModalState),
                      _buildFilterChip('Paid', 'PAID', setModalState),
                      _buildFilterChip('Unpaid', 'UNPAID', setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetFilter();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchPaymentData();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF4F46E5),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedPaymentStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedPaymentStatus = value;
        });
        setState(() {
          _selectedPaymentStatus = value;
        });
      },
      selectedColor: const Color(0xFF4F46E5).withOpacity(0.1),
      checkmarkColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.blue;
      case 'PREPARING': return Colors.purple;
      case 'READY_FOR_PICKUP': return Colors.teal;
      case 'OUT_FOR_DELIVERY': return Colors.indigo;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  bool _isToday() {
    if (_selectedStartDate == null || _selectedEndDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedStart = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
    final selectedEnd = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day);

    return selectedStart == today && selectedEnd == today;
  }

  String _getSummaryTitle() {
    if (_isToday()) {
      return "Today's Summary";
    } else if (_selectedStartDate != null && _selectedEndDate != null &&
               _selectedStartDate!.year == _selectedEndDate!.year &&
               _selectedStartDate!.month == _selectedEndDate!.month &&
               _selectedStartDate!.day == _selectedEndDate!.day) {
      return "Summary";
    } else {
      return "Period Summary";
    }
  }

  String _getSummaryDateText() {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      return DateFormat('EEEE, MMM dd').format(DateTime.now());
    }

    if (_selectedStartDate!.year == _selectedEndDate!.year &&
        _selectedStartDate!.month == _selectedEndDate!.month &&
        _selectedStartDate!.day == _selectedEndDate!.day) {
      // Single date
      return DateFormat('EEEE, MMM dd').format(_selectedStartDate!);
    } else {
      // Date range
      return '${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd').format(_selectedEndDate!)}';
    }
  }
}
