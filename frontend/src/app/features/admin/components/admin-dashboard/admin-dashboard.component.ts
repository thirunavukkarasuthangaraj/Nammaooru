import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AdminDashboardService, AdminDashboardStats, SystemMetrics } from '../../services/admin-dashboard.service';

@Component({
  selector: 'app-admin-dashboard',
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.scss']
})
export class AdminDashboardComponent implements OnInit {
  stats: AdminDashboardStats = {
    totalUsers: 0,
    totalShops: 0,
    totalOrders: 0,
    totalRevenue: 0,
    activeUsers: 0,
    pendingShops: 0,
    todayOrders: 0,
    todayRevenue: 0,
    userGrowth: 0,
    shopGrowth: 0,
    orderGrowth: 0,
    revenueGrowth: 0
  };

  systemMetrics: SystemMetrics = {
    cpuUsage: 0,
    memoryUsage: 0,
    diskUsage: 0,
    activeConnections: 0,
    responseTime: 0,
    errorRate: 0
  };

  recentActivity: any[] = [];
  isLoading = true;

  constructor(
    private adminService: AdminDashboardService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.isLoading = true;

    // Mock dashboard data while backend is being fixed
    this.stats = {
      totalUsers: 1247,
      totalShops: 89,
      totalOrders: 3456,
      totalRevenue: 2456789,
      activeUsers: 156,
      pendingShops: 12,
      todayOrders: 67,
      todayRevenue: 45670,
      userGrowth: 8.5,
      shopGrowth: 12.3,
      orderGrowth: 15.7,
      revenueGrowth: 18.2
    };

    this.systemMetrics = {
      cpuUsage: 65,
      memoryUsage: 78,
      diskUsage: 45,
      activeConnections: 234,
      responseTime: 120,
      errorRate: 1.2
    };

    this.recentActivity = [
      {
        type: 'USER_REGISTRATION',
        message: 'New user registered: john.doe@email.com',
        timestamp: new Date('2025-01-22T10:30:00'),
        severity: 'success'
      },
      {
        type: 'SHOP_APPLICATION',
        message: 'New shop application: Fresh Foods Market',
        timestamp: new Date('2025-01-22T10:15:00'),
        severity: 'info'
      },
      {
        type: 'ORDER_PLACED',
        message: 'Order #ORD-2025-003 placed for ₹850',
        timestamp: new Date('2025-01-22T09:45:00'),
        severity: 'success'
      },
      {
        type: 'PAYMENT_COMPLETED',
        message: 'Payment completed for order #ORD-2025-002',
        timestamp: new Date('2025-01-22T09:30:00'),
        severity: 'success'
      }
    ];

    this.isLoading = false;
  }

  navigateToUsers(): void {
    this.router.navigate(['/admin/users']);
  }

  navigateToShops(): void {
    this.router.navigate(['/admin/shops']);
  }

  navigateToOrders(): void {
    this.router.navigate(['/admin/orders']);
  }

  navigateToAnalytics(): void {
    this.router.navigate(['/admin/analytics']);
  }

  getMetricStatus(value: number, threshold: number): string {
    if (value >= threshold) return 'danger';
    if (value >= threshold * 0.8) return 'warning';
    return 'success';
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  formatPercentage(value: number): string {
    return `${value.toFixed(1)}%`;
  }

  getGrowthClass(growth: number): string {
    if (growth > 0) return 'growth-positive';
    if (growth < 0) return 'growth-negative';
    return 'growth-neutral';
  }

  getActivityIcon(type: string): string {
    switch (type) {
      case 'USER_REGISTRATION':
        return 'person_add';
      case 'SHOP_APPLICATION':
        return 'store';
      case 'ORDER_PLACED':
        return 'shopping_cart';
      case 'PAYMENT_COMPLETED':
        return 'payment';
      default:
        return 'info';
    }
  }

  getActivityColor(severity: string): string {
    switch (severity) {
      case 'success':
        return 'text-success';
      case 'warning':
        return 'text-warning';
      case 'error':
        return 'text-danger';
      default:
        return 'text-info';
    }
  }

  refreshDashboard(): void {
    this.loadDashboardData();
  }
}