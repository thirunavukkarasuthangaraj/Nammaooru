import { Component, OnInit } from '@angular/core';
import { AnalyticsService } from '../../../../core/services/analytics.service';

export interface DashboardMetrics {
  totalRevenue: number;
  totalOrders: number;
  totalCustomers: number;
  totalShops: number;
  averageOrderValue: number;
  conversionRate: number;
  monthlyGrowth: number;
  revenueData: any[];
  orderData: any[];
  categoryData: any[];
  topShops: any[];
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  metrics: DashboardMetrics | null = null;
  loading = false;
  selectedPeriod = '30'; // days

  periodOptions = [
    { value: '7', label: 'Last 7 days' },
    { value: '30', label: 'Last 30 days' },
    { value: '90', label: 'Last 3 months' },
    { value: '365', label: 'Last year' }
  ];

  constructor(private analyticsService: AnalyticsService) {}

  ngOnInit(): void {
    this.loadDashboardMetrics();
  }

  loadDashboardMetrics(): void {
    this.loading = true;
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - parseInt(this.selectedPeriod));

    this.analyticsService.getDashboardMetrics(startDate, endDate).subscribe({
      next: (metrics) => {
        this.metrics = metrics;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading dashboard metrics:', error);
        // Use mock data when API fails
        this.metrics = this.getMockMetrics();
        this.loading = false;
      }
    });
  }

  private getMockMetrics(): DashboardMetrics {
    return {
      totalRevenue: 2847650,
      totalOrders: 1234,
      totalCustomers: 567,
      totalShops: 45,
      averageOrderValue: 2310,
      conversionRate: 3.8,
      monthlyGrowth: 12.5,
      revenueData: [
        { month: 'Jan', revenue: 180000 },
        { month: 'Feb', revenue: 220000 },
        { month: 'Mar', revenue: 195000 },
        { month: 'Apr', revenue: 280000 },
        { month: 'May', revenue: 310000 },
        { month: 'Jun', revenue: 295000 }
      ],
      orderData: [
        { day: 'Mon', orders: 45 },
        { day: 'Tue', orders: 52 },
        { day: 'Wed', orders: 38 },
        { day: 'Thu', orders: 65 },
        { day: 'Fri', orders: 71 },
        { day: 'Sat', orders: 89 },
        { day: 'Sun', orders: 62 }
      ],
      categoryData: [
        { category: 'Electronics', value: 35 },
        { category: 'Clothing', value: 25 },
        { category: 'Food & Beverages', value: 20 },
        { category: 'Home & Garden', value: 15 },
        { category: 'Others', value: 5 }
      ],
      topShops: [
        { name: 'Electronics Hub', revenue: 458000, orders: 234 },
        { name: 'Fashion Store', revenue: 387000, orders: 198 },
        { name: 'Super Mart', revenue: 342000, orders: 176 },
        { name: 'Tech World', revenue: 298000, orders: 145 },
        { name: 'Style Zone', revenue: 265000, orders: 132 }
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
}