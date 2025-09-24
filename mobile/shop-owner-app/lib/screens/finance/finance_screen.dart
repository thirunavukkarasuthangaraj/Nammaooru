import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/transaction.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  String _selectedTransactionType = 'All';

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
  ];

  final List<String> _transactionTypes = [
    'All',
    'Sale',
    'Refund',
    'Commission',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceData();
    });
  }

  void _loadFinanceData() {
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    financeProvider.loadTransactions();
    orderProvider.loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Transactions'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<FinanceProvider, OrderProvider>(
        builder: (context, financeProvider, orderProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(financeProvider, orderProvider),
              _buildAnalyticsTab(financeProvider, orderProvider),
              _buildTransactionsTab(financeProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(FinanceProvider financeProvider, OrderProvider orderProvider) {
    final filteredTransactions = _getFilteredTransactions(financeProvider.transactions);
    final totalRevenue = filteredTransactions
        .where((t) => t.type == 'Sale')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final totalRefunds = filteredTransactions
        .where((t) => t.type == 'Refund')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final totalCommissions = filteredTransactions
        .where((t) => t.type == 'Commission')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final netIncome = totalRevenue - totalRefunds - totalCommissions;

    return RefreshIndicator(
      onRefresh: () async {
        _loadFinanceData();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          _buildRevenueOverviewCard(totalRevenue, totalRefunds, netIncome),
          const SizedBox(height: 24),
          _buildFinancialMetricsGrid(financeProvider, orderProvider),
          const SizedBox(height: 24),
          _buildRecentTransactions(filteredTransactions.take(5).toList()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(FinanceProvider financeProvider, OrderProvider orderProvider) {
    final filteredTransactions = _getFilteredTransactions(financeProvider.transactions);

    return RefreshIndicator(
      onRefresh: () async {
        _loadFinanceData();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          _buildRevenueChart(filteredTransactions),
          const SizedBox(height: 24),
          _buildTransactionTypeChart(filteredTransactions),
          const SizedBox(height: 24),
          _buildDailyRevenueChart(filteredTransactions),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(FinanceProvider financeProvider) {
    final filteredTransactions = _getFilteredTransactions(financeProvider.transactions);

    return Column(
      children: [
        _buildTransactionFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadFinanceData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) => _buildTransactionTile(filteredTransactions[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueOverviewCard(double totalRevenue, double totalRefunds, double netIncome) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Overview',
                  style: AppTextStyles.heading3,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRevenueMetric('Gross Revenue', totalRevenue, AppColors.primary),
            const SizedBox(height: 12),
            _buildRevenueMetric('Total Refunds', totalRefunds, AppColors.error),
            const SizedBox(height: 12),
            _buildRevenueMetric('Net Income', netIncome, AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          AppHelpers.formatCurrency(amount),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialMetricsGrid(FinanceProvider financeProvider, OrderProvider orderProvider) {
    final transactions = _getFilteredTransactions(financeProvider.transactions);
    final orders = orderProvider.orders;

    final avgOrderValue = orders.isNotEmpty
        ? orders.fold(0.0, (sum, order) => sum + order.totalAmount) / orders.length
        : 0.0;

    final totalOrders = orders.length;
    final totalTransactions = transactions.length;
    final conversionRate = totalOrders > 0 ? (totalTransactions / totalOrders * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Order Value',
                AppHelpers.formatCurrency(avgOrderValue),
                Icons.shopping_cart,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.receipt_long,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Transactions',
                totalTransactions.toString(),
                Icons.payment,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Conversion',
                '${conversionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: AppTextStyles.heading3,
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.map((transaction) => _buildTransactionTile(transaction)),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    Color typeColor;
    IconData typeIcon;

    switch (transaction.type) {
      case 'Sale':
        typeColor = AppColors.success;
        typeIcon = Icons.arrow_upward;
        break;
      case 'Refund':
        typeColor = AppColors.error;
        typeIcon = Icons.arrow_downward;
        break;
      case 'Commission':
        typeColor = AppColors.warning;
        typeIcon = Icons.remove;
        break;
      default:
        typeColor = AppColors.info;
        typeIcon = Icons.payment;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                typeIcon,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppHelpers.formatDate(transaction.date),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (transaction.orderId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order #${transaction.orderId}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == 'Refund' || transaction.type == 'Commission' ? '-' : '+'}${AppHelpers.formatCurrency(transaction.amount)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.type,
                    style: AppTextStyles.caption.copyWith(
                      color: typeColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<Transaction> transactions) {
    final salesTransactions = transactions.where((t) => t.type == 'Sale').toList();

    if (salesTransactions.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text('No sales data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(salesTransactions),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeChart(List<Transaction> transactions) {
    final saleCount = transactions.where((t) => t.type == 'Sale').length;
    final refundCount = transactions.where((t) => t.type == 'Refund').length;
    final commissionCount = transactions.where((t) => t.type == 'Commission').length;

    if (saleCount == 0 && refundCount == 0 && commissionCount == 0) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text('No transaction data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Types',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (saleCount > 0)
                      PieChartSectionData(
                        value: saleCount.toDouble(),
                        title: 'Sales\n$saleCount',
                        color: AppColors.success,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (refundCount > 0)
                      PieChartSectionData(
                        value: refundCount.toDouble(),
                        title: 'Refunds\n$refundCount',
                        color: AppColors.error,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (commissionCount > 0)
                      PieChartSectionData(
                        value: commissionCount.toDouble(),
                        title: 'Commission\n$commissionCount',
                        color: AppColors.warning,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRevenueChart(List<Transaction> transactions) {
    final dailyRevenue = _getDailyRevenue(transactions);

    if (dailyRevenue.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text('No daily revenue data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Revenue',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: dailyRevenue.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedTransactionType,
              isExpanded: true,
              items: _transactionTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTransactionType = value!),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];

    transactions.sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (int i = 0; i < transactions.length && i < 10; i++) {
      spots.add(FlSpot(i.toDouble(), transactions[i].amount));
    }

    return spots;
  }

  Map<int, double> _getDailyRevenue(List<Transaction> transactions) {
    final dailyRevenue = <int, double>{};
    final salesTransactions = transactions.where((t) => t.type == 'Sale').toList();

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dayTransactions = salesTransactions.where((t) =>
        t.date.year == date.year &&
        t.date.month == date.month &&
        t.date.day == date.day
      );

      final dayRevenue = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      dailyRevenue[i] = dayRevenue;
    }

    return dailyRevenue;
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    var filtered = transactions.where((transaction) {
      if (_selectedTransactionType != 'All' && transaction.type != _selectedTransactionType) {
        return false;
      }

      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'Today':
          return transaction.date.year == now.year &&
                 transaction.date.month == now.month &&
                 transaction.date.day == now.day;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return transaction.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'This Month':
          return transaction.date.year == now.year &&
                 transaction.date.month == now.month;
        case 'Last Month':
          final lastMonth = DateTime(now.year, now.month - 1);
          return transaction.date.year == lastMonth.year &&
                 transaction.date.month == lastMonth.month;
        case 'This Year':
          return transaction.date.year == now.year;
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}