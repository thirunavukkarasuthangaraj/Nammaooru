import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { NotificationService } from '@core/services/notification.service';
import { AuthService } from '@core/services/auth.service';
import { OrderService, OrderResponse } from '@core/services/order.service';
import { ShopOwnerOrderService } from '../../services/shop-owner-order.service';
import { FirebaseService } from '@core/services/firebase.service';
import { finalize, switchMap, catchError, takeUntil } from 'rxjs/operators';
import { of, Subject, interval } from 'rxjs';

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
    <div class="notifications-page">
      <!-- Clean Header -->
      <div class="page-header">
        <div class="header-left">
          <h1>Notifications</h1>
          <span class="unread-badge" *ngIf="getUnreadCount() > 0">{{ getUnreadCount() }} unread</span>
        </div>
        <div class="header-actions">
          <button mat-button [class.active]="showOnlyUnread" (click)="toggleUnreadOnly()">
            <mat-icon>filter_list</mat-icon>
            Unread Only
          </button>
          <button mat-button (click)="markAllAsRead()" [disabled]="getUnreadCount() === 0">
            <mat-icon>done_all</mat-icon>
            Mark All Read
          </button>
          <button mat-icon-button (click)="refreshNotifications()">
            <mat-icon>refresh</mat-icon>
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading notifications...</p>
      </div>

      <!-- Notifications Table -->
      <div class="notifications-table" *ngIf="!loading">
        <div class="notification-row"
             *ngFor="let notification of getFilteredNotifications()"
             [class.unread]="notification.status === 'unread'"
             [class.urgent]="notification.priority === 'urgent'"
             (click)="markAsRead(notification)">

          <div class="notification-icon">
            <mat-icon [class]="'type-' + notification.type">{{ getTypeIcon(notification.type) }}</mat-icon>
          </div>

          <div class="notification-content">
            <div class="notification-title">{{ notification.title }}</div>
            <div class="notification-message">{{ notification.message }}</div>
          </div>

          <div class="notification-amount" *ngIf="notification.orderData">
            <strong>₹{{ notification.orderData.totalAmount }}</strong>
            <small>({{ notification.orderData.orderItems.length || 0 }} items)</small>
          </div>

          <div class="notification-status-column">
            <div class="notification-time">
              {{ notification.createdAt | date:'short':'Asia/Kolkata' }}
            </div>
            <div class="order-status" *ngIf="notification.orderData">
              <span class="status-badge" [class]="'status-' + getOrderStatus(notification)">
                {{ getOrderStatus(notification) }}
              </span>
            </div>
          </div>

          <div class="notification-priority">
            <span class="priority-badge" [class]="'priority-' + notification.priority">
              {{ notification.priority }}
            </span>
          </div>

          <div class="notification-actions" *ngIf="notification.actionRequired">
            <button mat-raised-button color="primary" size="small"
                    (click)="handleAction(notification); $event.stopPropagation()"
                    [disabled]="notification.status === 'processing'">
              {{ notification.status === 'processing' ? 'Processing...' : 'Accept' }}
            </button>
            <button mat-stroked-button color="warn" size="small"
                    (click)="rejectOrder(notification); $event.stopPropagation()"
                    [disabled]="notification.status === 'processing'">
              Reject
            </button>
          </div>
        </div>

        <!-- Empty State -->
        <div *ngIf="getFilteredNotifications().length === 0" class="empty-state">
          <mat-icon>notifications_none</mat-icon>
          <h3>No notifications found</h3>
          <p>{{ getEmptyStateMessage() }}</p>
        </div>
      </div>

      <!-- Load More Button -->
      <div class="load-more" *ngIf="hasMoreNotifications && !loading">
        <button mat-button (click)="loadMoreNotifications()">
          Load More
        </button>
      </div>
    </div>
  `,
  styles: [`
    .notifications-page {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
      background: #f8f9fa;
      min-height: 100vh;
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      background: white;
      padding: 20px 24px;
      border-radius: 12px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .header-left {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .page-header h1 {
      margin: 0;
      font-size: 1.5rem;
      font-weight: 600;
      color: #1a1a1a;
    }

    .unread-badge {
      background: #e3f2fd;
      color: #1976d2;
      padding: 4px 12px;
      border-radius: 16px;
      font-size: 0.8rem;
      font-weight: 500;
    }

    .header-actions {
      display: flex;
      gap: 8px;
      align-items: center;
    }

    .header-actions .active {
      background: #1976d2;
      color: white;
    }

    .notifications-table {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .notification-row {
      display: grid;
      grid-template-columns: 50px 3fr 140px 110px 80px 200px;
      gap: 16px;
      align-items: center;
      padding: 16px 20px;
      border-bottom: 1px solid #f0f2f4;
      cursor: pointer;
      transition: all 0.15s ease;
    }

    .notification-row:last-child {
      border-bottom: none;
    }

    .notification-row:hover {
      background: #f8f9fb;
      transform: translateY(-1px);
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .notification-row.unread {
      background: linear-gradient(90deg, #f0f7ff 0%, #ffffff 6px);
      border-left: 3px solid #2196f3;
    }

    .notification-row.urgent {
      border-left: 3px solid #ff5722;
    }

    .notification-icon {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      background: linear-gradient(135deg, #e3f2fd, #bbdefb);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .notification-icon mat-icon {
      font-size: 18px;
      color: #1976d2;
    }

    .notification-content {
      min-width: 0;
    }

    .notification-title {
      font-weight: 500;
      font-size: 0.95rem;
      color: #1a1a1a;
      margin-bottom: 2px;
      line-height: 1.3;
    }

    .notification-message {
      color: #6b7280;
      font-size: 0.85rem;
      line-height: 1.3;
      opacity: 0.9;
    }

    .notification-amount {
      text-align: right;
      font-weight: 600;
      color: #059669;
      font-size: 0.9rem;
    }

    .notification-amount small {
      display: block;
      color: #9ca3af;
      font-weight: 400;
      font-size: 0.75rem;
      margin-top: 2px;
    }

    .notification-status-column {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .notification-time {
      color: #9ca3af;
      font-size: 0.75rem;
      white-space: nowrap;
    }

    .order-status {
      margin-top: 2px;
    }

    .status-badge {
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 0.65rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }

    .status-badge.status-PENDING {
      background: #fff3cd;
      color: #856404;
    }

    .status-badge.status-CONFIRMED {
      background: #d4edda;
      color: #155724;
    }

    .status-badge.status-ACCEPTED {
      background: #d1ecf1;
      color: #0c5460;
    }

    .status-badge.status-PREPARING {
      background: #e2e3e5;
      color: #383d41;
    }

    .status-badge.status-READY {
      background: #d4edda;
      color: #155724;
    }

    .status-badge.status-UNKNOWN {
      background: #f8f9fa;
      color: #6c757d;
    }

    .notification-priority {
      text-align: center;
    }

    .priority-badge {
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 0.7rem;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .priority-badge.priority-urgent {
      background: #ffebee;
      color: #c62828;
    }

    .priority-badge.priority-high {
      background: #fff3e0;
      color: #e65100;
    }

    .priority-badge.priority-medium {
      background: #e3f2fd;
      color: #1565c0;
    }

    .priority-badge.priority-low {
      background: #f3f4f6;
      color: #6b7280;
    }

    .notification-actions {
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }

    .notification-actions button {
      padding: 6px 14px;
      font-size: 0.8rem;
      border-radius: 6px;
      font-weight: 500;
      min-width: 70px;
      height: 32px;
    }

    .notification-actions button[color="primary"] {
      background: #2196f3;
      color: white;
      border: none;
    }

    .notification-actions button[color="warn"] {
      color: #f44336;
      border: 1px solid #f44336;
      background: transparent;
    }

    .empty-state {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 3rem;
      width: 3rem;
      height: 3rem;
      margin-bottom: 10px;
      color: #ccc;
    }

    .loading-container {
      text-align: center;
      padding: 40px;
    }

    .load-more {
      text-align: center;
      margin-top: 20px;
    }

    .type-order { color: #10b981; }
    .type-customer { color: #3b82f6; }
    .type-inventory { color: #f59e0b; }
    .type-system { color: #6b7280; }
    .type-info { color: #06b6d4; }
    .type-success { color: #10b981; }
    .type-warning { color: #f59e0b; }
    .type-error { color: #ef4444; }
  `]
})
export class NotificationsComponent implements OnInit, OnDestroy {
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
  private destroy$ = new Subject<void>();

  constructor(
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private notificationService: NotificationService,
    private authService: AuthService,
    private orderService: OrderService,
    private shopOwnerOrderService: ShopOwnerOrderService,
    private firebaseService: FirebaseService
  ) {}

  ngOnInit(): void {
    this.loadNotifications();

    // Listen for Firebase notifications
    this.firebaseService.onMessageReceived()
      .pipe(takeUntil(this.destroy$))
      .subscribe(message => {
        if (message) {
          console.log('New Firebase notification received:', message);
          // Reload notifications when a new message arrives
          this.loadNotifications();

          // Show browser notification
          if (message.notification) {
            this.firebaseService.showNotification(
              message.notification.title || 'New Notification',
              message.notification.body || 'You have a new order notification'
            );
          }
        }
      });

    // Auto-refresh notifications every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.loadNotifications();
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
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
    // Get shop ID from localStorage (same way as orders component)
    const cachedShopId = localStorage.getItem('current_shop_id');
    if (!cachedShopId) {
      console.error('No shop ID found in localStorage');
      return of([]);
    }
    const shopId = parseInt(cachedShopId, 10);

    return this.orderService.getOrdersByShop(String(shopId || ''), 0, 50)
      .pipe(
        switchMap(orderPage => {
          const allOrders = orderPage.data.content;
          const notifications: ShopNotification[] = allOrders.map((order: any) => {
            let title = '';
            let message = '';
            let type: 'info' | 'success' | 'warning' | 'error' | 'order' = 'order';
            let priority: 'low' | 'medium' | 'high' | 'urgent' = 'medium';
            let actionRequired = false;

            // Set notification details based on order status
            switch(order.status) {
              case 'PENDING':
                title = '🆕 New Order Received';
                message = `New order ${order.orderNumber} from ${order.customerName} - ₹${order.totalAmount}`;
                type = 'order';
                priority = 'high';
                actionRequired = true;
                break;
              case 'ACCEPTED':
                title = '✅ Order Accepted';
                message = `Order ${order.orderNumber} has been accepted and is being prepared`;
                type = 'success';
                priority = 'medium';
                break;
              case 'PREPARING':
                title = '👨‍🍳 Order Being Prepared';
                message = `Order ${order.orderNumber} is currently being prepared`;
                type = 'info';
                priority = 'medium';
                break;
              case 'READY_FOR_PICKUP':
                title = '📦 Order Ready for Pickup';
                message = `Order ${order.orderNumber} is ready and waiting for pickup`;
                type = 'info';
                priority = 'medium';
                break;
              case 'OUT_FOR_DELIVERY':
                title = '🚚 Order Out for Delivery';
                message = `Order ${order.orderNumber} is out for delivery to ${order.customerName}`;
                type = 'info';
                priority = 'low';
                break;
              case 'DELIVERED':
                title = '✔️ Order Delivered';
                message = `Order ${order.orderNumber} has been successfully delivered - ₹${order.totalAmount}`;
                type = 'success';
                priority = 'low';
                break;
              case 'CANCELLED':
                title = '❌ Order Cancelled';
                message = `Order ${order.orderNumber} has been cancelled by ${order.cancelledBy || 'customer'}`;
                type = 'warning';
                priority = 'high';
                break;
              case 'REJECTED':
                title = '🚫 Order Rejected';
                message = `Order ${order.orderNumber} was rejected`;
                type = 'error';
                priority = 'medium';
                break;
              case 'RETURNED':
                title = '↩️ Order Returned';
                message = `Order ${order.orderNumber} has been returned by customer`;
                type = 'warning';
                priority = 'high';
                break;
              case 'REFUNDED':
                title = '💰 Order Refunded';
                message = `Order ${order.orderNumber} has been refunded - ₹${order.totalAmount}`;
                type = 'info';
                priority = 'medium';
                break;
              default:
                title = 'Order Update';
                message = `Order ${order.orderNumber} status: ${order.status}`;
                type = 'info';
                priority = 'low';
            }

            // Determine if notification is unread (orders from last 24 hours)
            const orderDate = new Date(order.createdAt);
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);
            const isRecent = orderDate > yesterday;

            return {
              id: order.id,
              title: title,
              message: message,
              type: type,
              priority: priority,
              status: (order.status === 'PENDING' || isRecent) ? 'unread' : 'read',
              createdAt: new Date(order.createdAt),
              actionRequired: actionRequired,
              actionUrl: `/orders/${order.id}`,
              relatedEntity: { type: 'order', id: order.id, name: order.orderNumber },
              orderData: order
            };
          });

          // Sort notifications by date, newest first
          notifications.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

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

  getOrderStatus(notification: ShopNotification): string {
    if (notification.orderData && notification.orderData.status) {
      return notification.orderData.status;
    }

    // Extract status from message for backward compatibility
    if (notification.message.includes('status: CONFIRMED')) {
      return 'CONFIRMED';
    } else if (notification.message.includes('status: ACCEPTED')) {
      return 'ACCEPTED';
    } else if (notification.message.includes('status: PREPARING')) {
      return 'PREPARING';
    } else if (notification.message.includes('status: READY_FOR_PICKUP')) {
      return 'READY';
    } else if (notification.message.includes('status: PENDING')) {
      return 'PENDING';
    }

    return 'UNKNOWN';
  }

}