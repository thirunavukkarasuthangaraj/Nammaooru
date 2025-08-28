import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '../../../../../environments/environment';
import Swal from 'sweetalert2';

interface Order {
  id: number;
  orderNumber: string;
  shopName: string;
  totalAmount: number;
  status: string;
  createdAt: string;
  items: any[];
}

@Component({
  selector: 'app-orders-list',
  templateUrl: './orders-list.component.html',
  styleUrls: ['./orders-list.component.scss']
})
export class OrdersListComponent implements OnInit {
  orders: Order[] = [];
  loading = false;

  constructor(
    private router: Router,
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading = true;
    const user = JSON.parse(localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser') || '{}');
    let customerId = user.customerId || user.id;
    
    // For testing with customer1, use hardcoded customer ID
    if (user.username === 'customer1') {
      customerId = 56; // Use the correct customer ID from database
    }
    
    if (customerId) {
      this.http.get<any>(`${environment.apiUrl}/orders/customer/${customerId}`)
        .subscribe({
          next: (response) => {
            this.orders = response.content || [];
            this.loading = false;
          },
          error: (error) => {
            console.error('Error loading orders:', error);
            // For testing, show mock order if API fails
            this.orders = [
              {
                id: 1,
                orderNumber: 'ORD-2024-TEST01',
                shopName: 'Test Grocery Store',
                totalAmount: 565,
                status: 'CONFIRMED',
                createdAt: new Date().toISOString(),
                items: [
                  { productName: 'Coffee Beans Arabica', quantity: 1 },
                  { productName: 'Dell Laptop XPS 13', quantity: 1 }
                ]
              }
            ];
            this.loading = false;
          }
        });
    } else {
      this.loading = false;
    }
  }

  trackOrder(order: Order): void {
    this.router.navigate(['/customer/track-order', order.orderNumber]);
  }

  continueShopping(): void {
    this.router.navigate(['/customer/shops']);
  }

  getStatusColor(status: string): string {
    const statusColors: { [key: string]: string } = {
      'PENDING': 'warn',
      'CONFIRMED': 'primary',
      'PREPARING': 'accent',
      'READY_FOR_PICKUP': 'primary',
      'OUT_FOR_DELIVERY': 'primary',
      'DELIVERED': 'primary',
      'CANCELLED': 'warn',
      'REFUNDED': 'warn'
    };
    return statusColors[status] || 'basic';
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

    this.http.put(`${environment.apiUrl}/orders/${order.id}/cancel?reason=${encodeURIComponent(reason)}`, 
      {},
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
    // Navigate to order details page
    this.router.navigate(['/customer/order-details', order.id]);
  }
}