import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router } from '@angular/router';
import { OrderService, OrderResponse } from '../../../../core/services/order.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-order-issues',
  templateUrl: './order-issues.component.html',
  styleUrls: ['./order-issues.component.scss']
})
export class OrderIssuesComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'status', 'paymentStatus', 'totalAmount', 'createdAt', 'actions'];
  dataSource = new MatTableDataSource<OrderResponse>();
  loading = false;
  totalOrders = 0;
  pageSize = 10;
  currentPage = 0;
  activeTab = 'CANCELLED';

  issueTypes = [
    { value: 'CANCELLED', label: 'Cancelled Orders', icon: 'cancel', color: '#f44336' },
    { value: 'FAILED', label: 'Failed Payments', icon: 'payment', color: '#ff9800' },
    { value: 'REFUNDED', label: 'Refunded Orders', icon: 'money_off', color: '#9c27b0' }
  ];

  constructor(
    private orderService: OrderService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadIssueOrders();
  }

  ngAfterViewInit(): void {
    this.dataSource.sort = this.sort;
  }

  loadIssueOrders(): void {
    this.loading = true;

    if (this.activeTab === 'FAILED' || this.activeTab === 'REFUNDED') {
      // Load all orders and filter by payment status
      this.orderService.getAllOrders(this.currentPage, this.pageSize).subscribe({
        next: (response) => {
          const orders = response.data?.content || [];
          this.dataSource.data = orders.filter(
            (o: OrderResponse) => o.paymentStatus === this.activeTab
          );
          this.totalOrders = this.dataSource.data.length;
          this.loading = false;
        },
        error: () => {
          this.dataSource.data = [];
          this.totalOrders = 0;
          this.loading = false;
        }
      });
    } else {
      // Load by order status (CANCELLED)
      this.orderService.getOrdersByStatus(this.activeTab, this.currentPage, this.pageSize).subscribe({
        next: (response) => {
          const data = response.data || response;
          this.dataSource.data = (data as any).content || [];
          this.totalOrders = (data as any).totalElements || this.dataSource.data.length;
          this.loading = false;
        },
        error: () => {
          this.dataSource.data = [];
          this.totalOrders = 0;
          this.loading = false;
        }
      });
    }
  }

  onTabChange(tab: string): void {
    this.activeTab = tab;
    this.currentPage = 0;
    this.loadIssueOrders();
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadIssueOrders();
  }

  viewOrder(order: OrderResponse): void {
    this.router.navigate(['/orders', order.id]);
  }

  formatStatus(status: string): string {
    if (!status) return '';
    return status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'CANCELLED': return 'warn';
      case 'PENDING': return 'warn';
      case 'CONFIRMED': return 'primary';
      case 'DELIVERED': return 'primary';
      case 'COMPLETED': return 'primary';
      case 'SELF_PICKUP_COLLECTED': return 'primary';
      default: return 'accent';
    }
  }

  getPaymentStatusColor(status: string): string {
    switch (status) {
      case 'PAID': return 'primary';
      case 'PENDING': return 'warn';
      case 'FAILED': return 'warn';
      case 'REFUNDED': return 'accent';
      case 'COLLECTED': return 'primary';
      default: return '';
    }
  }

  goBack(): void {
    this.router.navigate(['/orders']);
  }
}
