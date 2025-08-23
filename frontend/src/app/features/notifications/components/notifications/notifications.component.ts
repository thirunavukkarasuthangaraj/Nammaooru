import { Component, OnInit, OnDestroy } from '@angular/core';
import { NotificationService, Notification } from '../../../../core/services/notification.service';
import { MatSnackBar } from '@angular/material/snack-bar';
import Swal from 'sweetalert2';
import { interval, Subscription } from 'rxjs';

@Component({
  selector: 'app-notifications',
  templateUrl: './notifications.component.html',
  styleUrls: ['./notifications.component.scss']
})
export class NotificationsComponent implements OnInit, OnDestroy {
  loading = false;
  selectedTab = 0;
  autoRefreshEnabled = true;
  refreshInterval = 30000; // 30 seconds
  
  // Notifications from API
  notifications: Notification[] = [];
  
  // Subscriptions
  private refreshSubscription?: Subscription;

  constructor(
    private notificationService: NotificationService,
    private snackBar: MatSnackBar
  ) { }

  ngOnInit(): void {
    this.loadNotifications();
    this.startAutoRefresh();
  }

  ngOnDestroy(): void {
    this.stopAutoRefresh();
  }

  loadNotifications(): void {
    this.loading = true;
    
    // Mock notifications with accept/reject functionality
    this.notifications = [
      {
        id: 1,
        title: 'New Shop Registration',
        message: 'Fresh Foods Market has applied to join your platform. Please review and approve their application.',
        type: 'SHOP',
        priority: 'HIGH',
        isRead: false,
        createdAt: new Date('2025-01-22T10:30:00'),
        action: 'PENDING_APPROVAL',
        actionData: { shopId: 123, shopName: 'Fresh Foods Market' }
      },
      {
        id: 2,
        title: 'Delivery Partner Application',
        message: 'John Smith has applied to become a delivery partner. Background check completed.',
        type: 'USER',
        priority: 'MEDIUM',
        isRead: false,
        createdAt: new Date('2025-01-22T09:15:00'),
        action: 'PENDING_APPROVAL',
        actionData: { partnerId: 456, partnerName: 'John Smith' }
      },
      {
        id: 3,
        title: 'Product Approval Request',
        message: 'Organic Apples product needs approval for sale on your platform.',
        type: 'INVENTORY',
        priority: 'MEDIUM',
        isRead: false,
        createdAt: new Date('2025-01-22T08:45:00'),
        action: 'PENDING_APPROVAL',
        actionData: { productId: 789, productName: 'Organic Apples' }
      },
      {
        id: 4,
        title: 'Order Cancellation Request',
        message: 'Customer Sarah Wilson has requested to cancel order #ORD-2025-002 (₹1,200)',
        type: 'ORDER',
        priority: 'HIGH',
        isRead: false,
        createdAt: new Date('2025-01-22T07:20:00'),
        action: 'PENDING_APPROVAL',
        actionData: { orderId: 'ORD-2025-002', customerName: 'Sarah Wilson', amount: 1200 }
      },
      {
        id: 5,
        title: 'Refund Request',
        message: 'Mike Johnson has requested a refund for damaged goods (₹675)',
        type: 'PAYMENT',
        priority: 'HIGH',
        isRead: true,
        createdAt: new Date('2025-01-21T16:10:00'),
        action: 'APPROVED',
        actionData: { refundId: 101, customerName: 'Mike Johnson', amount: 675 }
      },
      {
        id: 6,
        title: 'Low Stock Alert',
        message: 'Fresh Bread inventory is running low (3 items remaining)',
        type: 'INVENTORY',
        priority: 'LOW',
        isRead: true,
        createdAt: new Date('2025-01-21T14:30:00'),
        action: undefined,
        actionData: undefined
      }
    ];
    
    this.loading = false;
  }

  get unreadNotifications(): Notification[] {
    return this.notifications.filter(n => !n.isRead);
  }

  get readNotifications(): Notification[] {
    return this.notifications.filter(n => n.isRead);
  }

  get allNotifications(): Notification[] {
    return this.notifications.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getCurrentNotifications(): Notification[] {
    switch (this.selectedTab) {
      case 0: return this.allNotifications;
      case 1: return this.unreadNotifications;
      case 2: return this.readNotifications;
      default: return this.allNotifications;
    }
  }

  markAsRead(notification: Notification): void {
    if (!notification.isRead) {
      this.notificationService.markAsRead(notification.id).subscribe({
        next: () => {
          notification.isRead = true;
        },
        error: (error) => {
          console.error('Error marking notification as read:', error);
          Swal.fire({
            title: 'Error!',
            text: 'Failed to mark notification as read.',
            icon: 'error',
            confirmButtonText: 'OK'
          });
        }
      });
    }
  }

  markAllAsRead(): void {
    Swal.fire({
      title: 'Mark All as Read',
      text: 'Are you sure you want to mark all notifications as read?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, mark all',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.notificationService.markAllAsRead().subscribe({
          next: () => {
            this.notifications.forEach(n => n.isRead = true);
            Swal.fire({
              title: 'Success!',
              text: 'All notifications marked as read.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          },
          error: (error) => {
            console.error('Error marking all notifications as read:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to mark all notifications as read.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  deleteNotification(notification: Notification): void {
    Swal.fire({
      title: 'Delete Notification',
      text: 'Are you sure you want to delete this notification? This action cannot be undone.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.notificationService.deleteNotification(notification.id).subscribe({
          next: () => {
            const index = this.notifications.indexOf(notification);
            if (index > -1) {
              this.notifications.splice(index, 1);
            }
            Swal.fire({
              title: 'Deleted!',
              text: 'Notification has been deleted.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          },
          error: (error) => {
            console.error('Error deleting notification:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to delete notification. Please try again.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  getNotificationIcon(type: string): string {
    switch (type) {
      case 'ORDER': return 'shopping_cart';
      case 'INVENTORY': return 'inventory';
      case 'SHOP': return 'store';
      case 'SYSTEM': return 'settings';
      case 'PAYMENT': return 'payment';
      case 'USER': return 'person';
      default: return 'notifications';
    }
  }

  getNotificationColor(type: string): string {
    switch (type) {
      case 'ORDER': return '#4caf50';
      case 'INVENTORY': return '#ff9800';
      case 'SHOP': return '#2196f3';
      case 'SYSTEM': return '#9c27b0';
      case 'PAYMENT': return '#4caf50';
      case 'USER': return '#607d8b';
      default: return '#666';
    }
  }

  getPriorityColor(priority: string): string {
    switch (priority) {
      case 'HIGH': return 'warn';
      case 'MEDIUM': return 'accent';
      case 'LOW': return 'primary';
      default: return '';
    }
  }

  formatTime(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  }

  onTabChange(event: any): void {
    this.selectedTab = event.index;
  }

  clearAllNotifications(): void {
    Swal.fire({
      title: 'Clear All Notifications',
      text: 'Are you sure you want to clear all notifications? This action cannot be undone.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, clear all',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.notificationService.clearAllNotifications().subscribe({
          next: () => {
            this.notifications = [];
            Swal.fire({
              title: 'Cleared!',
              text: 'All notifications have been cleared.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          },
          error: (error) => {
            console.error('Error clearing notifications:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to clear notifications. Please try again.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  sendTestNotification(): void {
    Swal.fire({
      title: 'Send Test Notification',
      html: `
        <div style="text-align: left;">
          <label for="test-title" style="display: block; margin-bottom: 5px;">Title:</label>
          <input id="test-title" class="swal2-input" placeholder="Test Notification" value="Test Notification">
          
          <label for="test-message" style="display: block; margin-bottom: 5px; margin-top: 15px;">Message:</label>
          <textarea id="test-message" class="swal2-textarea" placeholder="This is a test notification">This is a test notification to verify the notification system.</textarea>
          
          <label for="test-type" style="display: block; margin-bottom: 5px; margin-top: 15px;">Type:</label>
          <select id="test-type" class="swal2-select">
            <option value="SYSTEM">System</option>
            <option value="ORDER">Order</option>
            <option value="INVENTORY">Inventory</option>
            <option value="SHOP">Shop</option>
            <option value="PAYMENT">Payment</option>
            <option value="USER">User</option>
          </select>
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Send Test',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const title = (document.getElementById('test-title') as HTMLInputElement).value;
        const message = (document.getElementById('test-message') as HTMLTextAreaElement).value;
        const type = (document.getElementById('test-type') as HTMLSelectElement).value;
        
        if (!title || !message) {
          Swal.showValidationMessage('Please fill in all fields');
          return false;
        }
        
        return { title, message, type };
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.notificationService.sendTestNotification(result.value).subscribe({
          next: () => {
            Swal.fire({
              title: 'Success!',
              text: 'Test notification sent successfully.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
            this.loadNotifications();
          },
          error: (error) => {
            console.error('Error sending test notification:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to send test notification.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  exportNotifications(): void {
    Swal.fire({
      title: 'Export Notifications',
      text: 'Choose export format:',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Export CSV',
      cancelButtonText: 'Cancel',
      showDenyButton: true,
      denyButtonText: 'Export Excel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.performExport('csv');
      } else if (result.isDenied) {
        this.performExport('xlsx');
      }
    });
  }

  performExport(format: string): void {
    this.notificationService.exportNotifications(format).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `notifications-${new Date().toISOString().split('T')[0]}.${format}`;
        link.click();
        window.URL.revokeObjectURL(url);
        Swal.fire({
          title: 'Success!',
          text: 'Notifications exported successfully.',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      },
      error: (error) => {
        console.error('Error exporting notifications:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to export notifications. Please try again.',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  startAutoRefresh(): void {
    if (this.autoRefreshEnabled && !this.refreshSubscription) {
      this.refreshSubscription = interval(this.refreshInterval).subscribe(() => {
        this.loadNotificationsQuietly();
      });
    }
  }

  stopAutoRefresh(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
      this.refreshSubscription = undefined;
    }
  }

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    
    if (this.autoRefreshEnabled) {
      this.startAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Enabled',
        text: `Notifications will refresh every ${this.refreshInterval / 1000} seconds.`,
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    } else {
      this.stopAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Disabled',
        text: 'Notifications will no longer refresh automatically.',
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    }
  }

  loadNotificationsQuietly(): void {
    // Load notifications without showing loading indicator for background refresh
    this.notificationService.getAllNotifications().subscribe({
      next: (response) => {
        const newNotifications = response.content;
        const newCount = newNotifications.filter(n => !n.isRead).length;
        const oldCount = this.notifications.filter(n => !n.isRead).length;
        
        this.notifications = newNotifications;
        
        // Show toast if new notifications arrived
        if (newCount > oldCount) {
          const newItems = newCount - oldCount;
          Swal.fire({
            title: 'New Notifications',
            text: `${newItems} new notification${newItems > 1 ? 's' : ''} received.`,
            icon: 'info',
            timer: 3000,
            showConfirmButton: false,
            position: 'top-end',
            toast: true
          });
        }
      },
      error: (error) => {
        console.error('Error loading notifications quietly:', error);
        // Don't show error message for background refresh failures
      }
    });
  }

  // Accept/Reject functionality
  acceptNotification(notification: any): void {
    Swal.fire({
      title: 'Accept Request',
      text: `Are you sure you want to accept this ${notification.type.toLowerCase()} request?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, Accept',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#4caf50'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update notification status
        notification.action = 'APPROVED';
        notification.isRead = true;
        
        Swal.fire({
          title: 'Accepted!',
          text: `${notification.actionData?.shopName || notification.actionData?.partnerName || notification.actionData?.productName || 'Request'} has been approved.`,
          icon: 'success',
          timer: 3000,
          showConfirmButton: false
        });
      }
    });
  }

  rejectNotification(notification: any): void {
    Swal.fire({
      title: 'Reject Request',
      html: `
        <p>Are you sure you want to reject this ${notification.type.toLowerCase()} request?</p>
        <textarea id="reject-reason" class="swal2-textarea" placeholder="Please provide a reason for rejection (optional)"></textarea>
      `,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, Reject',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#f44336',
      preConfirm: () => {
        const reason = (document.getElementById('reject-reason') as HTMLTextAreaElement).value;
        return reason;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        // Update notification status
        notification.action = 'REJECTED';
        notification.isRead = true;
        notification.rejectionReason = result.value;
        
        Swal.fire({
          title: 'Rejected!',
          text: `${notification.actionData?.shopName || notification.actionData?.partnerName || notification.actionData?.productName || 'Request'} has been rejected.`,
          icon: 'success',
          timer: 3000,
          showConfirmButton: false
        });
      }
    });
  }

  changeRefreshInterval(): void {
    Swal.fire({
      title: 'Change Refresh Interval',
      html: `
        <label for="refresh-interval" style="display: block; margin-bottom: 10px;">Refresh every (seconds):</label>
        <input id="refresh-interval" class="swal2-input" type="number" min="10" max="300" value="${this.refreshInterval / 1000}" style="width: 200px;">
        <div style="margin-top: 10px; font-size: 0.9em; color: #666;">
          Range: 10-300 seconds
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Update',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const seconds = parseInt((document.getElementById('refresh-interval') as HTMLInputElement).value);
        
        if (isNaN(seconds) || seconds < 10 || seconds > 300) {
          Swal.showValidationMessage('Please enter a value between 10 and 300 seconds');
          return false;
        }
        
        return seconds;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.refreshInterval = result.value * 1000;
        
        // Restart auto-refresh with new interval
        if (this.autoRefreshEnabled) {
          this.stopAutoRefresh();
          this.startAutoRefresh();
        }
        
        Swal.fire({
          title: 'Success!',
          text: `Refresh interval updated to ${result.value} seconds.`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      }
    });
  }
}