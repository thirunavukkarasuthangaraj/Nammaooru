import { Component, OnInit, OnDestroy } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable, Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { AppState } from '../../../../store/app.state';
import * as DashboardActions from '../../../../store/dashboard/dashboard.actions';
import { WebSocketService } from '../../../../core/services/websocket.service';
import { ChartConfiguration } from 'chart.js';

@Component({
  selector: 'app-shop-owner-dashboard',
  templateUrl: './shop-owner-dashboard.component.html',
  styleUrls: ['./shop-owner-dashboard.component.scss']
})
export class ShopOwnerDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  // Business Metrics
  businessMetrics = {
    todayRevenue: 0,
    weekRevenue: 0,
    monthRevenue: 0,
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    avgOrderValue: 0,
    repeatCustomers: 0,
    newCustomers: 0,
    rating: 0,
    totalProducts: 0,
    lowStockItems: 0
  };
  
  // Financial Summary
  financialSummary = {
    totalEarnings: 0,
    pendingPayouts: 0,
    commission: 0,
    netEarnings: 0,
    lastPayout: null as Date | null,
    nextPayout: null as Date | null
  };
  
  // Inventory Status
  inventory = {
    totalItems: 0,
    inStock: 0,
    lowStock: 0,
    outOfStock: 0,
    expiringSoon: 0
  };
  
  // Recent Orders
  recentOrders: any[] = [];
  pendingOrders: any[] = [];
  
  // Top Products
  topProducts: any[] = [];
  
  // Customer Analytics
  customerAnalytics = {
    totalCustomers: 0,
    newThisMonth: 0,
    repeatRate: 0,
    avgOrderFrequency: 0
  };
  
  // Reviews
  recentReviews: any[] = [];
  reviewStats = {
    average: 0,
    total: 0,
    fiveStar: 0,
    fourStar: 0,
    threeStar: 0,
    twoStar: 0,
    oneStar: 0
  };
  
  // Charts
  revenueChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Revenue (₹)',
      backgroundColor: 'rgba(255, 107, 53, 0.2)',
      borderColor: '#FF6B35',
      fill: true
    }]
  };
  
  orderChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Orders',
      backgroundColor: '#006994'
    }]
  };
  
  categoryChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: ['#FF6B35', '#FFD700', '#006994', '#4CAF50', '#C41E3A']
    }]
  };
  
  customerChartData: ChartConfiguration['data'] = {
    labels: ['New', 'Returning'],
    datasets: [{
      data: [0, 0],
      backgroundColor: ['#FFD700', '#FF6B35']
    }]
  };
  
  // Quick Actions
  quickActions = [
    { icon: 'add_box', label: 'Add Product', action: 'add-product' },
    { icon: 'inventory', label: 'Update Stock', action: 'update-stock' },
    { icon: 'local_offer', label: 'Create Offer', action: 'create-offer' },
    { icon: 'receipt', label: 'View Orders', action: 'view-orders' }
  ];
  
  // Notifications
  notifications: any[] = [];
  
  constructor(
    private store: Store<AppState>,
    private websocketService: WebSocketService
  ) {}
  
  ngOnInit(): void {
    this.loadDashboardData();
    this.setupRealTimeUpdates();
    this.startAutoRefresh();
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
  
  private loadDashboardData(): void {
    this.store.dispatch(DashboardActions.loadDashboardMetrics({ 
      role: 'SHOP_OWNER', 
      period: '30days' 
    }));
    
    // Load shop-specific data
    this.loadBusinessMetrics();
    this.loadFinancialSummary();
    this.loadInventoryStatus();
    this.loadRecentOrders();
    this.loadTopProducts();
    this.loadCustomerAnalytics();
    this.loadReviews();
  }
  
  private setupRealTimeUpdates(): void {
    this.websocketService.connect().pipe(
      takeUntil(this.destroy$)
    ).subscribe();
    
    // Subscribe to shop-specific updates
    this.websocketService.subscribe('/topic/shop/dashboard')
      .pipe(takeUntil(this.destroy$))
      .subscribe(update => {
        this.handleRealTimeUpdate(update);
      });
      
    // New order notifications
    this.websocketService.subscribe('/topic/shop/orders')
      .pipe(takeUntil(this.destroy$))
      .subscribe(order => {
        this.handleNewOrder(order);
      });
      
    // Inventory alerts
    this.websocketService.subscribe('/topic/shop/inventory')
      .pipe(takeUntil(this.destroy$))
      .subscribe(alert => {
        this.handleInventoryAlert(alert);
      });
  }
  
  private startAutoRefresh(): void {
    interval(60000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.refreshDashboard();
      });
  }
  
  private handleRealTimeUpdate(update: any): void {
    if (update.type === 'REVENUE_UPDATE') {
      this.businessMetrics.todayRevenue = update.data.revenue;
    } else if (update.type === 'ORDER_UPDATE') {
      this.businessMetrics.pendingOrders = update.data.pending;
      this.businessMetrics.completedOrders = update.data.completed;
    }
  }
  
  private handleNewOrder(order: any): void {
    this.recentOrders.unshift(order);
    this.pendingOrders.unshift(order);
    this.businessMetrics.pendingOrders++;
    this.businessMetrics.todayRevenue += order.amount;
    
    // Show notification
    this.notifications.unshift({
      type: 'new_order',
      message: `New order #${order.orderNumber} received!`,
      amount: order.amount,
      timestamp: new Date()
    });
  }
  
  private handleInventoryAlert(alert: any): void {
    if (alert.type === 'LOW_STOCK') {
      this.inventory.lowStock++;
      this.notifications.unshift({
        type: 'inventory',
        message: `Low stock alert: ${alert.productName}`,
        timestamp: new Date()
      });
    }
  }
  
  private loadBusinessMetrics(): void {
    // Implementation for loading business metrics
  }
  
  private loadFinancialSummary(): void {
    // Implementation for loading financial summary
  }
  
  private loadInventoryStatus(): void {
    // Implementation for loading inventory status
  }
  
  private loadRecentOrders(): void {
    // Implementation for loading recent orders
  }
  
  private loadTopProducts(): void {
    // Implementation for loading top products
  }
  
  private loadCustomerAnalytics(): void {
    // Implementation for loading customer analytics
  }
  
  private loadReviews(): void {
    // Implementation for loading reviews
  }
  
  refreshDashboard(): void {
    this.store.dispatch(DashboardActions.refreshDashboard());
  }
  
  handleQuickAction(action: string): void {
    console.log('Quick action:', action);
    // Navigate to appropriate section
  }
  
  acceptOrder(orderId: string): void {
    console.log('Accepting order:', orderId);
  }
  
  rejectOrder(orderId: string): void {
    console.log('Rejecting order:', orderId);
  }
  
  updateInventory(productId: string): void {
    console.log('Updating inventory:', productId);
  }
  
  respondToReview(reviewId: string): void {
    console.log('Responding to review:', reviewId);
  }
  
  exportReport(type: string): void {
    console.log('Exporting report:', type);
  }
  
  viewAnalytics(): void {
    console.log('Viewing detailed analytics');
  }

  // Helper methods for UI
  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  getCurrentDate(): string {
    const options: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return new Date().toLocaleDateString('en-IN', options);
  }

  getShopOwnerName(): string {
    // Try to get from localStorage or use default
    const shopData = localStorage.getItem('shopData');
    if (shopData) {
      try {
        const parsed = JSON.parse(shopData);
        return parsed.ownerName || parsed.shopName || 'Shop Owner';
      } catch {
        return 'Shop Owner';
      }
    }
    return 'Shop Owner';
  }

  formatCurrency(value: number): string {
    if (!value) return '0';
    if (value >= 100000) {
      return (value / 100000).toFixed(1) + 'L';
    } else if (value >= 1000) {
      return (value / 1000).toFixed(1) + 'K';
    }
    return value.toLocaleString('en-IN');
  }
}