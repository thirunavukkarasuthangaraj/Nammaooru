import { Component, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-payment-confirm-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule,
    FormsModule
  ],
  templateUrl: './payment-confirm-dialog.component.html',
  styleUrls: ['./payment-confirm-dialog.component.scss']
})
export class PaymentConfirmDialogComponent {
  paymentMethod = 'CASH';
  notes = '';

  constructor(
    public dialogRef: MatDialogRef<PaymentConfirmDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any
  ) {}

  onCancel(): void {
    this.dialogRef.close();
  }

  onConfirm(): void {
    this.dialogRef.close({
      paymentMethod: this.paymentMethod,
      notes: this.notes
    });
  }

  formatCurrency(amount: number): string {
    return `₹${Math.abs(amount).toFixed(2)}`;
  }

  getPaymentDirection(): string {
    return this.data.netAmount > 0 ? 'received from' : 'paid to';
  }
}
