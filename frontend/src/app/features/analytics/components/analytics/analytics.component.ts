import { Component, OnInit } from '@angular/core';
import { AnalyticsService, DashboardMetrics } from '../../../../core/services/analytics.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-analytics',
  templateUrl: './analytics.component.html',
  styleUrls: ['./analytics.component.scss']
})
export class AnalyticsComponent implements OnInit {
  dashboardMetrics: DashboardMetrics | null = null;
  loading = true;
  dateRange = {
    start: new Date(new Date().getFullYear(), new Date().getMonth(), 1), // First day of current month
    end: new Date() // Today
  };

  // Chart data
  revenueChartData: any[] = [];
  ordersChartData: any[] = [];
  categoryChartData: any[] = [];
  
  // Chart options
  chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
    },
    scales: {
      y: {
        beginAtZero: true
      }
    }
  };

  doughnutOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'right' as const,
      },
    },
  };

  constructor(private analyticsService: AnalyticsService) {}

  ngOnInit(): void {
    this.loadDashboardMetrics();
  }

  loadDashboardMetrics(): void {
    this.loading = true;
    this.analyticsService.getDashboardMetrics(this.dateRange.start, this.dateRange.end).subscribe({
      next: (metrics) => {
        this.dashboardMetrics = metrics;
        this.prepareChartData();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading dashboard metrics:', error);
        this.showMockData(); // Show mock data if API fails
        this.loading = false;
      }
    });
  }

  showMockData(): void {
    // Mock data for demonstration
    this.dashboardMetrics = {
      totalRevenue: 125460.50,
      totalOrders: 1247,
      totalCustomers: 892,
      totalShops: 45,
      averageOrderValue: 100.53,
      conversionRate: 12.5,
      customerRetentionRate: 78.2,
      monthlyGrowth: 15.3,
      revenueData: [
        { period: 'Week 1', revenue: 25000, previousRevenue: 20000, growthPercentage: 25, date: '2024-01-01' },
        { period: 'Week 2', revenue: 30000, previousRevenue: 25000, growthPercentage: 20, date: '2024-01-08' },
        { period: 'Week 3', revenue: 35000, previousRevenue: 30000, growthPercentage: 16.7, date: '2024-01-15' },
        { period: 'Week 4', revenue: 35460, previousRevenue: 35000, growthPercentage: 1.3, date: '2024-01-22' }
      ],
      orderData: [
        { period: 'Week 1', orderCount: 250, previousOrderCount: 200, growthPercentage: 25, date: '2024-01-01' },
        { period: 'Week 2', orderCount: 300, previousOrderCount: 250, growthPercentage: 20, date: '2024-01-08' },
        { period: 'Week 3', orderCount: 350, previousOrderCount: 300, growthPercentage: 16.7, date: '2024-01-15' },
        { period: 'Week 4', orderCount: 347, previousOrderCount: 350, growthPercentage: -0.9, date: '2024-01-22' }
      ],
      categoryData: [
        { categoryName: 'Groceries', revenue: 45000, orderCount: 580, marketShare: 35.8, growthPercentage: 12.5 },
        { categoryName: 'Electronics', revenue: 32000, orderCount: 165, marketShare: 25.5, growthPercentage: 8.3 },
        { categoryName: 'Fashion', revenue: 28460, orderCount: 290, marketShare: 22.7, growthPercentage: 15.2 },
        { categoryName: 'Food & Beverage', revenue: 20000, orderCount: 212, marketShare: 16.0, growthPercentage: 22.1 }
      ],
      topShops: [
        { shopId: 1, shopName: 'Green Grocer', shopOwner: 'Raj Kumar', revenue: 15400, orderCount: 234, customerCount: 156, rating: 4.8, growthPercentage: 18.5, status: 'ACTIVE' },
        { shopId: 2, shopName: 'Tech Central', shopOwner: 'Priya Singh', revenue: 12800, orderCount: 89, customerCount: 78, rating: 4.6, growthPercentage: 12.3, status: 'ACTIVE' },
        { shopId: 3, shopName: 'Fashion Hub', shopOwner: 'Amit Patel', revenue: 11200, orderCount: 145, customerCount: 98, rating: 4.7, growthPercentage: 25.1, status: 'ACTIVE' }
      ],
      topProducts: [
        { productId: 1, productName: 'Organic Apples', category: 'Groceries', quantitySold: 245, revenue: 3675, averageRating: 4.9, stockLevel: 150, conversionRate: 35.2, trendDirection: 'UP' },
        { productId: 2, productName: 'Smartphone X1', category: 'Electronics', quantitySold: 28, revenue: 14000, averageRating: 4.5, stockLevel: 45, conversionRate: 28.1, trendDirection: 'UP' },
        { productId: 3, productName: 'Cotton T-Shirt', category: 'Fashion', quantitySold: 156, revenue: 4680, averageRating: 4.3, stockLevel: 78, conversionRate: 22.8, trendDirection: 'STABLE' }
      ],
      revenueByPeriod: { 'Jan': 95000, 'Feb': 110000, 'Mar': 125460 },
      ordersByPeriod: { 'Jan': 920, 'Feb': 1050, 'Mar': 1247 },
      conversionByPeriod: { 'Jan': 10.2, 'Feb': 11.8, 'Mar': 12.5 }
    };
    this.prepareChartData();
  }

  prepareChartData(): void {
    if (!this.dashboardMetrics) return;

    // Revenue chart data
    this.revenueChartData = [
      {
        label: 'Revenue',
        data: this.dashboardMetrics.revenueData.map(item => item.revenue),
        backgroundColor: 'rgba(54, 162, 235, 0.2)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 2,
        tension: 0.4
      }
    ];

    // Orders chart data
    this.ordersChartData = [
      {
        label: 'Orders',
        data: this.dashboardMetrics.orderData.map(item => item.orderCount),
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 2,
        tension: 0.4
      }
    ];

    // Category chart data (Doughnut)
    this.categoryChartData = [
      {
        data: this.dashboardMetrics.categoryData.map(item => item.revenue),
        backgroundColor: [
          'rgba(255, 99, 132, 0.8)',
          'rgba(54, 162, 235, 0.8)',
          'rgba(255, 205, 86, 0.8)',
          'rgba(75, 192, 192, 0.8)',
          'rgba(153, 102, 255, 0.8)'
        ],
        borderWidth: 1
      }
    ];
  }

  onDateRangeChange(): void {
    this.loadDashboardMetrics();
  }

  formatCurrency(value: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(value);
  }

  formatPercentage(value: number): string {
    return value.toFixed(1) + '%';
  }

  generateReport(): void {
    Swal.fire({
      title: 'Generate Analytics Report',
      text: 'This will generate a comprehensive analytics report for the selected date range.',
      icon: 'info',
      showCancelButton: true,
      confirmButtonText: 'Generate',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.analyticsService.generateAnalytics(this.dateRange.start, this.dateRange.end, 'CUSTOM').subscribe({
          next: () => {
            Swal.fire('Success!', 'Analytics report generated successfully', 'success');
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to generate analytics report', 'error');
          }
        });
      }
    });
  }

  exportData(): void {
    if (!this.dashboardMetrics) return;
    
    const data = {
      dateRange: this.dateRange,
      metrics: this.dashboardMetrics,
      exportedAt: new Date().toISOString()
    };
    
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `analytics-report-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    window.URL.revokeObjectURL(url);
    
    Swal.fire('Success!', 'Analytics data exported successfully', 'success');
  }
}