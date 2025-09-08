import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export interface StockUpdateData {
  productName: string;
  currentStock: number;
  unit?: string;
}

@Component({
  selector: 'app-stock-update-dialog',
  template: `
    <h2 mat-dialog-title>Update Stock - {{ data.productName }}</h2>
    <form [formGroup]="stockForm" (ngSubmit)="onSubmit()">
      <mat-dialog-content>
        <div class="stock-form">
          <div class="current-stock-info">
            <p><strong>Current Stock:</strong> {{ data.currentStock }} {{ data.unit || 'units' }}</p>
          </div>

          <mat-form-field appearance="outline" class="full-width">
            <mat-label>New Stock Quantity</mat-label>
            <input matInput 
                   type="number" 
                   formControlName="stockQuantity"
                   min="0"
                   step="1">
            <mat-hint>{{ data.unit || 'units' }}</mat-hint>
            <mat-error *ngIf="stockForm.get('stockQuantity')?.hasError('required')">
              Stock quantity is required
            </mat-error>
            <mat-error *ngIf="stockForm.get('stockQuantity')?.hasError('min')">
              Stock quantity cannot be negative
            </mat-error>
          </mat-form-field>

          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Update Reason (Optional)</mat-label>
            <textarea matInput 
                      formControlName="reason"
                      rows="2"
                      placeholder="e.g., New stock arrived, Inventory correction, etc.">
            </textarea>
          </mat-form-field>

          <div class="stock-change" *ngIf="getStockChange() !== 0">
            <p [class.positive]="getStockChange() > 0" [class.negative]="getStockChange() < 0">
              <strong>Change:</strong> 
              <span *ngIf="getStockChange() > 0">+</span>{{ getStockChange() }} {{ data.unit || 'units' }}
            </p>
          </div>
        </div>
      </mat-dialog-content>
      
      <mat-dialog-actions align="end">
        <button mat-button type="button" (click)="onCancel()">Cancel</button>
        <button mat-raised-button 
                color="primary" 
                type="submit"
                [disabled]="stockForm.invalid">
          Update Stock
        </button>
      </mat-dialog-actions>
    </form>
  `,
  styles: [`
    .stock-form {
      min-width: 400px;
      padding: 16px 0;
    }
    
    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }
    
    .current-stock-info {
      background: #f5f5f5;
      padding: 12px;
      border-radius: 4px;
      margin-bottom: 16px;
    }
    
    .current-stock-info p {
      margin: 0;
      color: #333;
    }
    
    .stock-change {
      background: #f5f5f5;
      padding: 12px;
      border-radius: 4px;
      margin-top: 16px;
    }
    
    .stock-change p {
      margin: 0;
    }
    
    .positive {
      color: #4CAF50;
    }
    
    .negative {
      color: #F44336;
    }
    
    mat-dialog-actions {
      margin-top: 16px;
    }
  `]
})
export class StockUpdateDialogComponent {
  stockForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<StockUpdateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: StockUpdateData
  ) {
    this.stockForm = this.fb.group({
      stockQuantity: [data.currentStock, [Validators.required, Validators.min(0)]],
      reason: ['']
    });
  }

  onSubmit(): void {
    if (this.stockForm.valid) {
      const result = {
        stockQuantity: this.stockForm.get('stockQuantity')?.value,
        reason: this.stockForm.get('reason')?.value
      };
      this.dialogRef.close(result);
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  getStockChange(): number {
    const newStock = this.stockForm.get('stockQuantity')?.value || 0;
    return newStock - this.data.currentStock;
  }
}