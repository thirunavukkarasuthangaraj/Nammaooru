import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '../../../../../environments/environment';

export interface ProductEditData {
  id: number;
  customName: string;
  description?: string;
  price: number;
  costPrice?: number;
  stockQuantity: number;
  category?: string;
  unit?: string;
  sku?: string;
  status: string;
  isAvailable: boolean;
  imageUrl?: string;
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
      costPrice: [this.data.costPrice || 0, [Validators.min(0)]],
      stockQuantity: [this.data.stockQuantity || 0, [Validators.required, Validators.min(0)]],
      category: [this.data.category || ''],
      unit: [this.data.unit || 'piece'],
      sku: [this.data.sku || ''],
      status: [this.data.status || 'ACTIVE'],
      isAvailable: [this.data.isAvailable !== false]
    });
  }

  onSubmit(): void {
    if (this.editForm.valid) {
      const updatedProduct = {
        ...this.data,
        ...this.editForm.value,
        imageUrl: this.currentImageUrl || this.data.imageUrl
        // Image already uploaded, just pass the URL
      };
      this.dialogRef.close(updatedProduct);
    } else {
      this.snackBar.open('Please fill all required fields', 'Close', { duration: 2000 });
    }
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
    // Get shop ID from environment or localStorage
    const shopId = parseInt(localStorage.getItem('current_shop_id') || '57', 10);
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
      const baseUrl = this.apiUrl.replace('/api', '');
      const cleanImageUrl = this.currentImageUrl.startsWith('/') ? 
        this.currentImageUrl.substring(1) : this.currentImageUrl;
      return `${baseUrl}/${cleanImageUrl}`;
    }
    return 'assets/images/product-placeholder.svg';
  }
}