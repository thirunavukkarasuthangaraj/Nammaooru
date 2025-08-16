import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { OrderService } from '../../../../core/services/order.service';
import { OrderStatusDialogComponent } from '../order-status-dialog/order-status-dialog.component';

export interface Order {
  id: number;
  orderNumber: string;
  customerName: string;
  shopName: string;
  status: string;
  totalAmount: number;
  createdAt: string;
  itemCount: number;
  paymentStatus: string;
}

@Component({
  selector: 'app-order-list',
  templateUrl: './order-list.component.html',
  styleUrls: ['./order-list.component.scss']
})
export class OrderListComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'status', 'totalAmount', 'createdAt', 'actions'];
  dataSource = new MatTableDataSource<Order>();
  loading = false;
  searchText = '';
  statusFilter = '';
  
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
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadOrders(): void {
    this.loading = true;
    this.orderService.getAllOrders(0, 100).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        this.snackBar.open('Error loading orders', 'Close', { duration: 3000 });
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

  viewOrder(order: Order): void {
    this.router.navigate(['/orders', order.id]);
  }

  updateOrderStatus(order: Order): void {
    const dialogRef = this.dialog.open(OrderStatusDialogComponent, {
      width: '400px',
      data: { 
        orderId: order.id, 
        currentStatus: order.status,
        orderNumber: order.orderNumber
      }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadOrders();
      }
    });
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
}