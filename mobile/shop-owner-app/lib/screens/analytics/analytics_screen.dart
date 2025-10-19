import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';

class AnalyticsScreen extends StatefulWidget {
  final String token;

  const AnalyticsScreen({
    super.key,
    required this.token,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '30'; // 7, 30, 90 days
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        ApiService.getShopAnalytics('1', days: int.parse(_selectedPeriod)),
        ApiService.getShopDashboard('1'),
        _loadDashboardStats(),
      ]);

      final analyticsResponse = futures[0] as dynamic;
      final dashboardResponse = futures[1] as dynamic;

      if (analyticsResponse?.success == true) {
        setState(() {
          _analyticsData = analyticsResponse.data?['data'] ?? {};
        });
      }

      if (dashboardResponse?.success == true) {
        setState(() {
          _dashboardData = dashboardResponse.data?['data'] ?? {};
        });
      }
    } catch (e) {
      _showError('Error loading analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final futures = await Future.wait([
        ApiService.getTodaysRevenue(),
        ApiService.getTodaysOrders(),
        ApiService.getProductCount(),
        ApiService.getLowStockCount(),
        ApiService.getCustomerCount(),
        ApiService.getNewCustomers(),
      ]);

      return {
        'todaysRevenue': futures[0].success ? futures[0].data['data'] : 0.0,
        'todaysOrders': futures[1].success ? futures[1].data['data'] : 0,
        'productCount': futures[2].success ? futures[2].data['data'] : 0,
        'lowStockCount': futures[3].success ? futures[3].data['data'] : 0,
        'customerCount': futures[4].success ? futures[4].data['data'] : 0,
        'newCustomers': futures[5].success ? futures[5].data['data'] : 0,
      };
    } catch (e) {
      return {};
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveLayout.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Analytics & Reports', style: AppTheme.h5),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(AppTheme.space8),
            child: ModernButton(
              text: '${_selectedPeriod}D',
              icon: Icons.calendar_today,
              variant: ButtonVariant.outline,
              size: ButtonSize.small,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
                  ),
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
                    ),
                    padding: const EdgeInsets.all(AppTheme.space20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.borderLight,
                            borderRadius: AppTheme.roundedRound,
                          ),
                        ),
                        Text('Select Period', style: AppTheme.h5),
                        const SizedBox(height: AppTheme.space20),
                        ...[
                          ('7', 'Last 7 days', Icons.today),
                          ('30', 'Last 30 days', Icons.calendar_month),
                          ('90', 'Last 90 days', Icons.date_range),
                        ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space12),
                          child: ModernButton(
                            text: item.$2,
                            icon: item.$3,
                            variant: _selectedPeriod == item.$1 ? ButtonVariant.primary : ButtonVariant.outline,
                            size: ButtonSize.large,
                            fullWidth: true,
                            useGradient: _selectedPeriod == item.$1,
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _selectedPeriod = item.$1);
                              _loadAnalytics();
                            },
                          ),
                        )),
                        const SizedBox(height: AppTheme.space8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: AppTheme.space24),

                    // Revenue Analytics
                    _buildSectionTitle('Revenue Analytics', Icons.attach_money),
                    _buildRevenueSection(),
                    const SizedBox(height: AppTheme.space24),

                    // Orders Analytics
                    _buildSectionTitle('Order Analytics', Icons.shopping_cart),
                    _buildOrdersSection(),
                    const SizedBox(height: AppTheme.space24),

                    // Product Performance
                    _buildSectionTitle('Product Performance', Icons.inventory),
                    _buildProductSection(),
                    const SizedBox(height: AppTheme.space24),

                    // Customer Analytics
                    _buildSectionTitle('Customer Analytics', Icons.people),
                    _buildCustomerSection(),
                    const SizedBox(height: AppTheme.space24),

                    // Export Options
                    _buildExportSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.roundedMedium,
            ),
            child: Icon(icon, color: AppTheme.textWhite, size: 20),
          ),
          const SizedBox(width: AppTheme.space12),
          Text(title, style: AppTheme.h5),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDashboardStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final gridColumns = ResponsiveLayout.getGridColumns(context);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: gridColumns > 3 ? 4 : 2,
          childAspectRatio: 1.4,
          mainAxisSpacing: AppTheme.space16,
          crossAxisSpacing: AppTheme.space16,
          children: [
            StatCard(
              title: 'Today\'s Revenue',
              value: '₹${(stats['todaysRevenue'] ?? 0.0).toStringAsFixed(2)}',
              icon: Icons.currency_rupee,
              color: AppTheme.success,
              subtitle: 'Today',
              useGradient: true,
            ),
            StatCard(
              title: 'Today\'s Orders',
              value: '${stats['todaysOrders'] ?? 0}',
              icon: Icons.shopping_cart,
              color: AppTheme.secondary,
              subtitle: 'Orders',
              useGradient: true,
            ),
            StatCard(
              title: 'Total Products',
              value: '${stats['productCount'] ?? 0}',
              icon: Icons.inventory,
              color: const Color(0xFF5E35B1),
              subtitle: 'Products',
            ),
            StatCard(
              title: 'Low Stock',
              value: '${stats['lowStockCount'] ?? 0}',
              icon: Icons.warning,
              color: AppTheme.warning,
              subtitle: 'Items',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    final revenueData = _analyticsData['revenue'] ?? {};

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Revenue', style: AppTheme.h5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
                  ),
                  borderRadius: AppTheme.roundedMedium,
                  boxShadow: AppTheme.shadowMedium,
                ),
                child: Text(
                  '₹${(revenueData['total'] ?? 0.0).toStringAsFixed(2)}',
                  style: AppTheme.h4.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          _buildAnalyticsRow('Average Order Value', '₹${(revenueData['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}'),
          _buildAnalyticsRow('Highest Sale Day', revenueData['highestSaleDay'] ?? 'N/A'),
          _buildAnalyticsRow('Revenue Growth', '${(revenueData['growth'] ?? 0.0).toStringAsFixed(1)}%'),

          const SizedBox(height: AppTheme.space16),

          // Revenue Chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: AppTheme.roundedLarge,
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(
                            days[value.toInt() % 7],
                            style: AppTheme.caption,
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: AppTheme.caption,
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getRevenueSpots(),
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    final ordersData = _analyticsData['orders'] ?? {};

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Statistics', style: AppTheme.h5),
          const SizedBox(height: AppTheme.space16),

          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Total Orders',
                  '${ordersData['total'] ?? 0}',
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildMiniStatCard(
                  'Completed',
                  '${ordersData['completed'] ?? 0}',
                  AppTheme.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space12),

          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Pending',
                  '${ordersData['pending'] ?? 0}',
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildMiniStatCard(
                  'Cancelled',
                  '${ordersData['cancelled'] ?? 0}',
                  AppTheme.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space16),

          _buildAnalyticsRow('Completion Rate', '${((ordersData['completed'] ?? 0) / (ordersData['total'] ?? 1) * 100).toStringAsFixed(1)}%'),
          _buildAnalyticsRow('Average Processing Time', '${ordersData['avgProcessingTime'] ?? 'N/A'}'),
          _buildAnalyticsRow('Peak Order Hour', ordersData['peakHour'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    final productsData = _analyticsData['products'] ?? {};

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Performance', style: AppTheme.h5),
          const SizedBox(height: AppTheme.space16),

          _buildAnalyticsRow('Best Selling Product', productsData['topProduct'] ?? 'N/A'),
          _buildAnalyticsRow('Total Products Sold', '${productsData['totalSold'] ?? 0}'),
          _buildAnalyticsRow('Out of Stock Items', '${productsData['outOfStock'] ?? 0}'),
          _buildAnalyticsRow('New Products Added', '${productsData['newProducts'] ?? 0}'),

          const SizedBox(height: AppTheme.space16),

          // Top Products List
          Text('Top Selling Products', style: AppTheme.h6),
          const SizedBox(height: AppTheme.space12),

          ...List.generate(3, (index) {
            final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent];
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space8),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: colors[index].withOpacity(0.1),
                borderRadius: AppTheme.roundedMedium,
                border: Border.all(color: colors[index].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[index], colors[index].withOpacity(0.7)],
                      ),
                      borderRadius: AppTheme.roundedRound,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'Product ${index + 1}',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${100 - index * 20} sold',
                    style: AppTheme.bodySmall.copyWith(
                      color: colors[index],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDashboardStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Analytics', style: AppTheme.h5),
              const SizedBox(height: AppTheme.space16),

              _buildAnalyticsRow('Total Customers', '${stats['customerCount'] ?? 0}'),
              _buildAnalyticsRow('New Customers (30d)', '${stats['newCustomers'] ?? 0}'),
              _buildAnalyticsRow('Customer Growth', '+${((stats['newCustomers'] ?? 0) / (stats['customerCount'] ?? 1) * 100).toStringAsFixed(1)}%'),

              const SizedBox(height: AppTheme.space16),

              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      'Repeat Customers',
                      '${(stats['customerCount'] ?? 0) - (stats['newCustomers'] ?? 0)}',
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _buildMiniStatCard(
                      'First Time Buyers',
                      '${stats['newCustomers'] ?? 0}',
                      AppTheme.info,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.roundedLarge,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: AppTheme.roundedMedium,
                ),
                child: const Icon(Icons.file_download, color: AppTheme.textWhite, size: 20),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Reports', style: AppTheme.h5),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Generate and download detailed reports',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space20),

          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Sales',
                  icon: Icons.bar_chart,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _exportReport('sales'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: ModernButton(
                  text: 'Products',
                  icon: Icons.inventory,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _exportReport('products'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space12),

          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Customers',
                  icon: Icons.people,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _exportReport('customers'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: ModernButton(
                  text: 'Financial',
                  icon: Icons.account_balance,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _exportReport('financial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $type report...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Open exported report
          },
        ),
      ),
    );
  }

  List<FlSpot> _getRevenueSpots() {
    final revenueData = _analyticsData['revenue'] ?? {};
    final dailyRevenue = revenueData['dailyRevenue'] as List<dynamic>? ?? [];

    if (dailyRevenue.isEmpty) {
      // Mock data for demonstration
      return [
        FlSpot(0, 1200),
        FlSpot(1, 1500),
        FlSpot(2, 1800),
        FlSpot(3, 1300),
        FlSpot(4, 2100),
        FlSpot(5, 1900),
        FlSpot(6, 2300),
      ];
    }

    return dailyRevenue.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['revenue'] ?? 0.0).toDouble()
      );
    }).toList();
  }
}