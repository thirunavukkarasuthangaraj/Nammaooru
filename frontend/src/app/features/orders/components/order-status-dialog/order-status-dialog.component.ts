import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderService } from '../../../../core/services/order.service';

export interface OrderStatusDialogData {
  orderId: number;
  currentStatus: string;
  orderNumber: string;
}

@Component({
  selector: 'app-order-status-dialog',
  templateUrl: './order-status-dialog.component.html',
  styleUrls: ['./order-status-dialog.component.scss']
})
export class OrderStatusDialogComponent {
  statusForm: FormGroup;
  loading = false;

  statusOptions = [
    { value: 'PENDING', label: 'Pending' },
    { value: 'CONFIRMED', label: 'Confirmed' },
    { value: 'PREPARING', label: 'Preparing' },
    { value: 'READY_FOR_PICKUP', label: 'Ready for Pickup' },
    { value: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
    { value: 'DELIVERED', label: 'Delivered' },
    { value: 'CANCELLED', label: 'Cancelled' }
  ];

  constructor(
    public dialogRef: MatDialogRef<OrderStatusDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: OrderStatusDialogData,
    private fb: FormBuilder,
    private orderService: OrderService,
    private snackBar: MatSnackBar
  ) {
    this.statusForm = this.fb.group({
      status: [data.currentStatus, Validators.required],
      reason: ['']
    });
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onSubmit(): void {
    if (this.statusForm.valid) {
      this.loading = true;
      const newStatus = this.statusForm.get('status')?.value;
      
      this.orderService.updateOrderStatus(this.data.orderId, newStatus).subscribe({
        next: () => {
          this.snackBar.open('Order status updated successfully', 'Close', { duration: 3000 });
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error updating order status:', error);
          this.snackBar.open('Error updating order status', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
    }
  }
}