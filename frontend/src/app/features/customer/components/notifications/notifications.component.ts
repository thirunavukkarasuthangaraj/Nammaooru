import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { MatSnackBar } from '@angular/material/snack-bar';

interface Notification {
  id: number;
  title: string;
  message: string;
  type: string;
  priority: string;
  isRead: boolean;
  createdAt: string;
  orderId?: number;
  orderNumber?: string;
}

@Component({
  selector: 'app-notifications',
  templateUrl: './notifications.component.html',
  styleUrls: ['./notifications.component.scss']
})
export class NotificationsComponent implements OnInit {
  notifications: Notification[] = [];
  loading = false;
  selectedFilter: string = 'all';

  filterTabs = [
    { key: 'all', label: 'All', icon: 'notifications' },
    { key: 'unread', label: 'Unread', icon: 'mark_email_unread' },
    { key: 'ORDER', label: 'Orders', icon: 'shopping_bag' },
    { key: 'MARKETING', label: 'Marketing', icon: 'local_offer' }
  ];

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  viewOrder(notification: Notification): void {
    if (notification.orderNumber) {
      // Navigate to track order page
      window.location.href = `/customer/track-order/${notification.orderNumber}`;
    }
  }

  ngOnInit(): void {
    this.loadNotifications();
  }

  onFilterChange(filter: string): void {
    this.selectedFilter = filter;
    this.loadNotifications();
  }

  loadNotifications(): void {
    this.loading = true;

    const token = localStorage.getItem('shop_management_token');
    const user = localStorage.getItem('shop_management_user');

    if (!user || !token) {
      this.loading = false;
      return;
    }

    let userId: number;
    try {
      const userData = JSON.parse(user);
      userId = userData.id;
    } catch (e) {
      console.error('Error parsing user data:', e);
      this.loading = false;
      return;
    }

    const headers: { [key: string]: string} = {
      'Authorization': `Bearer ${token}`
    };

    let apiUrl = `${environment.apiUrl}/notifications/user/${userId}`;

    if (this.selectedFilter === 'unread') {
      apiUrl = `${environment.apiUrl}/notifications/user/${userId}/unread`;
    } else if (this.selectedFilter !== 'all') {
      apiUrl = `${environment.apiUrl}/notifications/user/${userId}/type/${this.selectedFilter}`;
    }

    console.log('Loading notifications from:', apiUrl);

    this.http.get<any>(apiUrl, { headers }).subscribe({
      next: (response) => {
        console.log('Notifications response:', response);

        if (response && response.content) {
          this.notifications = response.content;
        } else if (Array.isArray(response)) {
          this.notifications = response;
        } else {
          this.notifications = [];
        }

        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading notifications:', error);
        this.notifications = [];
        this.loading = false;
        this.snackBar.open('Failed to load notifications', 'Close', { duration: 3000 });
      }
    });
  }

  markAsRead(notification: Notification): void {
    if (notification.isRead) {
      return;
    }

    const token = localStorage.getItem('shop_management_token');
    const headers: { [key: string]: string } = {
      'Authorization': `Bearer ${token}`
    };

    this.http.put(`${environment.apiUrl}/notifications/${notification.id}/read`, {}, { headers }).subscribe({
      next: () => {
        notification.isRead = true;
        this.snackBar.open('Notification marked as read', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error marking notification as read:', error);
      }
    });
  }

  markAllAsRead(): void {
    const token = localStorage.getItem('shop_management_token');
    const user = localStorage.getItem('shop_management_user');

    if (!user || !token) {
      return;
    }

    let userId: number;
    try {
      const userData = JSON.parse(user);
      userId = userData.id;
    } catch (e) {
      console.error('Error parsing user data:', e);
      return;
    }

    const headers: { [key: string]: string } = {
      'Authorization': `Bearer ${token}`
    };

    this.http.put(`${environment.apiUrl}/notifications/user/${userId}/read-all`, {}, { headers }).subscribe({
      next: () => {
        this.notifications.forEach(n => n.isRead = true);
        this.snackBar.open('All notifications marked as read', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error marking all as read:', error);
        this.snackBar.open('Failed to mark all as read', 'Close', { duration: 3000 });
      }
    });
  }

  getNotificationIcon(notification: Notification): string {
    const icons: { [key: string]: string } = {
      'ORDER': 'shopping_bag',
      'ORDER_STATUS_UPDATE': 'local_shipping',
      'PAYMENT': 'payment',
      'MARKETING': 'local_offer',
      'SYSTEM': 'info',
      'PROMOTION': 'card_giftcard'
    };
    return icons[notification.type] || 'notifications';
  }

  getNotificationColor(notification: Notification): string {
    const colors: { [key: string]: string } = {
      'HIGH': '#f44336',
      'MEDIUM': '#ff9800',
      'LOW': '#2196f3',
      'NORMAL': '#757575'
    };
    return colors[notification.priority] || '#757575';
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    const diffHours = Math.floor(diffTime / (1000 * 60 * 60));
    const diffMinutes = Math.floor(diffTime / (1000 * 60));

    if (diffMinutes < 1) {
      return 'Just now';
    } else if (diffMinutes < 60) {
      return `${diffMinutes} minute${diffMinutes > 1 ? 's' : ''} ago`;
    } else if (diffHours < 24) {
      return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return `${diffDays} days ago`;
    } else {
      return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
    }
  }

  getSelectedTabIndex(): number {
    return this.filterTabs.findIndex(tab => tab.key === this.selectedFilter);
  }
}
