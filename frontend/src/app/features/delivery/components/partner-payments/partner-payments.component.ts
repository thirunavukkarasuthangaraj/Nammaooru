import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { PaymentConfirmDialogComponent } from '../payment-confirm-dialog/payment-confirm-dialog.component';

interface PartnerPayment {
  partnerId: number;
  partnerName: string;
  partnerPhone: string;
  partnerEmail: string;
  totalOrders: number;
  cashCollected: number;
  commissionEarned: number;
  netAmount: number;
  paymentStatus: string;
  lastDelivery: string;
}

@Component({
  selector: 'app-partner-payments',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatDialogModule,
    MatSnackBarModule,
    MatProgressSpinnerModule,
    MatChipsModule,
    MatTooltipModule
  ],
  templateUrl: './partner-payments.component.html',
  styleUrls: ['./partner-payments.component.scss']
})
export class PartnerPaymentsComponent implements OnInit {
  Math = Math;  // Expose Math to template

  displayedColumns: string[] = [
    'partnerName',
    'totalOrders',
    'cashCollected',
    'commissionEarned',
    'netAmount',
    'actions'
  ];

  payments: PartnerPayment[] = [];
  loading = false;
  totalPartners = 0;

  constructor(
    private http: HttpClient,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadPayments();
  }

  loadPayments(): void {
    this.loading = true;
    this.http.get<any>(`${environment.apiUrl}/admin/delivery-partners/payments`)
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.payments = response.payments;
            this.totalPartners = response.totalPartners;
          }
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading payments:', error);
          this.snackBar.open('Error loading payments', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
  }

  markAsPaid(payment: PartnerPayment): void {
    const dialogRef = this.dialog.open(PaymentConfirmDialogComponent, {
      width: '500px',
      data: payment
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.processPayment(payment, result);
      }
    });
  }

  processPayment(payment: PartnerPayment, paymentData: any): void {
    this.loading = true;

    const requestData = {
      amount: payment.netAmount,
      paymentMethod: paymentData.paymentMethod,
      notes: paymentData.notes
    };

    this.http.post<any>(
      `${environment.apiUrl}/admin/delivery-partners/${payment.partnerId}/mark-paid`,
      requestData
    ).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Payment marked as paid successfully!', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar']
          });
          this.loadPayments(); // Reload the data
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error marking payment:', error);
        this.snackBar.open('Error processing payment', 'Close', { duration: 3000 });
        this.loading = false;
      }
    });
  }

  formatCurrency(amount: number): string {
    return `₹${amount.toFixed(2)}`;
  }

  getAmountClass(amount: number): string {
    return amount > 0 ? 'amount-positive' : 'amount-negative';
  }

  getAmountTooltip(amount: number): string {
    if (amount > 0) {
      return 'Partner owes you this amount';
    } else if (amount < 0) {
      return 'You owe partner this amount';
    }
    return 'No pending amount';
  }

  // Dashboard helper methods
  getTotalCash(): number {
    return this.payments.reduce((sum, p) => sum + p.cashCollected, 0);
  }

  getTotalCommission(): number {
    return this.payments.reduce((sum, p) => sum + p.commissionEarned, 0);
  }

  viewDetails(payment: PartnerPayment): void {
    // For now, just show a simple info message
    // Later can open detailed dialog
    console.log('View details for:', payment.partnerName);
  }
}
