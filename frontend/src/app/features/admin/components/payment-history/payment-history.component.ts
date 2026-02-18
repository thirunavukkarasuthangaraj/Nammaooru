import { Component, OnInit, ViewChild } from '@angular/core';
import { MatPaginator, PageEvent } from '@angular/material/paginator';
import { PaymentService } from '../../services/payment.service';

@Component({
  selector: 'app-payment-history',
  templateUrl: './payment-history.component.html',
  styleUrls: ['./payment-history.component.scss']
})
export class PaymentHistoryComponent implements OnInit {
  // Stats
  totalCollected = 0;
  baseAmountCollected = 0;
  processingFeeCollected = 0;
  successfulPayments = 0;
  failedPayments = 0;
  pendingPayments = 0;
  razorpayFee = 0;
  gstOnFee = 0;
  netAmount = 0;
  byPostType: { [key: string]: number } = {};

  // Payments table
  payments: any[] = [];
  totalElements = 0;
  pageSize = 20;
  pageIndex = 0;
  displayedColumns: string[] = ['id', 'user', 'postType', 'amount', 'processingFee', 'totalAmount', 'status', 'createdAt', 'paidAt'];

  // Loading states
  statsLoading = true;
  paymentsLoading = true;

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.loadStats();
    this.loadPayments();
  }

  loadStats(): void {
    this.statsLoading = true;
    this.paymentService.getStats().subscribe({
      next: (response: any) => {
        const data = response.data || response;
        this.totalCollected = data.totalCollected || 0;
        this.baseAmountCollected = data.baseAmountCollected || 0;
        this.processingFeeCollected = data.processingFeeCollected || 0;
        this.successfulPayments = data.successfulPayments || 0;
        this.failedPayments = data.failedPayments || 0;
        this.pendingPayments = data.pendingPayments || 0;
        this.razorpayFee = data.razorpayFee || 0;
        this.gstOnFee = data.gstOnFee || 0;
        this.netAmount = data.netAmount || 0;
        this.byPostType = data.byPostType || {};
        this.statsLoading = false;
      },
      error: () => {
        this.statsLoading = false;
      }
    });
  }

  loadPayments(): void {
    this.paymentsLoading = true;
    this.paymentService.getAllPayments(this.pageIndex, this.pageSize).subscribe({
      next: (response: any) => {
        const data = response.data || response;
        this.payments = data.content || data || [];
        this.totalElements = data.totalElements || this.payments.length;
        this.paymentsLoading = false;
      },
      error: () => {
        this.paymentsLoading = false;
      }
    });
  }

  onPageChange(event: PageEvent): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadPayments();
  }

  refresh(): void {
    this.loadStats();
    this.loadPayments();
  }

  getPostTypeLabel(postType: string): string {
    const labels: { [key: string]: string } = {
      'MARKETPLACE': 'Marketplace',
      'FARM_PRODUCTS': 'Farm Products',
      'LABOURS': 'Labours',
      'TRAVELS': 'Travels',
      'PARCEL_SERVICE': 'Parcel Service',
      'REAL_ESTATE': 'Real Estate'
    };
    return labels[postType] || postType;
  }

  getStatusChipClass(status: string): string {
    switch (status) {
      case 'PAID': return 'paid';
      case 'FAILED': return 'failed';
      case 'CREATED': return 'created';
      default: return 'created';
    }
  }

  get postTypeEntries(): { type: string; amount: number }[] {
    return Object.entries(this.byPostType).map(([type, amount]) => ({ type, amount }));
  }
}
