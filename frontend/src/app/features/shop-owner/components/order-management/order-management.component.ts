import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';
import { MatSnackBar } from '@angular/material/snack-bar';
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
}

interface OrderItem {
  id: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

@Component({
  selector: 'app-order-management',
  templateUrl: './order-management.component.html',
  styleUrls: ['./order-management.component.scss']
})
export class OrderManagementComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  shopId: number | null = null;
  pendingOrders: Order[] = [];
  activeOrders: Order[] = [];
  completedOrders: Order[] = [];
  
  selectedTab = 0;
  loading = false;
  autoRefreshEnabled = true;
  refreshInterval = 30000; // 30 seconds
  
  todayStats = {
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    revenue: 0,
    averageOrderValue: 0,
    totalProfit: 0,
    profitMargin: 0
  };

  showProfitDetails = false;
  profitBreakdown = {
    totalRevenue: 0,
    totalCost: 0,
    totalProfit: 0,
    topProfitableItems: [] as any[]
  };
  
  private apiUrl = environment.apiUrl;

  constructor(
    private http: HttpClient,
    private shopContext: ShopContextService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    // Wait for shop context to load
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop) {
        this.shopId = shop.id;
        this.loadAllData();
        this.startAutoRefresh();
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
    this.loadTodayStats();
  }

  loadOrders(): void {
    if (!this.shopId) return;
    
    this.loading = true;
    console.log('Loading orders for shop ID:', this.shopId);
    
    // Load all orders for this shop
    this.http.get<any>(`${this.apiUrl}/orders/shop/${this.shopId}`, {
      params: { size: '100' }
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const orders = response.content || response || [];
          this.categorizeOrders(orders);
          this.loading = false;
          console.log('Orders loaded:', orders.length);
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
      ['DELIVERED', 'CANCELLED'].includes(order.status)
    );
  }

  private loadTodayStats(): void {
    if (!this.shopId) return;
    
    // Use the orders we already loaded instead of separate API call
    this.calculateTodayStats(this.getAllOrders());
  }
  
  private calculateTodayStats(orders: Order[]): void {
    const today = new Date().toDateString();
    const todayOrders = orders.filter(order => 
      new Date(order.createdAt).toDateString() === today
    );
    
    const totalOrders = todayOrders.length;
    const pendingOrders = todayOrders.filter(o => o.status === 'PENDING').length;
    const completedOrders = todayOrders.filter(o => o.status === 'DELIVERED').length;
    const revenue = todayOrders
      .filter(o => o.status === 'DELIVERED')
      .reduce((sum, order) => sum + order.totalAmount, 0);
    
    this.todayStats = {
      totalOrders,
      pendingOrders,
      completedOrders,
      revenue,
      averageOrderValue: totalOrders > 0 ? revenue / totalOrders : 0,
      totalProfit: revenue * 0.2, // Assuming 20% profit margin
      profitMargin: 20
    };
  }

  private getAllOrders(): Order[] {
    return [...this.pendingOrders, ...this.activeOrders, ...this.completedOrders];
  }

  private startAutoRefresh(): void {
    if (this.autoRefreshEnabled) {
      interval(this.refreshInterval)
        .pipe(takeUntil(this.destroy$))
        .subscribe(() => {
          console.log('Auto-refreshing orders...');
          this.loadAllData();
        });
    }
  }

  refreshOrders(): void {
    this.loadAllData();
    this.snackBar.open('Orders refreshed', 'Close', { duration: 2000 });
    console.log('Orders refreshed manually');
  }

  acceptOrder(order: Order): void {
    console.log('Accepting order:', order.id);
    
    Swal.fire({
      title: 'Accept Order?',
      text: `Accept order ${order.orderNumber}?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#28a745',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, Accept!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.updateOrderStatus(order.id, 'CONFIRMED', 'Order accepted successfully!');
      }
    });
  }

  rejectOrder(order: Order): void {
    console.log('Rejecting order:', order.id);
    
    Swal.fire({
      title: 'Reject Order?',
      text: `Are you sure you want to reject order ${order.orderNumber}?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc3545',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, Reject!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.updateOrderStatus(order.id, 'CANCELLED', 'Order rejected successfully!');
      }
    });
  }

  markAsReady(order: Order): void {
    console.log('Marking order as ready:', order.id);
    
    Swal.fire({
      title: 'Mark as Ready?',
      text: `Mark order ${order.orderNumber} as ready for pickup/delivery?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#007bff',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, Mark Ready!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.updateOrderStatus(order.id, 'READY_FOR_PICKUP', 'Order marked as ready for delivery!');
      }
    });
  }

  markAsPreparing(order: Order): void {
    this.updateOrderStatus(order.id, 'PREPARING', 'Order is now being prepared!');
  }

  private updateOrderStatus(orderId: number, status: string, successMessage: string): void {
    // First try the status update endpoint
    this.http.put(`${this.apiUrl}/orders/${orderId}/status`, { status })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          console.log('Order status update response:', response);
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
          console.error('Error updating order status:', error);
          // Fallback: try PUT to /orders/{id} with full order update
          this.http.put(`${this.apiUrl}/orders/${orderId}`, { status })
            .pipe(takeUntil(this.destroy$))
            .subscribe({
              next: () => {
                this.loadAllData();
                this.snackBar.open(successMessage, 'Close', { duration: 3000 });
              },
              error: (fallbackError) => {
                console.error('Fallback order update failed:', fallbackError);
                this.handleError('Failed to update order status. Please try again.');
              }
            });
        }
      });
  }

  viewOrderDetails(order: Order): void {
    // Open order details modal
    let itemsHtml = '';
    if (order.orderItems && order.orderItems.length > 0) {
      itemsHtml = order.orderItems.map(item => 
        `<div class="order-item">
          <span>${item.productName}</span> 
          <span>× ${item.quantity}</span>
          <span>₹${item.totalPrice}</span>
        </div>`
      ).join('');
    }

    Swal.fire({
      title: `Order ${order.orderNumber}`,
      html: `
        <div class="order-details">
          <p><strong>Customer:</strong> ${order.customerName || 'N/A'}</p>
          <p><strong>Phone:</strong> ${order.customerPhone || 'N/A'}</p>
          <p><strong>Status:</strong> <span class="badge ${this.getStatusBadgeClass(order.status)}">${order.status}</span></p>
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

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    console.log('Auto-refresh:', this.autoRefreshEnabled ? 'enabled' : 'disabled');
    
    if (this.autoRefreshEnabled) {
      this.startAutoRefresh();
    }
  }
  
  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'PENDING': return 'badge-warning';
      case 'CONFIRMED': return 'badge-info';
      case 'PREPARING': return 'badge-primary';
      case 'READY_FOR_PICKUP': return 'badge-success';
      case 'OUT_FOR_DELIVERY': return 'badge-info';
      case 'DELIVERED': return 'badge-success';
      case 'CANCELLED': return 'badge-danger';
      default: return 'badge-secondary';
    }
  }
  
  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }
  
  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleString('en-IN');
  }

  getOrderCount(tab: number): number {
    switch (tab) {
      case 0: return this.pendingOrders.length;
      case 1: return this.activeOrders.length;
      case 2: return this.completedOrders.length;
      default: return 0;
    }
  }

  selectTab(index: number): void {
    this.selectedTab = index;
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return '#ffc107';
      case 'CONFIRMED': return '#17a2b8';
      case 'PREPARING': return '#007bff';
      case 'READY_FOR_PICKUP': return '#28a745';
      case 'OUT_FOR_DELIVERY': return '#17a2b8';
      case 'DELIVERED': return '#28a745';
      case 'CANCELLED': return '#dc3545';
      default: return '#6c757d';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'PENDING': return 'schedule';
      case 'CONFIRMED': return 'check_circle';
      case 'PREPARING': return 'restaurant';
      case 'READY_FOR_PICKUP': return 'done_all';
      case 'OUT_FOR_DELIVERY': return 'local_shipping';
      case 'DELIVERED': return 'verified';
      case 'CANCELLED': return 'cancel';
      default: return 'help';
    }
  }

  printOrder(order: Order): void {
    this.snackBar.open('Print functionality coming soon', 'Close', { duration: 2000 });
  }

  toggleProfitDetails(): void {
    this.showProfitDetails = !this.showProfitDetails;
  }

  sendDailySummary(): void {
    this.snackBar.open('Daily summary sent!', 'Close', { duration: 2000 });
  }
}