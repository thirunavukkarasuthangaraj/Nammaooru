import { Component, OnInit } from '@angular/core';
import { AuthService } from '@core/services/auth.service';
import { ShopService } from '@core/services/shop.service';
import { User, UserRole } from '@core/models/auth.model';
import { Shop } from '@core/models/shop.model';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-shop-owner-dashboard',
  template: `
    <div class="shop-owner-dashboard">
      <!-- Welcome Header -->
      <div class="dashboard-header">
        <div class="welcome-section">
          <h1 class="welcome-title">Welcome back, {{ (currentUser$ | async)?.username }}!</h1>
          <p class="welcome-subtitle">Here's what's happening with your shop today</p>
        </div>
        <div class="header-actions">
          <button mat-raised-button color="primary" routerLink="/products/shop-owner">
            <mat-icon>add_shopping_cart</mat-icon>
            Add Products
          </button>
          <button mat-raised-button color="accent" routerLink="/products/my-shop">
            <mat-icon>inventory</mat-icon>
            View Inventory
          </button>
        </div>
      </div>

      <!-- Quick Stats Cards -->
      <div class="stats-grid">
        <mat-card class="stat-card revenue">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>attach_money</mat-icon>
              </div>
              <div class="stat-details">
                <h3 class="stat-value">₹{{ todaysRevenue | number:'1.0-0' }}</h3>
                <p class="stat-label">Today's Revenue</p>
                <span class="stat-change positive">+12.5%</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card orders">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>shopping_cart</mat-icon>
              </div>
              <div class="stat-details">
                <h3 class="stat-value">{{ todaysOrders }}</h3>
                <p class="stat-label">Today's Orders</p>
                <span class="stat-change positive">+8 new</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card products">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>inventory_2</mat-icon>
              </div>
              <div class="stat-details">
                <h3 class="stat-value">{{ totalProducts }}</h3>
                <p class="stat-label">Active Products</p>
                <span class="stat-change warning">{{ lowStockCount }} low stock</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card customers">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>people</mat-icon>
              </div>
              <div class="stat-details">
                <h3 class="stat-value">{{ totalCustomers }}</h3>
                <p class="stat-label">Total Customers</p>
                <span class="stat-change positive">+{{ newCustomers }} this week</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Main Content Grid -->
      <div class="content-grid">
        <!-- Recent Orders -->
        <mat-card class="content-card orders-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>receipt_long</mat-icon>
              Recent Orders
            </mat-card-title>
            <div class="card-actions">
              <button mat-button routerLink="/orders">View All</button>
            </div>
          </mat-card-header>
          <mat-card-content>
            <div class="orders-list" *ngIf="recentOrders.length > 0; else noOrders">
              <div class="order-item" *ngFor="let order of recentOrders">
                <div class="order-info">
                  <h4 class="order-id">#{{ order.id }}</h4>
                  <p class="order-customer">{{ order.customerName }}</p>
                  <span class="order-time">{{ order.createdAt | date:'short' }}</span>
                </div>
                <div class="order-details">
                  <p class="order-amount">₹{{ order.total | number:'1.0-0' }}</p>
                  <span class="order-status" [class]="'status-' + order.status.toLowerCase()">
                    {{ order.status }}
                  </span>
                </div>
              </div>
            </div>
            <ng-template #noOrders>
              <div class="empty-state">
                <mat-icon>inbox</mat-icon>
                <p>No recent orders</p>
              </div>
            </ng-template>
          </mat-card-content>
        </mat-card>

        <!-- Low Stock Alert -->
        <mat-card class="content-card inventory-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>warning</mat-icon>
              Low Stock Alert
            </mat-card-title>
            <div class="card-actions">
              <button mat-button routerLink="/products/my-shop">Manage Inventory</button>
            </div>
          </mat-card-header>
          <mat-card-content>
            <div class="inventory-list" *ngIf="lowStockProducts.length > 0; else noLowStock">
              <div class="inventory-item" *ngFor="let product of lowStockProducts">
                <div class="product-info">
                  <img [src]="product.imageUrl" [alt]="product.name" class="product-image">
                  <div class="product-details">
                    <h4 class="product-name">{{ product.name }}</h4>
                    <p class="product-category">{{ product.category }}</p>
                  </div>
                </div>
                <div class="stock-info">
                  <span class="stock-count critical">{{ product.stock }} left</span>
                  <button mat-button color="primary" (click)="updateStock(product)">
                    <mat-icon>add</mat-icon>
                    Update
                  </button>
                </div>
              </div>
            </div>
            <ng-template #noLowStock>
              <div class="empty-state">
                <mat-icon>check_circle</mat-icon>
                <p>All products are well stocked!</p>
              </div>
            </ng-template>
          </mat-card-content>
        </mat-card>

        <!-- Sales Chart -->
        <mat-card class="content-card chart-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>trending_up</mat-icon>
              Sales Overview
            </mat-card-title>
            <div class="card-actions">
              <button mat-button routerLink="/reports">View Reports</button>
            </div>
          </mat-card-header>
          <mat-card-content>
            <div class="chart-placeholder">
              <mat-icon>analytics</mat-icon>
              <p>Sales chart will be displayed here</p>
              <small>Integration with charting library needed</small>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Quick Actions -->
        <mat-card class="content-card actions-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>flash_on</mat-icon>
              Quick Actions
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="quick-actions-grid">
              <button mat-stroked-button class="action-button" routerLink="/products/shop-owner">
                <mat-icon>add_box</mat-icon>
                <span>Add Products</span>
              </button>
              <button mat-stroked-button class="action-button" routerLink="/orders/new">
                <mat-icon>receipt</mat-icon>
                <span>New Order</span>
              </button>
              <button mat-stroked-button class="action-button" routerLink="/shop/profile">
                <mat-icon>store</mat-icon>
                <span>Shop Profile</span>
              </button>
              <button mat-stroked-button class="action-button" routerLink="/reports">
                <mat-icon>assessment</mat-icon>
                <span>Reports</span>
              </button>
              <button mat-stroked-button class="action-button" routerLink="/settings">
                <mat-icon>settings</mat-icon>
                <span>Settings</span>
              </button>
              <button mat-stroked-button class="action-button" routerLink="/help">
                <mat-icon>help</mat-icon>
                <span>Help & Support</span>
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .shop-owner-dashboard {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .dashboard-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .welcome-title {
      font-size: 2rem;
      font-weight: 500;
      margin: 0 0 8px 0;
      color: #333;
    }

    .welcome-subtitle {
      font-size: 1rem;
      color: #666;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .header-actions button {
      height: 48px;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      padding: 0;
      border-radius: 12px;
      overflow: hidden;
    }

    .stat-card.revenue { border-left: 4px solid #4caf50; }
    .stat-card.orders { border-left: 4px solid #2196f3; }
    .stat-card.products { border-left: 4px solid #ff9800; }
    .stat-card.customers { border-left: 4px solid #9c27b0; }

    .stat-content {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 16px;
    }

    .stat-icon {
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      width: 56px;
      height: 56px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .stat-icon mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .stat-details {
      flex: 1;
    }

    .stat-value {
      font-size: 1.8rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #333;
    }

    .stat-label {
      font-size: 0.9rem;
      color: #666;
      margin: 0 0 4px 0;
    }

    .stat-change {
      font-size: 0.8rem;
      font-weight: 500;
      padding: 2px 8px;
      border-radius: 12px;
    }

    .stat-change.positive {
      background: #e8f5e8;
      color: #4caf50;
    }

    .stat-change.warning {
      background: #fff3e0;
      color: #ff9800;
    }

    .content-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .content-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .content-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 16px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .content-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.1rem;
      font-weight: 500;
    }

    .card-actions {
      margin-left: auto;
    }

    .orders-list, .inventory-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .order-item, .inventory-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 8px;
    }

    .order-info h4, .product-details h4 {
      margin: 0 0 4px 0;
      font-size: 0.9rem;
      font-weight: 600;
    }

    .order-info p, .product-details p {
      margin: 0 0 2px 0;
      font-size: 0.8rem;
      color: #666;
    }

    .order-time {
      font-size: 0.7rem !important;
      color: #999 !important;
    }

    .order-amount {
      font-weight: 600;
      color: #333;
      margin-bottom: 4px !important;
    }

    .order-status {
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 0.7rem;
      font-weight: 500;
      text-transform: uppercase;
    }

    .status-pending { background: #fff3e0; color: #ff9800; }
    .status-processing { background: #e3f2fd; color: #2196f3; }
    .status-completed { background: #e8f5e8; color: #4caf50; }
    .status-cancelled { background: #ffebee; color: #f44336; }

    .product-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .product-image {
      width: 40px;
      height: 40px;
      border-radius: 8px;
      object-fit: cover;
    }

    .stock-info {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .stock-count.critical {
      background: #ffebee;
      color: #f44336;
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.8rem;
      font-weight: 500;
    }

    .chart-placeholder {
      text-align: center;
      padding: 40px;
      color: #999;
    }

    .chart-placeholder mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
    }

    .quick-actions-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .action-button {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      padding: 16px;
      height: auto;
      min-height: 80px;
    }

    .action-button mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .action-button span {
      font-size: 0.8rem;
      text-align: center;
    }

    .empty-state {
      text-align: center;
      padding: 24px;
      color: #999;
    }

    .empty-state mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 12px;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .shop-owner-dashboard {
        padding: 16px;
      }

      .dashboard-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .stats-grid {
        grid-template-columns: 1fr;
      }

      .content-grid {
        grid-template-columns: 1fr;
      }

      .welcome-title {
        font-size: 1.5rem;
      }

      .header-actions {
        width: 100%;
        justify-content: center;
      }

      .quick-actions-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 480px) {
      .header-actions {
        flex-direction: column;
        width: 100%;
      }

      .stat-content {
        padding: 12px;
        gap: 12px;
      }

      .stat-icon {
        width: 48px;
        height: 48px;
      }

      .stat-value {
        font-size: 1.4rem;
      }
    }
  `]
})
export class ShopOwnerDashboardComponent implements OnInit {
  currentUser$: Observable<User | null>;
  loading = false;
  
  // Dashboard data from API
  todaysRevenue = 0;
  todaysOrders = 0;
  totalProducts = 0;
  lowStockCount = 0;
  totalCustomers = 0;
  newCustomers = 0;

  recentOrders: any[] = [];
  lowStockProducts: any[] = [];

  constructor(
    private authService: AuthService,
    private shopService: ShopService
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {
    this.loadDashboardData();
  }

  private loadDashboardData(): void {
    this.loading = true;
    this.loadTodaysStats();
    this.loadRecentOrders();
    this.loadLowStockProducts();
    this.loadCustomerStats();
  }

  private loadTodaysStats(): void {
    // Get today's revenue and orders from backend
    this.shopService.getTodaysRevenue().subscribe({
      next: (revenue) => {
        this.todaysRevenue = revenue || 0;
      },
      error: (error) => {
        console.error('Error loading todays revenue:', error);
        this.todaysRevenue = 0;
      }
    });

    this.shopService.getTodaysOrderCount().subscribe({
      next: (count) => {
        this.todaysOrders = count || 0;
      },
      error: (error) => {
        console.error('Error loading todays orders:', error);
        this.todaysOrders = 0;
      }
    });

    this.shopService.getTotalProductCount().subscribe({
      next: (count) => {
        this.totalProducts = count || 0;
      },
      error: (error) => {
        console.error('Error loading product count:', error);
        this.totalProducts = 0;
      }
    });

    this.shopService.getLowStockCount().subscribe({
      next: (count) => {
        this.lowStockCount = count || 0;
      },
      error: (error) => {
        console.error('Error loading low stock count:', error);
        this.lowStockCount = 0;
      }
    });
  }

  private loadRecentOrders(): void {
    this.shopService.getRecentOrders(5).subscribe({
      next: (orders) => {
        this.recentOrders = orders || [];
      },
      error: (error) => {
        console.error('Error loading recent orders:', error);
        this.recentOrders = [];
      }
    });
  }

  private loadLowStockProducts(): void {
    this.shopService.getLowStockProducts(10).subscribe({
      next: (products) => {
        this.lowStockProducts = products || [];
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading low stock products:', error);
        this.lowStockProducts = [];
        this.loading = false;
      }
    });
  }

  private loadCustomerStats(): void {
    this.shopService.getTotalCustomerCount().subscribe({
      next: (count) => {
        this.totalCustomers = count || 0;
      },
      error: (error) => {
        console.error('Error loading customer count:', error);
        this.totalCustomers = 0;
      }
    });

    this.shopService.getNewCustomerCount().subscribe({
      next: (count) => {
        this.newCustomers = count || 0;
      },
      error: (error) => {
        console.error('Error loading new customer count:', error);
        this.newCustomers = 0;
      }
    });
  }

  updateStock(product: any): void {
    // Navigate to product edit page or show update dialog
    console.log('Updating stock for product:', product.name);
    // TODO: Implement actual stock update functionality
    // this.router.navigate(['/products/edit', product.id]);
  }
}