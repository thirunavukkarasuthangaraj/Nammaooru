import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl } from '@angular/forms';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { ShopOwnerOrderService, ShopOwnerOrder } from '../../services/shop-owner-order.service';
import { AssignmentService } from '../../services/assignment.service';

@Component({
  selector: 'app-orders-management',
  templateUrl: './orders-management.component.html',
  styleUrls: ['./orders-management.component.scss']
})
export class OrdersManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Order data
  orders: ShopOwnerOrder[] = [];
  filteredOrders: ShopOwnerOrder[] = [];
  pendingOrders: ShopOwnerOrder[] = [];
  processingOrders: ShopOwnerOrder[] = [];
  todayOrders: ShopOwnerOrder[] = [];
  inProgressOrders: ShopOwnerOrder[] = [];
  
  // Shop ID - should be retrieved from auth service
  shopId = 1;
  
  // Filter controls
  searchTerm = '';
  selectedStatus = '';
  selectedTabIndex = 0;
  startDate: Date | null = null;
  endDate: Date | null = null;
  
  // Pagination
  totalOrders = 0;
  pageSize = 10;

  // Assignment state
  isAssigningPartner = false;

  constructor(
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private orderService: ShopOwnerOrderService,
    private assignmentService: AssignmentService
  ) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.orderService.getShopOrders(this.shopId).subscribe({
      next: (orders) => {
        this.orders = orders;
        this.updateOrderLists();
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        this.snackBar.open('Error loading orders', 'Close', { duration: 3000 });
      }
    });
  }

  updateOrderLists(): void {
    this.filteredOrders = [...this.orders];
    this.pendingOrders = this.orders.filter(o => o.status === 'PENDING');
    this.processingOrders = this.orders.filter(o => o.status === 'CONFIRMED');
    this.todayOrders = this.orders.filter(o => this.isToday(new Date(o.createdAt)));
    this.inProgressOrders = this.orders.filter(o =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(o.status)
    );
    this.totalOrders = this.orders.length;
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

  onTabChange(event: any): void {
    this.selectedTabIndex = event.index;
  }

  acceptOrder(orderId: number): void {
    this.orderService.acceptOrder(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.snackBar.open('Order accepted successfully', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error accepting order:', error);
        this.snackBar.open('Error accepting order', 'Close', { duration: 3000 });
      }
    });
  }

  rejectOrder(orderId: number): void {
    const reason = prompt('Please provide a reason for rejection:');
    if (reason) {
      this.orderService.rejectOrder(orderId, reason).subscribe({
        next: (updatedOrder) => {
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex] = updatedOrder;
            this.updateOrderLists();
          }
          this.snackBar.open('Order rejected', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error rejecting order:', error);
          this.snackBar.open('Error rejecting order', 'Close', { duration: 3000 });
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
        this.snackBar.open('Order marked as ready', 'Close', { duration: 3000 });
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

  quickAccept(orderId: number): void {
    this.acceptOrder(orderId);
  }

  quickReject(orderId: number): void {
    this.rejectOrder(orderId);
  }

  moveToNextStage(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (order) {
      switch (order.status) {
        case 'CONFIRMED':
          this.startPreparing(orderId);
          break;
        case 'PREPARING':
          this.markReady(orderId);
          break;
        case 'READY_FOR_PICKUP':
          this.markPickedUp(orderId);
          break;
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
      case 'READY_FOR_PICKUP': return 'Mark Delivered';
      default: return 'Next Stage';
    }
  }

  viewOrderDetails(orderId: number): void {
    this.snackBar.open('Order details dialog would open here', 'Close', { duration: 3000 });
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
}