import { Component, OnInit } from '@angular/core';
import { ShopPaymentsService, ShopBalanceRow } from '../../services/shop-payments.service';
import { SwalService } from '../../../../core/services/swal.service';

type StatusTab = 'PAID' | 'PENDING' | 'FAILED' | 'REFUNDED' | 'ALL';

interface OrderPaymentRow {
  orderId: number;
  orderNumber: string;
  paymentMethod: string;
  subtotal: number;
  taxAmount: number;
  deliveryFee: number;
  totalAmount: number;
  orderStatus: string;
  paymentStatus: string;
  createdAt: string;
  isOnline: boolean;
  razorpayMdr: number;
  gstOnGatewayFee: number;
  totalGatewayFee: number;
  customerPaid: number;
  gatewayStatus: string | null;
}

@Component({
  selector: 'app-shop-payments',
  templateUrl: './shop-payments.component.html',
  styleUrls: ['./shop-payments.component.scss']
})
export class ShopPaymentsComponent implements OnInit {
  private static readonly SUCCESS_CODE = '0000';
  private static readonly FETCH_SIZE = 1000;

  shops: ShopBalanceRow[] = [];
  filteredShops: ShopBalanceRow[] = [];
  shopSearch = '';
  isLoadingShops = false;

  selectedShop: ShopBalanceRow | null = null;
  summary: any = null;
  private allOrders: OrderPaymentRow[] = [];
  pagedOrders: OrderPaymentRow[] = [];

  displayedColumns = [
    'select', 'orderNumber', 'method', 'subtotal', 'taxAmount', 'deliveryFee', 'youReceive',
    'razorpayMdr', 'gstOnGatewayFee', 'status', 'createdAt'
  ];

  isDateRangeExpanded = false;
  selectedOrderIds = new Set<number>();
  releaseReferenceInput = '';
  isReleasing = false;

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
    private shopPaymentsService: ShopPaymentsService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadShops();
  }

  private todayIso(): string {
    return new Date().toISOString().substring(0, 10);
  }

  private daysAgoIso(days: number): string {
    const d = new Date();
    d.setDate(d.getDate() - days);
    return d.toISOString().substring(0, 10);
  }

  loadShops(): void {
    this.isLoadingShops = true;
    this.shopPaymentsService.getShopsSummary().subscribe({
      next: (response) => {
        if (response.statusCode === ShopPaymentsComponent.SUCCESS_CODE) {
          this.shops = (response.data?.content || []).sort((a: ShopBalanceRow, b: ShopBalanceRow) => b.balance - a.balance);
          this.filteredShops = this.shops;
        } else {
          this.swal.toast(response.message || 'Failed to load shops', 'error');
        }
        this.isLoadingShops = false;
      },
      error: (error) => {
        console.error('Error loading shops:', error);
        this.swal.toast('Error loading shops', 'error');
        this.isLoadingShops = false;
      }
    });
  }

  onShopSearch(): void {
    const q = this.shopSearch.trim().toLowerCase();
    this.filteredShops = !q ? this.shops : this.shops.filter((s) => s.shopName.toLowerCase().includes(q));
  }

  selectShop(shop: ShopBalanceRow): void {
    this.selectedShop = shop;
    this.selectedDate = this.todayIso();
    this.rangeStart = this.daysAgoIso(30);
    this.rangeEnd = this.todayIso();
    this.selectedTab = 'PAID';
    this.currentPage = 0;
    this.selectedOrderIds.clear();
    this.releaseReferenceInput = '';
    this.loadSummary();
    this.loadOrders();
  }

  backToList(): void {
    this.selectedShop = null;
    this.summary = null;
  }

  loadSummary(): void {
    if (!this.selectedShop) return;
    this.isLoadingSummary = true;
    this.shopPaymentsService.getShopSummary(this.selectedShop.shopId, this.selectedDate).subscribe({
      next: (response) => {
        if (response.statusCode === ShopPaymentsComponent.SUCCESS_CODE) {
          this.summary = response.data;
        } else {
          this.swal.toast(response.message || 'Failed to load summary', 'error');
        }
        this.isLoadingSummary = false;
      },
      error: (error) => {
        console.error('Error loading summary:', error);
        this.swal.toast('Error loading summary', 'error');
        this.isLoadingSummary = false;
      }
    });
  }

  loadOrders(): void {
    if (!this.selectedShop) return;
    this.isLoadingOrders = true;
    this.shopPaymentsService.getShopOrders(this.selectedShop.shopId, this.rangeStart, this.rangeEnd, 0, ShopPaymentsComponent.FETCH_SIZE).subscribe({
      next: (response) => {
        if (response.statusCode === ShopPaymentsComponent.SUCCESS_CODE) {
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
    this.selectedOrderIds.clear();
    this.loadOrders();
  }

  toggleDateRange(): void {
    this.isDateRangeExpanded = !this.isDateRangeExpanded;
  }

  isSelectable(row: OrderPaymentRow): boolean {
    // Only online, actually-PAID orders contributed to the wallet balance - COD and
    // pending/failed rows have nothing to "release" against.
    return row.isOnline && this.statusFor(row) === 'PAID';
  }

  isSelected(row: OrderPaymentRow): boolean {
    return this.selectedOrderIds.has(row.orderId);
  }

  toggleRowSelection(row: OrderPaymentRow): void {
    if (!this.isSelectable(row)) return;
    if (this.selectedOrderIds.has(row.orderId)) {
      this.selectedOrderIds.delete(row.orderId);
    } else {
      this.selectedOrderIds.add(row.orderId);
    }
  }

  get selectableRowsOnPage(): OrderPaymentRow[] {
    return this.pagedOrders.filter((r) => this.isSelectable(r));
  }

  get isAllOnPageSelected(): boolean {
    const selectable = this.selectableRowsOnPage;
    return selectable.length > 0 && selectable.every((r) => this.selectedOrderIds.has(r.orderId));
  }

  toggleSelectAllOnPage(): void {
    if (this.isAllOnPageSelected) {
      this.selectableRowsOnPage.forEach((r) => this.selectedOrderIds.delete(r.orderId));
    } else {
      this.selectableRowsOnPage.forEach((r) => this.selectedOrderIds.add(r.orderId));
    }
  }

  get selectedTotal(): number {
    return this.allOrders
      .filter((r) => this.selectedOrderIds.has(r.orderId))
      .reduce((sum, r) => sum + r.totalAmount, 0);
  }

  releaseSelectedPayment(): void {
    if (!this.selectedShop || this.selectedOrderIds.size === 0) return;
    this.doRelease(this.selectedTotal);
  }

  releaseFullBalance(): void {
    if (!this.selectedShop || !this.summary || this.summary.walletBalance <= 0) return;
    this.doRelease(undefined);
  }

  private doRelease(amount: number | undefined): void {
    const reference = this.releaseReferenceInput.trim();
    if (!reference) {
      this.swal.toast('Enter the UTR / transaction reference first', 'warning');
      return;
    }
    if (!this.selectedShop) return;
    this.isReleasing = true;
    this.shopPaymentsService.releasePayment(this.selectedShop.shopId, reference, amount).subscribe({
      next: (response) => {
        this.isReleasing = false;
        if (response.statusCode === ShopPaymentsComponent.SUCCESS_CODE) {
          this.swal.toast(`Payment released to ${this.selectedShop!.shopName}`, 'success');
          this.selectedOrderIds.clear();
          this.releaseReferenceInput = '';
          this.loadSummary();
        } else {
          this.swal.toast(response.message || 'Failed to release payment', 'error');
        }
      },
      error: (error) => {
        this.isReleasing = false;
        console.error('Error releasing payment:', error);
        this.swal.toast(error?.error?.message || 'Error releasing payment', 'error');
      }
    });
  }

  // Deep-links into whatever UPI app is installed with the amount and payee
  // pre-filled - the admin still taps to confirm and send from their own account.
  payViaUpi(amount: number): void {
    if (!this.summary?.upiId || !this.selectedShop) return;
    const params = new URLSearchParams({
      pa: this.summary.upiId,
      pn: this.selectedShop.shopName,
      am: amount.toFixed(2),
      cu: 'INR',
      tn: `Nammaooru payout - ${this.selectedShop.shopName}`
    });
    window.open(`upi://pay?${params.toString()}`, '_blank');
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
