import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { of } from 'rxjs';

interface ShopProduct {
  id: number;
  name?: string;
  displayName?: string;
  customName?: string;
  productName?: string;
  masterProduct?: {
    name: string;
    nameTamil?: string;
  };
  price: number;
  sellingPrice?: number;
  primaryImageUrl?: string;
  imageUrl?: string;
  baseWeight?: string;
  baseUnit?: string;
  unit?: string;
  weight?: string;
}

@Component({
  selector: 'app-combo-form',
  templateUrl: './combo-form.component.html',
  styleUrls: ['./combo-form.component.css']
})
export class ComboFormComponent implements OnInit {
  comboForm!: FormGroup;
  isEditMode = false;
  isLoading = false;
  isSaving = false;
  shopProducts: ShopProduct[] = [];
  filteredProducts: ShopProduct[] = [];
  searchQuery = '';

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private snackBar: MatSnackBar,
    public dialogRef: MatDialogRef<ComboFormComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { mode: 'create' | 'edit'; combo?: any; shopId: number }
  ) {
    this.isEditMode = data.mode === 'edit';
  }

  ngOnInit(): void {
    this.initForm();
    this.loadProducts();
    if (this.isEditMode && this.data.combo) {
      this.populateForm(this.data.combo);
    }
  }

  initForm(): void {
    const today = new Date();
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);

    this.comboForm = this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(100)]],
      nameTamil: ['', Validators.maxLength(100)],
      description: ['', Validators.maxLength(500)],
      comboPrice: [0, [Validators.required, Validators.min(1)]],
      startDate: [today, Validators.required],
      endDate: [nextMonth, Validators.required],
      bannerImageUrl: [''],
      items: this.fb.array([], Validators.minLength(2))
    });
  }

  get itemsFormArray(): FormArray {
    return this.comboForm.get('items') as FormArray;
  }

  loadProducts(): void {
    if (!this.data.shopId) {
      this.showSnackBar('Shop ID not found. Please try again.', 'error');
      return;
    }

    this.isLoading = true;
    // Load all products once - search will filter locally
    const url = `${environment.apiUrl}/shops/${this.data.shopId}/products?page=0&size=500`;

    this.http.get<any>(url).subscribe({
      next: (response) => {
        this.shopProducts = response.data?.content || response.content || response.data || response || [];
        // Keep dropdown closed by default - user can click toggle or type to search
        this.filteredProducts = [];
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.showSnackBar('Failed to load products', 'error');
      }
    });
  }

  showProducts(): void {
    // Only show dropdown if there's a search query or user explicitly clicks to browse
    // For edit mode, don't auto-show to avoid covering existing items
    if (!this.isEditMode || this.searchQuery.trim()) {
      if (this.filteredProducts.length === 0 && this.shopProducts.length > 0) {
        this.filteredProducts = [...this.shopProducts];
      }
    }
  }

  hideDropdown(): void {
    // Small delay to allow click events to register before hiding
    setTimeout(() => {
      this.filteredProducts = [];
    }, 200);
  }

  toggleProductDropdown(): void {
    if (this.filteredProducts.length > 0) {
      this.filteredProducts = [];
    } else {
      this.filteredProducts = [...this.shopProducts];
    }
  }

  filterProducts(): void {
    const query = this.searchQuery.toLowerCase().trim();
    if (!query) {
      // Keep dropdown closed when search is cleared
      this.filteredProducts = [];
      return;
    }
    // Show filtered products when user types
    this.filteredProducts = this.shopProducts.filter(p => {
      const name = this.getProductName(p).toLowerCase();
      const nameTamil = this.getProductNameTamil(p)?.toLowerCase() || '';
      return name.includes(query) || nameTamil.includes(query);
    });
  }

  getProductName(product: ShopProduct): string {
    return product.name || product.displayName || product.customName || product.productName || product.masterProduct?.name || 'Unknown Product';
  }

  getProductNameTamil(product: ShopProduct): string | undefined {
    return product.masterProduct?.nameTamil;
  }

  getProductImage(product: ShopProduct): string | undefined {
    const imageUrl = product.primaryImageUrl || product.imageUrl;
    if (!imageUrl) return undefined;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Prepend base URL for relative paths
    const cleanPath = imageUrl.startsWith('/') ? imageUrl : '/' + imageUrl;
    return `${environment.imageBaseUrl}${cleanPath}`;
  }

  getProductPrice(product: ShopProduct): number {
    return product.sellingPrice || product.price || 0;
  }

  getProductUnit(product: ShopProduct): string {
    if (product.baseWeight && product.baseUnit) {
      return `${product.baseWeight} ${product.baseUnit}`;
    }
    if (product.weight && product.unit) {
      return `${product.weight} ${product.unit}`;
    }
    return '';
  }

  addProduct(product: ShopProduct): void {
    // Check if product already added
    const existing = this.itemsFormArray.controls.find(
      ctrl => ctrl.get('shopProductId')?.value === product.id
    );
    if (existing) {
      this.showSnackBar('Product already added', 'error');
      return;
    }

    const itemGroup = this.fb.group({
      shopProductId: [product.id, Validators.required],
      productName: [this.getProductName(product)],
      productNameTamil: [this.getProductNameTamil(product)],
      quantity: [1, [Validators.required, Validators.min(1)]],
      unitPrice: [this.getProductPrice(product)],
      imageUrl: [this.getProductImage(product)],
      unit: [this.getProductUnit(product)]
    });

    this.itemsFormArray.push(itemGroup);
    this.calculateOriginalPrice();
    this.searchQuery = '';
    this.filteredProducts = []; // Hide dropdown after adding
    this.showSnackBar(`${this.getProductName(product)} added`, 'success');
  }

  removeProduct(index: number): void {
    this.itemsFormArray.removeAt(index);
    this.calculateOriginalPrice();
  }

  updateQuantity(index: number, delta: number): void {
    const control = this.itemsFormArray.at(index).get('quantity');
    if (control) {
      const newValue = Math.max(1, control.value + delta);
      control.setValue(newValue);
      this.calculateOriginalPrice();
    }
  }

  calculateOriginalPrice(): number {
    let total = 0;
    this.itemsFormArray.controls.forEach(ctrl => {
      const qty = ctrl.get('quantity')?.value || 0;
      const price = ctrl.get('unitPrice')?.value || 0;
      total += qty * price;
    });
    return total;
  }

  getDiscountPercentage(): number {
    const original = this.calculateOriginalPrice();
    const combo = this.comboForm.get('comboPrice')?.value || 0;
    if (original === 0 || combo >= original) return 0;
    return Math.round(((original - combo) / original) * 100);
  }

  getSavings(): number {
    const original = this.calculateOriginalPrice();
    const combo = this.comboForm.get('comboPrice')?.value || 0;
    return Math.max(0, original - combo);
  }

  populateForm(combo: any): void {
    this.comboForm.patchValue({
      name: combo.name,
      nameTamil: combo.nameTamil,
      description: combo.description,
      comboPrice: combo.comboPrice,
      startDate: new Date(combo.startDate),
      endDate: new Date(combo.endDate),
      bannerImageUrl: combo.bannerImageUrl
    });

    // Add existing items
    if (combo.items && combo.items.length > 0) {
      combo.items.forEach((item: any) => {
        // Convert relative image URL to full URL
        const imageUrl = this.getFullImageUrl(item.imageUrl);
        const itemGroup = this.fb.group({
          shopProductId: [item.shopProductId, Validators.required],
          productName: [item.productName],
          productNameTamil: [item.productNameTamil],
          quantity: [item.quantity, [Validators.required, Validators.min(1)]],
          unitPrice: [item.unitPrice],
          imageUrl: [imageUrl],
          unit: [item.unit]
        });
        this.itemsFormArray.push(itemGroup);
      });
    }
  }

  getFullImageUrl(imageUrl: string | undefined): string | undefined {
    if (!imageUrl) return undefined;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    const cleanPath = imageUrl.startsWith('/') ? imageUrl : '/' + imageUrl;
    return `${environment.imageBaseUrl}${cleanPath}`;
  }

  onSubmit(): void {
    if (this.comboForm.invalid) {
      this.markFormGroupTouched(this.comboForm);
      if (this.itemsFormArray.length < 2) {
        this.showSnackBar('Please add at least 2 products', 'error');
      } else {
        this.showSnackBar('Please fill all required fields', 'error');
      }
      return;
    }

    this.isSaving = true;
    const formValue = this.comboForm.value;

    const payload = {
      name: formValue.name,
      nameTamil: formValue.nameTamil || null,
      description: formValue.description || null,
      comboPrice: formValue.comboPrice,
      startDate: formValue.startDate.toISOString(),
      endDate: formValue.endDate.toISOString(),
      bannerImageUrl: formValue.bannerImageUrl || null,
      items: formValue.items.map((item: any) => ({
        shopProductId: item.shopProductId,
        quantity: item.quantity
      }))
    };

    const url = this.isEditMode
      ? `${environment.apiUrl}/shops/${this.data.shopId}/combos/${this.data.combo.id}`
      : `${environment.apiUrl}/shops/${this.data.shopId}/combos`;

    const request = this.isEditMode
      ? this.http.put(url, payload)
      : this.http.post(url, payload);

    request.subscribe({
      next: () => {
        this.isSaving = false;
        this.showSnackBar(
          this.isEditMode ? 'Combo updated successfully' : 'Combo created successfully',
          'success'
        );
        this.dialogRef.close(true);
      },
      error: (error) => {
        this.isSaving = false;
        const message = error.error?.message || 'Failed to save combo';
        this.showSnackBar(message, 'error');
      }
    });
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  onCancel(): void {
    this.dialogRef.close(false);
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }
}
