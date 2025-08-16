import { Component, OnInit } from '@angular/core';
import { NotificationService, Notification } from '../../../../core/services/notification.service';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-notifications',
  templateUrl: './notifications.component.html',
  styleUrls: ['./notifications.component.scss']
})
export class NotificationsComponent implements OnInit {
  loading = false;
  selectedTab = 0;
  
  // Notifications from API
  notifications: Notification[] = [];

  constructor(
    private notificationService: NotificationService,
    private snackBar: MatSnackBar
  ) { }

  ngOnInit(): void {
    this.loadNotifications();
  }

  loadNotifications(): void {
    this.loading = true;
    this.notificationService.getAllNotifications().subscribe({
      next: (response) => {
        this.notifications = response.content;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading notifications:', error);
        this.snackBar.open('Error loading notifications', 'Close', { duration: 3000 });
        this.loading = false;
      }
    });
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
          this.snackBar.open('Error marking notification as read', 'Close', { duration: 3000 });
        }
      });
    }
  }

  markAllAsRead(): void {
    this.notificationService.markAllAsRead().subscribe({
      next: () => {
        this.notifications.forEach(n => n.isRead = true);
        this.snackBar.open('All notifications marked as read', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error marking all notifications as read:', error);
        this.snackBar.open('Error marking all as read', 'Close', { duration: 3000 });
      }
    });
  }

  deleteNotification(notification: Notification): void {
    this.notificationService.deleteNotification(notification.id).subscribe({
      next: () => {
        const index = this.notifications.indexOf(notification);
        if (index > -1) {
          this.notifications.splice(index, 1);
        }
        this.snackBar.open('Notification deleted', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error deleting notification:', error);
        this.snackBar.open('Error deleting notification', 'Close', { duration: 3000 });
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
}