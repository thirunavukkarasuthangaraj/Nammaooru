import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { OrderService, OrderResponse } from '../../../../core/services/order.service';
import { OrderStatusDialogComponent } from '../order-status-dialog/order-status-dialog.component';
import Swal from 'sweetalert2';
import { interval, Subscription } from 'rxjs';

@Component({
  selector: 'app-order-list',
  templateUrl: './order-list.component.html',
  styleUrls: ['./order-list.component.scss']
})
export class OrderListComponent implements OnInit, OnDestroy {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'status', 'paymentStatus', 'totalAmount', 'createdAt', 'actions'];
  dataSource = new MatTableDataSource<OrderResponse>();
  loading = false;
  searchText = '';
  statusFilter = '';
  totalOrders = 0;
  pageSize = 10;
  currentPage = 0;
  
  // Real-time updates
  autoRefreshEnabled = true;
  refreshInterval = 60000; // 60 seconds for orders
  private refreshSubscription?: Subscription;
  
  statusOptions = [
    { value: '', label: 'All Statuses' },
    { value: 'PENDING', label: 'Pending' },
    { value: 'CONFIRMED', label: 'Confirmed' },
    { value: 'PREPARING', label: 'Preparing' },
    { value: 'READY_FOR_PICKUP', label: 'Ready for Pickup' },
    { value: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
    { value: 'DELIVERED', label: 'Delivered' },
    { value: 'CANCELLED', label: 'Cancelled' }
  ];

  constructor(
    private orderService: OrderService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadOrders();
    this.startAutoRefresh();
  }

  ngOnDestroy(): void {
    this.stopAutoRefresh();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadOrders(): void {
    this.loading = true;
    this.orderService.getAllOrders(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.totalOrders = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load orders. Please try again.',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.loading = false;
      }
    });
  }

  applyFilter(): void {
    let filteredData = this.dataSource.data;

    if (this.searchText) {
      filteredData = filteredData.filter(order =>
        order.orderNumber.toLowerCase().includes(this.searchText.toLowerCase()) ||
        order.customerName.toLowerCase().includes(this.searchText.toLowerCase()) ||
        order.shopName.toLowerCase().includes(this.searchText.toLowerCase())
      );
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(order => order.status === this.statusFilter);
    }

    this.dataSource.data = filteredData;
  }

  clearFilters(): void {
    this.searchText = '';
    this.statusFilter = '';
    this.loadOrders();
  }

  viewOrder(order: OrderResponse): void {
    this.router.navigate(['/orders', order.id]);
  }

  updateOrderStatus(order: OrderResponse): void {
    Swal.fire({
      title: 'Update Order Status',
      input: 'select',
      inputOptions: {
        'PENDING': 'Pending',
        'CONFIRMED': 'Confirmed',
        'PREPARING': 'Preparing',
        'READY_FOR_PICKUP': 'Ready for Pickup',
        'OUT_FOR_DELIVERY': 'Out for Delivery',
        'DELIVERED': 'Delivered',
        'CANCELLED': 'Cancelled'
      },
      inputValue: order.status,
      showCancelButton: true,
      confirmButtonText: 'Update',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value !== order.status) {
        this.orderService.updateOrderStatus(order.id, result.value).subscribe({
          next: () => {
            Swal.fire('Success!', 'Order status updated successfully', 'success');
            this.loadOrders();
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to update order status', 'error');
          }
        });
      }
    });
  }

  cancelOrder(order: OrderResponse): void {
    Swal.fire({
      title: 'Cancel Order',
      text: 'Please provide a reason for cancellation:',
      input: 'textarea',
      inputPlaceholder: 'Cancellation reason...',
      showCancelButton: true,
      confirmButtonText: 'Cancel Order',
      cancelButtonText: 'Close',
      confirmButtonColor: '#d33'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.orderService.cancelOrder(order.id, result.value).subscribe({
          next: () => {
            Swal.fire('Success!', 'Order cancelled successfully', 'success');
            this.loadOrders();
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to cancel order', 'error');
          }
        });
      }
    });
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadOrders();
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return 'warn';
      case 'CONFIRMED': return 'primary';
      case 'PREPARING': return 'primary';
      case 'READY_FOR_PICKUP': return 'accent';
      case 'OUT_FOR_DELIVERY': return 'accent';
      case 'DELIVERED': return 'primary';
      case 'CANCELLED': return 'warn';
      default: return '';
    }
  }

  getPaymentStatusColor(status: string): string {
    switch (status) {
      case 'PAID': return 'primary';
      case 'PENDING': return 'warn';
      case 'FAILED': return 'warn';
      case 'REFUNDED': return 'accent';
      default: return '';
    }
  }

  startAutoRefresh(): void {
    if (this.autoRefreshEnabled && !this.refreshSubscription) {
      this.refreshSubscription = interval(this.refreshInterval).subscribe(() => {
        this.loadOrdersQuietly();
      });
    }
  }

  stopAutoRefresh(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
      this.refreshSubscription = undefined;
    }
  }

  loadOrdersQuietly(): void {
    // Load orders without showing loading indicator for background refresh
    this.orderService.getAllOrders(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const currentOrderCount = this.dataSource.data.length;
        const newOrderCount = response.content.length;
        
        this.dataSource.data = response.content;
        this.totalOrders = response.totalElements;
        
        // Show toast if new orders arrived
        if (newOrderCount > currentOrderCount) {
          const newItems = newOrderCount - currentOrderCount;
          Swal.fire({
            title: 'New Orders',
            text: `${newItems} new order${newItems > 1 ? 's' : ''} received.`,
            icon: 'info',
            timer: 3000,
            showConfirmButton: false,
            position: 'top-end',
            toast: true
          });
        }
      },
      error: (error) => {
        console.error('Error loading orders quietly:', error);
        // Don't show error message for background refresh failures
      }
    });
  }

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    
    if (this.autoRefreshEnabled) {
      this.startAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Enabled',
        text: `Orders will refresh every ${this.refreshInterval / 1000} seconds.`,
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    } else {
      this.stopAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Disabled',
        text: 'Orders will no longer refresh automatically.',
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    }
  }
}