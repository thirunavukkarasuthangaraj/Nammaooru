import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@core/services/auth.service';
import { ShopService } from '@core/services/shop.service';
import { SoundService } from '@core/services/sound.service';
import { OrderService } from '@core/services/order.service';
import { User } from '@core/models/auth.model';
import { Observable, interval, Subscription } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

interface DashboardStats {
  todayOrders: number;
  totalOrders: number;
  pendingOrders: number;
  todayRevenue: number;
  monthlyRevenue: number;
  totalProducts: number;
  lowStockProducts: number;
  outOfStockProducts: number;
}

@Component({
  selector: 'app-shop-owner-dashboard',
  template: `
    <div class="dashboard-wrapper">
      <!-- Welcome Header -->
      <div class="welcome-section">
        <div class="welcome-content">
          <h1 class="greeting">Good {{ getGreeting() }}, {{ (currentUser$ | async)?.username }}!</h1>
          <p class="date-text">{{ getCurrentDate() }}</p>
        </div>
        <button class="refresh-btn" (click)="refreshDashboard()">
          <mat-icon>refresh</mat-icon>
          Refresh
        </button>
      </div>

      <!-- Loading State -->
      <div class="loading-container" *ngIf="isLoading">
        <mat-spinner diameter="40"></mat-spinner>
      </div>

      <div class="dashboard-content" *ngIf="!isLoading">
        <!-- Top Stats Row - Horizontal Cards -->
        <div class="stats-grid">
          <div class="stat-card" routerLink="/shop-owner/orders-management">
            <div class="stat-icon blue">
              <mat-icon>shopping_bag</mat-icon>
            </div>
            <div class="stat-info">
              <span class="stat-value">{{ stats.todayOrders }}</span>
              <span class="stat-label">Today's Orders</span>
            </div>
          </div>

          <div class="stat-card" [class.alert]="stats.pendingOrders > 0" routerLink="/shop-owner/orders-management">
            <div class="stat-icon orange">
              <mat-icon>pending_actions</mat-icon>
            </div>
            <div class="stat-info">
              <span class="stat-value">{{ stats.pendingOrders }}</span>
              <span class="stat-label">Pending</span>
            </div>
          </div>

          <div class="stat-card" routerLink="/shop-owner/orders-management">
            <div class="stat-icon green">
              <mat-icon>check_circle</mat-icon>
            </div>
            <div class="stat-info">
              <span class="stat-value">{{ stats.totalOrders }}</span>
              <span class="stat-label">Total Orders</span>
            </div>
          </div>

          <div class="stat-card revenue-highlight">
            <div class="stat-icon dark-green">
              <mat-icon>currency_rupee</mat-icon>
            </div>
            <div class="stat-info">
              <span class="stat-value">₹{{ formatCurrency(stats.todayRevenue) }}</span>
              <span class="stat-label">Today's Revenue</span>
            </div>
          </div>
        </div>

        <!-- Main Content Grid -->
        <div class="content-grid">
          <!-- Left Column -->
          <div class="main-column">
            <!-- Revenue Overview Card -->
            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Revenue Overview</h2>
                <span class="period-badge">This Month</span>
              </div>
              <div class="revenue-stats">
                <div class="revenue-item">
                  <span class="revenue-label">Today</span>
                  <div class="revenue-amount">
                    <span class="currency">₹</span>
                    <span class="amount">{{ formatCurrency(stats.todayRevenue) }}</span>
                  </div>
                  <span class="trend up" *ngIf="stats.todayRevenue > 0">
                    <mat-icon>trending_up</mat-icon> Active
                  </span>
                </div>
                <div class="revenue-divider"></div>
                <div class="revenue-item">
                  <span class="revenue-label">This Month</span>
                  <div class="revenue-amount">
                    <span class="currency">₹</span>
                    <span class="amount">{{ formatCurrency(stats.monthlyRevenue) }}</span>
                  </div>
                  <span class="trend neutral">
                    <mat-icon>calendar_today</mat-icon> Monthly
                  </span>
                </div>
              </div>
            </div>

            <!-- Inventory Status Card -->
            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Inventory Status</h2>
                <button class="card-action-btn" routerLink="/shop-owner/my-products">
                  <mat-icon>arrow_forward</mat-icon>
                </button>
              </div>
              <div class="inventory-grid">
                <div class="inventory-item">
                  <div class="inv-icon green">
                    <mat-icon>inventory_2</mat-icon>
                  </div>
                  <span class="inv-value">{{ stats.totalProducts }}</span>
                  <span class="inv-label">Total Products</span>
                </div>
                <div class="inventory-item" [class.warning]="stats.lowStockProducts > 0">
                  <div class="inv-icon yellow">
                    <mat-icon>warning_amber</mat-icon>
                  </div>
                  <span class="inv-value">{{ stats.lowStockProducts }}</span>
                  <span class="inv-label">Low Stock</span>
                </div>
                <div class="inventory-item" [class.danger]="stats.outOfStockProducts > 0">
                  <div class="inv-icon red">
                    <mat-icon>error_outline</mat-icon>
                  </div>
                  <span class="inv-value">{{ stats.outOfStockProducts }}</span>
                  <span class="inv-label">Out of Stock</span>
                </div>
              </div>
              <div class="inventory-alert" *ngIf="hasStockAlert" routerLink="/shop-owner/my-products">
                <mat-icon>notifications_active</mat-icon>
                <span>{{ stats.lowStockProducts + stats.outOfStockProducts }} items need attention</span>
                <mat-icon class="arrow">chevron_right</mat-icon>
              </div>
            </div>
          </div>

          <!-- Right Column -->
          <div class="side-column">
            <!-- Quick Actions Card -->
            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Quick Actions</h2>
              </div>
              <div class="actions-list">
                <button class="action-btn" routerLink="/shop-owner/pos-billing">
                  <div class="action-icon green">
                    <mat-icon>point_of_sale</mat-icon>
                  </div>
                  <span class="action-text">POS Billing</span>
                  <mat-icon class="action-arrow">chevron_right</mat-icon>
                </button>
                <button class="action-btn" routerLink="/shop-owner/orders-management">
                  <div class="action-icon blue">
                    <mat-icon>receipt_long</mat-icon>
                  </div>
                  <span class="action-text">View Orders</span>
                  <mat-icon class="action-arrow">chevron_right</mat-icon>
                </button>
                <button class="action-btn" routerLink="/shop-owner/my-products">
                  <div class="action-icon purple">
                    <mat-icon>category</mat-icon>
                  </div>
                  <span class="action-text">My Products</span>
                  <mat-icon class="action-arrow">chevron_right</mat-icon>
                </button>
                <button class="action-btn" routerLink="/shop-owner/bulk-edit">
                  <div class="action-icon orange">
                    <mat-icon>table_chart</mat-icon>
                  </div>
                  <span class="action-text">Bulk Edit</span>
                  <mat-icon class="action-arrow">chevron_right</mat-icon>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    /* Modern Dashboard Wrapper */
    .dashboard-wrapper {
      padding: 24px;
      background: #f8fafc;
      min-height: calc(100vh - 64px);
    }

    /* Welcome Section */
    .welcome-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 28px;
    }

    .welcome-content .greeting {
      font-size: 26px;
      font-weight: 700;
      color: #1e293b;
      margin: 0 0 4px 0;
      letter-spacing: -0.5px;
    }

    .welcome-content .date-text {
      font-size: 14px;
      color: #64748b;
      margin: 0;
      font-weight: 500;
    }

    .refresh-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 20px;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
      background: white;
      color: #475569;
      font-weight: 500;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .refresh-btn:hover {
      border-color: #4ade80;
      color: #16a34a;
      background: #f0fdf4;
    }

    .refresh-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    /* Loading */
    .loading-container {
      display: flex;
      justify-content: center;
      padding: 80px;
    }

    /* Stats Grid - Top Row */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      margin-bottom: 28px;
    }

    .stat-card {
      background: white;
      border-radius: 16px;
      padding: 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      border: 1px solid #f1f5f9;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .stat-card:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
      transform: translateY(-2px);
    }

    .stat-card.alert {
      background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
      border-color: #fcd34d;
    }

    .stat-card.revenue-highlight {
      background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
      border-color: #86efac;
    }

    .stat-icon {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .stat-icon mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
      color: white;
    }

    .stat-icon.blue { background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); }
    .stat-icon.orange { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); }
    .stat-icon.green { background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%); }
    .stat-icon.dark-green { background: linear-gradient(135deg, #16a34a 0%, #15803d 100%); }
    .stat-icon.purple { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); }
    .stat-icon.yellow { background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%); }
    .stat-icon.red { background: linear-gradient(135deg, #f87171 0%, #ef4444 100%); }

    .stat-info {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .stat-info .stat-value {
      font-size: 24px;
      font-weight: 700;
      color: #1e293b;
      letter-spacing: -0.5px;
    }

    .stat-info .stat-label {
      font-size: 13px;
      color: #64748b;
      font-weight: 500;
    }

    /* Content Grid */
    .content-grid {
      display: grid;
      grid-template-columns: 1fr 380px;
      gap: 24px;
    }

    .main-column, .side-column {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    /* Card Base */
    .card {
      background: white;
      border-radius: 16px;
      border: 1px solid #f1f5f9;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
      overflow: hidden;
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px 16px;
    }

    .card-title {
      font-size: 16px;
      font-weight: 600;
      color: #1e293b;
      margin: 0;
      letter-spacing: -0.2px;
    }

    .period-badge {
      background: #f0fdf4;
      color: #16a34a;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }

    .card-action-btn {
      width: 36px;
      height: 36px;
      background: #f8fafc;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
    }

    .card-action-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      color: #64748b;
    }

    .card-action-btn:hover {
      background: #f0fdf4;
    }

    .card-action-btn:hover mat-icon {
      color: #16a34a;
    }

    /* Revenue Card */
    .revenue-stats {
      display: flex;
      padding: 0 24px 24px;
      gap: 32px;
    }

    .revenue-item {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .revenue-label {
      font-size: 13px;
      color: #64748b;
      font-weight: 500;
    }

    .revenue-amount {
      display: flex;
      align-items: baseline;
    }

    .revenue-amount .currency {
      font-size: 18px;
      font-weight: 600;
      color: #64748b;
      margin-right: 2px;
    }

    .revenue-amount .amount {
      font-size: 32px;
      font-weight: 700;
      color: #1e293b;
      letter-spacing: -1px;
    }

    .trend {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      font-weight: 600;
    }

    .trend mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .trend.up { color: #16a34a; }
    .trend.neutral { color: #64748b; }

    .revenue-divider {
      width: 1px;
      background: linear-gradient(180deg, transparent 0%, #e2e8f0 20%, #e2e8f0 80%, transparent 100%);
    }

    /* Inventory Card */
    .inventory-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
      padding: 0 24px;
    }

    .inventory-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px 16px;
      background: #f8fafc;
      border-radius: 12px;
      transition: all 0.2s ease;
    }

    .inventory-item.warning {
      background: #fffbeb;
    }

    .inventory-item.warning .inv-value {
      color: #d97706;
    }

    .inventory-item.danger {
      background: #fef2f2;
    }

    .inventory-item.danger .inv-value {
      color: #dc2626;
    }

    .inv-icon {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 12px;
    }

    .inv-icon mat-icon {
      font-size: 22px;
      width: 22px;
      height: 22px;
      color: white;
    }

    .inv-value {
      font-size: 28px;
      font-weight: 700;
      color: #1e293b;
      letter-spacing: -0.5px;
    }

    .inv-label {
      font-size: 12px;
      color: #64748b;
      font-weight: 500;
      margin-top: 4px;
    }

    .inventory-alert {
      display: flex;
      align-items: center;
      gap: 10px;
      margin: 20px 24px 24px;
      padding: 14px 16px;
      background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .inventory-alert:hover {
      transform: translateX(4px);
    }

    .inventory-alert mat-icon {
      color: #b45309;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .inventory-alert span {
      flex: 1;
      font-size: 13px;
      font-weight: 600;
      color: #92400e;
    }

    .inventory-alert .arrow {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    /* Quick Actions Card */
    .actions-list {
      padding: 0 16px 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .action-btn {
      display: flex;
      align-items: center;
      gap: 14px;
      width: 100%;
      padding: 14px 16px;
      background: #f8fafc;
      border: 1px solid transparent;
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .action-btn:hover {
      background: white;
      border-color: #e2e8f0;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    }

    .action-btn:hover .action-arrow {
      transform: translateX(4px);
      color: #4ade80;
    }

    .action-icon {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .action-icon mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      color: white;
    }

    .action-text {
      flex: 1;
      font-size: 14px;
      font-weight: 600;
      color: #1e293b;
      text-align: left;
    }

    .action-arrow {
      font-size: 18px;
      width: 18px;
      height: 18px;
      color: #94a3b8;
      transition: all 0.2s ease;
    }

    /* Responsive Design */
    @media (max-width: 1200px) {
      .content-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 900px) {
      .stats-grid {
        grid-template-columns: repeat(2, 1fr);
      }
    }

    @media (max-width: 600px) {
      .dashboard-wrapper {
        padding: 16px;
      }

      .welcome-section {
        flex-direction: column;
        align-items: flex-start;
        gap: 16px;
      }

      .welcome-content .greeting {
        font-size: 22px;
      }

      .stats-grid {
        grid-template-columns: 1fr 1fr;
        gap: 12px;
      }

      .stat-card {
        padding: 16px;
      }

      .stat-icon {
        width: 44px;
        height: 44px;
      }

      .stat-info .stat-value {
        font-size: 20px;
      }

      .inventory-grid {
        grid-template-columns: 1fr;
        gap: 12px;
        padding: 0 16px;
      }

      .revenue-stats {
        flex-direction: column;
        gap: 20px;
        padding: 0 16px 16px;
      }

      .revenue-divider {
        width: 100%;
        height: 1px;
      }

      .card-header {
        padding: 16px 16px 12px;
      }

      .inventory-alert {
        margin: 16px;
      }
    }
  `]
})
export class ShopOwnerDashboardComponent implements OnInit, OnDestroy {
  currentUser$: Observable<User | null>;
  isLoading = true;
  unreadNotificationCount = 0;

  stats: DashboardStats = {
    todayOrders: 0,
    totalOrders: 0,
    pendingOrders: 0,
    todayRevenue: 0,
    monthlyRevenue: 0,
    totalProducts: 0,
    lowStockProducts: 0,
    outOfStockProducts: 0,
  };

  private refreshSubscription?: Subscription;
  private previousOrderCount = 0;

  constructor(
    private authService: AuthService,
    private shopService: ShopService,
    private soundService: SoundService,
    private orderService: OrderService,
    private http: HttpClient,
    private router: Router
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  get hasStockAlert(): boolean {
    return this.stats.lowStockProducts > 0 || this.stats.outOfStockProducts > 0;
  }

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

  ngOnInit(): void {
    this.loadCachedStats();
    this.loadDashboardData();
    this.startAutoRefresh();
  }

  private loadCachedStats(): void {
    const cachedStats = localStorage.getItem('dashboard_stats');
    if (cachedStats) {
      try {
        const parsed = JSON.parse(cachedStats);
        this.stats = {
          todayOrders: parsed.todayOrders || 0,
          totalOrders: parsed.totalOrders || 0,
          pendingOrders: parsed.pendingOrders || 0,
          todayRevenue: parsed.todayRevenue || 0,
          monthlyRevenue: parsed.monthlyRevenue || 0,
          totalProducts: parsed.totalProducts || 0,
          lowStockProducts: parsed.lowStockProducts || 0,
          outOfStockProducts: parsed.outOfStockProducts || 0,
        };
        this.isLoading = false;
      } catch (e) {
        console.warn('Error parsing cached stats:', e);
      }
    }
  }

  private saveCachedStats(): void {
    localStorage.setItem('dashboard_stats', JSON.stringify(this.stats));
  }

  ngOnDestroy(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
    }
  }

  loadDashboardData(): void {
    this.isLoading = true;

    this.http.get<any>(`${environment.apiUrl}/shops/my-shop`, { withCredentials: true })
      .subscribe({
        next: (response) => {
          if (response.data && response.data.shopId) {
            if (response.data.id) {
              localStorage.setItem('current_shop_id', response.data.id.toString());
            }
            localStorage.setItem('current_shop_string_id', response.data.shopId);
            this.fetchDashboardStats(response.data.shopId);
          } else {
            console.error('No shop found for this user');
            this.isLoading = false;
          }
        },
        error: (error) => {
          console.error('Error fetching shop:', error);
          const cachedStringId = localStorage.getItem('current_shop_string_id');
          if (cachedStringId) {
            this.fetchDashboardStats(cachedStringId);
          } else {
            this.isLoading = false;
          }
        }
      });
  }

  private fetchDashboardStats(shopId: string): void {
    this.http.get<any>(`${environment.apiUrl}/shops/${shopId}/dashboard`, { withCredentials: true })
      .subscribe({
        next: (response) => {
          if (response.statusCode === '0000' && response.data) {
            const orderMetrics = response.data.orderMetrics || {};
            const productMetrics = response.data.productMetrics || {};

            this.stats = {
              todayOrders: orderMetrics.todayOrders || 0,
              totalOrders: orderMetrics.totalOrders || 0,
              pendingOrders: orderMetrics.pendingOrders || 0,
              todayRevenue: orderMetrics.todayRevenue || 0,
              monthlyRevenue: orderMetrics.monthlyRevenue || 0,
              totalProducts: productMetrics.totalProducts || 0,
              lowStockProducts: productMetrics.lowStockProducts || 0,
              outOfStockProducts: productMetrics.outOfStockProducts || 0,
            };

            this.unreadNotificationCount = this.stats.pendingOrders;

            if (this.stats.pendingOrders > this.previousOrderCount && this.previousOrderCount > 0) {
              this.soundService.playNotificationSound();
            }
            this.previousOrderCount = this.stats.pendingOrders;

            this.saveCachedStats();
          }
          this.isLoading = false;
        },
        error: () => {
          this.isLoading = false;
        }
      });
  }

  refreshDashboard(): void {
    this.loadDashboardData();
  }

  formatCurrency(amount: number): string {
    if (amount >= 100000) {
      return (amount / 100000).toFixed(1) + 'L';
    } else if (amount >= 1000) {
      return (amount / 1000).toFixed(1) + 'K';
    }
    return amount.toFixed(0);
  }

  private startAutoRefresh(): void {
    this.refreshSubscription = interval(30000).subscribe(() => {
      this.loadDashboardData();
    });
  }
}
