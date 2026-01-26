import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

export interface ProductAssignmentData {
  product: {
    id: number;
    name: string;
    description?: string;
    sku?: string;
    category?: {
      id: number;
      name: string;
    };
    brand?: string;
    baseUnit?: string;
    primaryImageUrl?: string;
    minPrice?: number;
    maxPrice?: number;
  };
}

@Component({
  selector: 'app-product-assignment-dialog',
  templateUrl: './product-assignment-dialog.component.html',
  styleUrls: ['./product-assignment-dialog.component.scss']
})
export class ProductAssignmentDialogComponent implements OnInit {
  assignmentForm: FormGroup;
  isLoading = false;
  private apiUrl = environment.apiUrl;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<ProductAssignmentDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ProductAssignmentData,
    private snackBar: MatSnackBar,
    private http: HttpClient
  ) {
    this.assignmentForm = this.fb.group({
      price: [
        data.product.minPrice || data.product.maxPrice || 100,
        [Validators.required, Validators.min(0.01)]
      ],
      originalPrice: [null, [Validators.min(0)]],
      stockQuantity: [0, [Validators.min(0)]],
      costPrice: [null, [Validators.min(0)]],
      customName: [''],
      customDescription: [''],
      sku: [''],
      barcode1: [''],
      barcode2: [''],
      barcode3: [''],
      nameTamil: [''],
      tags: [''],
      voiceSearchTags: [''],
      isAvailable: [true]
    });
  }

  ngOnInit(): void {
    // Pre-fill suggested price from market data
    if (this.data.product.minPrice) {
      this.assignmentForm.patchValue({
        price: this.data.product.minPrice
      });
    }
  }

  getProfit(): number {
    const price = this.assignmentForm.get('price')?.value || 0;
    const costPrice = this.assignmentForm.get('costPrice')?.value || 0;
    return price - costPrice;
  }

  getProfitPercentage(): number {
    const price = this.assignmentForm.get('price')?.value || 0;
    const costPrice = this.assignmentForm.get('costPrice')?.value || 0;
    if (costPrice === 0) return 0;
    return ((price - costPrice) / costPrice) * 100;
  }

  assignProduct(): void {
    if (this.assignmentForm.invalid) {
      this.markFormGroupTouched();
      return;
    }

    this.isLoading = true;
    const formValue = this.assignmentForm.value;

    const productData = {
      masterProductId: this.data.product.id,
      price: formValue.price,
      originalPrice: formValue.originalPrice || null,
      stockQuantity: formValue.stockQuantity || 0,
      costPrice: formValue.costPrice || null,
      isAvailable: formValue.isAvailable,
      customName: formValue.customName || undefined,
      customDescription: formValue.customDescription || undefined,
      sku: formValue.sku || undefined,
      barcode1: formValue.barcode1 || undefined,
      barcode2: formValue.barcode2 || undefined,
      barcode3: formValue.barcode3 || undefined,
      nameTamil: formValue.nameTamil || undefined,
      tags: formValue.tags || undefined,
      voiceSearchTags: formValue.voiceSearchTags || undefined
    };

    console.log('Assigning product with data:', productData);

    this.http.post<any>(`${this.apiUrl}/shop-products/create`, productData)
      .subscribe({
        next: (response) => {
          this.snackBar.open(
            `Successfully added "${this.data.product.name}" to your shop`,
            'Close',
            { duration: 3000, panelClass: 'success-snackbar' }
          );
          this.dialogRef.close({ success: true, data: response });
        },
        error: (error) => {
          console.error('Error assigning product:', error);
          const errorMsg = error.error?.message || error.message || 'Failed to add product';
          this.snackBar.open(
            `Error: ${errorMsg}`,
            'Close',
            { duration: 4000, panelClass: 'error-snackbar' }
          );
          this.isLoading = false;
        }
      });
  }

  private markFormGroupTouched(): void {
    Object.keys(this.assignmentForm.controls).forEach(key => {
      const control = this.assignmentForm.get(key);
      control?.markAsTouched();
    });
  }
}