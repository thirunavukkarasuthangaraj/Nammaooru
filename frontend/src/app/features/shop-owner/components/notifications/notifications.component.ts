import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { NotificationService } from '@core/services/notification.service';
import { AuthService } from '@core/services/auth.service';
import { OrderService, OrderResponse } from '@core/services/order.service';
import { ShopOwnerOrderService } from '../../services/shop-owner-order.service';
import { finalize, switchMap, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

interface ShopNotification {
  id: number;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error' | 'order' | 'customer' | 'inventory' | 'system';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'unread' | 'read' | 'archived' | 'processing';
  createdAt: Date;
  readAt?: Date;
  actionRequired: boolean;
  actionUrl?: string;
  relatedEntity?: {
    type: 'order' | 'customer' | 'product' | 'shop';
    id: number;
    name: string;
  };
  orderData?: OrderResponse; // Add order details
}

@Component({
  selector: 'app-notifications',
  template: `
    <div class="notifications-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Notifications</h1>
          <p class="page-subtitle">Stay updated with your shop activities</p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button (click)="markAllAsRead()" [disabled]="getUnreadCount() === 0">
            <mat-icon>done_all</mat-icon>
            Mark All Read
          </button>
          <button mat-raised-button color="primary" (click)="refreshNotifications()">
            <mat-icon>refresh</mat-icon>
            Refresh
          </button>
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="summary-cards">
        <mat-card class="summary-card unread">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>notifications</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getUnreadCount() }}</h3>
                <p>Unread Notifications</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card urgent">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>priority_high</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getUrgentCount() }}</h3>
                <p>Urgent Notifications</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card actions">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>assignment</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getActionRequiredCount() }}</h3>
                <p>Action Required</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card today">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>today</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getTodayCount() }}</h3>
                <p>Today's Notifications</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Filters -->
      <mat-card class="filters-card">
        <mat-card-content>
          <div class="filters-section">
            <div class="filter-group">
              <mat-form-field appearance="outline">
                <mat-label>Filter by Type</mat-label>
                <mat-select [(value)]="selectedType" (selectionChange)="applyFilters()">
                  <mat-option value="">All Types</mat-option>
                  <mat-option value="order">Orders</mat-option>
                  <mat-option value="customer">Customers</mat-option>
                  <mat-option value="inventory">Inventory</mat-option>
                  <mat-option value="system">System</mat-option>
                  <mat-option value="info">Information</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Filter by Priority</mat-label>
                <mat-select [(value)]="selectedPriority" (selectionChange)="applyFilters()">
                  <mat-option value="">All Priorities</mat-option>
                  <mat-option value="urgent">Urgent</mat-option>
                  <mat-option value="high">High</mat-option>
                  <mat-option value="medium">Medium</mat-option>
                  <mat-option value="low">Low</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Filter by Status</mat-label>
                <mat-select [(value)]="selectedStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Status</mat-option>
                  <mat-option value="unread">Unread</mat-option>
                  <mat-option value="read">Read</mat-option>
                  <mat-option value="archived">Archived</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="action-group">
              <button mat-button [class.active]="showOnlyUnread" (click)="toggleUnreadOnly()">
                <mat-icon>visibility_off</mat-icon>
                Unread Only
              </button>
              <button mat-button [class.active]="showOnlyActionRequired" (click)="toggleActionRequiredOnly()">
                <mat-icon>assignment</mat-icon>
                Action Required
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading notifications...</p>
      </div>

      <!-- Notifications List -->
      <div class="notifications-list" *ngIf="!loading">
        <mat-card class="notification-card" 
                  *ngFor="let notification of getFilteredNotifications()" 
                  [class.unread]="notification.status === 'unread'"
                  [class.urgent]="notification.priority === 'urgent'"
                  (click)="markAsRead(notification)">
          <mat-card-content>
            <div class="notification-content">
              <div class="notification-header">
                <div class="notification-meta">
                  <div class="notification-type">
                    <mat-icon [class]="'type-' + notification.type">{{ getTypeIcon(notification.type) }}</mat-icon>
                    <span class="type-label">{{ notification.type | titlecase }}</span>
                  </div>
                  <div class="notification-priority">
                    <span class="priority-badge" [class]="'priority-' + notification.priority">
                      {{ notification.priority | titlecase }}
                    </span>
                  </div>
                </div>
                <div class="notification-actions">
                  <button mat-icon-button *ngIf="notification.status === 'unread'" 
                          (click)="markAsRead(notification); $event.stopPropagation()"
                          matTooltip="Mark as read">
                    <mat-icon>done</mat-icon>
                  </button>
                  <button mat-icon-button [matMenuTriggerFor]="actionMenu" 
                          [matMenuTriggerData]="{ notification: notification }"
                          (click)="$event.stopPropagation()">
                    <mat-icon>more_vert</mat-icon>
                  </button>
                </div>
              </div>

              <div class="notification-body">
                <h3 class="notification-title">{{ notification.title }}</h3>
                <p class="notification-message">{{ notification.message }}</p>
                
                <!-- Order Items Display -->
                <div class="order-items" *ngIf="notification.orderData && notification.orderData.orderItems && notification.orderData.orderItems.length > 0">
                  <h4 class="items-title">Order Items:</h4>
                  <div class="items-list">
                    <div class="order-item" *ngFor="let item of notification.orderData.orderItems">
                      <div class="item-image" *ngIf="item.productImageUrl">
                        <img [src]="item.productImageUrl" [alt]="item.productName" />
                      </div>
                      <div class="item-details">
                        <div class="item-name">{{ item.productName }}</div>
                        <div class="item-quantity">Qty: {{ item.quantity }}</div>
                        <div class="item-price">₹{{ item.totalPrice }}</div>
                      </div>
                    </div>
                  </div>
                  <div class="order-total">
                    <strong>Total: ₹{{ notification.orderData.totalAmount }}</strong>
                  </div>
                </div>
                
                <div class="notification-footer">
                  <div class="notification-time">
                    <mat-icon>schedule</mat-icon>
                    <span>{{ notification.createdAt | date:'medium' }}</span>
                  </div>
                  
                  <div class="notification-related" *ngIf="notification.relatedEntity">
                    <mat-icon>link</mat-icon>
                    <span>{{ notification.relatedEntity.type | titlecase }}: {{ notification.relatedEntity.name }}</span>
                  </div>
                </div>

                <div class="notification-action" *ngIf="notification.actionRequired">
                  <button mat-raised-button color="primary" 
                          (click)="handleAction(notification); $event.stopPropagation()"
                          [disabled]="notification.status === 'processing'">
                    <mat-icon *ngIf="notification.status !== 'processing'">check</mat-icon>
                    <mat-spinner *ngIf="notification.status === 'processing'" diameter="20"></mat-spinner>
                    {{ notification.status === 'processing' ? 'Processing...' : 'Accept Order' }}
                  </button>
                  <button mat-stroked-button color="warn" 
                          (click)="rejectOrder(notification); $event.stopPropagation()"
                          [disabled]="notification.status === 'processing'"
                          style="margin-left: 8px;">
                    <mat-icon>close</mat-icon>
                    Reject
                  </button>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Empty State -->
        <div *ngIf="getFilteredNotifications().length === 0" class="empty-state">
          <mat-icon>notifications_none</mat-icon>
          <h3>No notifications found</h3>
          <p>{{ getEmptyStateMessage() }}</p>
        </div>
      </div>

      <!-- Load More Button -->
      <div class="load-more-section" *ngIf="hasMoreNotifications && !loading">
        <button mat-stroked-button (click)="loadMoreNotifications()">
          <mat-icon>expand_more</mat-icon>
          Load More Notifications
        </button>
      </div>
    </div>

    <!-- Action Menu -->
    <mat-menu #actionMenu="matMenu">
      <ng-template matMenuContent let-notification="notification">
        <button mat-menu-item (click)="markAsRead(notification)" 
                *ngIf="notification.status === 'unread'">
          <mat-icon>done</mat-icon>
          <span>Mark as Read</span>
        </button>
        <button mat-menu-item (click)="markAsUnread(notification)" 
                *ngIf="notification.status === 'read'">
          <mat-icon>markunread</mat-icon>
          <span>Mark as Unread</span>
        </button>
        <button mat-menu-item (click)="archiveNotification(notification)">
          <mat-icon>archive</mat-icon>
          <span>Archive</span>
        </button>
        <button mat-menu-item (click)="deleteNotification(notification)" class="warn-menu-item">
          <mat-icon>delete</mat-icon>
          <span>Delete</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .notifications-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .summary-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .summary-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      overflow: hidden;
    }

    .summary-card.unread { border-left: 4px solid #3b82f6; }
    .summary-card.urgent { border-left: 4px solid #ef4444; }
    .summary-card.actions { border-left: 4px solid #f59e0b; }
    .summary-card.today { border-left: 4px solid #10b981; }

    .card-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .card-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .summary-card.unread .card-icon { background: #3b82f6; }
    .summary-card.urgent .card-icon { background: #ef4444; }
    .summary-card.actions .card-icon { background: #f59e0b; }
    .summary-card.today .card-icon { background: #10b981; }

    .card-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0;
      color: #1f2937;
    }

    .card-details p {
      font-size: 0.9rem;
      color: #6b7280;
      margin: 0;
    }

    .filters-card {
      margin-bottom: 16px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .filters-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .filter-group {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .action-group {
      display: flex;
      gap: 8px;
    }

    .action-group button.active {
      background: #dbeafe;
      color: #1d4ed8;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 200px;
    }

    .notifications-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .notification-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      cursor: pointer;
      transition: all 0.2s ease;
      border-left: 4px solid transparent;
    }

    .notification-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .notification-card.unread {
      background: #f8fafc;
      border-left-color: #3b82f6;
    }

    .notification-card.urgent {
      border-left-color: #ef4444;
      background: #fef2f2;
    }

    .notification-content {
      padding: 4px;
    }

    .notification-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .notification-meta {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .notification-type {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .type-label {
      font-size: 0.8rem;
      font-weight: 500;
      text-transform: uppercase;
      color: #6b7280;
    }

    .priority-badge {
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 0.7rem;
      font-weight: 600;
      text-transform: uppercase;
    }

    .priority-badge.priority-urgent {
      background: #fee2e2;
      color: #dc2626;
    }

    .priority-badge.priority-high {
      background: #fef3c7;
      color: #d97706;
    }

    .priority-badge.priority-medium {
      background: #dbeafe;
      color: #2563eb;
    }

    .priority-badge.priority-low {
      background: #f3f4f6;
      color: #6b7280;
    }

    .notification-actions {
      display: flex;
      gap: 4px;
    }

    .notification-title {
      font-size: 1.1rem;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #1f2937;
    }

    .notification-message {
      font-size: 0.9rem;
      color: #4b5563;
      margin: 0 0 12px 0;
      line-height: 1.5;
    }

    .notification-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .notification-time, .notification-related {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .notification-time mat-icon, .notification-related mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .notification-action {
      margin-top: 12px;
    }

    .type-order { color: #10b981; }
    .type-customer { color: #3b82f6; }
    .type-inventory { color: #f59e0b; }
    .type-system { color: #6b7280; }
    .type-info { color: #06b6d4; }
    .type-success { color: #10b981; }
    .type-warning { color: #f59e0b; }
    .type-error { color: #ef4444; }

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 80px 20px;
      text-align: center;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #d1d5db;
      margin-bottom: 16px;
    }

    .empty-state h3 {
      font-size: 1.2rem;
      margin: 0 0 8px 0;
      color: #6b7280;
    }

    .empty-state p {
      color: #9ca3af;
      margin: 0;
    }

    .load-more-section {
      display: flex;
      justify-content: center;
      margin-top: 24px;
    }

    .warn-menu-item {
      color: #dc2626 !important;
    }

    /* Order Items Styles */
    .order-items {
      margin: 16px 0;
      padding: 16px;
      background: #f8fafc;
      border-radius: 8px;
      border: 1px solid #e2e8f0;
    }

    .items-title {
      font-size: 1rem;
      font-weight: 600;
      margin: 0 0 12px 0;
      color: #1f2937;
    }

    .items-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin-bottom: 12px;
    }

    .order-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px;
      background: white;
      border-radius: 6px;
      border: 1px solid #e5e7eb;
    }

    .item-image {
      width: 40px;
      height: 40px;
      flex-shrink: 0;
    }

    .item-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 4px;
    }

    .item-details {
      flex: 1;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .item-name {
      font-weight: 500;
      color: #1f2937;
    }

    .item-quantity {
      font-size: 0.9rem;
      color: #6b7280;
    }

    .item-price {
      font-weight: 600;
      color: #059669;
    }

    .order-total {
      text-align: right;
      padding-top: 8px;
      border-top: 1px solid #e5e7eb;
      color: #1f2937;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .notifications-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .summary-cards {
        grid-template-columns: 1fr 1fr;
      }

      .filters-section {
        flex-direction: column;
        align-items: stretch;
      }

      .filter-group {
        flex-direction: column;
        gap: 12px;
      }

      .notification-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }

      .notification-footer {
        flex-direction: column;
        align-items: flex-start;
        gap: 4px;
      }
    }
  `]
})
export class NotificationsComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  loading = false;
  hasMoreNotifications = true;
  
  selectedType = '';
  selectedPriority = '';
  selectedStatus = '';
  showOnlyUnread = false;
  showOnlyActionRequired = false;

  notifications: ShopNotification[] = [];

  constructor(
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private notificationService: NotificationService,
    private authService: AuthService,
    private orderService: OrderService,
    private shopOwnerOrderService: ShopOwnerOrderService
  ) {}

  ngOnInit(): void {
    this.loadNotifications();
  }

  loadNotifications(): void {
    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    
    if (!currentUser) {
      this.snackBar.open('User not found', 'Close', { duration: 3000 });
      this.loading = false;
      return;
    }

    // Load pending orders for the shop owner and convert to notifications
    this.loadOrderNotifications()
      .pipe(finalize(() => this.loading = false))
      .subscribe({
        next: (notifications) => {
          console.log('Loaded order notifications:', notifications);
          // Use only real order-based notifications
          this.notifications = notifications;
        },
        error: (error) => {
          console.error('Error loading order notifications:', error);
          this.snackBar.open('Failed to load notifications', 'Close', { duration: 3000 });
          // Show empty state on error
          this.notifications = [];
        }
      });
  }

  private loadOrderNotifications() {
    const currentUser = this.authService.getCurrentUser();
    if (!currentUser?.shopId) {
      console.error('No shop ID found for current user');
      return of([]);
    }
    const shopId = currentUser.shopId;
    
    return this.orderService.getOrdersByShop(String(shopId || ''), 0, 20)
      .pipe(
        switchMap(orderPage => {
          const pendingOrders = orderPage.content.filter(order => order.status === 'PENDING');
          const notifications: ShopNotification[] = pendingOrders.map(order => ({
            id: order.id,
            title: 'New Order Received',
            message: `You have received a new order ${order.orderNumber} from ${order.customerName} worth ₹${order.totalAmount}`,
            type: 'order',
            priority: 'high',
            status: 'unread',
            createdAt: new Date(order.createdAt),
            actionRequired: true,
            actionUrl: `/orders/${order.id}`,
            relatedEntity: { type: 'order', id: order.id, name: order.orderNumber },
            orderData: order
          }));
          return of(notifications);
        }),
        catchError(() => {
          // Return empty array on error
          return of([]);
        })
      );
  }

  refreshNotifications(): void {
    this.loadNotifications();
    this.snackBar.open('Notifications refreshed', 'Close', { duration: 2000 });
  }

  loadMoreNotifications(): void {
    // Simulate loading more notifications
    this.hasMoreNotifications = false;
    this.snackBar.open('No more notifications to load', 'Close', { duration: 2000 });
  }

  getFilteredNotifications(): ShopNotification[] {
    return this.notifications.filter(notification => {
      const matchesType = !this.selectedType || notification.type === this.selectedType;
      const matchesPriority = !this.selectedPriority || notification.priority === this.selectedPriority;
      const matchesStatus = !this.selectedStatus || notification.status === this.selectedStatus;
      const matchesUnread = !this.showOnlyUnread || notification.status === 'unread';
      const matchesActionRequired = !this.showOnlyActionRequired || notification.actionRequired;
      
      return matchesType && matchesPriority && matchesStatus && matchesUnread && matchesActionRequired;
    });
  }

  applyFilters(): void {
    // Filters are applied in getFilteredNotifications()
  }

  toggleUnreadOnly(): void {
    this.showOnlyUnread = !this.showOnlyUnread;
  }

  toggleActionRequiredOnly(): void {
    this.showOnlyActionRequired = !this.showOnlyActionRequired;
  }

  getUnreadCount(): number {
    return this.notifications.filter(n => n.status === 'unread').length;
  }

  getUrgentCount(): number {
    return this.notifications.filter(n => n.priority === 'urgent').length;
  }

  getActionRequiredCount(): number {
    return this.notifications.filter(n => n.actionRequired).length;
  }

  getTodayCount(): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return this.notifications.filter(n => n.createdAt >= today).length;
  }

  getTypeIcon(type: string): string {
    const iconMap: { [key: string]: string } = {
      'order': 'shopping_bag',
      'customer': 'person',
      'inventory': 'inventory',
      'system': 'settings',
      'info': 'info',
      'success': 'check_circle',
      'warning': 'warning',
      'error': 'error'
    };
    return iconMap[type] || 'notifications';
  }

  getEmptyStateMessage(): string {
    if (this.showOnlyUnread) return 'No unread notifications';
    if (this.showOnlyActionRequired) return 'No notifications requiring action';
    if (this.selectedType) return `No ${this.selectedType} notifications`;
    return 'You\'re all caught up!';
  }

  markAsRead(notification: ShopNotification): void {
    if (notification.status === 'unread') {
      notification.status = 'read';
      notification.readAt = new Date();
      this.snackBar.open('Notification marked as read', 'Close', { duration: 2000 });
    }
  }

  markAsUnread(notification: ShopNotification): void {
    notification.status = 'unread';
    notification.readAt = undefined;
    this.snackBar.open('Notification marked as unread', 'Close', { duration: 2000 });
  }

  markAllAsRead(): void {
    this.notifications.forEach(notification => {
      if (notification.status === 'unread') {
        notification.status = 'read';
        notification.readAt = new Date();
      }
    });
    this.snackBar.open('All notifications marked as read', 'Close', { duration: 3000 });
  }

  archiveNotification(notification: ShopNotification): void {
    notification.status = 'archived';
    this.snackBar.open('Notification archived', 'Close', { duration: 2000 });
  }

  deleteNotification(notification: ShopNotification): void {
    const index = this.notifications.indexOf(notification);
    if (index > -1) {
      this.notifications.splice(index, 1);
      this.snackBar.open('Notification deleted', 'Close', { duration: 2000 });
    }
  }

  handleAction(notification: ShopNotification): void {
    if (notification.type === 'order' && notification.relatedEntity) {
      // Handle order acceptance
      this.acceptOrder(notification);
    } else if (notification.actionUrl) {
      this.snackBar.open(`Navigating to ${notification.actionUrl}`, 'Close', { duration: 2000 });
      // Here you would typically navigate using Router
      // this.router.navigate([notification.actionUrl]);
    } else {
      this.snackBar.open('Action completed', 'Close', { duration: 2000 });
    }
    
    // Mark as read when action is taken
    this.markAsRead(notification);
  }

  acceptOrder(notification: ShopNotification): void {
    if (!notification.relatedEntity || notification.status === 'processing') {
      return;
    }

    const orderId = notification.relatedEntity.id;
    notification.status = 'processing';

    this.shopOwnerOrderService.acceptOrder(orderId, '30 minutes', 'Order accepted and will be prepared shortly')
      .pipe(finalize(() => {
        // Reset processing status after completion
        setTimeout(() => {
          if (notification.status === 'processing') {
            notification.status = 'read';
          }
        }, 1000);
      }))
      .subscribe({
        next: (acceptedOrder) => {
          console.log('Order accepted successfully:', acceptedOrder);
          this.snackBar.open(`Order ${notification.relatedEntity!.name} accepted successfully!`, 'Close', { duration: 5000 });
          
          // Update notification
          notification.actionRequired = false;
          notification.status = 'read';
          notification.title = 'Order Accepted';
          notification.message = `Order ${notification.relatedEntity!.name} has been accepted and is being prepared.`;
          notification.type = 'success';
          
          // Refresh notifications to get latest data
          setTimeout(() => this.loadNotifications(), 2000);
        },
        error: (error) => {
          console.error('Error accepting order:', error);
          notification.status = 'unread';
          this.snackBar.open('Failed to accept order. Please try again.', 'Close', { duration: 5000 });
        }
      });
  }

  rejectOrder(notification: ShopNotification): void {
    if (!notification.relatedEntity || notification.status === 'processing') {
      return;
    }

    const orderId = notification.relatedEntity.id;
    const reason = 'Order rejected by shop owner'; // Could open a dialog for custom reason

    notification.status = 'processing';

    this.shopOwnerOrderService.rejectOrder(orderId, reason)
      .pipe(finalize(() => {
        setTimeout(() => {
          if (notification.status === 'processing') {
            notification.status = 'read';
          }
        }, 1000);
      }))
      .subscribe({
        next: (rejectedOrder) => {
          console.log('Order rejected successfully:', rejectedOrder);
          this.snackBar.open(`Order ${notification.relatedEntity!.name} rejected.`, 'Close', { duration: 5000 });
          
          // Update notification
          notification.actionRequired = false;
          notification.status = 'read';
          notification.title = 'Order Rejected';
          notification.message = `Order ${notification.relatedEntity!.name} has been rejected.`;
          notification.type = 'warning';
          
          // Refresh notifications to get latest data
          setTimeout(() => this.loadNotifications(), 2000);
        },
        error: (error) => {
          console.error('Error rejecting order:', error);
          notification.status = 'unread';
          this.snackBar.open('Failed to reject order. Please try again.', 'Close', { duration: 5000 });
        }
      });
  }
}