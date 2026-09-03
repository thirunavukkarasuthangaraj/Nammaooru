import { Component, OnInit } from '@angular/core';
import { PaymentsService, PaymentSummary, OrderPaymentRow } from '../../services/payments.service';
import { SwalService } from '../../../../core/services/swal.service';

@Component({
  selector: 'app-payments',
  templateUrl: './payments.component.html',
  styleUrls: ['./payments.component.scss']
})
export class PaymentsComponent implements OnInit {
  private static readonly SUCCESS_CODE = '0000';

  summary: PaymentSummary | null = null;
  orders: OrderPaymentRow[] = [];
  displayedColumns = [
    'orderNumber', 'method', 'subtotal', 'taxAmount', 'deliveryFee', 'youReceive',
    'razorpayMdr', 'gstOnGatewayFee', 'status', 'createdAt'
  ];

  selectedDate: string = this.todayIso();
  rangeStart: string = this.daysAgoIso(30);
  rangeEnd: string = this.todayIso();

  isLoadingSummary = false;
  isLoadingOrders = false;

  currentPage = 0;
  pageSize = 20;
  totalOrders = 0;

  constructor(
    private paymentsService: PaymentsService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadSummary();
    this.loadOrders();
  }

  private todayIso(): string {
    return new Date().toISOString().substring(0, 10);
  }

  private daysAgoIso(days: number): string {
    const d = new Date();
    d.setDate(d.getDate() - days);
    return d.toISOString().substring(0, 10);
  }

  loadSummary(): void {
    this.isLoadingSummary = true;
    this.paymentsService.getSummary(this.selectedDate).subscribe({
      next: (response) => {
        if (response.statusCode === PaymentsComponent.SUCCESS_CODE) {
          this.summary = response.data;
        } else {
          this.swal.toast(response.message || 'Failed to load payment summary', 'error');
        }
        this.isLoadingSummary = false;
      },
      error: (error) => {
        console.error('Error loading payment summary:', error);
        this.swal.toast('Error loading payment summary', 'error');
        this.isLoadingSummary = false;
      }
    });
  }

  loadOrders(): void {
    this.isLoadingOrders = true;
    this.paymentsService.getOrders(this.rangeStart, this.rangeEnd, this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        if (response.statusCode === PaymentsComponent.SUCCESS_CODE) {
          this.orders = response.data?.content || [];
          this.totalOrders = response.data?.totalItems ?? this.orders.length;
        } else {
          this.swal.toast(response.message || 'Failed to load orders', 'error');
        }
        this.isLoadingOrders = false;
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        this.swal.toast('Error loading orders', 'error');
        this.isLoadingOrders = false;
      }
    });
  }

  onDateChange(): void {
    this.loadSummary();
  }

  onRangeChange(): void {
    this.currentPage = 0;
    this.loadOrders();
  }

  onPageChange(event: { pageIndex: number; pageSize: number }): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadOrders();
  }

  methodLabel(row: OrderPaymentRow): string {
    return row.isOnline ? 'UPI / Online' : 'Cash on Delivery';
  }

  methodClass(row: OrderPaymentRow): string {
    return row.isOnline ? 'method-online' : 'method-cod';
  }

  statusFor(row: OrderPaymentRow): string {
    return row.isOnline ? (row.gatewayStatus || 'PENDING') : row.orderStatus;
  }

  statusClass(status: string): string {
    switch (status) {
      case 'PAID':
      case 'DELIVERED':
      case 'COMPLETED': return 'status-paid';
      case 'FAILED':
      case 'CANCELLED': return 'status-failed';
      case 'REFUNDED':
      case 'PARTIALLY_REFUNDED': return 'status-refunded';
      default: return 'status-pending';
    }
  }

  statusLabel(status: string): string {
    switch (status) {
      case 'PAID': return 'Paid';
      case 'FAILED': return 'Failed';
      case 'REFUNDED': return 'Refunded';
      case 'PARTIALLY_REFUNDED': return 'Partially Refunded';
      case 'DELIVERED': return 'Delivered';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default: return status ? (status.charAt(0) + status.slice(1).toLowerCase()) : 'Pending';
    }
  }
}
