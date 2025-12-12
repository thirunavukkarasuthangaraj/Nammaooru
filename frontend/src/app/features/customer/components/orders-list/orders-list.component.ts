import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '../../../../../environments/environment';
import Swal from 'sweetalert2';

interface OrderItem {
  id: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  productImageUrl?: string;
}

interface Order {
  id: number;
  orderNumber: string;
  shopName: string;
  totalAmount: number;
  status: string;
  createdAt: string;
  paymentMethod: string;
  orderItems?: OrderItem[];
  items?: any[];  // For backward compatibility
}

@Component({
  selector: 'app-orders-list',
  templateUrl: './orders-list.component.html',
  styleUrls: ['./orders-list.component.scss']
})
export class OrdersListComponent implements OnInit {
  orders: Order[] = [];
  loading = false;
  selectedStatus: string | null = null;
  expandedOrderId: number | null = null;

  statusTabs = [
    { key: null, label: 'All' },
    { key: 'PENDING', label: 'Pending' },
    { key: 'CONFIRMED', label: 'Confirmed' },
    { key: 'PREPARING', label: 'Preparing' },
    { key: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
    { key: 'DELIVERED', label: 'Delivered' },
    { key: 'CANCELLED', label: 'Cancelled' }
  ];

  constructor(
    private router: Router,
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  onTabChange(status: string | null): void {
    this.selectedStatus = status;
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading = true;

    // Use the correct API endpoint - backend gets customerId from authentication
    const token = localStorage.getItem('shop_management_token');
    const headers: { [key: string]: string } = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    // Add status filter to API call
    const statusParam = this.selectedStatus ? `?status=${this.selectedStatus}` : '';

    console.log('Fetching orders with status:', this.selectedStatus);
    console.log('API URL:', `${environment.apiUrl}/customer/orders${statusParam}`);
    console.log('Headers:', headers);

    this.http.get<any>(`${environment.apiUrl}/customer/orders${statusParam}`, { headers })
      .subscribe({
        next: (response) => {
          console.log('Orders API response:', response);
          console.log('Response type:', typeof response);
          console.log('Response keys:', Object.keys(response || {}));

          // Backend returns statusCode "0000" for success, not a success boolean
          if (response && response.statusCode === "0000" && response.data) {
            console.log('Response data:', response.data);
            console.log('Response data.content:', response.data.content);

            // response.data is a Page object with content array
            const rawOrders = response.data.content || [];
            console.log('Raw orders count:', rawOrders.length);

            // Map orderItems to items for template compatibility
            this.orders = rawOrders.map((order: any) => ({
              ...order,
              items: order.orderItems || order.items || []
            }));
            console.log('Processed orders:', this.orders);
          } else if (Array.isArray(response)) {
            // Handle case where response is directly an array
            console.log('Response is an array, processing directly');
            this.orders = response.map((order: any) => ({
              ...order,
              items: order.orderItems || order.items || []
            }));
          } else {
            console.log('No orders found in response or error occurred');
            console.log('StatusCode:', response?.statusCode);
            this.orders = [];
          }
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading orders:', error);
          console.error('Error status:', error.status);
          console.error('Error message:', error.message);
          this.orders = [];
          this.loading = false;
          this.snackBar.open('Failed to load orders', 'Close', { duration: 3000 });
        }
      });
  }

  trackOrder(order: Order): void {
    this.router.navigate(['/customer/track-order', order.orderNumber]);
  }

  continueShopping(): void {
    this.router.navigate(['/customer/shops']);
  }

  getStatusColor(status: string): string {
    const statusColors: { [key: string]: string } = {
      'PENDING': '#FF9800',      // Orange
      'CONFIRMED': '#2196F3',    // Blue
      'PREPARING': '#9C27B0',    // Purple
      'READY_FOR_PICKUP': '#2196F3',
      'OUT_FOR_DELIVERY': '#2196F3',
      'DELIVERED': '#4CAF50',    // Green
      'CANCELLED': '#F44336',    // Red
      'REFUNDED': '#F44336'
    };
    return statusColors[status] || '#9E9E9E';
  }

  getStatusIcon(status: string): string {
    const statusIcons: { [key: string]: string } = {
      'PENDING': 'schedule',
      'CONFIRMED': 'check_circle',
      'PREPARING': 'restaurant',
      'READY_FOR_PICKUP': 'inventory',
      'OUT_FOR_DELIVERY': 'local_shipping',
      'DELIVERED': 'done_all',
      'CANCELLED': 'cancel',
      'REFUNDED': 'money_off'
    };
    return statusIcons[status] || 'info';
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return `Today, ${this.formatTime(date)}`;
    } else if (diffDays === 1) {
      return `Yesterday, ${this.formatTime(date)}`;
    } else if (diffDays < 7) {
      return `${diffDays} days ago`;
    } else {
      return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
    }
  }

  formatTime(date: Date): string {
    let hour = date.getHours();
    const minute = date.getMinutes();
    const period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour === 0 ? 12 : hour;
    return `${hour}:${minute.toString().padStart(2, '0')} ${period}`;
  }

  getItemsPreview(order: Order): string {
    if (!order.items || order.items.length === 0) {
      return '';
    }
    const items = order.items.slice(0, 2);
    const names = items.map(item => item.productName).join(', ');
    return order.items.length > 2 ? names + '...' : names;
  }

  getSelectedTabIndex(): number {
    return this.statusTabs.findIndex(tab => tab.key === this.selectedStatus);
  }

  formatPaymentMethod(paymentMethod: string): string {
    if (!paymentMethod) return '';
    return paymentMethod.replace(/_/g, ' ');
  }

  canCancelOrder(order: Order): boolean {
    // Orders can only be cancelled if they are PENDING or CONFIRMED
    return ['PENDING', 'CONFIRMED'].includes(order.status);
  }

  cancelOrder(order: Order): void {
    Swal.fire({
      title: 'Cancel Order?',
      html: `
        <p>Are you sure you want to cancel this order?</p>
        <p><strong>Order #${order.orderNumber}</strong></p>
        <p>Total: ₹${order.totalAmount}</p>
        <hr>
        <p>Please select a reason for cancellation:</p>
      `,
      input: 'select',
      inputOptions: {
        'Changed my mind': 'Changed my mind',
        'Ordered by mistake': 'Ordered by mistake',
        'Found better price elsewhere': 'Found better price elsewhere',
        'Delivery taking too long': 'Delivery taking too long',
        'Need to modify order': 'Need to modify order',
        'Other': 'Other reason'
      },
      inputPlaceholder: 'Select reason',
      showCancelButton: true,
      confirmButtonText: 'Yes, Cancel Order',
      cancelButtonText: 'Keep Order',
      confirmButtonColor: '#f44336',
      cancelButtonColor: '#6c757d',
      inputValidator: (value) => {
        return !value && 'You need to select a reason for cancellation!'
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.performOrderCancellation(order, result.value);
      }
    });
  }

  private performOrderCancellation(order: Order, reason: string): void {
    const token = localStorage.getItem('shop_management_token');
    const headers: { [key: string]: string } = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    this.http.post(`${environment.apiUrl}/customer/orders/${order.id}/cancel`,
      { reason: reason },
      { headers }
    ).subscribe({
      next: (response) => {
        // Update the order status locally
        order.status = 'CANCELLED';
        
        // Show success message
        this.snackBar.open('Order cancelled successfully', 'Close', {
          duration: 5000,
          panelClass: ['success-snackbar']
        });

        // Show confirmation dialog
        Swal.fire({
          title: 'Order Cancelled!',
          html: `
            <p>Your order has been cancelled successfully.</p>
            <p><strong>Order #${order.orderNumber}</strong></p>
            <p>If you paid online, the refund will be processed within 3-5 business days.</p>
          `,
          icon: 'success',
          confirmButtonText: 'OK'
        });
      },
      error: (error) => {
        console.error('Error cancelling order:', error);
        
        let errorMessage = 'Failed to cancel order. Please try again.';
        if (error.error?.message) {
          errorMessage = error.error.message;
        }
        
        this.snackBar.open(errorMessage, 'Close', {
          duration: 5000,
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  reorderItems(order: Order): void {
    // Navigate to shop with pre-selected items
    this.router.navigate(['/customer/shops'], {
      queryParams: { reorder: order.id }
    });
  }

  viewOrderDetails(order: Order): void {
    // Toggle expansion of order details
    if (this.expandedOrderId === order.id) {
      this.expandedOrderId = null;
    } else {
      this.expandedOrderId = order.id;
    }
  }

  isOrderExpanded(order: Order): boolean {
    return this.expandedOrderId === order.id;
  }

  onImageError(event: Event): void {
    const target = event.target as HTMLImageElement;
    target.src = '/assets/images/product-placeholder.jpg';
  }
}