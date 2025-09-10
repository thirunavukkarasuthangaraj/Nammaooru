import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export interface BulkPriceUpdateData {
  products: any[];
  usingFallbackData: boolean;
}

@Component({
  selector: 'app-bulk-price-update-dialog',
  templateUrl: './bulk-price-update-dialog.component.html',
  styleUrls: ['./bulk-price-update-dialog.component.scss']
})
export class BulkPriceUpdateDialogComponent {
  bulkUpdateForm: FormGroup;
  
  constructor(
    private fb: FormBuilder,
    public dialogRef: MatDialogRef<BulkPriceUpdateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: BulkPriceUpdateData
  ) {
    this.bulkUpdateForm = this.fb.group({
      priceType: ['fixed', Validators.required],
      newPrice: [null],
      percentage: [null]
    });

    // Set up validators based on price type
    this.bulkUpdateForm.get('priceType')?.valueChanges.subscribe(value => {
      const newPriceControl = this.bulkUpdateForm.get('newPrice');
      const percentageControl = this.bulkUpdateForm.get('percentage');
      
      if (value === 'fixed') {
        newPriceControl?.setValidators([Validators.required, Validators.min(0)]);
        percentageControl?.clearValidators();
      } else if (value === 'percentage') {
        percentageControl?.setValidators([Validators.required]);
        newPriceControl?.clearValidators();
      }
      
      newPriceControl?.updateValueAndValidity();
      percentageControl?.updateValueAndValidity();
    });
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onUpdate(): void {
    if (this.bulkUpdateForm.valid) {
      const formValue = this.bulkUpdateForm.value;
      this.dialogRef.close({
        priceType: formValue.priceType,
        newPrice: formValue.newPrice,
        percentage: formValue.percentage
      });
    }
  }

  getPreviewPrice(currentPrice: number): number {
    const formValue = this.bulkUpdateForm.value;
    if (formValue.priceType === 'fixed' && formValue.newPrice) {
      return formValue.newPrice;
    } else if (formValue.priceType === 'percentage' && formValue.percentage) {
      return currentPrice * (1 + formValue.percentage / 100);
    }
    return currentPrice;
  }
}