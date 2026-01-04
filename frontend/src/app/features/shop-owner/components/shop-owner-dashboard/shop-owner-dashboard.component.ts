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
    <div class="dashboard-container">
      <!-- Header Section -->
      <div class="dashboard-header">
        <div class="header-content">
          <span class="welcome-text">Welcome back,</span>
          <h1 class="user-name">{{ (currentUser$ | async)?.username }}</h1>
        </div>
        <div class="header-actions">
          <button mat-icon-button class="notification-btn" routerLink="/shop-owner/notifications">
            <mat-icon [matBadge]="unreadNotificationCount"
                     [matBadgeHidden]="unreadNotificationCount === 0"
                     matBadgeColor="warn"
                     matBadgeSize="small">notifications</mat-icon>
          </button>
          <button mat-icon-button (click)="refreshDashboard()" matTooltip="Refresh">
            <mat-icon>refresh</mat-icon>
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div class="loading-container" *ngIf="isLoading">
        <mat-spinner diameter="40"></mat-spinner>
      </div>

      <div class="dashboard-content" *ngIf="!isLoading">
        <!-- Orders Overview Section -->
        <div class="section">
          <div class="section-title">
            <mat-icon>shopping_cart</mat-icon>
            <span>Orders Overview</span>
          </div>
          <div class="metrics-row three-col">
            <div class="metric-card clickable" routerLink="/shop-owner/orders-management">
              <div class="metric-icon blue">
                <mat-icon>today</mat-icon>
              </div>
              <div class="metric-value blue">{{ stats.todayOrders }}</div>
              <div class="metric-label">Today's Orders</div>
            </div>
            <div class="metric-card clickable"
                 [class.highlight]="stats.pendingOrders > 0"
                 routerLink="/shop-owner/orders-management">
              <div class="metric-icon orange">
                <mat-icon>pending_actions</mat-icon>
              </div>
              <div class="metric-value orange">{{ stats.pendingOrders }}</div>
              <div class="metric-label">Pending</div>
            </div>
            <div class="metric-card clickable" routerLink="/shop-owner/orders-management">
              <div class="metric-icon purple">
                <mat-icon>receipt_long</mat-icon>
              </div>
              <div class="metric-value purple">{{ stats.totalOrders }}</div>
              <div class="metric-label">Total Orders</div>
            </div>
          </div>
        </div>

        <!-- Revenue Section -->
        <div class="section">
          <div class="section-title">
            <mat-icon>account_balance_wallet</mat-icon>
            <span>Revenue</span>
          </div>
          <div class="revenue-row">
            <div class="revenue-card green">
              <div class="revenue-header">
                <mat-icon>currency_rupee</mat-icon>
                <span>Today</span>
              </div>
              <div class="revenue-value">
                <span class="currency">₹</span>
                <span class="amount">{{ formatCurrency(stats.todayRevenue) }}</span>
              </div>
            </div>
            <div class="revenue-card teal">
              <div class="revenue-header">
                <mat-icon>calendar_month</mat-icon>
                <span>This Month</span>
              </div>
              <div class="revenue-value">
                <span class="currency">₹</span>
                <span class="amount">{{ formatCurrency(stats.monthlyRevenue) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Inventory Section -->
        <div class="section">
          <div class="section-title">
            <mat-icon>inventory_2</mat-icon>
            <span>Inventory</span>
          </div>
          <div class="inventory-card clickable"
               [class.alert]="hasStockAlert"
               routerLink="/shop-owner/my-products">
            <div class="inventory-stats">
              <div class="inventory-stat">
                <mat-icon class="purple">inventory_2</mat-icon>
                <div class="stat-value purple">{{ stats.totalProducts }}</div>
                <div class="stat-label">Total</div>
              </div>
              <div class="stat-divider"></div>
              <div class="inventory-stat">
                <mat-icon [class.orange]="stats.lowStockProducts > 0"
                         [class.grey]="stats.lowStockProducts === 0">warning_amber</mat-icon>
                <div class="stat-value"
                     [class.orange]="stats.lowStockProducts > 0"
                     [class.grey]="stats.lowStockProducts === 0">{{ stats.lowStockProducts }}</div>
                <div class="stat-label">Low Stock</div>
              </div>
              <div class="stat-divider"></div>
              <div class="inventory-stat">
                <mat-icon [class.red]="stats.outOfStockProducts > 0"
                         [class.grey]="stats.outOfStockProducts === 0">error_outline</mat-icon>
                <div class="stat-value"
                     [class.red]="stats.outOfStockProducts > 0"
                     [class.grey]="stats.outOfStockProducts === 0">{{ stats.outOfStockProducts }}</div>
                <div class="stat-label">Out of Stock</div>
              </div>
            </div>
            <div class="alert-banner" *ngIf="hasStockAlert">
              <mat-icon>warning_amber</mat-icon>
              <span>Stock needs attention! Click to manage.</span>
              <mat-icon>arrow_forward_ios</mat-icon>
            </div>
          </div>
        </div>

        <!-- Quick Actions Section -->
        <div class="section">
          <div class="section-title">
            <mat-icon>flash_on</mat-icon>
            <span>Quick Actions</span>
          </div>
          <div class="actions-grid">
            <div class="action-card" routerLink="/shop-owner/orders-management">
              <div class="action-icon blue">
                <mat-icon>receipt_long</mat-icon>
              </div>
              <span class="action-label">Orders</span>
              <mat-icon class="action-arrow">arrow_forward_ios</mat-icon>
            </div>
            <div class="action-card" routerLink="/shop-owner/my-products">
              <div class="action-icon purple">
                <mat-icon>category</mat-icon>
              </div>
              <span class="action-label">Products</span>
              <mat-icon class="action-arrow">arrow_forward_ios</mat-icon>
            </div>
            <div class="action-card" routerLink="/shop-owner/shop-profile">
              <div class="action-icon green">
                <mat-icon>store</mat-icon>
              </div>
              <span class="action-label">Shop Profile</span>
              <mat-icon class="action-arrow">arrow_forward_ios</mat-icon>
            </div>
            <div class="action-card" routerLink="/shop-owner/notifications">
              <div class="action-icon orange">
                <mat-icon>notifications</mat-icon>
              </div>
              <span class="action-label">Notifications</span>
              <mat-icon class="action-arrow">arrow_forward_ios</mat-icon>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-container {
      min-height: 100vh;
      background: #f5f7fa;
    }

    .dashboard-header {
      background: linear-gradient(135deg, #1B5E20 0%, #388E3C 100%);
      padding: 24px 20px 32px;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
    }

    .header-content {
      color: white;
    }

    .welcome-text {
      font-size: 14px;
      opacity: 0.8;
    }

    .user-name {
      font-size: 22px;
      font-weight: 600;
      margin: 4px 0 0 0;
    }

    .header-actions {
      display: flex;
      gap: 4px;
    }

    .header-actions button {
      color: white;
    }

    .notification-btn ::ng-deep .mat-badge-content {
      background: #f44336;
    }

    .loading-container {
      display: flex;
      justify-content: center;
      padding: 60px;
    }

    .dashboard-content {
      padding: 16px;
      margin-top: -16px;
    }

    .section {
      margin-bottom: 24px;
    }

    .section-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 16px;
      font-weight: 600;
      color: #212121;
      margin-bottom: 12px;
    }

    .section-title mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      color: #424242;
    }

    /* Metrics Row */
    .metrics-row {
      display: grid;
      gap: 12px;
    }

    .metrics-row.three-col {
      grid-template-columns: repeat(3, 1fr);
    }

    .metric-card {
      background: white;
      border-radius: 12px;
      padding: 16px 12px;
      text-align: center;
      border: 1px solid #e0e0e0;
      transition: all 0.2s ease;
    }

    .metric-card.clickable {
      cursor: pointer;
    }

    .metric-card.clickable:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }

    .metric-card.highlight {
      background: rgba(230, 81, 0, 0.1);
      border-color: #E65100;
      border-width: 2px;
    }

    .metric-icon {
      width: 40px;
      height: 40px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 8px;
    }

    .metric-icon mat-icon {
      color: white;
      font-size: 22px;
      width: 22px;
      height: 22px;
    }

    .metric-icon.blue { background: rgba(25, 118, 210, 0.15); }
    .metric-icon.blue mat-icon { color: #1976D2; }
    .metric-icon.orange { background: rgba(230, 81, 0, 0.15); }
    .metric-icon.orange mat-icon { color: #E65100; }
    .metric-icon.purple { background: rgba(123, 31, 162, 0.15); }
    .metric-icon.purple mat-icon { color: #7B1FA2; }

    .metric-value {
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .metric-value.blue { color: #1976D2; }
    .metric-value.orange { color: #E65100; }
    .metric-value.purple { color: #7B1FA2; }

    .metric-label {
      font-size: 11px;
      color: #757575;
    }

    /* Revenue Cards */
    .revenue-row {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
    }

    .revenue-card {
      padding: 16px;
      border-radius: 12px;
      color: white;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .revenue-card.green {
      background: linear-gradient(135deg, #2E7D32 0%, #43A047 100%);
    }

    .revenue-card.teal {
      background: linear-gradient(135deg, #00796B 0%, #00897B 100%);
    }

    .revenue-header {
      display: flex;
      align-items: center;
      gap: 6px;
      opacity: 0.9;
      font-size: 13px;
      margin-bottom: 12px;
    }

    .revenue-header mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .revenue-value {
      display: flex;
      align-items: flex-start;
    }

    .revenue-value .currency {
      font-size: 16px;
      font-weight: 500;
      margin-right: 2px;
    }

    .revenue-value .amount {
      font-size: 26px;
      font-weight: 700;
    }

    /* Inventory Card */
    .inventory-card {
      background: white;
      border-radius: 12px;
      padding: 16px;
      border: 1px solid #e0e0e0;
      transition: all 0.2s ease;
    }

    .inventory-card.clickable {
      cursor: pointer;
    }

    .inventory-card.clickable:hover {
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }

    .inventory-card.alert {
      border-color: #FF9800;
      border-width: 2px;
    }

    .inventory-stats {
      display: flex;
      align-items: center;
    }

    .inventory-stat {
      flex: 1;
      text-align: center;
    }

    .inventory-stat mat-icon {
      font-size: 22px;
      width: 22px;
      height: 22px;
      margin-bottom: 6px;
    }

    .inventory-stat .stat-value {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 2px;
    }

    .inventory-stat .stat-label {
      font-size: 10px;
      color: #757575;
    }

    .stat-divider {
      width: 1px;
      height: 50px;
      background: #e0e0e0;
    }

    .purple { color: #7B1FA2; }
    .orange { color: #FF9800; }
    .red { color: #f44336; }
    .grey { color: #9e9e9e; }

    .alert-banner {
      display: flex;
      align-items: center;
      gap: 8px;
      background: #FFF3E0;
      padding: 8px 12px;
      border-radius: 8px;
      margin-top: 12px;
    }

    .alert-banner mat-icon:first-child {
      color: #E65100;
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .alert-banner span {
      flex: 1;
      font-size: 12px;
      font-weight: 500;
      color: #E65100;
    }

    .alert-banner mat-icon:last-child {
      color: #E65100;
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    /* Action Cards */
    .actions-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
    }

    .action-card {
      background: white;
      border-radius: 12px;
      padding: 16px 12px;
      display: flex;
      align-items: center;
      gap: 12px;
      border: 1px solid #e0e0e0;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .action-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }

    .action-icon {
      width: 44px;
      height: 44px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .action-icon mat-icon {
      font-size: 22px;
      width: 22px;
      height: 22px;
    }

    .action-icon.blue { background: rgba(25, 118, 210, 0.15); }
    .action-icon.blue mat-icon { color: #1976D2; }
    .action-icon.purple { background: rgba(123, 31, 162, 0.15); }
    .action-icon.purple mat-icon { color: #7B1FA2; }
    .action-icon.green { background: rgba(46, 125, 50, 0.15); }
    .action-icon.green mat-icon { color: #2E7D32; }
    .action-icon.orange { background: rgba(230, 81, 0, 0.15); }
    .action-icon.orange mat-icon { color: #E65100; }

    .action-label {
      flex: 1;
      font-size: 14px;
      font-weight: 600;
      color: #212121;
    }

    .action-arrow {
      font-size: 16px;
      width: 16px;
      height: 16px;
      color: #bdbdbd;
    }

    /* Responsive */
    @media (max-width: 480px) {
      .metrics-row.three-col {
        grid-template-columns: repeat(3, 1fr);
      }

      .metric-card {
        padding: 12px 8px;
      }

      .metric-value {
        font-size: 18px;
      }

      .metric-label {
        font-size: 9px;
      }

      .revenue-value .amount {
        font-size: 22px;
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

  ngOnInit(): void {
    this.loadDashboardData();
    this.startAutoRefresh();
  }

  ngOnDestroy(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
    }
  }

  loadDashboardData(): void {
    this.isLoading = true;

    // Always fetch fresh shopId from my-shop endpoint to ensure we have the correct value
    this.http.get<any>(`${environment.apiUrl}/shops/my-shop`, { withCredentials: true })
      .subscribe({
        next: (response) => {
          if (response.data && response.data.shopId) {
            // Update localStorage with correct shopId
            localStorage.setItem('current_shop_id', response.data.shopId);
            if (response.data.id) {
              localStorage.setItem('current_shop_numeric_id', response.data.id.toString());
            }
            // Load dashboard with the fetched shopId
            this.fetchDashboardStats(response.data.shopId);
          } else {
            console.error('No shop found for this user');
            this.isLoading = false;
          }
        },
        error: (error) => {
          console.error('Error fetching shop:', error);
          // Fallback to localStorage if API fails
          const cachedShopId = localStorage.getItem('current_shop_id');
          if (cachedShopId && cachedShopId.startsWith('SHOP-')) {
            this.fetchDashboardStats(cachedShopId);
          } else {
            this.isLoading = false;
          }
        }
      });
  }

  private fetchDashboardStats(shopId: string): void {
    // Fetch dashboard data from API
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

            // Play sound for new orders
            if (this.stats.pendingOrders > this.previousOrderCount && this.previousOrderCount > 0) {
              this.soundService.playNotificationSound();
            }
            this.previousOrderCount = this.stats.pendingOrders;
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
    // Refresh every 30 seconds
    this.refreshSubscription = interval(30000).subscribe(() => {
      this.loadDashboardData();
    });
  }
}
