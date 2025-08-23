import { Component, OnInit, OnDestroy } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable, Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { AppState } from '../../../../store/app.state';
import * as DashboardActions from '../../../../store/dashboard/dashboard.actions';
import { DashboardMetrics } from '../../../../store/dashboard/dashboard.actions';
import { WebSocketService } from '../../../../core/services/websocket.service';
import { ChartConfiguration, ChartType } from 'chart.js';

@Component({
  selector: 'app-super-admin-dashboard',
  templateUrl: './super-admin-dashboard.component.html',
  styleUrls: ['./super-admin-dashboard.component.scss']
})
export class SuperAdminDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  // Dashboard Metrics
  metrics$: Observable<DashboardMetrics | null>;
  loading$: Observable<boolean>;
  
  // Real-time data
  currentTime = new Date();
  liveUsers = 0;
  systemStatus = 'Operational';
  
  // Chart configurations
  revenueChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Revenue (₹)',
        backgroundColor: 'rgba(255, 107, 53, 0.2)',
        borderColor: '#FF6B35',
        borderWidth: 2,
        fill: true
      }
    ]
  };
  
  revenueChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top'
      },
      title: {
        display: true,
        text: 'Revenue Trend'
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: function(value) {
            return '₹' + value.toLocaleString('en-IN');
          }
        }
      }
    }
  };
  
  orderVolumeChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Orders',
        backgroundColor: '#006994',
        borderColor: '#006994',
        borderWidth: 2
      }
    ]
  };
  
  shopDistributionData: ChartConfiguration['data'] = {
    labels: ['Active', 'Pending', 'Suspended', 'Rejected'],
    datasets: [{
      data: [0, 0, 0, 0],
      backgroundColor: ['#4CAF50', '#FFC107', '#FF6B35', '#C41E3A']
    }]
  };
  
  userGrowthData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Customers',
        borderColor: '#FFD700',
        backgroundColor: 'rgba(255, 215, 0, 0.1)'
      },
      {
        data: [],
        label: 'Shop Owners',
        borderColor: '#FF6B35',
        backgroundColor: 'rgba(255, 107, 53, 0.1)'
      },
      {
        data: [],
        label: 'Delivery Partners',
        borderColor: '#006994',
        backgroundColor: 'rgba(0, 105, 148, 0.1)'
      }
    ]
  };
  
  // Geographic data for map
  geographicData: any[] = [];
  
  // Key Performance Indicators
  kpis = {
    totalRevenue: 0,
    totalOrders: 0,
    activeShops: 0,
    totalCustomers: 0,
    avgOrderValue: 0,
    conversionRate: 0,
    monthlyGrowth: 0,
    deliverySuccessRate: 0
  };
  
  // Recent activities
  recentActivities: any[] = [];
  
  // Top performers
  topShops: any[] = [];
  topDeliveryPartners: any[] = [];
  
  // System health metrics
  systemHealth = {
    cpu: 0,
    memory: 0,
    activeConnections: 0,
    responseTime: 0,
    uptime: '99.99%'
  };
  
  // Financial summary
  financialSummary = {
    todayRevenue: 0,
    weekRevenue: 0,
    monthRevenue: 0,
    pendingPayouts: 0,
    totalCommission: 0
  };
  
  // Alerts and notifications
  criticalAlerts: any[] = [];
  pendingApprovals = {
    shops: 0,
    deliveryPartners: 0,
    withdrawals: 0
  };
  
  constructor(
    private store: Store<AppState>,
    private websocketService: WebSocketService
  ) {
    this.metrics$ = this.store.select(state => state.dashboard.metrics);
    this.loading$ = this.store.select(state => state.dashboard.loading);
  }
  
  ngOnInit(): void {
    this.initializeDashboard();
    this.setupRealTimeUpdates();
    this.loadDashboardData();
    this.startAutoRefresh();
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
  
  private initializeDashboard(): void {
    // Set current time
    interval(1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.currentTime = new Date();
      });
  }
  
  private setupRealTimeUpdates(): void {
    // Subscribe to WebSocket for real-time updates
    this.websocketService.connect().pipe(
      takeUntil(this.destroy$)
    ).subscribe();
    
    // Listen for dashboard updates
    this.websocketService.subscribe('/topic/dashboard/super-admin')
      .pipe(takeUntil(this.destroy$))
      .subscribe(update => {
        this.handleRealTimeUpdate(update);
      });
    
    // Listen for system health updates
    this.websocketService.subscribe('/topic/system/health')
      .pipe(takeUntil(this.destroy$))
      .subscribe(health => {
        this.updateSystemHealth(health);
      });
    
    // Listen for critical alerts
    this.websocketService.subscribe('/topic/alerts/critical')
      .pipe(takeUntil(this.destroy$))
      .subscribe(alert => {
        this.criticalAlerts.unshift(alert);
        if (this.criticalAlerts.length > 10) {
          this.criticalAlerts.pop();
        }
      });
  }
  
  private loadDashboardData(): void {
    this.store.dispatch(DashboardActions.loadDashboardMetrics({ 
      role: 'SUPER_ADMIN', 
      period: '30days' 
    }));
    
    this.store.dispatch(DashboardActions.loadGeographicData());
    
    // Subscribe to metrics updates
    this.metrics$.pipe(takeUntil(this.destroy$)).subscribe(metrics => {
      if (metrics) {
        this.updateCharts(metrics);
        this.updateKPIs(metrics);
      }
    });
  }
  
  private startAutoRefresh(): void {
    // Auto-refresh every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.refreshDashboard();
      });
  }
  
  private handleRealTimeUpdate(update: any): void {
    if (update.type === 'METRICS_UPDATE') {
      this.store.dispatch(DashboardActions.updateLiveMetrics({ 
        metrics: update.data 
      }));
    } else if (update.type === 'NEW_ORDER') {
      this.kpis.totalOrders++;
      this.recentActivities.unshift({
        type: 'order',
        message: `New order #${update.data.orderNumber} placed`,
        timestamp: new Date(),
        amount: update.data.amount
      });
    } else if (update.type === 'NEW_SHOP_REGISTRATION') {
      this.pendingApprovals.shops++;
    }
  }
  
  private updateSystemHealth(health: any): void {
    this.systemHealth = {
      cpu: health.cpu || 0,
      memory: health.memory || 0,
      activeConnections: health.activeConnections || 0,
      responseTime: health.responseTime || 0,
      uptime: health.uptime || '99.99%'
    };
  }
  
  private updateCharts(metrics: DashboardMetrics): void {
    // Update revenue chart
    if (metrics.revenueData) {
      this.revenueChartData.labels = metrics.revenueData.map(d => d.date);
      this.revenueChartData.datasets[0].data = metrics.revenueData.map(d => d.amount);
    }
    
    // Update order volume chart
    if (metrics.orderData) {
      this.orderVolumeChartData.labels = metrics.orderData.map(d => d.date);
      this.orderVolumeChartData.datasets[0].data = metrics.orderData.map(d => d.count);
    }
    
    // Update top shops
    this.topShops = metrics.topShops || [];
  }
  
  private updateKPIs(metrics: DashboardMetrics): void {
    this.kpis = {
      totalRevenue: metrics.totalRevenue,
      totalOrders: metrics.totalOrders,
      activeShops: metrics.totalShops,
      totalCustomers: metrics.totalCustomers,
      avgOrderValue: metrics.averageOrderValue,
      conversionRate: metrics.conversionRate,
      monthlyGrowth: metrics.monthlyGrowth,
      deliverySuccessRate: 95.5 // This would come from metrics
    };
  }
  
  refreshDashboard(): void {
    this.store.dispatch(DashboardActions.refreshDashboard());
  }
  
  navigateToSection(section: string): void {
    // Navigate to specific section
    console.log('Navigating to:', section);
  }
  
  exportReport(type: string): void {
    // Export dashboard report
    console.log('Exporting report:', type);
  }
  
  handleAlert(alert: any): void {
    // Handle critical alert
    console.log('Handling alert:', alert);
  }
  
  viewAllActivities(): void {
    // Navigate to activities page
    console.log('Viewing all activities');
  }
  
  changeTimeRange(range: string): void {
    this.store.dispatch(DashboardActions.loadDashboardMetrics({ 
      role: 'SUPER_ADMIN', 
      period: range 
    }));
  }
}