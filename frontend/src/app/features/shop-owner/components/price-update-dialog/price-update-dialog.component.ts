import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export interface PriceUpdateData {
  productName: string;
  currentPrice: number;
  costPrice?: number;
}

@Component({
  selector: 'app-price-update-dialog',
  template: `
    <h2 mat-dialog-title>Update Price - {{ data.productName }}</h2>
    <form [formGroup]="priceForm" (ngSubmit)="onSubmit()">
      <mat-dialog-content>
        <div class="price-form">
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Current Price (₹)</mat-label>
            <input matInput 
                   type="number" 
                   formControlName="price"
                   step="0.01"
                   min="0">
            <mat-error *ngIf="priceForm.get('price')?.hasError('required')">
              Price is required
            </mat-error>
            <mat-error *ngIf="priceForm.get('price')?.hasError('min')">
              Price must be greater than 0
            </mat-error>
          </mat-form-field>

          <mat-form-field appearance="outline" class="full-width" *ngIf="data.costPrice">
            <mat-label>Cost Price (₹)</mat-label>
            <input matInput 
                   type="number" 
                   formControlName="costPrice"
                   step="0.01"
                   min="0">
          </mat-form-field>

          <div class="price-info" *ngIf="data.costPrice && priceForm.get('price')?.value && priceForm.get('costPrice')?.value">
            <p class="margin-info">
              <strong>Profit Margin:</strong> 
              ₹{{ getProfit() }} ({{ getProfitPercentage() }}%)
            </p>
          </div>
        </div>
      </mat-dialog-content>
      
      <mat-dialog-actions align="end">
        <button mat-button type="button" (click)="onCancel()">Cancel</button>
        <button mat-raised-button 
                color="primary" 
                type="submit"
                [disabled]="priceForm.invalid">
          Update Price
        </button>
      </mat-dialog-actions>
    </form>
  `,
  styles: [`
    .price-form {
      min-width: 400px;
      padding: 16px 0;
    }
    
    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }
    
    .price-info {
      background: #f5f5f5;
      padding: 12px;
      border-radius: 4px;
      margin-top: 16px;
    }
    
    .margin-info {
      margin: 0;
      color: #333;
    }
    
    mat-dialog-actions {
      margin-top: 16px;
    }
  `]
})
export class PriceUpdateDialogComponent {
  priceForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<PriceUpdateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: PriceUpdateData
  ) {
    this.priceForm = this.fb.group({
      price: [data.currentPrice, [Validators.required, Validators.min(0.01)]],
      costPrice: [data.costPrice || 0, [Validators.min(0)]]
    });
  }

  onSubmit(): void {
    if (this.priceForm.valid) {
      const result = {
        price: this.priceForm.get('price')?.value,
        costPrice: this.priceForm.get('costPrice')?.value
      };
      this.dialogRef.close(result);
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  getProfit(): number {
    const price = this.priceForm.get('price')?.value || 0;
    const costPrice = this.priceForm.get('costPrice')?.value || 0;
    return Math.max(0, price - costPrice);
  }

  getProfitPercentage(): string {
    const price = this.priceForm.get('price')?.value || 0;
    const costPrice = this.priceForm.get('costPrice')?.value || 0;
    if (costPrice === 0) return '0';
    return ((this.getProfit() / costPrice) * 100).toFixed(1);
  }
}