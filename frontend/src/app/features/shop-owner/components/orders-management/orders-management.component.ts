import { Component, OnInit } from '@angular/core';
import { ShopOwnerOrderService, ShopOwnerOrder } from '../../services/shop-owner-order.service';
import { AssignmentService } from '../../services/assignment.service';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-orders-management',
  templateUrl: './orders-management.component.html',
  styleUrls: ['./orders-management.component.scss']
})
export class OrdersManagementComponent implements OnInit {

  // Order data
  orders: ShopOwnerOrder[] = [];
  filteredOrders: ShopOwnerOrder[] = [];
  pendingOrders: ShopOwnerOrder[] = [];
  processingOrders: ShopOwnerOrder[] = [];
  activeOrders: ShopOwnerOrder[] = [];
  completedOrders: ShopOwnerOrder[] = [];
  todayOrders: ShopOwnerOrder[] = [];
  inProgressOrders: ShopOwnerOrder[] = [];

  // Shop ID - should be retrieved from auth service
  shopId = 2; // Changed to match the shop ID in the database

  // Filter controls
  searchTerm = '';
  selectedStatus = '';
  selectedTabIndex = 0;
  startDate: Date | null = null;
  endDate: Date | null = null;

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

  constructor(
    private orderService: ShopOwnerOrderService,
    private assignmentService: AssignmentService,
    private authService: AuthService
  ) {}

  // Temporary method to manually set token for testing
  public setTestToken(): void {
    const testToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0aGlydTI3OCIsImV4cCI6MTc1ODAwMzY1MCwiaWF0IjoxNzU3OTE3MjUwfQ.JKSEk9skIGXFzAsZrbfhzhYSeArqYgg9Swvvet2Nzbo';
    localStorage.setItem('shop_management_token', testToken);
    localStorage.setItem('token', testToken); // Fallback key
    console.log('Test token set in localStorage');
  }

  ngOnInit(): void {
    // Set token for testing purposes
    this.setTestToken();

    // Debug: Check token and authentication status
    console.log('Token in localStorage:', localStorage.getItem('shop_management_token'));
    console.log('Auth service token:', this.authService.getToken());
    console.log('Is authenticated:', this.authService.isAuthenticated());

    this.loadDashboardData();
  }

  loadDashboardData(): void {
    console.log('Loading dashboard data...');

    // Load all orders first, then calculate statistics from them
    this.loadOrders();
  }

  loadOrders(): void {
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
          this.snackBar.open('Authentication required. Please login to view orders.', 'Close', { duration: 5000 });
        } else {
          this.snackBar.open('Error loading orders. Please try again.', 'Close', { duration: 3000 });
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

    // Calculate TODAY's revenue
    const today = new Date();
    const todayDeliveredOrders = allDeliveredOrders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate.toDateString() === today.toDateString();
    });

    // Today's revenue from today's delivered orders
    this.todayRevenue = todayDeliveredOrders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);

    // If no revenue today, calculate from all active orders today
    if (this.todayRevenue === 0) {
      const allTodayOrders = this.orders.filter(order => {
        const orderDate = new Date(order.createdAt);
        return orderDate.toDateString() === today.toDateString();
      });
      this.todayRevenue = allTodayOrders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
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
      
      return matchesSearch && matchesStatus;
    });
  }

  onTabChange(event: MatTabChangeEvent): void {
    this.selectedTabIndex = event.index;
  }

  acceptOrder(order: ShopOwnerOrder): void {
    this.orderService.acceptOrder(order.id).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === order.id);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
          this.applyFilter();
        }
        this.successMessage = 'Order accepted successfully';
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (error) => {
        console.error('Error accepting order:', error);
        this.errorMessage = 'Error accepting order';
        setTimeout(() => this.errorMessage = '', 3000);
      }
    });
  }

  rejectOrder(order: ShopOwnerOrder): void {
    const reason = prompt('Please provide a reason for rejection:');
    if (reason) {
      this.orderService.rejectOrder(order.id, reason).subscribe({
        next: (updatedOrder) => {
          const orderIndex = this.orders.findIndex(o => o.id === order.id);
          if (orderIndex !== -1) {
            this.orders[orderIndex] = updatedOrder;
            this.updateOrderLists();
            this.applyFilter();
          }
          this.successMessage = 'Order rejected';
          setTimeout(() => this.successMessage = '', 3000);
        },
        error: (error) => {
          console.error('Error rejecting order:', error);
          this.errorMessage = 'Error rejecting order';
          setTimeout(() => this.errorMessage = '', 3000);
        }
      });
    }
  }

  startPreparing(orderId: number): void {
    this.orderService.startPreparing(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.snackBar.open('Order preparation started', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error starting preparation:', error);
        this.snackBar.open('Error starting preparation', 'Close', { duration: 3000 });
      }
    });
  }

  markReady(orderId: number): void {
    this.orderService.markReady(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.snackBar.open('Order marked as ready for pickup and auto-assigned to delivery partner', 'Close', { duration: 5000 });
      },
      error: (error) => {
        console.error('Error marking ready:', error);
        this.snackBar.open('Error marking ready', 'Close', { duration: 3000 });
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
        this.snackBar.open('Order marked as delivered', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error marking delivered:', error);
        this.snackBar.open('Error marking delivered', 'Close', { duration: 3000 });
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
    this.snackBar.open('Order printed successfully', 'Close', { duration: 3000 });
  }

  viewCustomer(customerId: number): void {
    this.snackBar.open('Customer details dialog would open here', 'Close', { duration: 3000 });
  }

  refundOrder(orderId: number): void {
    this.snackBar.open('Refund process initiated', 'Close', { duration: 3000 });
  }

  reportIssue(orderId: number): void {
    this.snackBar.open('Issue reporting dialog would open here', 'Close', { duration: 3000 });
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

          this.snackBar.open(
            `Order assigned to ${response.assignment.deliveryPartner.name}`,
            'Close',
            { duration: 5000 }
          );
        } else {
          this.snackBar.open(response.message || 'Failed to assign delivery partner', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        this.isAssigningPartner = false;
        console.error('Error assigning delivery partner:', error);
        this.snackBar.open('Error assigning delivery partner', 'Close', { duration: 3000 });
      }
    });
  }

  onPageChange(event: any): void {
    // Handle pagination
  }

  verifyDriver(orderId: number, verificationCode: string): void {
    if (!verificationCode || verificationCode.length < 4) {
      this.snackBar.open('Please enter a valid verification code', 'Close', { duration: 3000 });
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

          this.snackBar.open('Driver verified successfully! Order can be handed over.', 'Close', {
            duration: 5000,
            panelClass: ['success-snackbar']
          });

          // Clear the verification code
          delete this.verificationCodes[orderId];
        } else {
          this.snackBar.open(response.message || 'Invalid verification code', 'Close', {
            duration: 3000,
            panelClass: ['error-snackbar']
          });
        }
      },
      error: (error) => {
        console.error('Error verifying driver:', error);
        this.snackBar.open('Error verifying driver. Please try again.', 'Close', {
          duration: 3000,
          panelClass: ['error-snackbar']
        });
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
    // Navigate to delivery management screen
    this.snackBar.open('Navigate to delivery management', 'Close', { duration: 3000 });
  }

  viewOrderDetails(order: ShopOwnerOrder): void {
    // View order details - could open a modal or navigate to details page
    this.successMessage = `Viewing details for Order #${order.orderNumber}`;
    setTimeout(() => this.successMessage = '', 3000);
  }
}