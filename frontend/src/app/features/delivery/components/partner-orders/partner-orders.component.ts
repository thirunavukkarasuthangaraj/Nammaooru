import { Component, OnInit, OnDestroy } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, takeUntil, interval } from 'rxjs';
import { OrderAssignmentService } from '../../services/order-assignment.service';
import { AuthService } from '../../../../core/services/auth.service';

interface OrderItem {
  id: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  productImageUrl?: string;
}

interface ActiveOrder {
  id: string;
  assignmentId: string;
  orderNumber: string;
  status: string;
  assignmentStatus: string;
  orderStatus: string;
  customerName: string;
  customerPhone: string;
  shopName: string;
  shopAddress: string;
  shopLatitude: number;
  shopLongitude: number;
  deliveryAddress: string;
  customerLatitude: number;
  customerLongitude: number;
  totalAmount: number;
  deliveryFee: number;
  paymentMethod: string;
  paymentStatus: string;
  pickupOtp: string;
  deliveryType: string;
  createdAt: string;
  items: OrderItem[];
  orderItems: OrderItem[];
}

@Component({
  selector: 'app-partner-orders',
  templateUrl: './partner-orders.component.html',
  styleUrls: ['./partner-orders.component.scss']
})
export class PartnerOrdersComponent implements OnInit, OnDestroy {
  orders: ActiveOrder[] = [];
  isLoading = true;
  partnerId: number | null = null;
  processingOrderId: string | null = null;
  private destroy$ = new Subject<void>();

  constructor(
    private orderAssignmentService: OrderAssignmentService,
    private authService: AuthService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.partnerId = user.id;
      this.loadOrders();

      // Auto-refresh every 30 seconds
      interval(30000)
        .pipe(takeUntil(this.destroy$))
        .subscribe(() => this.loadOrders());
    } else {
      this.isLoading = false;
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadOrders(): void {
    if (!this.partnerId) return;

    this.orderAssignmentService.getActiveOrdersForPartner(this.partnerId).subscribe({
      next: (response) => {
        if (response.success && response.orders) {
          this.orders = response.orders.map((o: any) => ({
            ...o,
            items: o.items || o.orderItems || []
          }));
        } else {
          this.orders = [];
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        this.isLoading = false;
      }
    });
  }

  getStatusLabel(status: string): string {
    const labels: { [key: string]: string } = {
      'accepted': 'Accepted - Go to Shop',
      'picked_up': 'Picked Up - Deliver Now',
      'in_transit': 'On the Way',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled - Return Items',
      'returning_to_shop': 'Returning to Shop',
      'returned_to_shop': 'Returned'
    };
    return labels[status?.toLowerCase()] || status;
  }

  getStatusClass(status: string): string {
    const classes: { [key: string]: string } = {
      'accepted': 'status-accepted',
      'picked_up': 'status-pickedup',
      'in_transit': 'status-transit',
      'delivered': 'status-delivered',
      'cancelled': 'status-cancelled',
      'returning_to_shop': 'status-returning',
      'returned_to_shop': 'status-returned'
    };
    return classes[status?.toLowerCase()] || 'status-default';
  }

  getStatusIcon(status: string): string {
    const icons: { [key: string]: string } = {
      'accepted': 'store',
      'picked_up': 'local_shipping',
      'in_transit': 'delivery_dining',
      'delivered': 'check_circle',
      'cancelled': 'cancel',
      'returning_to_shop': 'undo',
      'returned_to_shop': 'assignment_return'
    };
    return icons[status?.toLowerCase()] || 'assignment';
  }

  // Navigation actions
  navigateToShop(order: ActiveOrder): void {
    if (order.shopLatitude && order.shopLongitude) {
      window.open(`https://www.google.com/maps/dir/?api=1&destination=${order.shopLatitude},${order.shopLongitude}`, '_blank');
    } else if (order.shopAddress) {
      window.open(`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(order.shopAddress)}`, '_blank');
    }
  }

  navigateToCustomer(order: ActiveOrder): void {
    if (order.customerLatitude && order.customerLongitude) {
      window.open(`https://www.google.com/maps/dir/?api=1&destination=${order.customerLatitude},${order.customerLongitude}`, '_blank');
    } else if (order.deliveryAddress) {
      window.open(`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(order.deliveryAddress)}`, '_blank');
    }
  }

  callCustomer(phone: string): void {
    window.open(`tel:${phone}`, '_self');
  }

  // Status progression actions
  markPickedUp(order: ActiveOrder): void {
    if (!this.partnerId) return;
    this.processingOrderId = order.id;

    this.orderAssignmentService.markPickedUp(Number(order.id), this.partnerId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.snackBar.open('Marked as picked up!', 'OK', { duration: 3000 });
            this.loadOrders();
          } else {
            this.snackBar.open(response.message || 'Failed', 'Close', { duration: 3000 });
          }
          this.processingOrderId = null;
        },
        error: (error) => {
          console.error('Error:', error);
          this.snackBar.open('Failed to update status', 'Close', { duration: 3000 });
          this.processingOrderId = null;
        }
      });
  }

  markDelivered(order: ActiveOrder): void {
    if (!this.partnerId) return;
    this.processingOrderId = order.id;

    this.orderAssignmentService.markDelivered(Number(order.id), this.partnerId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.snackBar.open('Delivery completed!', 'OK', { duration: 3000 });
            this.loadOrders();
          } else {
            this.snackBar.open(response.message || 'Failed', 'Close', { duration: 3000 });
          }
          this.processingOrderId = null;
        },
        error: (error) => {
          console.error('Error:', error);
          this.snackBar.open('Failed to update status', 'Close', { duration: 3000 });
          this.processingOrderId = null;
        }
      });
  }

  getPaymentLabel(method: string): string {
    const labels: { [key: string]: string } = {
      'COD': 'Cash on Delivery',
      'CASH_ON_DELIVERY': 'Cash on Delivery',
      'ONLINE': 'Paid Online',
      'UPI': 'Paid via UPI',
      'CARD': 'Paid via Card'
    };
    return labels[method] || method;
  }
}
