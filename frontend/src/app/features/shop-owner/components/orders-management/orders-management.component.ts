import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatTabChangeEvent } from '@angular/material/tabs';
import { ShopOwnerOrderService, ShopOwnerOrder } from '../../services/shop-owner-order.service';
import { AssignmentService } from '../../services/assignment.service';
import { AuthService } from '../../../../core/services/auth.service';
import { environment } from '../../../../../environments/environment';

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

  constructor(
    private orderService: ShopOwnerOrderService,
    private assignmentService: AssignmentService,
    private authService: AuthService,
    private snackBar: MatSnackBar,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Check if user is authenticated
    if (!this.authService.isAuthenticated()) {
      console.error('User not authenticated. Redirecting to login...');
      this.router.navigate(['/auth/login']);
      return;
    }

    // Get the current user
    const currentUser = this.authService.getCurrentUser();
    if (currentUser && currentUser.role === 'SHOP_OWNER') {
      // Get shop ID from user or use default
      // In production, this should come from the user's shop association
      this.shopId = 2; // This should be fetched from user's actual shop
    }

    console.log('Current user:', currentUser);
    console.log('Loading orders for shop:', this.shopId);

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
    const order = this.orders.find(o => o.id === orderId);
    if (!order) {
      this.snackBar.open('Order not found', 'Close', { duration: 3000 });
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

    this.snackBar.open(`Order #${order.orderNumber} sent to printer`, 'Close', { duration: 3000 });
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
      const imageHtml = (item.image || item.productImageUrl)
        ? `<img src="${this.getImageUrl(item.image || item.productImageUrl || '')}" alt="${item.name || item.productName}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px; margin-right: 10px;">`
        : `<div style="width: 50px; height: 50px; background: #f0f0f0; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 10px; font-size: 20px;">${this.getItemIcon(item.name || item.productName)}</div>`;

      return `
        <tr>
          <td style="display: flex; align-items: center; padding: 12px;">
            ${imageHtml}
            <div>
              <div style="font-weight: 600; margin-bottom: 4px;">${item.name || item.productName}</div>
              <div style="color: #666; font-size: 12px;">Unit Price: ₹${item.price || item.unitPrice}</div>
            </div>
          </td>
          <td style="text-align: center; font-weight: 600; color: #667eea;">${item.quantity}</td>
          <td style="text-align: center; color: #666;">${item.quantity} × ₹${item.price || item.unitPrice}</td>
          <td style="text-align: right; font-weight: 700; color: #38a169;">₹${(item.quantity * (item.price || item.unitPrice)) | 0}</td>
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
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            margin: 0;
          }
          .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            overflow: hidden;
          }
          .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 24px;
            text-align: center;
          }
          .content { padding: 24px; }
          .section {
            margin-bottom: 24px;
            background: #f8f9fa;
            padding: 16px;
            border-radius: 12px;
            border-left: 4px solid #667eea;
          }
          .section h3 {
            margin: 0 0 12px 0;
            color: #2d3748;
            font-size: 18px;
          }
          .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
          }
          .info-item {
            background: white;
            padding: 12px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
          }
          .info-label {
            font-weight: 600;
            color: #4a5568;
            font-size: 12px;
            text-transform: uppercase;
            margin-bottom: 4px;
          }
          .info-value {
            color: #2d3748;
            font-weight: 500;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
          }
          th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 16px;
            text-align: left;
            font-weight: 600;
          }
          td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
          }
          tr:last-child td {
            border-bottom: none;
          }
          .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
          }
          .status-pending { background: #fed7d7; color: #c53030; }
          .status-confirmed { background: #bee3f8; color: #2b6cb0; }
          .status-preparing { background: #fbb6ce; color: #b83280; }
          .status-ready { background: #c6f6d5; color: #2f855a; }
          .status-delivered { background: #d4edda; color: #155724; }
          .total-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 12px;
            margin-top: 20px;
          }
          .print-btn {
            background: #6b7280;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            margin-top: 20px;
          }
          .print-btn:hover {
            background: #4b5563;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order Details</h1>
            <h2>Order #${order.orderNumber}</h2>
            <div class="status-badge ${this.getStatusClass(order.status)}">
              ${this.getStatusLabel(order.status)}
            </div>
          </div>

          <div class="content">
            <div class="section">
              <h3>📋 Order Information</h3>
              <div class="info-grid">
                <div class="info-item">
                  <div class="info-label">Order Date</div>
                  <div class="info-value">${new Date(order.createdAt).toLocaleString()}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Method</div>
                  <div class="info-value">${order.paymentMethod === 'CASH_ON_DELIVERY' ? '💰 Cash on Delivery' : '💳 Paid Online'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Status</div>
                  <div class="info-value">${order.paymentStatus}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Total Amount</div>
                  <div class="info-value" style="font-size: 18px; font-weight: 700; color: #38a169;">₹${order.totalAmount}</div>
                </div>
              </div>
            </div>

            <div class="section">
              <h3>👤 Customer Information</h3>
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
              <h3>🛍️ Order Items (${order.items?.length || 0} items)</h3>
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
                  <div style="font-size: 18px; font-weight: 600;">Order Total</div>
                  <div style="opacity: 0.9; font-size: 14px;">${order.items?.length || 0} items</div>
                </div>
                <div style="font-size: 32px; font-weight: 800;">₹${order.totalAmount}</div>
              </div>
            </div>

            <button class="print-btn" onclick="window.print()">🖨️ Print Order Details</button>
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
    if (!imageUrl) return '';

    // If the URL already contains http/https, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Construct full URL using backend server URL (without /api)
    const baseUrl = 'http://localhost:8080'; // Direct backend server URL
    return `${baseUrl}${imageUrl}`;
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