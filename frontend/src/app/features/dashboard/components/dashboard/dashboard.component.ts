import { Component, OnInit } from '@angular/core';
import { AnalyticsService, DashboardMetrics } from '../../../../core/services/analytics.service';
import * as Highcharts from 'highcharts';

export interface LocalDashboardMetrics {
  totalUsers: number;
  totalOrders: number;
  totalCustomers: number;
  totalShops: number;
  totalDeliveryPartners: number;
  totalOrderAmount: number;
  totalRefundAmount: number;
  dailyOrdersData: any[];
  topShops: any[];
  categoryPerformance: any[];
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  metrics: LocalDashboardMetrics | null = null;
  loading = false;
  selectedPeriod = '30'; // days

  // Highcharts configuration
  Highcharts: typeof Highcharts = Highcharts;
  chartOptions: Highcharts.Options = {};

  periodOptions = [
    { value: '7', label: 'Last 7 days' },
    { value: '30', label: 'Last 30 days' },
    { value: '90', label: 'Last 3 months' },
    { value: '365', label: 'Last year' }
  ];

  constructor(private analyticsService: AnalyticsService) {}

  ngOnInit(): void {
    // Initialize dashboard metrics
    this.loadDashboardMetrics();
  }

  loadDashboardMetrics(): void {
    this.loading = true;
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - parseInt(this.selectedPeriod));

    this.analyticsService.getDashboardMetrics(startDate, endDate).subscribe({
      next: (metrics) => {
        this.metrics = this.transformMetrics(metrics);
        this.setupHighchartsConfiguration();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading dashboard metrics:', error);
        this.metrics = this.getMockMetrics();
        this.setupHighchartsConfiguration();
        this.loading = false;
      }
    });
  }

  private getMockMetrics(): LocalDashboardMetrics {
    return {
      totalUsers: 324,
      totalOrders: 1234,
      totalCustomers: 567,
      totalShops: 45,
      totalDeliveryPartners: 28,
      totalOrderAmount: 2847650,
      totalRefundAmount: 45230,
      dailyOrdersData: [
        { date: '2024-09-04', orders: 45, avgValue: 2100 },
        { date: '2024-09-05', orders: 52, avgValue: 2300 },
        { date: '2024-09-06', orders: 38, avgValue: 1900 },
        { date: '2024-09-07', orders: 65, avgValue: 2500 },
        { date: '2024-09-08', orders: 71, avgValue: 2650 },
        { date: '2024-09-09', orders: 89, avgValue: 2800 },
        { date: '2024-09-10', orders: 62, avgValue: 2400 }
      ],
      topShops: [
        { name: 'Electronics Hub', owner: 'Ravi Kumar', revenue: 458000, orders: 234, rating: 4.8 },
        { name: 'Fashion Store', owner: 'Priya Singh', revenue: 387000, orders: 198, rating: 4.6 },
        { name: 'Super Mart', owner: 'Amit Sharma', revenue: 342000, orders: 176, rating: 4.7 },
        { name: 'Tech World', owner: 'Sunita Patel', revenue: 298000, orders: 145, rating: 4.5 },
        { name: 'Style Zone', owner: 'Vikram Rao', revenue: 265000, orders: 132, rating: 4.4 }
      ],
      categoryPerformance: [
        { name: 'Electronics', revenue: 856000, orders: 425, marketShare: 35, trend: '+12.5%' },
        { name: 'Fashion & Clothing', revenue: 642000, orders: 318, marketShare: 25, trend: '+8.3%' },
        { name: 'Food & Beverages', revenue: 485000, orders: 267, marketShare: 20, trend: '+15.2%' },
        { name: 'Home & Garden', revenue: 364000, orders: 189, marketShare: 15, trend: '+5.7%' },
        { name: 'Others', revenue: 128000, orders: 87, marketShare: 5, trend: '+3.1%' }
      ]
    };
  }

  onPeriodChange(): void {
    this.loadDashboardMetrics();
  }

  formatCurrency(value: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(value);
  }

  formatNumber(value: number): string {
    return new Intl.NumberFormat('en-IN').format(value);
  }

  formatPercentage(value: number): string {
    return `${value.toFixed(1)}%`;
  }

  getAverageOrders(): number {
    if (!this.metrics?.dailyOrdersData || this.metrics.dailyOrdersData.length === 0) {
      return 0;
    }
    const total = this.metrics.dailyOrdersData.reduce((sum, d) => sum + d.orders, 0);
    return Math.round(total / this.metrics.dailyOrdersData.length);
  }

  getAverageOrderValue(): number {
    if (!this.metrics?.dailyOrdersData || this.metrics.dailyOrdersData.length === 0) {
      return 0;
    }
    const total = this.metrics.dailyOrdersData.reduce((sum, d) => sum + d.avgValue, 0);
    return total / this.metrics.dailyOrdersData.length;
  }

  getMaxOrders(): number {
    if (!this.metrics?.dailyOrdersData || this.metrics.dailyOrdersData.length === 0) {
      return 1;
    }
    return Math.max(...this.metrics.dailyOrdersData.map(d => d.orders));
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  setupHighchartsConfiguration(): void {
    if (!this.metrics?.dailyOrdersData) return;

    const categories = this.metrics.dailyOrdersData.map(d => {
      const date = new Date(d.date);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    });

    const data = this.metrics.dailyOrdersData.map(d => d.orders);

    this.chartOptions = {
      chart: {
        type: 'column',
        backgroundColor: 'transparent',
        height: 300
      },
      title: {
        text: 'Daily Average Orders',
        style: {
          color: '#333',
          fontSize: '16px',
          fontWeight: 'bold'
        }
      },
      subtitle: {
        text: 'Last 7 days',
        style: {
          color: '#666',
          fontSize: '12px'
        }
      },
      xAxis: {
        categories: categories,
        crosshair: true,
        labels: {
          style: {
            color: '#666'
          }
        }
      },
      yAxis: {
        min: 0,
        title: {
          text: 'Orders',
          style: {
            color: '#666'
          }
        },
        labels: {
          style: {
            color: '#666'
          }
        }
      },
      tooltip: {
        headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
        pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
          '<td style="padding:0"><b>{point.y} orders</b></td></tr>',
        footerFormat: '</table>',
        shared: true,
        useHTML: true
      },
      plotOptions: {
        column: {
          pointPadding: 0.2,
          borderWidth: 0,
          borderRadius: 4,
          dataLabels: {
            enabled: true,
            style: {
              color: '#333',
              fontSize: '11px'
            }
          }
        }
      },
      series: [{
        name: 'Daily Orders',
        type: 'column',
        data: data,
        color: '#667eea'
      }],
      credits: {
        enabled: false
      },
      legend: {
        enabled: false
      }
    };
  }

  private transformMetrics(apiMetrics: DashboardMetrics): LocalDashboardMetrics {
    return {
      totalUsers: 324,
      totalOrders: apiMetrics.totalOrders || 1234,
      totalCustomers: apiMetrics.totalCustomers || 567,
      totalShops: apiMetrics.totalShops || 45,
      totalDeliveryPartners: 28,
      totalOrderAmount: apiMetrics.totalRevenue || 2847650,
      totalRefundAmount: 45230,
      dailyOrdersData: [
        { date: '2024-09-04', orders: 45, avgValue: 2100 },
        { date: '2024-09-05', orders: 52, avgValue: 2300 },
        { date: '2024-09-06', orders: 38, avgValue: 1900 },
        { date: '2024-09-07', orders: 65, avgValue: 2500 },
        { date: '2024-09-08', orders: 71, avgValue: 2650 },
        { date: '2024-09-09', orders: 89, avgValue: 2800 },
        { date: '2024-09-10', orders: 62, avgValue: 2400 }
      ],
      topShops: [
        { name: 'Electronics Hub', owner: 'Ravi Kumar', revenue: 458000, orders: 234, rating: 4.8 },
        { name: 'Fashion Store', owner: 'Priya Singh', revenue: 387000, orders: 198, rating: 4.6 },
        { name: 'Super Mart', owner: 'Amit Sharma', revenue: 342000, orders: 176, rating: 4.7 },
        { name: 'Tech World', owner: 'Sunita Patel', revenue: 298000, orders: 145, rating: 4.5 },
        { name: 'Style Zone', owner: 'Vikram Rao', revenue: 265000, orders: 132, rating: 4.4 }
      ],
      categoryPerformance: [
        { name: 'Electronics', revenue: 856000, orders: 425, marketShare: 35, trend: '+12.5%' },
        { name: 'Fashion & Clothing', revenue: 642000, orders: 318, marketShare: 25, trend: '+8.3%' },
        { name: 'Food & Beverages', revenue: 485000, orders: 267, marketShare: 20, trend: '+15.2%' },
        { name: 'Home & Garden', revenue: 364000, orders: 189, marketShare: 15, trend: '+5.7%' },
        { name: 'Others', revenue: 128000, orders: 87, marketShare: 5, trend: '+3.1%' }
      ]
    };
  }
}