import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService } from '../../../../core/services/offline-storage.service';

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
  // Shop-level multiple barcodes
  barcode1?: string;
  barcode2?: string;
  barcode3?: string;
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

  isSaving = false;

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private http: HttpClient,
    private offlineStorage: OfflineStorageService,
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
      tags: [this.data.tags || ''],
      // Shop-level multiple barcodes (all optional)
      barcode1: [this.data.barcode1 || ''],
      barcode2: [this.data.barcode2 || ''],
      barcode3: [this.data.barcode3 || '']
    });
  }

  onSubmit(): void {
    if (this.editForm.valid) {
      const formValue = this.editForm.value;

      // Validate duplicate barcodes within same product
      const b1 = formValue.barcode1?.trim() || '';
      const b2 = formValue.barcode2?.trim() || '';
      const b3 = formValue.barcode3?.trim() || '';

      if (b1 && b2 && b1.toLowerCase() === b2.toLowerCase()) {
        this.snackBar.open('Barcode 1 and Barcode 2 cannot be the same.', 'Close', { duration: 3000 });
        return;
      }
      if (b1 && b3 && b1.toLowerCase() === b3.toLowerCase()) {
        this.snackBar.open('Barcode 1 and Barcode 3 cannot be the same.', 'Close', { duration: 3000 });
        return;
      }
      if (b2 && b3 && b2.toLowerCase() === b3.toLowerCase()) {
        this.snackBar.open('Barcode 2 and Barcode 3 cannot be the same.', 'Close', { duration: 3000 });
        return;
      }

      // Validate barcodes against other products (async)
      this.validateAndSave(formValue, b1, b2, b3);
    } else {
      this.snackBar.open('Please fill all required fields', 'Close', { duration: 2000 });
    }
  }

  /**
   * Validate barcodes against other products and save
   */
  private async validateAndSave(formValue: any, b1: string, b2: string, b3: string): Promise<void> {
    this.isSaving = true;

    // Validate barcodes against other products (SKU, barcode, barcode1/2/3)
    const barcodeValidationError = await this.offlineStorage.validateBarcodes(
      b1 || null,
      b2 || null,
      b3 || null,
      this.data.id  // Exclude current product from check
    );

    if (barcodeValidationError) {
      this.isSaving = false;
      this.snackBar.open(barcodeValidationError, 'Close', { duration: 5000 });
      return;
    }

    // All validations passed - close dialog with updated product
    const updatedProduct = {
      ...this.data,
      ...formValue,
      imageUrl: this.currentImageUrl || this.data.imageUrl,
      // Map frontend field names to backend field names
      voiceSearchTags: formValue.tags // Backend expects voiceSearchTags for voice search tags
    };
    this.isSaving = false;
    this.dialogRef.close(updatedProduct);
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  calculateProfit(): number {
    const price = this.editForm.get('price')?.value || 0;
    const costPrice = this.editForm.get('costPrice')?.value || 0;
    return price - costPrice;
  }

  calculateProfitMargin(): number {
    const price = this.editForm.get('price')?.value || 0;
    const costPrice = this.editForm.get('costPrice')?.value || 0;
    if (price === 0) return 0;
    return ((price - costPrice) / price) * 100;
  }

  calculateDiscountAmount(): number {
    const originalPrice = this.editForm.get('originalPrice')?.value || 0;
    const price = this.editForm.get('price')?.value || 0;
    if (originalPrice > price) {
      return originalPrice - price;
    }
    return 0;
  }

  calculateDiscountPercentage(): number {
    const originalPrice = this.editForm.get('originalPrice')?.value || 0;
    const price = this.editForm.get('price')?.value || 0;
    if (originalPrice > 0 && originalPrice > price) {
      return ((originalPrice - price) / originalPrice) * 100;
    }
    return 0;
  }

  onFileSelected(event: Event): void {
    const fileInput = event.target as HTMLInputElement;
    if (fileInput.files && fileInput.files[0]) {
      const file = fileInput.files[0];
      
      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.snackBar.open('Please select a valid image file', 'Close', { duration: 3000 });
        return;
      }
      
      // Validate file size (5MB max)
      if (file.size > 5 * 1024 * 1024) {
        this.snackBar.open('Image size should be less than 5MB', 'Close', { duration: 3000 });
        return;
      }
      
      this.selectedFile = file;
      
      // Create preview first
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview = reader.result as string;
      };
      reader.readAsDataURL(file);
      
      // Upload image immediately after selection
      this.uploadImageNow(file);
    }
  }
  
  private uploadImageNow(file: File): void {
    // Get shop ID from environment or localStorage - use string shopId directly
    const shopId = localStorage.getItem('current_shop_id') || localStorage.getItem('current_shop_numeric_id') || '57';
    let productId = this.data.id;
    
    console.log('Upload Debug - Shop ID:', shopId);
    console.log('Upload Debug - Product ID:', productId);
    console.log('Upload Debug - Product Data:', this.data);
    
    // Always use a default product ID if missing (for testing)
    if (!productId) {
      productId = 1; // Use a default ID for testing
      // Check if we're in demo mode or if product doesn't exist in DB
      console.warn('Product ID not found, image upload will be simulated locally');
      
      // For demo/local mode, just show preview without uploading
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview = reader.result as string;
        this.currentImageUrl = reader.result as string;
        this.data.imageUrl = reader.result as string;
        this.snackBar.open('Image preview updated (not saved to server)', 'Close', { duration: 3000 });
      };
      reader.readAsDataURL(file);
      return;
    }
    
    this.snackBar.open('Uploading image...', 'Close', { duration: 1000 });
    
    // Upload image immediately
    const formData = new FormData();
    formData.append('images', file);
    
    const apiUrl = environment.apiUrl;
    const uploadUrl = `${apiUrl}/products/images/shop/${shopId}/${productId}`;
    
    console.log('Upload URL:', uploadUrl);
    
    // Get the auth token properly
    const authToken = localStorage.getItem('auth_token') || localStorage.getItem('shop_management_token');
    
    fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + authToken
      },
      body: formData
    })
    .then(response => response.json())
    .then(response => {
      console.log('Image upload response:', response);
      
      if (response && response.data && response.data.length > 0) {
        const uploadedImage = response.data[0];
        // Store the uploaded image URL
        this.currentImageUrl = uploadedImage.imageUrl;
        this.data.imageUrl = uploadedImage.imageUrl;
        
        // Update preview to show the uploaded image
        this.imagePreview = null; // Clear base64 preview
        this.snackBar.open('Image uploaded successfully!', 'Close', { duration: 3000 });
      } else if (response.statusCode === '9999') {
        this.snackBar.open('Error: ' + response.message, 'Close', { duration: 5000 });
      }
    })
    .catch(error => {
      console.error('Upload error:', error);
      this.snackBar.open('Failed to upload image', 'Close', { duration: 3000 });
    });
  }

  clearImage(): void {
    this.selectedFile = null;
    this.imagePreview = null;
  }

  getProductImageUrl(): string {
    if (this.currentImageUrl) {
      if (this.currentImageUrl.startsWith('http://') || this.currentImageUrl.startsWith('https://')) {
        return this.currentImageUrl;
      }
      // Use imageBaseUrl (frontend domain) for serving images
      const cleanImageUrl = this.currentImageUrl.startsWith('/') ?
        this.currentImageUrl : '/' + this.currentImageUrl;
      return `${environment.imageBaseUrl}${cleanImageUrl}`;
    }
    return 'assets/images/product-placeholder.svg';
  }
}