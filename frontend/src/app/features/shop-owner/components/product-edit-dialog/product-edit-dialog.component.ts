import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

export interface ProductEditData {
  id: number;
  customName: string;
  description?: string;
  price: number;
  originalPrice?: number;
  costPrice?: number;
  stockQuantity: number;
  category?: string;
  unit?: string;
  sku?: string;
  status: string;
  isAvailable: boolean;
  imageUrl?: string;
  nameTamil?: string;
  tags?: string;
  masterProductId?: number;
}

@Component({
  selector: 'app-product-edit-dialog',
  templateUrl: './product-edit-dialog.component.html',
  styleUrls: ['./product-edit-dialog.component.scss']
})
export class ProductEditDialogComponent implements OnInit {
  editForm!: FormGroup;
  categories = ['Electronics', 'Food & Beverages', 'Clothing', 'Garden', 'Medicine', 'Groceries', 'Other'];
  units = ['piece', 'kg', 'gram', 'liter', 'ml', 'dozen', 'pack', 'box', 'bag'];
  statuses = ['ACTIVE', 'INACTIVE', 'OUT_OF_STOCK'];
  
  selectedFile: File | null = null;
  imagePreview: string | null = null;
  currentImageUrl: string | null = null;
  private apiUrl = environment.apiUrl;

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private http: HttpClient,
    public dialogRef: MatDialogRef<ProductEditDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ProductEditData
  ) {}

  ngOnInit(): void {
    this.initForm();
    if (this.data.imageUrl) {
      this.currentImageUrl = this.data.imageUrl;
    }
  }

  initForm(): void {
    this.editForm = this.fb.group({
      customName: [this.data.customName || '', [Validators.required, Validators.minLength(3)]],
      description: [this.data.description || ''],
      price: [this.data.price || 0, [Validators.required, Validators.min(0)]],
      originalPrice: [this.data.originalPrice || 0, [Validators.min(0)]],
      costPrice: [this.data.costPrice || 0, [Validators.min(0)]],
      stockQuantity: [this.data.stockQuantity || 0, [Validators.required, Validators.min(0)]],
      category: [this.data.category || ''],
      unit: [this.data.unit || 'piece'],
      sku: [this.data.sku || ''],
      status: [this.data.status || 'ACTIVE'],
      isAvailable: [this.data.isAvailable !== false],
      nameTamil: [this.data.nameTamil || ''],
      tags: [this.data.tags || '']
    });
  }

  onSubmit(): void {
    if (this.editForm.valid) {
      const formValue = this.editForm.value;

      // Update master product voice fields if they changed
      if (this.data.masterProductId && (formValue.nameTamil !== this.data.nameTamil || formValue.tags !== this.data.tags)) {
        const updateData = { nameTamil: formValue.nameTamil, tags: formValue.tags };
        this.http.patch(`${this.apiUrl}/products/master/${this.data.masterProductId}/voice-fields`, updateData)
          .subscribe({
            next: () => console.log('Voice fields updated'),
            error: (err) => console.error('Error updating voice fields:', err)
          });
      }

      const updatedProduct = {
        ...this.data,
        ...formValue,
        imageUrl: this.currentImageUrl || this.data.imageUrl
      };
      this.dialogRef.close(updatedProduct);
    } else {
      this.snackBar.open('Please fill all required fields', 'Close', { duration: 2000 });
    }
  }

