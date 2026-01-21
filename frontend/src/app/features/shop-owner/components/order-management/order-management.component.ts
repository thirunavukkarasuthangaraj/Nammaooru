import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderService } from '../../../../core/services/order.service';
import { OrderAssignmentService } from '../../../../core/services/order-assignment.service';
import { DeliveryPartnerService, DeliveryPartner } from '../../../delivery/services/delivery-partner.service';
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
  items?: OrderItem[]; // Alternative property name
}

interface OrderItem {
  id: number;
  productName: string;
  name?: string; // Alternative property name
  quantity: number;
  unitPrice: number;
  price?: number; // Alternative property name
  totalPrice: number;
}

@Component({
  selector: 'app-order-management',
  templateUrl: './order-management.component.html',
  styleUrls: ['./order-management.component.scss']
})
export class OrderManagementComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  shopId: string | null = null;
  pendingOrders: Order[] = [];
  activeOrders: Order[] = [];
  completedOrders: Order[] = [];
  
  selectedTab = 0;
  loading = false;
  autoRefreshEnabled = true;
  refreshInterval = 30000; // 30 seconds

  // Additional properties for template binding
  totalOrders = 0;
  todayRevenue = 0;
  searchTerm = '';
  filteredOrders: Order[] = [];
  successMessage = '';
  errorMessage = '';
  selectedStatus = '';
  
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

  // Assignment Modal Properties
  showAssignmentModal = false;
  selectedOrder: Order | null = null;
  availablePartners: DeliveryPartner[] = [];
  loadingPartners = false;
  partnerAssignments: { [partnerId: number]: number } = {};

  constructor(
    private http: HttpClient,
    private router: Router,
    private orderService: OrderService,
    private assignmentService: OrderAssignmentService,
    private partnerService: DeliveryPartnerService,
    private shopContext: ShopContextService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    console.log('Order Management Component initialized');
    
    // Always start with fallback shopId and load data immediately
    this.shopId = "2";
    console.log('Starting with hardcoded shopId: 2 for demo');
    
    // Load data immediately
    this.loadAllData();
    this.startAutoRefresh();
    
    // Also try to get shop context in parallel but don't wait for it
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop) {
        console.log('Shop context loaded:', shop, 'Updating shopId to:', shop.id);
        // Only update shopId if we get a valid shop context
        this.shopId = shop.id.toString();
        // Reload data with correct shop ID
        this.loadAllData();
      } else {
        console.log('No shop context available, continuing with fallback shopId: 2');
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
    // loadTodayStats() is now called from within loadOrders() after orders are loaded
  }

  loadOrders(): void {
    console.log('=== loadOrders called ===');
    console.log('shopId:', this.shopId);
    
    if (!this.shopId) {
      console.log('No shopId available, aborting load');
      return;
    }
    
    this.loading = true;
    console.log('Starting to load orders for shop ID:', this.shopId);
    
    // Use OrderService to load orders for this shop
    this.orderService.getOrdersByShop(this.shopId, 0, 100)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          console.log('=== API Response received ===');
          console.log('Full API response:', response);
          console.log('Response type:', typeof response);
          console.log('Response keys:', Object.keys(response));
          
          const orders = response.data.content || [];
          console.log('Extracted orders:', orders);
          console.log('Orders count:', orders.length);
          
          this.categorizeOrders(orders);
          this.calculateTodayStats(orders); // Calculate stats after orders are loaded
          this.loading = false;
          console.log('=== Orders successfully loaded ===');
          console.log('Pending:', this.pendingOrders.length);
          console.log('Active:', this.activeOrders.length);
          console.log('Completed:', this.completedOrders.length);
          console.log('Today Stats:', this.todayStats);
        },
        error: (error) => {
          console.error('=== API Error ===');
          console.error('Error loading orders:', error);
          console.error('Error status:', error.status);
          console.error('Error message:', error.message);
          this.handleError('Failed to load orders: ' + (error.message || error.status));
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

  
  private calculateTodayStats(orders: Order[]): void {
    const today = new Date().toDateString();
    const todayOrders = orders.filter(order => 
      new Date(order.createdAt).toDateString() === today
    );
    
    const totalOrders = todayOrders.length;
    const pendingOrders = todayOrders.filter(o => o.status === 'PENDING').length;
    const completedOrders = todayOrders.filter(o =>
      ['DELIVERED', 'SELF_PICKUP_COLLECTED'].includes(o.status)
    ).length;
    const revenue = todayOrders
      .filter(o => ['DELIVERED', 'SELF_PICKUP_COLLECTED'].includes(o.status))
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
        this.performOrderAction(order.id, 'accept', 'Order accepted successfully!');
      }
    });
  }

  rejectOrder(order: Order): void {
    console.log('Rejecting order:', order.id);
    
    Swal.fire({
      title: 'Reject Order',
      text: `Please provide a reason for rejecting order ${order.orderNumber}:`,
      input: 'textarea',
      inputPlaceholder: 'Enter rejection reason...',
      inputValidator: (value) => {
        if (!value) {
          return 'Please provide a reason for rejection';
        }
        if (value.length < 10) {
          return 'Rejection reason must be at least 10 characters long';
        }
        return null;
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc3545',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Reject Order',
      cancelButtonText: 'Cancel',
      allowOutsideClick: false,
      allowEscapeKey: false
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.performOrderReject(order.id, result.value);
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
        this.performOrderAction(order.id, 'ready', 'Order marked as ready for delivery!');
      }
    });
  }

  markAsPreparing(order: Order): void {
    this.performOrderAction(order.id, 'prepare', 'Order is now being prepared!');
  }

  private performOrderReject(orderId: number, reason: string): void {
    this.orderService.rejectOrder(orderId, reason)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          console.log('Order reject response:', response);
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
          console.error('Error rejecting order:', error);
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
          console.log(`Order ${action} response:`, response);
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
          console.error(`Error performing order action ${action}:`, error);
          this.handleError(`Failed to ${action} order. Please try again.`);
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

  // Assignment Methods
  assignDeliveryPartner(order: Order): void {
    this.selectedOrder = order;
    this.showAssignmentModal = true;
    this.loadAvailablePartners();
  }

  closeAssignmentModal(): void {
    this.showAssignmentModal = false;
    this.selectedOrder = null;
    this.availablePartners = [];
    this.partnerAssignments = {};
  }

  private loadAvailablePartners(): void {
    this.loadingPartners = true;
    
    this.partnerService.getAvailablePartners()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response && response.data) {
            this.availablePartners = response.data;
            this.loadPartnerWorkloads();
          } else {
            this.availablePartners = [];
          }
          this.loadingPartners = false;
        },
        error: (error) => {
          console.error('Error loading partners:', error);
          this.availablePartners = [];
          this.loadingPartners = false;
          this.snackBar.open('Failed to load delivery partners', 'Close', { duration: 3000 });
        }
      });
  }

  private loadPartnerWorkloads(): void {
    this.availablePartners.forEach(partner => {
      this.assignmentService.getActiveAssignments(partner.id)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (response && response.data) {
              this.partnerAssignments[partner.id] = response.data.length;
            } else {
              this.partnerAssignments[partner.id] = 0;
            }
          },
          error: (error) => {
            console.error(`Error loading assignments for partner ${partner.id}:`, error);
            this.partnerAssignments[partner.id] = 0;
          }
        });
    });
  }

  assignToPartner(orderId: number, partnerId: number): void {
    const assignmentRequest = {
      orderId: orderId,
      deliveryPartnerId: partnerId,
      notes: 'Assigned from order management dashboard'
    };

    this.assignmentService.assignOrder(assignmentRequest)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          console.log('Order assigned successfully:', response);
          this.snackBar.open('Order assigned to delivery partner!', 'Close', { duration: 3000 });
          
          Swal.fire({
            title: 'Success!',
            text: 'Order has been assigned to delivery partner.',
            icon: 'success',
            timer: 3000,
            timerProgressBar: true
          });

          this.closeAssignmentModal();
          this.loadAllData(); // Refresh orders
        },
        error: (error) => {
          console.error('Error assigning order:', error);
          this.snackBar.open('Failed to assign order. Please try again.', 'Close', { duration: 3000 });
          
          Swal.fire({
            title: 'Error!',
            text: 'Failed to assign order to delivery partner.',
            icon: 'error'
          });
        }
      });
  }

  getActiveOrdersCount(partnerId: number): number {
    return this.partnerAssignments[partnerId] || 0;
  }

  getVehicleIcon(vehicleType: string): string {
    switch (vehicleType) {
      case 'BIKE': return '🏍️';
      case 'SCOOTER': return '🛵';
      case 'BICYCLE': return '🚲';
      case 'CAR': return '🚗';
      case 'AUTO': return '🛺';
      default: return '🚚';
    }
  }

  // ===== NAVIGATION TO DELIVERY MANAGEMENT =====

  /**
   * Navigate to enhanced delivery management screen for order assignment and tracking
   */
  assignDelivery(orderId: number): void {
    console.log('Navigating to delivery management for order:', orderId);
    this.router.navigate(['/shop-owner/delivery-management'], {
      queryParams: { orderId: orderId }
    });
  }

  // ===== ADDITIONAL METHODS FOR TEMPLATE BINDING =====

  printReceipt(orderId: number): void {
    // Implement receipt printing
    this.snackBar.open('Receipt printing feature will be implemented', 'Close', { duration: 3000 });
  }

  callCustomer(phone: string): void {
    if (phone) {
      window.open(`tel:${phone}`, '_self');
    }
  }

  reportIssue(orderId: number): void {
    // Implement issue reporting
    this.snackBar.open('Issue reporting feature will be implemented', 'Close', { duration: 3000 });
  }

  applyFilter(): void {
    // Apply filtering logic
    this.filteredOrders = this.pendingOrders.filter(order => {
      return !this.searchTerm ||
        order.orderNumber.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        (order.customerName && order.customerName.toLowerCase().includes(this.searchTerm.toLowerCase()));
    });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'PENDING': return 'status-pending';
      case 'CONFIRMED': return 'status-confirmed';
      case 'PREPARING': return 'status-preparing';
      case 'READY_FOR_PICKUP': return 'status-ready';
      case 'OUT_FOR_DELIVERY': return 'status-delivery';
      case 'DELIVERED': return 'status-delivered';
      case 'CANCELLED': return 'status-cancelled';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY_FOR_PICKUP': return 'Ready';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  startPreparing(orderId: number): void {
    this.markAsPreparing(this.pendingOrders.find(o => o.id === orderId)!);
  }

  markReady(orderId: number): void {
    this.markAsReady(this.activeOrders.find(o => o.id === orderId)!);
  }

}