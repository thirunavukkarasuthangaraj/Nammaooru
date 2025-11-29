import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatTabChangeEvent } from '@angular/material/tabs';
import { ShopOwnerOrderService, ShopOwnerOrder } from '../../services/shop-owner-order.service';
import { AssignmentService } from '../../services/assignment.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';
import { Subject } from 'rxjs';
import { takeUntil, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-orders-management',
  templateUrl: './orders-management.component.html',
  styleUrls: ['./orders-management.component.scss']
})
export class OrdersManagementComponent implements OnInit, OnDestroy {

  // Order data
  orders: ShopOwnerOrder[] = [];
  filteredOrders: ShopOwnerOrder[] = [];
  pendingOrders: ShopOwnerOrder[] = [];
  processingOrders: ShopOwnerOrder[] = [];
  activeOrders: ShopOwnerOrder[] = [];
  completedOrders: ShopOwnerOrder[] = [];
  todayOrders: ShopOwnerOrder[] = [];
  inProgressOrders: ShopOwnerOrder[] = [];

  // Shop ID - dynamically retrieved from shop context service
  shopId: number | null = null;

  // Filter controls
  searchTerm = '';
  selectedStatus = '';
  selectedTabIndex = 0;
  startDate: Date | null = null;
  endDate: Date | null = null;
  fromDate: string = '';
  toDate: string = '';

  // Pagination
  totalOrders = 0;
  pageSize = 10;

  // Statistics
  todayRevenue = 0;
  todayProfit = 0;
  profitMargin = 20; // Default 20% profit margin

  // Assignment state
  isAssigningPartner = false;

  // Driver verification
  verificationCodes: { [orderId: number]: string } = {};

  // Message properties
  successMessage = '';
  errorMessage = '';

  // Unsubscription subject
  private destroy$ = new Subject<void>();

  constructor(
    private orderService: ShopOwnerOrderService,
    private assignmentService: AssignmentService,
    private authService: AuthService,
    private shopContextService: ShopContextService,
    private snackBar: MatSnackBar,
    private swal: SwalService,
    private router: Router,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    // Check if user is authenticated
    if (!this.authService.isAuthenticated()) {
      console.error('User not authenticated. Redirecting to login...');
      this.router.navigate(['/auth/login']);
      return;
    }

    // Simple: Get shop ID from localStorage and load orders
    this.loadOrdersFromCache();
  }

  ngOnDestroy(): void {
    // Clean up subscriptions
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadOrdersFromCache(): void {
    // Check cache first
    const cachedShopId = localStorage.getItem('current_shop_id');
    if (cachedShopId) {
      this.shopId = parseInt(cachedShopId, 10);
      console.log('Using cached shop ID:', this.shopId);
      this.loadOrders();
      return;
    }

    // No cache - call API to get shop ID dynamically
    console.log('No cached shop ID - calling /api/shops/my-shop');
    this.http.get<any>(`${environment.apiUrl}/shops/my-shop`).subscribe({
      next: (response) => {
        if (response.data && response.data.id) {
          this.shopId = response.data.id;
          localStorage.setItem('current_shop_id', response.data.id.toString());
          console.log('Got shop ID from API:', this.shopId);
          this.loadOrders();
        }
      },
      error: (error) => {
        console.error('Error getting shop ID:', error);
      }
    });
  }

  loadDashboardData(): void {
    console.log('Loading dashboard data...');

    // Load all orders first, then calculate statistics from them
    this.loadOrders();
  }

  loadOrders(): void {
    if (!this.shopId) {
      console.log('No shop ID available, cannot load orders');
      return;
    }

    console.log('Loading orders for shop:', this.shopId);

    this.orderService.getShopOrders(this.shopId).subscribe({
      next: (orders) => {
        console.log('Orders loaded successfully:', orders.length);
        this.orders = orders;
        this.updateOrderLists();

        // Show success message if orders are loaded
        if (orders.length > 0) {
          this.successMessage = `Loaded ${orders.length} orders successfully`;
          setTimeout(() => this.successMessage = '', 3000);
        }
      },
      error: (error) => {
        console.error('Error loading orders:', error);

        // Check if it's an authentication error
        if (error.status === 401 || error.status === 403) {
          this.swal.error('Authentication Required', 'Please login to view orders.');
        } else {
          this.swal.error('Error', 'Failed to load orders. Please try again.');
        }
      }
    });
  }

  updateOrderLists(): void {
    this.filteredOrders = [...this.orders];

    // Filter orders by status
    this.pendingOrders = this.orders.filter(o => o.status === 'PENDING');
    this.processingOrders = this.orders.filter(o => o.status === 'CONFIRMED');
    this.activeOrders = this.orders.filter(o =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(o.status)
    );
    this.completedOrders = this.orders.filter(o => o.status === 'DELIVERED');

    // Filter today's orders
    this.todayOrders = this.orders.filter(o => this.isToday(new Date(o.createdAt)));

    // In-progress orders
    this.inProgressOrders = this.orders.filter(o =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(o.status)
    );

    // Set total count
    this.totalOrders = this.orders.length;

    // Calculate comprehensive statistics
    this.calculateStatistics();
  }

  calculateStatistics(): void {
    // Calculate OVERALL revenue from ALL delivered orders (not just today)
    const allDeliveredOrders = this.orders.filter(order =>
      order.status === 'DELIVERED' || order.paymentStatus === 'PAID'
    );

    // Calculate TODAY's revenue from all orders (not just delivered)
    const today = new Date();
    const allTodayOrders = this.orders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate.toDateString() === today.toDateString();
    });

    // Revenue from all today's orders
    this.todayRevenue = allTodayOrders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);

    // If no orders today, show total revenue from all orders
    if (this.todayRevenue === 0) {
      this.todayRevenue = this.orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
    }

    // Calculate profit based on margin
    this.todayProfit = this.todayRevenue * (this.profitMargin / 100);

    console.log('Statistics calculated:', {
      totalOrders: this.totalOrders,
      pendingOrders: this.pendingOrders.length,
      completedOrders: this.completedOrders.length,
      todayOrders: this.todayOrders.length,
      todayRevenue: this.todayRevenue,
      todayProfit: this.todayProfit
    });
  }

  isToday(date: Date): boolean {
    const today = new Date();
    return date.toDateString() === today.toDateString();
  }

  applyFilter(): void {
    this.filteredOrders = this.orders.filter(order => {
      const matchesSearch = !this.searchTerm ||
        order.orderNumber.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        order.customerName.toLowerCase().includes(this.searchTerm.toLowerCase());

      const matchesStatus = !this.selectedStatus ||
        order.status === this.selectedStatus;

      const matchesDateRange = this.matchesDateRange(order);

      return matchesSearch && matchesStatus && matchesDateRange;
    });
  }

  matchesDateRange(order: ShopOwnerOrder): boolean {
    if (!this.fromDate && !this.toDate) {
      return true; // No date filter applied
    }

    try {
      const orderDate = new Date(order.createdAt);
      const orderDateOnly = new Date(orderDate.getFullYear(), orderDate.getMonth(), orderDate.getDate());

      if (this.fromDate) {
        const fromDateParts = this.fromDate.split('-');
        const fromDateOnly = new Date(parseInt(fromDateParts[0]), parseInt(fromDateParts[1]) - 1, parseInt(fromDateParts[2]));
        if (orderDateOnly < fromDateOnly) {
          return false;
        }
      }

      if (this.toDate) {
        const toDateParts = this.toDate.split('-');
        const toDateOnly = new Date(parseInt(toDateParts[0]), parseInt(toDateParts[1]) - 1, parseInt(toDateParts[2]));
        if (orderDateOnly > toDateOnly) {
          return false;
        }
      }

      return true;
    } catch (error) {
      console.error('Error in date filtering:', error);
      return true; // Return true if there's an error to show the order
    }
  }

  clearDateFilter(): void {
    this.fromDate = '';
    this.toDate = '';
    this.applyFilter();
  }

  onTabChange(event: MatTabChangeEvent): void {
    this.selectedTabIndex = event.index;
  }

  acceptOrder(order: ShopOwnerOrder): void {
    this.swal.loading('Accepting order...');
    this.orderService.acceptOrder(order.id).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === order.id);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
          this.applyFilter();
        }
        this.swal.close();
        this.swal.success('Order Accepted!', `Order #${order.orderNumber} has been accepted successfully.`);
      },
      error: (error) => {
        console.error('Error accepting order:', error);
        this.swal.close();
        this.swal.error('Error', 'Failed to accept order. Please try again.');
      }
    });
  }

  rejectOrder(order: ShopOwnerOrder): void {
    this.swal.custom({
      title: 'Reject Order',
      text: 'Please provide a reason for rejection:',
      input: 'text',
      inputPlaceholder: 'Enter reason...',
      showCancelButton: true,
      confirmButtonText: 'Reject',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ef4444',
      inputValidator: (value) => {
        if (!value) {
          return 'You need to provide a reason!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.swal.loading('Rejecting order...');
        this.orderService.rejectOrder(order.id, result.value).subscribe({
          next: (updatedOrder) => {
            const orderIndex = this.orders.findIndex(o => o.id === order.id);
            if (orderIndex !== -1) {
              this.orders[orderIndex] = updatedOrder;
              this.updateOrderLists();
              this.applyFilter();
            }
            this.swal.close();
            this.swal.success('Order Rejected', `Order #${order.orderNumber} has been rejected.`);
          },
          error: (error) => {
            console.error('Error rejecting order:', error);
            this.swal.close();
            this.swal.error('Error', 'Failed to reject order. Please try again.');
          }
        });
      }
    });
  }

  cancelOrder(order: ShopOwnerOrder): void {
    // Define predefined cancellation reasons
    const cancelReasons = [
      'Item out of stock',
      'Customer request',
      'Damaged items',
      'Wrong items packed',
      'Unable to prepare on time',
      'Other (please specify)'
    ];

    // Create options HTML for SweetAlert
    const reasonsHtml = cancelReasons
      .map((reason, index) => `
        <label style="display: block; margin: 8px 0; cursor: pointer;">
          <input type="radio" name="cancelReason" value="${reason}" ${index === 0 ? 'checked' : ''} style="margin-right: 8px;">
          <span>${reason}</span>
        </label>
      `)
      .join('');

    this.swal.custom({
      title: 'Cancel Order',
      html: `
        <div style="text-align: left; padding: 10px 0;">
          <p style="margin-bottom: 15px; font-weight: 500;">Why are you cancelling this order?</p>
          <div style="border: 1px solid #ddd; padding: 12px; border-radius: 4px; max-height: 250px; overflow-y: auto;">
            ${reasonsHtml}
          </div>
          <textarea id="customReason" placeholder="If 'Other', please specify reason here..." style="width: 100%; margin-top: 12px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; display: none; min-height: 60px;" maxlength="255"></textarea>
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Cancel Order',
      cancelButtonText: 'Go Back',
      confirmButtonColor: '#ef4444',
      didOpen: () => {
        // Add event listener for radio button changes
        const radioButtons = document.querySelectorAll('input[name="cancelReason"]');
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        radioButtons.forEach((radio: any) => {
          radio.addEventListener('change', (e: any) => {
            if (e.target.value === 'Other (please specify)') {
              customReasonTextarea.style.display = 'block';
            } else {
              customReasonTextarea.style.display = 'none';
            }
          });
        });
      },
      inputValidator: () => {
        const selectedReason = (document.querySelector('input[name="cancelReason"]:checked') as any)?.value;
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        if (!selectedReason) {
          return 'Please select a cancellation reason';
        }

        if (selectedReason === 'Other (please specify)' && !customReasonTextarea.value.trim()) {
          return 'Please specify the reason';
        }

        return null;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        const selectedReason = (document.querySelector('input[name="cancelReason"]:checked') as any)?.value;
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        const cancellationReason = selectedReason === 'Other (please specify)'
          ? customReasonTextarea.value.trim()
          : selectedReason;

        this.swal.loading('Cancelling order...');
        this.orderService.cancelOrder(order.id, cancellationReason).subscribe({
          next: (updatedOrder) => {
            const orderIndex = this.orders.findIndex(o => o.id === order.id);
            if (orderIndex !== -1) {
              this.orders[orderIndex] = updatedOrder;
              this.updateOrderLists();
              this.applyFilter();
            }
            this.swal.close();
            this.swal.success('Order Cancelled', `Order #${order.orderNumber} has been cancelled successfully.`);
          },
          error: (error) => {
            console.error('Error cancelling order:', error);
            this.swal.close();
            this.swal.error('Error', 'Failed to cancel order. Please try again.');
          }
        });
      }
    });
  }

  startPreparing(orderId: number): void {
    this.swal.loading('Starting preparation...');
    this.orderService.startPreparing(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.swal.close();
        this.swal.toast('Order preparation started', 'success');
      },
      error: (error) => {
        console.error('Error starting preparation:', error);
        this.swal.close();
        this.swal.error('Error', 'Failed to start preparation. Please try again.');
      }
    });
  }

  markReady(orderId: number): void {
    this.swal.loading('Marking order as ready...');
    this.orderService.markReady(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.swal.close();
        this.swal.success('Order Ready!', 'Order marked as ready and auto-assigned to delivery partner.');
      },
      error: (error) => {
        console.error('Error marking ready:', error);
        this.swal.close();
        this.swal.error('Error', 'Failed to mark order as ready. Please try again.');
      }
    });
  }

  markPickedUp(orderId: number): void {
    this.orderService.markDelivered(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.swal.toast('Order marked as delivered', 'success');
      },
      error: (error) => {
        console.error('Error marking delivered:', error);
        this.swal.error('Error', 'Failed to mark order as delivered.');
      }
    });
  }

  quickAccept(order: ShopOwnerOrder): void {
    this.acceptOrder(order);
  }

  quickReject(order: ShopOwnerOrder): void {
    this.rejectOrder(order);
  }

  moveToNextStage(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (order) {
      switch (order.status) {
        case 'CONFIRMED':
          this.startPreparing(orderId);
          break;
        case 'PREPARING':
          this.markReady(orderId); // This will auto-assign delivery partner
          break;
        // Removed READY_FOR_PICKUP case as assignment is automatic
      }
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return 'warn';
      case 'CONFIRMED': return 'primary';
      case 'PREPARING': return 'accent';
      case 'READY_FOR_PICKUP': return 'primary';
      case 'DELIVERED': return 'primary';
      case 'CANCELLED': return 'warn';
      default: return 'basic';
    }
  }

  isUrgent(createdAt: string): boolean {
    const now = new Date();
    const orderDate = new Date(createdAt);
    const diffMinutes = (now.getTime() - orderDate.getTime()) / (1000 * 60);
    return diffMinutes > 15; // Orders older than 15 minutes are urgent
  }

  getTimeAgo(createdAt: string): string {
    const now = new Date();
    const orderDate = new Date(createdAt);
    const diffMinutes = Math.floor((now.getTime() - orderDate.getTime()) / (1000 * 60));
    if (diffMinutes < 1) return 'Just now';
    if (diffMinutes < 60) return `${diffMinutes} min ago`;
    const diffHours = Math.floor(diffMinutes / 60);
    return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  }

  getEstimatedTime(status: string): number {
    switch (status) {
      case 'CONFIRMED': return 25;
      case 'PREPARING': return 15;
      case 'READY_FOR_PICKUP': return 5;
      default: return 0;
    }
  }

  getNextStageAction(status: string): string {
    switch (status) {
      case 'CONFIRMED': return 'Start Preparing';
      case 'PREPARING': return 'Mark Ready';
      default: return 'Next Stage';
    }
  }

  shouldShowNextStageButton(status: string): boolean {
    // Hide button for orders that are ready for pickup or beyond
    return status === 'CONFIRMED' || status === 'PREPARING';
  }

  getStatusLabel(status: string): string {
    // Convert status to readable format
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY_FOR_PICKUP': return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status.replace(/_/g, ' ');
    }
  }


  printOrder(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (!order) {
      this.swal.error('Error', 'Order not found');
      return;
    }

    // Create printable content
    const printContent = this.generatePrintContent(order);

    // Open print window
    const printWindow = window.open('', '_blank', 'width=800,height=600');
    if (printWindow) {
      printWindow.document.write(printContent);
      printWindow.document.close();
      printWindow.focus();
      printWindow.print();
      printWindow.close();
    }

    this.swal.toast(`Order #${order.orderNumber} sent to printer`, 'success');
  }

  generatePrintContent(order: ShopOwnerOrder): string {
    const itemsHtml = order.items.map(item => `
      <tr>
        <td>${item.name || item.productName}</td>
        <td style="text-align: center;">${item.quantity}</td>
        <td style="text-align: right;">₹${item.price || item.unitPrice}</td>
        <td style="text-align: right;">₹${item.total || item.totalPrice}</td>
      </tr>
    `).join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Order #${order.orderNumber}</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          .header { text-align: center; margin-bottom: 30px; }
          .order-info { margin-bottom: 20px; }
          .customer-info { margin-bottom: 20px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
          th, td { padding: 8px; border: 1px solid #ddd; }
          th { background-color: #f5f5f5; }
          .total { font-weight: bold; font-size: 16px; }
          .footer { margin-top: 30px; text-align: center; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Order Receipt</h1>
          <h2>Order #${order.orderNumber}</h2>
        </div>

        <div class="order-info">
          <p><strong>Date:</strong> ${new Date(order.createdAt).toLocaleString()}</p>
          <p><strong>Status:</strong> ${this.getStatusLabel(order.status)}</p>
          <p><strong>Payment Method:</strong> ${order.paymentMethod === 'CASH_ON_DELIVERY' ? 'Cash on Delivery' : 'Paid Online'}</p>
        </div>

        <div class="customer-info">
          <h3>Customer Details</h3>
          <p><strong>Name:</strong> ${order.customerName}</p>
          <p><strong>Phone:</strong> ${order.customerPhone}</p>
          <p><strong>Address:</strong> ${order.customerAddress || order.deliveryAddress}</p>
        </div>

        <h3>Order Items</h3>
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Quantity</th>
              <th>Unit Price</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
          <tfoot>
            <tr class="total">
              <td colspan="3">Total Amount</td>
              <td style="text-align: right;">₹${order.totalAmount}</td>
            </tr>
          </tfoot>
        </table>

        <div class="footer">
          <p>Thank you for your order!</p>
          <p>Printed on: ${new Date().toLocaleString()}</p>
        </div>
      </body>
      </html>
    `;
  }

  viewCustomer(customerId: number): void {
    this.swal.info('Coming Soon', 'Customer details feature is under development.');
  }

  refundOrder(orderId: number): void {
    this.swal.info('Refund Initiated', 'Refund process has been started.');
  }

  reportIssue(orderId: number): void {
    this.swal.info('Coming Soon', 'Issue reporting feature is under development.');
  }

  assignDeliveryPartner(orderId: number): void {
    this.isAssigningPartner = true;

    // For now, we'll auto-assign to available partner
    // Later this can be enhanced with a partner selection dialog
    const assignedBy = 1; // TODO: Should get from auth service - current user ID

    this.assignmentService.autoAssignOrder(orderId, assignedBy).subscribe({
      next: (response) => {
        this.isAssigningPartner = false;

        if (response.success && response.assignment) {
          // Update order status
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex].status = 'OUT_FOR_DELIVERY';
            this.updateOrderLists();
          }

          this.swal.success('Order Assigned', `Order assigned to ${response.assignment.deliveryPartner.name}`);
        } else {
          this.swal.error('Assignment Failed', response.message || 'Failed to assign delivery partner');
        }
      },
      error: (error) => {
        this.isAssigningPartner = false;
        console.error('Error assigning delivery partner:', error);
        this.swal.error('Error', 'Failed to assign delivery partner. Please try again.');
      }
    });
  }

  onPageChange(event: any): void {
    // Handle pagination
  }

  verifyDriver(orderId: number, verificationCode: string): void {
    if (!verificationCode || verificationCode.length < 4) {
      this.swal.warning('Invalid Code', 'Please enter a valid verification code');
      return;
    }

    // Call the verification service/API
    this.orderService.verifyDriverForPickup(orderId, verificationCode).subscribe({
      next: (response) => {
        if (response.success) {
          // Update order status locally
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex].driverVerified = true;
            this.updateOrderLists();
          }

          this.swal.success('Driver Verified!', 'Order can be handed over to the delivery partner.');

          // Clear the verification code
          delete this.verificationCodes[orderId];
        } else {
          this.swal.error('Verification Failed', response.message || 'Invalid verification code');
        }
      },
      error: (error) => {
        console.error('Error verifying driver:', error);
        this.swal.error('Error', 'Failed to verify driver. Please try again.');
      }
    });
  }

  // ===== ADDITIONAL METHODS FOR NEW UI =====

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

  assignDelivery(orderId: number): void {
    this.assignDeliveryPartner(orderId);
  }

  viewOrderDetails(order: ShopOwnerOrder): void {
    // Create detailed view content
    const detailsContent = this.generateOrderDetailsContent(order);

    // Open details window
    const detailsWindow = window.open('', '_blank', 'width=900,height=700,scrollbars=yes');
    if (detailsWindow) {
      detailsWindow.document.write(detailsContent);
      detailsWindow.document.close();
      detailsWindow.focus();
    }

    this.successMessage = `Viewing details for Order #${order.orderNumber}`;
    setTimeout(() => this.successMessage = '', 3000);
  }

  generateOrderDetailsContent(order: ShopOwnerOrder): string {
    const itemsHtml = order.items.map(item => {
      const unitPrice = item.price || item.unitPrice || 0;
      const totalPrice = item.quantity * unitPrice;

      const imageHtml = (item.image || item.productImageUrl)
        ? `<img src="${this.getImageUrl(item.image || item.productImageUrl || '')}" alt="${item.name || item.productName}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px; margin-right: 10px;">`
        : `<div style="width: 50px; height: 50px; background: #ecf0f1; border-radius: 4px; display: flex; align-items: center; justify-content: center; margin-right: 10px; font-size: 18px; color: #7f8c8d; font-weight: bold;">${(item.name || item.productName || 'P')[0].toUpperCase()}</div>`;

      return `
        <tr>
          <td style="display: flex; align-items: center; padding: 12px;">
            ${imageHtml}
            <div>
              <div style="font-weight: 600; margin-bottom: 4px; color: #2c3e50;">${item.name || item.productName}</div>
              <div style="color: #7f8c8d; font-size: 12px;">Unit Price: ₹${unitPrice}</div>
            </div>
          </td>
          <td style="text-align: center; font-weight: 600; color: #3498db;">${item.quantity}</td>
          <td style="text-align: center; color: #7f8c8d;">${item.quantity} × ₹${unitPrice}</td>
          <td style="text-align: right; font-weight: 700; color: #2c3e50;">₹${totalPrice.toFixed(0)}</td>
        </tr>
      `;
    }).join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Order Details - #${order.orderNumber}</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            padding: 20px;
            background: #f5f6fa;
            margin: 0;
          }
          .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(44, 62, 80, 0.08);
            overflow: hidden;
          }
          .header {
            background: #2c3e50;
            color: white;
            padding: 24px;
            text-align: center;
          }
          .content { padding: 24px; }
          .section {
            margin-bottom: 24px;
            background: #ecf0f1;
            padding: 16px;
            border-radius: 6px;
            border-left: 3px solid #3498db;
          }
          .section h3 {
            margin: 0 0 12px 0;
            color: #2c3e50;
            font-size: 16px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
          }
          .info-item {
            background: white;
            padding: 12px;
            border-radius: 4px;
            border: 1px solid #dfe6e9;
          }
          .info-label {
            font-weight: 500;
            color: #7f8c8d;
            font-size: 11px;
            text-transform: uppercase;
            margin-bottom: 4px;
            letter-spacing: 0.5px;
          }
          .info-value {
            color: #2c3e50;
            font-weight: 600;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 6px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(44, 62, 80, 0.08);
          }
          th {
            background: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 500;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
          }
          tr:last-child td {
            border-bottom: none;
          }
          .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          .status-pending { background: rgba(52, 152, 219, 0.15); color: #2980b9; border: 1px solid rgba(52, 152, 219, 0.3); }
          .status-confirmed { background: rgba(52, 152, 219, 0.1); color: #3498db; border: 1px solid #3498db; }
          .status-preparing { background: rgba(41, 128, 185, 0.1); color: #2980b9; border: 1px solid #2980b9; }
          .status-ready { background: rgba(44, 62, 80, 0.1); color: #2c3e50; border: 1px solid #2c3e50; }
          .status-delivered { background: #ecf0f1; color: #7f8c8d; border: 1px solid #dfe6e9; }
          .total-section {
            background: rgba(44, 62, 80, 0.05);
            border: 1px solid rgba(44, 62, 80, 0.1);
            color: #2c3e50;
            padding: 20px;
            border-radius: 6px;
            margin-top: 20px;
          }
          .print-btn {
            background: #2c3e50;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 500;
            margin-top: 20px;
            font-size: 14px;
          }
          .print-btn:hover {
            background: #34495e;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 600;">Order Details</h1>
            <h2 style="margin: 0 0 12px 0; font-size: 16px; font-weight: 400;">Order #${order.orderNumber}</h2>
            <div class="status-badge ${this.getStatusClass(order.status)}">
              ${this.getStatusLabel(order.status)}
            </div>
          </div>

          <div class="content">
            <div class="section">
              <h3>Order Information</h3>
              <div class="info-grid">
                <div class="info-item">
                  <div class="info-label">Order Date</div>
                  <div class="info-value">${new Date(order.createdAt).toLocaleString()}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Method</div>
                  <div class="info-value">${order.paymentMethod === 'CASH_ON_DELIVERY' ? 'Cash on Delivery' : 'Online Payment'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Status</div>
                  <div class="info-value">${order.paymentStatus}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Total Amount</div>
                  <div class="info-value" style="font-size: 18px; font-weight: 700; color: #2c3e50;">₹${order.totalAmount}</div>
                </div>
              </div>
            </div>

            <div class="section">
              <h3>Customer Information</h3>
              <div class="info-grid">
                <div class="info-item">
                  <div class="info-label">Customer Name</div>
                  <div class="info-value">${order.customerName}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Phone Number</div>
                  <div class="info-value">${order.customerPhone || 'Not provided'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Email</div>
                  <div class="info-value">${order.customerEmail || 'Not provided'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Delivery Address</div>
                  <div class="info-value">${order.customerAddress || order.deliveryAddress || 'Not provided'}</div>
                </div>
              </div>
            </div>

            <div class="section">
              <h3>Order Items (${order.items?.length || 0})</h3>
              <table>
                <thead>
                  <tr>
                    <th>Item Details</th>
                    <th style="text-align: center;">Quantity</th>
                    <th style="text-align: center;">Calculation</th>
                    <th style="text-align: right;">Total</th>
                  </tr>
                </thead>
                <tbody>
                  ${itemsHtml}
                </tbody>
              </table>
            </div>

            <div class="total-section">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                  <div style="font-size: 16px; font-weight: 500; color: #7f8c8d;">Order Total</div>
                  <div style="font-size: 12px; color: #95a5a6;">${order.items?.length || 0} items</div>
                </div>
                <div style="font-size: 24px; font-weight: 600; color: #2c3e50;">₹${order.totalAmount}</div>
              </div>
            </div>

            <button class="print-btn" onclick="window.print()">Print Order Details</button>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  getItemIcon(itemName: string): string {
    if (!itemName) return '🍽️';

    const name = itemName.toLowerCase();
    if (name.includes('coffee')) return '☕';
    if (name.includes('tea')) return '🍵';
    if (name.includes('pizza')) return '🍕';
    if (name.includes('burger')) return '🍔';
    if (name.includes('cake')) return '🎂';
    if (name.includes('bread')) return '🍞';
    if (name.includes('milk')) return '🥛';
    if (name.includes('water')) return '💧';
    if (name.includes('juice')) return '🧃';
    if (name.includes('rice')) return '🍚';
    if (name.includes('chicken')) return '🍗';
    if (name.includes('fish')) return '🐟';
    if (name.includes('egg')) return '🥚';
    if (name.includes('fruit')) return '🍎';
    if (name.includes('vegetable')) return '🥕';
    if (name.includes('abc')) return '🥤';
    return '🍽️';
  }

  selectStatusTab(status: string): void {
    this.selectedStatus = status;
    this.applyFilter();
  }

  getOrdersByStatus(status: string): ShopOwnerOrder[] {
    return this.orders.filter(order => order.status === status);
  }

  getImageUrl(imageUrl: string): string {
    return getImageUrlUtil(imageUrl);
  }

  onImageError(event: any): void {
    // Hide the image and show fallback icon when image fails to load
    const imgElement = event.target;
    if (imgElement) {
      imgElement.style.display = 'none';
      // You could also show a fallback icon here
      const container = imgElement.parentElement;
      if (container && !container.querySelector('.fallback-icon')) {
        const fallbackIcon = document.createElement('div');
        fallbackIcon.className = 'item-icon fallback-icon';
        fallbackIcon.textContent = '🍽️'; // Default food icon
        container.appendChild(fallbackIcon);
      }
    }
  }
}