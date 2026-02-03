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
        this.showEmptyData();
        this.loading = false;
      }
    });
  }

  showEmptyData(): void {
    this.dashboardMetrics = {
      totalRevenue: 0,
      totalOrders: 0,
      totalCustomers: 0,
      totalShops: 0,
      averageOrderValue: 0,
      conversionRate: 0,
      customerRetentionRate: 0,
      monthlyGrowth: 0,
      revenueData: [],
      orderData: [],
      categoryData: [],
      topShops: [],
      topProducts: [],
      revenueByPeriod: {},
      ordersByPeriod: {},
      conversionByPeriod: {}
    };
  }

  prepareChartData(): void {
    if (!this.dashboardMetrics) return;

    const revenueData = this.dashboardMetrics.revenueData || [];
    const orderData = this.dashboardMetrics.orderData || [];
    const categoryData = this.dashboardMetrics.categoryData || [];

    // Revenue chart data
    this.revenueChartData = [
      {
        label: 'Revenue',
        data: revenueData.map(item => item.revenue),
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
        data: orderData.map(item => item.orderCount),
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 2,
        tension: 0.4
      }
    ];

    // Category chart data (Doughnut)
    this.categoryChartData = [
      {
        data: categoryData.map(item => item.revenue),
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
    }).format(value || 0);
  }

  formatPercentage(value: number): string {
    if (value == null) return '0.0%';
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