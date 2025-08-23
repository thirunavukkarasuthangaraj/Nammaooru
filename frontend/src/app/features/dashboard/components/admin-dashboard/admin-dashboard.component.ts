import { Component, OnInit, OnDestroy } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable, Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { AppState } from '../../../../store/app.state';
import * as DashboardActions from '../../../../store/dashboard/dashboard.actions';
import { WebSocketService } from '../../../../core/services/websocket.service';
import { ChartConfiguration } from 'chart.js';

@Component({
  selector: 'app-admin-dashboard',
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.scss']
})
export class AdminDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  // Metrics
  metrics = {
    activeShops: 0,
    pendingOrders: 0,
    deliveriesInProgress: 0,
    customerComplaints: 0,
    todayOrders: 0,
    averageDeliveryTime: 0,
    customerSatisfaction: 0,
    shopCompliance: 0
  };
  
  // Shop Monitoring
  shopPerformance: any[] = [];
  problematicShops: any[] = [];
  topRatedShops: any[] = [];
  
  // Order Management
  recentOrders: any[] = [];
  disputedOrders: any[] = [];
  delayedOrders: any[] = [];
  
  // Customer Support
  openTickets: any[] = [];
  escalatedIssues: any[] = [];
  customerFeedback: any[] = [];
  
  // Quality Metrics
  qualityMetrics = {
    foodQuality: 0,
    packagingQuality: 0,
    deliveryQuality: 0,
    overallQuality: 0
  };
  
  // Charts
  orderTrendData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Orders',
      backgroundColor: '#006994',
      borderColor: '#006994'
    }]
  };
  
  shopPerformanceData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Performance Score',
      backgroundColor: '#4CAF50'
    }]
  };
  
  customerSatisfactionData: ChartConfiguration['data'] = {
    labels: ['Very Satisfied', 'Satisfied', 'Neutral', 'Dissatisfied', 'Very Dissatisfied'],
    datasets: [{
      data: [0, 0, 0, 0, 0],
      backgroundColor: ['#4CAF50', '#8BC34A', '#FFC107', '#FF9800', '#F44336']
    }]
  };
  
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
      role: 'ADMIN', 
      period: '30days' 
    }));
  }
  
  private setupRealTimeUpdates(): void {
    this.websocketService.connect().pipe(
      takeUntil(this.destroy$)
    ).subscribe();
    
    this.websocketService.subscribe('/topic/dashboard/admin')
      .pipe(takeUntil(this.destroy$))
      .subscribe(update => {
        this.handleRealTimeUpdate(update);
      });
      
    this.websocketService.subscribe('/topic/orders/status')
      .pipe(takeUntil(this.destroy$))
      .subscribe(order => {
        this.updateOrderStatus(order);
      });
      
    this.websocketService.subscribe('/topic/shops/alerts')
      .pipe(takeUntil(this.destroy$))
      .subscribe(alert => {
        this.handleShopAlert(alert);
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
    if (update.type === 'METRICS') {
      this.metrics = { ...this.metrics, ...update.data };
    } else if (update.type === 'NEW_COMPLAINT') {
      this.metrics.customerComplaints++;
      this.openTickets.unshift(update.data);
    }
  }
  
  private updateOrderStatus(order: any): void {
    const index = this.recentOrders.findIndex(o => o.id === order.id);
    if (index !== -1) {
      this.recentOrders[index] = order;
    }
  }
  
  private handleShopAlert(alert: any): void {
    this.notifications.unshift({
      type: 'shop_alert',
      message: alert.message,
      timestamp: new Date(),
      shopId: alert.shopId
    });
  }
  
  refreshDashboard(): void {
    this.store.dispatch(DashboardActions.refreshDashboard());
  }
  
  viewShopDetails(shopId: string): void {
    console.log('Viewing shop:', shopId);
  }
  
  handleComplaint(ticketId: string): void {
    console.log('Handling complaint:', ticketId);
  }
  
  resolveDispute(orderId: string): void {
    console.log('Resolving dispute:', orderId);
  }
  
  exportReport(type: string): void {
    console.log('Exporting report:', type);
  }
}