import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/helpers.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  bool _isLoading = false;
  
  // Sample data - replace with actual API calls
  final Map<String, dynamic> _analyticsData = {
    'sales': {
      'total': 15750.0,
      'orders': 89,
      'avgOrderValue': 177.0,
      'growth': 12.5,
    },
    'products': {
      'totalProducts': 156,
      'lowStock': 12,
      'outOfStock': 3,
      'bestSelling': 'Organic Bananas',
    },
    'customers': {
      'totalCustomers': 234,
      'newCustomers': 18,
      'returningCustomers': 67,
      'satisfaction': 4.6,
    },
    'performance': {
      'orderAcceptanceRate': 94.2,
      'avgPreparationTime': 18.5,
      'onTimeDeliveryRate': 89.3,
      'cancellationRate': 2.1,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF9800); // Orange theme for shop owners

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Business Analytics',
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            onPressed: _showPeriodSelector,
            icon: const Icon(Icons.calendar_today),
          ),
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(primaryColor),
          _buildTabBar(primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesTab(),
                      _buildProductsTab(),
                      _buildCustomersTab(),
                      _buildPerformanceTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.date_range, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Period: $_selectedPeriod',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${_analyticsData['sales']['growth']}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: primaryColor,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Sales'),
          Tab(text: 'Products'),
          Tab(text: 'Customers'),
          Tab(text: 'Performance'),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final salesData = _analyticsData['sales'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid([
            {
              'title': 'Total Sales',
              'value': Helpers.formatCurrency(salesData['total']),
              'icon': Icons.currency_rupee,
              'color': Colors.green,
              'growth': '+${salesData['growth']}%',
            },
            {
              'title': 'Total Orders',
              'value': salesData['orders'].toString(),
              'icon': Icons.shopping_bag,
              'color': Colors.blue,
              'growth': '+8%',
            },
            {
              'title': 'Avg Order Value',
              'value': Helpers.formatCurrency(salesData['avgOrderValue']),
              'icon': Icons.trending_up,
              'color': Colors.orange,
              'growth': '+3.2%',
            },
            {
              'title': 'Revenue Growth',
              'value': '${salesData['growth']}%',
              'icon': Icons.analytics,
              'color': Colors.purple,
              'growth': '+1.5%',
            },
          ]),
          const SizedBox(height: 24),
          _buildSalesChart(),
          const SizedBox(height: 24),
          _buildTopSellingProducts(),
          const SizedBox(height: 24),
          _buildSalesByCategory(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final productsData = _analyticsData['products'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid([
            {
              'title': 'Total Products',
              'value': productsData['totalProducts'].toString(),
              'icon': Icons.inventory,
              'color': Colors.blue,
              'growth': '+5',
            },
            {
              'title': 'Low Stock',
              'value': productsData['lowStock'].toString(),
              'icon': Icons.warning,
              'color': Colors.orange,
              'growth': '-2',
            },
            {
              'title': 'Out of Stock',
              'value': productsData['outOfStock'].toString(),
              'icon': Icons.error,
              'color': Colors.red,
              'growth': '+1',
            },
            {
              'title': 'Best Selling',
              'value': productsData['bestSelling'],
              'icon': Icons.star,
              'color': Colors.green,
              'growth': '156 sold',
            },
          ]),
          const SizedBox(height: 24),
          _buildInventoryStatus(),
          const SizedBox(height: 24),
          _buildProductPerformance(),
          const SizedBox(height: 24),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    final customersData = _analyticsData['customers'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid([
            {
              'title': 'Total Customers',
              'value': customersData['totalCustomers'].toString(),
              'icon': Icons.people,
              'color': Colors.blue,
              'growth': '+18',
            },
            {
              'title': 'New Customers',
              'value': customersData['newCustomers'].toString(),
              'icon': Icons.person_add,
              'color': Colors.green,
              'growth': '+5',
            },
            {
              'title': 'Returning',
              'value': customersData['returningCustomers'].toString(),
              'icon': Icons.repeat,
              'color': Colors.orange,
              'growth': '+12',
            },
            {
              'title': 'Satisfaction',
              'value': '${customersData['satisfaction']} ⭐',
              'icon': Icons.sentiment_satisfied,
              'color': Colors.purple,
              'growth': '+0.2',
            },
          ]),
          const SizedBox(height: 24),
          _buildCustomerSegments(),
          const SizedBox(height: 24),
          _buildCustomerRetention(),
          const SizedBox(height: 24),
          _buildRecentReviews(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final performanceData = _analyticsData['performance'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid([
            {
              'title': 'Order Acceptance',
              'value': '${performanceData['orderAcceptanceRate']}%',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'growth': '+2.1%',
            },
            {
              'title': 'Avg Prep Time',
              'value': '${performanceData['avgPreparationTime']} min',
              'icon': Icons.timer,
              'color': Colors.orange,
              'growth': '-1.2 min',
            },
            {
              'title': 'On-Time Delivery',
              'value': '${performanceData['onTimeDeliveryRate']}%',
              'icon': Icons.schedule,
              'color': Colors.blue,
              'growth': '+3.5%',
            },
            {
              'title': 'Cancellation Rate',
              'value': '${performanceData['cancellationRate']}%',
              'icon': Icons.cancel,
              'color': Colors.red,
              'growth': '-0.8%',
            },
          ]),
          const SizedBox(height: 24),
          _buildPerformanceTrends(),
          const SizedBox(height: 24),
          _buildOperationalInsights(),
          const SizedBox(height: 24),
          _buildImprovementSuggestions(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<Map<String, dynamic>> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    metric['icon'] as IconData,
                    color: metric['color'] as Color,
                    size: 24,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (metric['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      metric['growth'] as String,
                      style: TextStyle(
                        color: metric['color'] as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric['value'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                metric['title'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Sales Chart Placeholder\n(Line/Bar chart showing daily/weekly sales)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProducts() {
    final topProducts = [
      {'name': 'Organic Bananas', 'sales': 156, 'revenue': 2340.0},
      {'name': 'Fresh Milk', 'sales': 142, 'revenue': 2130.0},
      {'name': 'Brown Bread', 'sales': 128, 'revenue': 1920.0},
      {'name': 'Tomatoes', 'sales': 115, 'revenue': 1725.0},
      {'name': 'Basmati Rice', 'sales': 98, 'revenue': 1470.0},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topProducts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final product = topProducts[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  product['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${product['sales']} units sold'),
                trailing: Text(
                  Helpers.formatCurrency(product['revenue'] as double),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalesByCategory() {
    final categories = [
      {'name': 'Fruits & Vegetables', 'percentage': 35, 'color': Colors.green},
      {'name': 'Dairy & Eggs', 'percentage': 25, 'color': Colors.blue},
      {'name': 'Grains & Cereals', 'percentage': 20, 'color': Colors.orange},
      {'name': 'Beverages', 'percentage': 12, 'color': Colors.purple},
      {'name': 'Others', 'percentage': 8, 'color': Colors.grey},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['name'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${category['percentage']}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInventoryStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Inventory Chart Placeholder\n(Pie chart showing stock levels)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Top performing products based on sales velocity and customer ratings.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Product Performance Metrics',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Category Performance Chart',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSegments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Segments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Customer Segmentation Chart\n(New vs Returning customers)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRetention() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Retention',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Customer repeat purchase rate and loyalty metrics.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Retention Rate Chart',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
    final reviews = [
      {'customer': 'John D.', 'rating': 5, 'comment': 'Great quality products!'},
      {'customer': 'Sarah M.', 'rating': 4, 'comment': 'Fast delivery, good service.'},
      {'customer': 'Raj K.', 'rating': 5, 'comment': 'Fresh vegetables, will order again.'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Text(
                      review['customer'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < (review['rating'] as int)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  review['comment'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Performance Metrics Chart\n(Order acceptance, delivery time, etc.)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Key operational metrics and insights to improve business performance.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Operational Insights Dashboard',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    final suggestions = [
      {
        'title': 'Reduce Preparation Time',
        'description': 'Consider batch preparation for popular items',
        'impact': 'High',
        'color': Colors.red,
      },
      {
        'title': 'Optimize Product Mix',
        'description': 'Focus on high-margin, fast-moving products',
        'impact': 'Medium',
        'color': Colors.orange,
      },
      {
        'title': 'Improve Order Acceptance',
        'description': 'Review capacity planning and staffing',
        'impact': 'Low',
        'color': Colors.green,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Improvement Suggestions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (suggestion['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (suggestion['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: suggestion['color'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            suggestion['impact'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final periods = [
          'Today',
          'This Week',
          'This Month',
          'Last Month',
          'This Quarter',
          'This Year',
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...periods.map((period) => ListTile(
                title: Text(period),
                leading: Radio<String>(
                  value: period,
                  groupValue: _selectedPeriod,
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                    Navigator.pop(context);
                    _loadAnalytics();
                  },
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}