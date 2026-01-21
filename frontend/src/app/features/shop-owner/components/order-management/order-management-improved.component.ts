import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderService } from '../../../../core/services/order.service';
import { ShopContextService } from '../../services/shop-context.service';
import Swal from 'sweetalert2';

interface Order {
  id: number;
  orderNumber: string;
  customerName?: string;
  customerEmail?: string;
  customerPhone?: string;
  status: string;
  paymentStatus: string;
  paymentMethod: string;
  deliveryType: 'HOME_DELIVERY' | 'SELF_PICKUP';
  subtotal: number;
  taxAmount: number;
  deliveryFee: number;
  discountAmount: number;
  totalAmount: number;
  deliveryAddress: any;
  specialInstructions?: string;
  createdAt: string;
  updatedAt: string;
  orderItems?: OrderItem[];
  items?: OrderItem[];
}

interface OrderItem {
  id: number;
  productName: string;
  name?: string;
  quantity: number;
  unitPrice: number;
  price?: number;
  totalPrice: number;
}

@Component({
  selector: 'app-order-management-improved',
  templateUrl: './order-management-improved.component.html',
  styleUrls: ['./order-management-improved.component.scss']
})
export class OrderManagementImprovedComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  shopId: string | null = null;
  pendingOrders: Order[] = [];
  activeOrders: Order[] = [];
  completedOrders: Order[] = [];

  selectedTab = 0;
  loading = false;
  autoRefreshEnabled = true;
  refreshInterval = 30000; // 30 seconds

  // Enhanced Analytics
  todayStats = {
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    cancelledOrders: 0,
    revenue: 0,
    totalReceived: 0,
    totalRefunds: 0,
    averageOrderValue: 0
  };

  constructor(
    private orderService: OrderService,
    private shopContext: ShopContextService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    // Always start with fallback shopId
    this.shopId = "2";
    this.loadAllData();
    this.startAutoRefresh();

    // Try to get shop context
    this.shopContext.shop$.pipe(takeUntil(this.destroy$)).subscribe(shop => {
      if (shop) {
        this.shopId = shop.id.toString();
        this.loadAllData();
      }
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadAllData(): void {
    if (!this.shopId) return;
    this.loadOrders();
  }

  loadOrders(): void {
    if (!this.shopId) return;

    this.loading = true;

    this.orderService.getOrdersByShop(this.shopId, 0, 100)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const orders = response.data.content || [];
          this.categorizeOrders(orders);
          this.calculateDetailedStats(orders);
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading orders:', error);
          this.handleError('Failed to load orders');
          this.loading = false;
        }
      });
  }

  private categorizeOrders(orders: Order[]): void {
    this.pendingOrders = orders.filter(order => order.status === 'PENDING');
    this.activeOrders = orders.filter(order =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(order.status)
    );
    this.completedOrders = orders.filter(order =>
      ['DELIVERED', 'CANCELLED', 'SELF_PICKUP_COLLECTED'].includes(order.status)
    );
  }

  // ===== ENHANCED ANALYTICS CALCULATION =====

  private calculateDetailedStats(orders: Order[]): void {
    const today = new Date().toDateString();
    const todayOrders = orders.filter(order =>
      new Date(order.createdAt).toDateString() === today
    );

    // Basic counts
    const totalOrders = todayOrders.length;
    const pendingOrders = todayOrders.filter(o => o.status === 'PENDING').length;
    const completedOrders = todayOrders.filter(o =>
      ['DELIVERED', 'SELF_PICKUP_COLLECTED'].includes(o.status)
    ).length;
    const cancelledOrders = todayOrders.filter(o => o.status === 'CANCELLED').length;

    // Financial metrics (include POS orders in revenue)
    const deliveredOrders = todayOrders.filter(o =>
      ['DELIVERED', 'SELF_PICKUP_COLLECTED'].includes(o.status)
    );
    const cancelledOrdersList = todayOrders.filter(o => o.status === 'CANCELLED');

    const revenue = deliveredOrders.reduce((sum, order) => sum + order.totalAmount, 0);
    const totalReceived = deliveredOrders
      .filter(o => o.paymentStatus === 'PAID')
      .reduce((sum, order) => sum + order.totalAmount, 0);
    const totalRefunds = cancelledOrdersList
      .filter(o => o.paymentStatus === 'REFUNDED')
      .reduce((sum, order) => sum + order.totalAmount, 0);

    this.todayStats = {
      totalOrders,
      pendingOrders,
      completedOrders,
      cancelledOrders,
      revenue,
      totalReceived,
      totalRefunds,
      averageOrderValue: totalOrders > 0 ? revenue / totalOrders : 0
    };
  }

  private startAutoRefresh(): void {
    if (this.autoRefreshEnabled) {
      interval(this.refreshInterval)
        .pipe(takeUntil(this.destroy$))
        .subscribe(() => {
          this.loadAllData();
        });
    }
  }

  refreshOrders(): void {
    this.loadAllData();
    this.snackBar.open('Orders refreshed', 'Close', { duration: 2000 });
  }

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    if (this.autoRefreshEnabled) {
      this.startAutoRefresh();
    }
  }

  // ===== ORDER ACTIONS =====

  acceptOrder(order: Order): void {
    Swal.fire({
      title: 'Accept Order?',
      html: `
        <p>Accept order <strong>${order.orderNumber}</strong>?</p>
        <div style="margin-top: 1rem; padding: 1rem; background: #f7fafc; border-radius: 8px;">
          <p><strong>Delivery Type:</strong> ${order.deliveryType === 'SELF_PICKUP' ? '🏪 Self Pickup (FREE)' : '🚚 Home Delivery (₹' + order.deliveryFee + ')'}</p>
          <p><strong>Total:</strong> ₹${order.totalAmount}</p>
        </div>
      `,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#28a745',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, Accept!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.performOrderAction(order.id, 'accept', 'Order accepted successfully!');
      }
    });
  }

  rejectOrder(order: Order): void {
    Swal.fire({
      title: 'Reject Order',
      text: `Please provide a reason for rejecting order ${order.orderNumber}:`,
      input: 'textarea',
      inputPlaceholder: 'Enter rejection reason...',
      inputValidator: (value) => {
        if (!value) return 'Please provide a reason for rejection';
        if (value.length < 10) return 'Rejection reason must be at least 10 characters long';
        return null;
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc3545',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Reject Order',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.performOrderReject(order.id, result.value);
      }
    });
  }

  markAsPreparing(order: Order): void {
    this.performOrderAction(order.id, 'prepare', 'Order is now being prepared!');
  }

  markAsReady(order: Order): void {
    Swal.fire({
      title: 'Mark as Ready?',
      html: `
        <p>Mark order <strong>${order.orderNumber}</strong> as ready for ${order.deliveryType === 'SELF_PICKUP' ? 'pickup' : 'delivery'}?</p>
        ${order.deliveryType === 'SELF_PICKUP'
          ? '<p style="margin-top: 1rem; color: #48bb78;"><strong>Customer will be notified to come collect the order</strong></p>'
          : '<p style="margin-top: 1rem; color: #4299e1;"><strong>A delivery partner will be assigned</strong></p>'
        }
      `,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#007bff',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, Mark Ready!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.performOrderAction(order.id, 'ready', `Order marked as ready for ${order.deliveryType === 'SELF_PICKUP' ? 'pickup' : 'delivery'}!`);
      }
    });
  }

  // ===== SELF-PICKUP HANDOVER (GREEN BUTTON) =====

  handoverSelfPickup(order: Order): void {
    Swal.fire({
      title: 'Handover to Customer',
      html: `
        <div style="text-align: center;">
          <p style="font-size: 1.1rem; margin-bottom: 1.5rem;">
            Are you ready to handover this order to the customer?
          </p>
          <div style="background: #f7fafc; padding: 1.5rem; border-radius: 12px; margin: 1rem 0;">
            <p style="margin: 0.5rem 0;"><strong>Order:</strong> ${order.orderNumber}</p>
            <p style="margin: 0.5rem 0;"><strong>Customer:</strong> ${order.customerName}</p>
            <p style="margin: 0.5rem 0;"><strong>Total:</strong> ₹${order.totalAmount}</p>
          </div>
          <div style="background: #fef5e7; padding: 1rem; border-radius: 8px; margin-top: 1rem;">
            <p style="margin: 0; color: #975a16; font-weight: 600;">
              💰 Collect payment from customer (${order.paymentMethod})
            </p>
          </div>
        </div>
      `,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#48bb78',
      cancelButtonColor: '#6c757d',
      confirmButtonText: '✅ Handover & Collect Payment',
      cancelButtonText: 'Cancel',
      width: 600
    }).then((result) => {
      if (result.isConfirmed) {
        // Call the self-pickup handover API
        this.orderService.handoverSelfPickup(order.id)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: (response) => {
              console.log('✅ Self-pickup handover successful:', response);
              this.loadAllData();

              Swal.fire({
                title: 'Order Handed Over! ✅',
                html: `
                  <p>Order <strong>${order.orderNumber}</strong> has been handed over successfully</p>
                  <p style="margin-top: 1rem; color: #48bb78;">
                    <strong>Status:</strong> DELIVERED<br>
                    <strong>Payment:</strong> PAID
                  </p>
                `,
                icon: 'success',
                timer: 3000,
                timerProgressBar: true
              });

              this.snackBar.open('Order handed over successfully!', 'Close', { duration: 3000 });
            },
            error: (error) => {
              console.error('Error handing over order:', error);
              this.handleError('Failed to handover order. Please try again.');
            }
          });
      }
    });
  }

  // ===== HOME DELIVERY OTP VERIFICATION (ORANGE BUTTON) =====

  verifyPickupOTP(order: Order): void {
    Swal.fire({
      title: 'Verify Pickup OTP',
      html: `
        <p>Enter the OTP from the delivery partner:</p>
        <div style="margin: 1.5rem 0;">
          <input id="otp-input" class="swal2-input" placeholder="Enter 4-digit OTP" maxlength="4" style="font-size: 1.5rem; text-align: center; letter-spacing: 0.5rem;">
        </div>
        <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-top: 1rem;">
          <p style="margin: 0; font-size: 0.9rem;"><strong>Order:</strong> ${order.orderNumber}</p>
          <p style="margin: 0.5rem 0; font-size: 0.9rem;"><strong>Delivery Partner:</strong> (Partner Name)</p>
        </div>
      `,
      icon: 'info',
      showCancelButton: true,
      confirmButtonColor: '#f6ad55',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Verify OTP',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const otp = (document.getElementById('otp-input') as HTMLInputElement).value;
        if (!otp) {
          Swal.showValidationMessage('Please enter OTP');
          return false;
        }
        if (otp.length !== 4) {
          Swal.showValidationMessage('OTP must be 4 digits');
          return false;
        }
        return otp;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        // Call the OTP verification API
        this.orderService.verifyPickupOTP(order.id, result.value)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: (response) => {
              console.log('✅ OTP verified successfully:', response);
              this.loadAllData();

              Swal.fire({
                title: 'OTP Verified! ✅',
                html: `
                  <p>Order <strong>${order.orderNumber}</strong> has been handed over to delivery partner</p>
                  <p style="margin-top: 1rem; color: #4299e1;">
                    <strong>Status:</strong> OUT_FOR_DELIVERY
                  </p>
                `,
                icon: 'success',
                timer: 3000,
                timerProgressBar: true
              });

              this.snackBar.open('Order handed over to delivery partner!', 'Close', { duration: 3000 });
            },
            error: (error) => {
              console.error('Error verifying OTP:', error);
              Swal.fire('Error', 'Invalid OTP. Please try again.', 'error');
            }
          });
      }
    });
  }

  private performOrderReject(orderId: number, reason: string): void {
    this.orderService.rejectOrder(orderId, reason)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.loadAllData();
          this.snackBar.open('Order rejected successfully!', 'Close', { duration: 3000 });

          Swal.fire({
            title: 'Order Rejected!',
            text: 'Order has been rejected successfully.',
            icon: 'success',
            timer: 3000,
            timerProgressBar: true
          });
        },
        error: (error) => {
          this.handleError('Failed to reject order. Please try again.');
        }
      });
  }

  private performOrderAction(orderId: number, action: string, successMessage: string): void {
    let actionObservable;

    switch (action) {
      case 'accept':
        actionObservable = this.orderService.acceptOrder(orderId);
        break;
      case 'ready':
        actionObservable = this.orderService.markOrderAsReady(orderId);
        break;
      case 'prepare':
        actionObservable = this.orderService.markOrderAsPreparing(orderId);
        break;
      default:
        console.error('Unknown action:', action);
        return;
    }

    actionObservable
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.loadAllData();
          this.snackBar.open(successMessage, 'Close', { duration: 3000 });

          Swal.fire({
            title: 'Success!',
            text: successMessage,
            icon: 'success',
            timer: 3000,
            timerProgressBar: true
          });
        },
        error: (error) => {
          this.handleError(`Failed to ${action} order. Please try again.`);
        }
      });
  }

  viewOrderDetails(order: Order): void {
    let itemsHtml = '';
    if (order.orderItems && order.orderItems.length > 0) {
      itemsHtml = order.orderItems.map(item =>
        `<div class="order-item" style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #e2e8f0;">
          <span>${item.productName}</span>
          <span>× ${item.quantity}</span>
          <span>₹${item.totalPrice}</span>
        </div>`
      ).join('');
    }

    Swal.fire({
      title: `Order ${order.orderNumber}`,
      html: `
        <div class="order-details" style="text-align: left;">
          <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
            <p><strong>Customer:</strong> ${order.customerName || 'N/A'}</p>
            <p><strong>Phone:</strong> ${order.customerPhone || 'N/A'}</p>
            <p><strong>Delivery Type:</strong> ${order.deliveryType === 'SELF_PICKUP' ? '🏪 Self Pickup' : '🚚 Home Delivery'}</p>
          </div>
          <p><strong>Status:</strong> <span class="badge ${this.getStatusBadgeClass(order.status)}" style="padding: 0.25rem 0.75rem; border-radius: 12px;">${order.status}</span></p>
          <p><strong>Payment:</strong> ${order.paymentMethod} (${order.paymentStatus})</p>
          <p><strong>Total:</strong> ₹${order.totalAmount}</p>
          <hr>
          <h4>Items:</h4>
          ${itemsHtml || '<p>No items available</p>'}
          ${order.specialInstructions ? `<hr><p><strong>Instructions:</strong> ${order.specialInstructions}</p>` : ''}
        </div>
      `,
      width: 600,
      showCloseButton: true,
      showConfirmButton: false
    });
  }

  private handleError(message: string): void {
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      panelClass: ['error-snackbar']
    });
  }

  getStatusBadgeClass(status: string): string {
    const map: { [key: string]: string } = {
      'PENDING': 'badge-warning',
      'CONFIRMED': 'badge-info',
      'PREPARING': 'badge-primary',
      'READY_FOR_PICKUP': 'badge-success',
      'OUT_FOR_DELIVERY': 'badge-info',
      'DELIVERED': 'badge-success',
      'CANCELLED': 'badge-danger'
    };
    return map[status] || 'badge-secondary';
  }

  getStatusClass(status: string): string {
    return `status-${status.toLowerCase().replace('_', '-')}`;
  }

  getStatusLabel(status: string): string {
    const map: { [key: string]: string } = {
      'PENDING': 'Pending',
      'CONFIRMED': 'Confirmed',
      'PREPARING': 'Preparing',
      'READY_FOR_PICKUP': 'Ready',
      'OUT_FOR_DELIVERY': 'Out for Delivery',
      'DELIVERED': 'Delivered',
      'CANCELLED': 'Cancelled'
    };
    return map[status] || status;
  }

  getStatusIcon(status: string): string {
    const map: { [key: string]: string } = {
      'PENDING': 'schedule',
      'CONFIRMED': 'check_circle',
      'PREPARING': 'restaurant',
      'READY_FOR_PICKUP': 'done_all',
      'OUT_FOR_DELIVERY': 'local_shipping',
      'DELIVERED': 'verified',
      'CANCELLED': 'cancel'
    };
    return map[status] || 'help';
  }

  formatCurrency(amount: number): string {
    return `₹${amount.toLocaleString('en-IN')}`;
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString('en-IN');
  }

  printOrder(order: Order): void {
    this.snackBar.open('Print functionality coming soon', 'Close', { duration: 2000 });
  }
}
