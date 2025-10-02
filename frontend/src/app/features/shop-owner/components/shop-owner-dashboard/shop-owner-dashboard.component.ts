import { Component, OnInit, OnDestroy } from '@angular/core';
import { AuthService } from '@core/services/auth.service';
import { ShopService } from '@core/services/shop.service';
import { SoundService } from '@core/services/sound.service';
import { OrderService } from '@core/services/order.service';
import { User, UserRole } from '@core/models/auth.model';
import { Shop } from '@core/models/shop.model';
import { Observable, interval, Subscription } from 'rxjs';

@Component({
  selector: 'app-shop-owner-dashboard',
  template: `
    <div class="shop-owner-dashboard">
      <!-- Welcome Header -->
      <div class="dashboard-header">
        <div class="welcome-section">
          <h1 class="welcome-title">Welcome back, {{ (currentUser$ | async)?.username }}!</h1>
          <p class="welcome-subtitle">Manage your shop with these essential tools</p>
        </div>
      </div>

      <!-- Main Menu Cards -->
      <div class="main-menu-grid">
        <!-- Notifications Card - NEW -->
        <mat-card class="menu-card notifications-card" routerLink="/shop-owner/notifications">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon notification-icon">
                <mat-icon [matBadge]="unreadNotificationCount"
                         [matBadgeHidden]="unreadNotificationCount === 0"
                         matBadgeColor="warn"
                         matBadgeSize="small">notifications</mat-icon>
              </div>
              <div class="card-info">
                <h3 class="card-title">Notifications</h3>
                <p class="card-description">View all order notifications and updates</p>
                <div class="notification-status" *ngIf="unreadNotificationCount > 0">
                  <span class="badge-unread">{{ unreadNotificationCount }} unread</span>
                </div>
              </div>
              <mat-icon class="arrow-icon">arrow_forward_ios</mat-icon>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Shop Profile -->
        <mat-card class="menu-card profile-card" routerLink="/shop-owner/shop-profile">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>store</mat-icon>
              </div>
              <div class="card-info">
                <h3 class="card-title">Shop Profile</h3>
                <p class="card-description">Manage your shop information, business hours, and settings</p>
              </div>
              <mat-icon class="arrow-icon">arrow_forward_ios</mat-icon>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Shop Products -->
        <mat-card class="menu-card products-card" routerLink="/shop-owner/my-products">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>inventory_2</mat-icon>
              </div>
              <div class="card-info">
                <h3 class="card-title">Shop Products</h3>
                <p class="card-description">Add, edit, and manage your product inventory</p>
              </div>
              <mat-icon class="arrow-icon">arrow_forward_ios</mat-icon>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Orders -->
        <mat-card class="menu-card orders-card" routerLink="/shop-owner/orders-management">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>receipt_long</mat-icon>
              </div>
              <div class="card-info">
                <h3 class="card-title">Orders</h3>
                <p class="card-description">View and manage customer orders and order history</p>
              </div>
              <mat-icon class="arrow-icon">arrow_forward_ios</mat-icon>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Quick Actions -->
      <div class="quick-actions-section">
        <h2 class="section-title">Quick Actions</h2>
        <div class="quick-actions-grid">
          <button mat-raised-button color="primary" class="quick-action-btn" routerLink="/shop-owner/add-product-modern">
            <mat-icon>add_box</mat-icon>
            <span>Create Product</span>
          </button>
          <button mat-raised-button color="accent" class="quick-action-btn" routerLink="/shop-owner/bulk-upload">
            <mat-icon>upload_file</mat-icon>
            <span>Bulk Product Upload</span>
          </button>
        </div>
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
      text-align: center;
      margin-bottom: 32px;
      background: white;
      padding: 32px 24px;
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

    .main-menu-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 32px;
    }

    .menu-card {
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      cursor: pointer;
      transition: all 0.3s ease;
      overflow: hidden;
    }

    .menu-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0,0,0,0.15);
    }

    .menu-card.notifications-card { border-left: 6px solid #e91e63; }
    .menu-card.profile-card { border-left: 6px solid #4caf50; }
    .menu-card.products-card { border-left: 6px solid #2196f3; }
    .menu-card.orders-card { border-left: 6px solid #ff9800; }

    .notification-icon {
      position: relative;
    }

    .notification-status {
      margin-top: 8px;
    }

    .badge-unread {
      background: #e91e63;
      color: white;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 0.75rem;
      font-weight: 500;
    }

    .card-content {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 24px;
    }

    .card-icon {
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      width: 64px;
      height: 64px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .card-icon mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .card-info {
      flex: 1;
    }

    .card-title {
      font-size: 1.3rem;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #333;
    }

    .card-description {
      font-size: 0.9rem;
      color: #666;
      margin: 0;
      line-height: 1.4;
    }

    .arrow-icon {
      color: #ccc;
      font-size: 20px;
    }

    .quick-actions-section {
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .section-title {
      font-size: 1.2rem;
      font-weight: 500;
      margin: 0 0 20px 0;
      color: #333;
      text-align: center;
    }

    .quick-actions-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      max-width: 500px;
      margin: 0 auto;
    }

    .quick-action-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      padding: 20px;
      height: auto;
      min-height: 100px;
      border-radius: 12px;
      font-weight: 500;
    }

    .quick-action-btn mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    .quick-action-btn span {
      font-size: 0.9rem;
      text-align: center;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .shop-owner-dashboard {
        padding: 16px;
      }

      .dashboard-header {
        padding: 24px 16px;
      }

      .welcome-title {
        font-size: 1.6rem;
      }

      .main-menu-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .card-content {
        padding: 20px;
        gap: 16px;
      }

      .card-icon {
        width: 56px;
        height: 56px;
      }

      .card-icon mat-icon {
        font-size: 28px;
        width: 28px;
        height: 28px;
      }

      .card-title {
        font-size: 1.2rem;
      }

      .quick-actions-grid {
        grid-template-columns: 1fr;
        gap: 12px;
      }
    }

    @media (max-width: 480px) {
      .card-content {
        padding: 16px;
        gap: 12px;
      }

      .card-icon {
        width: 48px;
        height: 48px;
      }

      .card-icon mat-icon {
        font-size: 24px;
        width: 24px;
        height: 24px;
      }

      .card-title {
        font-size: 1.1rem;
      }

      .card-description {
        font-size: 0.8rem;
      }

      .quick-action-btn {
        min-height: 80px;
        padding: 16px;
      }

      .quick-action-btn mat-icon {
        font-size: 24px;
        width: 24px;
        height: 24px;
      }
    }
  `]
})
export class ShopOwnerDashboardComponent implements OnInit, OnDestroy {
  currentUser$: Observable<User | null>;
  loading = false;
  unreadNotificationCount = 0;

  // Dashboard data from API
  todaysRevenue = 0;
  todaysOrders = 0;
  totalProducts = 0;
  lowStockCount = 0;
  totalCustomers = 0;
  newCustomers = 0;
  previousOrderCount = 0;

  recentOrders: any[] = [];
  lowStockProducts: any[] = [];

  // Auto-refresh subscription
  private refreshSubscription?: Subscription;

  constructor(
    private authService: AuthService,
    private shopService: ShopService,
    private soundService: SoundService,
    private orderService: OrderService
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {
    this.loadDashboardData();
    this.loadNotificationCount();
    this.startAutoRefresh();
  }
  
  ngOnDestroy(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
    }
  }

  private loadDashboardData(): void {
    this.loading = true;
    this.loadTodaysStats();
    this.loadRecentOrders();
    this.loadLowStockProducts();
    this.loadCustomerStats();
  }

  private loadNotificationCount(): void {
    // Get shop ID from localStorage (same way as orders and notifications components)
    const cachedShopId = localStorage.getItem('current_shop_id');
    if (cachedShopId) {
      const shopId = parseInt(cachedShopId, 10);
      this.orderService.getOrdersByShop(String(shopId), 0, 50)
        .subscribe({
          next: (orderPage) => {
            if (orderPage.data?.content) {
              // Count pending orders and recent orders (last 24 hours) as unread
              const pendingOrders = orderPage.data.content.filter((order: any) => order.status === 'PENDING');
              const yesterday = new Date();
              yesterday.setDate(yesterday.getDate() - 1);
              const recentOrders = orderPage.data.content.filter((order: any) => {
                const orderDate = new Date(order.createdAt);
                return orderDate > yesterday;
              });

              // Use whichever count is higher
              this.unreadNotificationCount = Math.max(pendingOrders.length, recentOrders.length);

              // Play sound for new pending orders
              if (pendingOrders.length > this.previousOrderCount && this.previousOrderCount > 0) {
                this.soundService.playNotificationSound();
              }
              this.previousOrderCount = pendingOrders.length;
            }
          },
          error: (error) => {
            console.error('Error loading notification count:', error);
          }
        });
    } else {
      console.error('No shop ID found in localStorage for notification count');
    }
  }

  private loadTodaysStats(): void {
    // Mock data while backend is being fixed
    this.todaysRevenue = 15420;
    this.todaysOrders = 23;
    this.totalProducts = 156;
    this.lowStockCount = 8;
  }

  private loadRecentOrders(): void {
    // Mock recent orders data
    this.recentOrders = [
      {
        id: 'ORD-2025-001',
        customerName: 'John Smith',
        createdAt: new Date('2025-01-22T10:30:00'),
        total: 850,
        status: 'PENDING'
      },
      {
        id: 'ORD-2025-002', 
        customerName: 'Sarah Wilson',
        createdAt: new Date('2025-01-22T09:15:00'),
        total: 1200,
        status: 'PROCESSING'
      },
      {
        id: 'ORD-2025-003',
        customerName: 'Mike Johnson', 
        createdAt: new Date('2025-01-22T08:45:00'),
        total: 675,
        status: 'COMPLETED'
      },
      {
        id: 'ORD-2025-004',
        customerName: 'Emily Davis',
        createdAt: new Date('2025-01-21T16:20:00'),
        total: 950,
        status: 'PROCESSING'
      }
    ];
  }

  private loadLowStockProducts(): void {
    // Mock low stock products data
    this.lowStockProducts = [
      {
        id: 1,
        name: 'Organic Apples',
        category: 'Fruits',
        stock: 5,
        imageUrl: 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=100&h=100&fit=crop'
      },
      {
        id: 2,
        name: 'Fresh Bread',
        category: 'Bakery', 
        stock: 3,
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100&h=100&fit=crop'
      },
      {
        id: 3,
        name: 'Whole Milk',
        category: 'Dairy',
        stock: 8,
        imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&h=100&fit=crop'
      }
    ];
    this.loading = false;
  }

  private loadCustomerStats(): void {
    // Mock customer stats
    this.totalCustomers = 89;
    this.newCustomers = 12;
  }

  updateStock(product: any): void {
    // Navigate to product edit page or show update dialog
    console.log('Updating stock for product:', product.name);
    // TODO: Implement actual stock update functionality
    // this.router.navigate(['/products/edit', product.id]);
  }
  
  private startAutoRefresh(): void {
    // Check for new orders every 30 seconds
    this.refreshSubscription = interval(30000).subscribe(() => {
      this.checkForNewOrders();
      this.loadNotificationCount();
    });
  }

  private checkForNewOrders(): void {
    // Store the previous order count
    const previousCount = this.recentOrders.length;
    
    // Simulate checking for new orders (in real app, this would call the API)
    const newOrderChance = Math.random();
    if (newOrderChance > 0.7) { // 30% chance of new order
      const newOrder = {
        id: `ORD-2025-${Math.floor(Math.random() * 1000)}`,
        customerName: `Customer ${Math.floor(Math.random() * 100)}`,
        createdAt: new Date(),
        total: Math.floor(Math.random() * 2000) + 500,
        status: 'PENDING'
      };
      
      // Add new order to the beginning of the list
      this.recentOrders.unshift(newOrder);
      if (this.recentOrders.length > 5) {
        this.recentOrders.pop(); // Keep only 5 recent orders
      }
      
      // Update order count
      this.todaysOrders++;
      this.todaysRevenue += newOrder.total;
      
      // Play notification sound
      this.soundService.playOrderNotification();
      
      // Show browser notification if permitted
      this.showBrowserNotification(newOrder);
    }
  }
  
  private showBrowserNotification(order: any): void {
    if ('Notification' in window && Notification.permission === 'granted') {
      const notification = new Notification('New Order Received! 🛒', {
        body: `Order #${order.id} from ${order.customerName} - ₹${order.total}`,
        icon: '/assets/icons/order-icon.png',
        badge: '/assets/icons/badge-icon.png',
        tag: 'order-notification',
        requireInteraction: false
      });
      
      notification.onclick = () => {
        window.focus();
        notification.close();
      };
      
      setTimeout(() => notification.close(), 5000);
    } else if ('Notification' in window && Notification.permission === 'default') {
      // Request permission if not already granted
      Notification.requestPermission();
    }
  }
}