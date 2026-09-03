import { Component, OnInit } from '@angular/core';
import { PaymentsService, PaymentSummary, PaymentTransaction } from '../../services/payments.service';
import { SwalService } from '../../../../core/services/swal.service';

@Component({
  selector: 'app-payments',
  templateUrl: './payments.component.html',
  styleUrls: ['./payments.component.scss']
})
export class PaymentsComponent implements OnInit {
  summary: PaymentSummary | null = null;
  transactions: PaymentTransaction[] = [];
  displayedColumns = ['orderNumber', 'orderAmount', 'gatewayFeeAmount', 'totalChargedAmount', 'status', 'createdAt'];

  selectedDate: string = new Date().toISOString().substring(0, 10);
  isLoadingSummary = false;
  isLoadingTransactions = false;

  currentPage = 0;
  pageSize = 20;
  totalTransactions = 0;

  constructor(
    private paymentsService: PaymentsService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadSummary();
    this.loadTransactions();
  }

  private static readonly SUCCESS_CODE = '0000';

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

  loadTransactions(): void {
    this.isLoadingTransactions = true;
    this.paymentsService.getTransactions(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        if (response.statusCode === PaymentsComponent.SUCCESS_CODE) {
          this.transactions = response.data?.content || [];
          this.totalTransactions = response.data?.totalItems ?? this.transactions.length;
        } else {
          this.swal.toast(response.message || 'Failed to load transactions', 'error');
        }
        this.isLoadingTransactions = false;
      },
      error: (error) => {
        console.error('Error loading transactions:', error);
        this.swal.toast('Error loading transactions', 'error');
        this.isLoadingTransactions = false;
      }
    });
  }

  onDateChange(): void {
    this.loadSummary();
  }

  onPageChange(event: { pageIndex: number; pageSize: number }): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadTransactions();
  }

  statusClass(status: string): string {
    switch (status) {
      case 'PAID': return 'status-paid';
      case 'FAILED': return 'status-failed';
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
      default: return 'Pending';
    }
  }
}
