import { Component, OnInit } from '@angular/core';
import { PaymentsService, PaymentSummary, OrderPaymentRow } from '../../services/payments.service';
import { SwalService } from '../../../../core/services/swal.service';

type StatusTab = 'PAID' | 'PENDING' | 'FAILED' | 'REFUNDED' | 'ALL';

@Component({
  selector: 'app-payments',
  templateUrl: './payments.component.html',
  styleUrls: ['./payments.component.scss']
})
export class PaymentsComponent implements OnInit {
  private static readonly SUCCESS_CODE = '0000';
  // Fetched once per date range and filtered/paginated client-side - a single
  // shop's order volume in a 30-day window is small enough that this is
  // simpler and faster than round-tripping the server on every tab click.
  private static readonly FETCH_SIZE = 1000;

  summary: PaymentSummary | null = null;
  private allOrders: OrderPaymentRow[] = [];
  pagedOrders: OrderPaymentRow[] = [];

  displayedColumns = [
    'orderNumber', 'method', 'subtotal', 'taxAmount', 'deliveryFee', 'youReceive',
    'razorpayMdr', 'gstOnGatewayFee', 'status', 'createdAt'
  ];

  statusTabs: { key: StatusTab; label: string }[] = [
    { key: 'PAID', label: 'Paid' },
    { key: 'PENDING', label: 'Pending' },
    { key: 'FAILED', label: 'Failed / Cancelled' },
    { key: 'REFUNDED', label: 'Refunded' },
    { key: 'ALL', label: 'All' }
  ];
  selectedTab: StatusTab = 'PAID';

  selectedDate: string = this.todayIso();
  rangeStart: string = this.daysAgoIso(30);
  rangeEnd: string = this.todayIso();

  isLoadingSummary = false;
  isLoadingOrders = false;

  currentPage = 0;
  pageSize = 20;

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
    this.paymentsService.getOrders(this.rangeStart, this.rangeEnd, 0, PaymentsComponent.FETCH_SIZE).subscribe({
      next: (response) => {
        if (response.statusCode === PaymentsComponent.SUCCESS_CODE) {
          this.allOrders = response.data?.content || [];
          this.currentPage = 0;
          this.applyFilter();
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

  private applyFilter(): void {
    const start = this.currentPage * this.pageSize;
    this.pagedOrders = this.filteredOrders.slice(start, start + this.pageSize);
  }

  get filteredOrders(): OrderPaymentRow[] {
    if (this.selectedTab === 'ALL') return this.allOrders;
    return this.allOrders.filter((row) => this.statusBucket(this.statusFor(row)) === this.selectedTab);
  }

  get filteredCount(): number {
    return this.filteredOrders.length;
  }

  tabCount(tab: StatusTab): number {
    if (tab === 'ALL') return this.allOrders.length;
    return this.allOrders.filter((row) => this.statusBucket(this.statusFor(row)) === tab).length;
  }

  selectTab(tab: StatusTab): void {
    this.selectedTab = tab;
    this.currentPage = 0;
    this.applyFilter();
  }

  onDateChange(): void {
    this.loadSummary();
  }

  onRangeChange(): void {
    this.loadOrders();
  }

  onPageChange(event: { pageIndex: number; pageSize: number }): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.applyFilter();
  }

  methodLabel(row: OrderPaymentRow): string {
    return row.isOnline ? 'UPI / Online' : 'Cash on Delivery';
  }

  methodClass(row: OrderPaymentRow): string {
    return row.isOnline ? 'method-online' : 'method-cod';
  }

  statusFor(row: OrderPaymentRow): string {
    // The order itself always wins over the payment record's status - a customer
    // backing out of Razorpay checkout cancels the ORDER (via cancelOrder()), but
    // the payment record just stays CREATED forever since payment was never
    // attempted. Without this, an abandoned checkout shows as "Awaiting Payment"
    // (Pending) instead of Cancelled, which is what actually happened.
    if (row.orderStatus === 'CANCELLED') return 'CANCELLED';
    return row.isOnline ? (row.gatewayStatus || 'CREATED') : row.orderStatus;
  }

  private statusBucket(status: string): StatusTab {
    switch (status) {
      case 'PAID':
      case 'DELIVERED':
      case 'COMPLETED':
      case 'SELF_PICKUP_COLLECTED':
        return 'PAID';
      case 'FAILED':
      case 'CANCELLED':
        return 'FAILED';
      case 'REFUNDED':
      case 'PARTIALLY_REFUNDED':
        return 'REFUNDED';
      default:
        return 'PENDING';
    }
  }

  statusClass(status: string): string {
    const bucket = this.statusBucket(status);
    switch (bucket) {
      case 'PAID': return 'status-paid';
      case 'FAILED': return 'status-failed';
      case 'REFUNDED': return 'status-refunded';
      default: return 'status-pending';
    }
  }

  statusLabel(status: string): string {
    const labels: Record<string, string> = {
      PAID: 'Paid',
      CREATED: 'Awaiting Payment',
      FAILED: 'Failed',
      REFUNDED: 'Refunded',
      PARTIALLY_REFUNDED: 'Partially Refunded',
      DELIVERED: 'Delivered',
      COMPLETED: 'Completed',
      SELF_PICKUP_COLLECTED: 'Picked Up',
      CANCELLED: 'Cancelled',
      PENDING: 'Pending',
      CONFIRMED: 'Confirmed',
      PREPARING: 'Preparing',
      READY: 'Ready',
      READY_FOR_PICKUP: 'Ready for Pickup',
      OUT_FOR_DELIVERY: 'Out for Delivery',
      RETURNING_TO_SHOP: 'Returning to Shop',
      RETURNED_TO_SHOP: 'Returned to Shop'
    };
    return labels[status] || status || 'Pending';
  }

  // Backend LocalDateTime values serialize without timezone info, which the
  // Angular `date` pipe then reads as if it were already browser-local time -
  // since the server stores wall-clock UTC, that showed times 5:30h behind
  // actual IST (matches orders-management.component.ts's same fix).
  formatDateTime(dateString: string): string {
    if (!dateString) return '';
    const hasTimezone = dateString.endsWith('Z') ||
                        /[+-]\d{2}:\d{2}$/.test(dateString) ||
                        /[+-]\d{4}$/.test(dateString);
    const d = hasTimezone ? new Date(dateString) : new Date(dateString + 'Z');
    return d.toLocaleString('en-IN', {
      timeZone: 'Asia/Kolkata',
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  }
}
