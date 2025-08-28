import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router, ActivatedRoute } from '@angular/router';
import { ProductService } from '@core/services/product.service';
import { ShopProductService } from '@core/services/shop-product.service';
import { ShopService } from '@core/services/shop.service';
import { ProductCategoryService } from '@core/services/product-category.service';
import { AuthService } from '@core/services/auth.service';
import { MasterProductRequest, ShopProductRequest, ProductCategory, ProductStatus, ShopProductStatus } from '@core/models/product.model';
import { Shop, BusinessType, ShopStatus } from '@core/models/shop.model';
import { forkJoin, of } from 'rxjs';
import { switchMap, catchError, map } from 'rxjs/operators';

@Component({
  selector: 'app-add-product',
  template: `
    <div class="add-product-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-left">
          <button mat-stroked-button routerLink="/shop-owner/products" class="back-button">
            <mat-icon>arrow_back</mat-icon>
            Back to Products
          </button>
          <div class="header-content">
            <h1 class="page-title">{{ isEditMode ? 'Edit Product' : 'Add New Product' }}</h1>
            <p class="page-subtitle">{{ isEditMode ? 'Update product information' : 'Add products to your shop inventory' }}</p>
          </div>
        </div>
      </div>

      <!-- Product Form -->
      <mat-card class="form-card">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>{{ isEditMode ? 'edit' : 'add_box' }}</mat-icon>
            Product Information
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <form [formGroup]="productForm" (ngSubmit)="onSubmit()" class="product-form">
            <!-- Basic Information -->
            <div class="form-section">
              <h3 class="section-title">Basic Information</h3>
              
              <div class="form-row">
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Product Name</mat-label>
                  <input matInput formControlName="name" placeholder="Enter product name">
                  <mat-error *ngIf="productForm.get('name')?.hasError('required')">
                    Product name is required
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Category</mat-label>
                  <mat-select formControlName="category">
                    <mat-option *ngFor="let category of productCategories" [value]="category.id">
                      {{ category.name }}
                    </mat-option>
                  </mat-select>
                  <mat-error *ngIf="productForm.get('category')?.hasError('required')">
                    Category is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Brand</mat-label>
                  <input matInput formControlName="brand" placeholder="Enter brand name">
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Description</mat-label>
                  <textarea matInput 
                           formControlName="description" 
                           placeholder="Enter product description"
                           rows="3"></textarea>
                </mat-form-field>
              </div>
            </div>

            <!-- Pricing & Stock -->
            <div class="form-section">
              <h3 class="section-title">Pricing & Stock</h3>
              
              <div class="form-row">
                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Price (₹)</mat-label>
                  <input matInput type="number" formControlName="price" placeholder="0.00">
                  <mat-error *ngIf="productForm.get('price')?.hasError('required')">
                    Price is required
                  </mat-error>
                  <mat-error *ngIf="productForm.get('price')?.hasError('min')">
                    Price must be greater than 0
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Cost Price (₹)</mat-label>
                  <input matInput type="number" formControlName="costPrice" placeholder="0.00">
                </mat-form-field>

                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Unit</mat-label>
                  <mat-select formControlName="unit">
                    <mat-option value="kg">Kilogram (kg)</mat-option>
                    <mat-option value="gram">Gram (g)</mat-option>
                    <mat-option value="liter">Liter (l)</mat-option>
                    <mat-option value="ml">Milliliter (ml)</mat-option>
                    <mat-option value="piece">Piece</mat-option>
                    <mat-option value="packet">Packet</mat-option>
                    <mat-option value="dozen">Dozen</mat-option>
                  </mat-select>
                  <mat-error *ngIf="productForm.get('unit')?.hasError('required')">
                    Unit is required
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Initial Stock</mat-label>
                  <input matInput type="number" formControlName="initialStock" placeholder="0">
                  <mat-error *ngIf="productForm.get('initialStock')?.hasError('required')">
                    Initial stock is required
                  </mat-error>
                  <mat-error *ngIf="productForm.get('initialStock')?.hasError('min')">
                    Stock must be 0 or greater
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Minimum Stock Alert</mat-label>
                  <input matInput type="number" formControlName="minStock" placeholder="0">
                </mat-form-field>

                <mat-form-field appearance="outline" class="third-width">
                  <mat-label>Maximum Stock</mat-label>
                  <input matInput type="number" formControlName="maxStock" placeholder="0">
                </mat-form-field>
              </div>
            </div>

            <!-- Product Details -->
            <div class="form-section">
              <h3 class="section-title">Product Details</h3>
              
              <div class="form-row">
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>SKU/Barcode</mat-label>
                  <input matInput formControlName="sku" placeholder="Enter SKU or barcode">
                </mat-form-field>

                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Supplier</mat-label>
                  <input matInput formControlName="supplier" placeholder="Enter supplier name">
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Shelf Location</mat-label>
                  <input matInput formControlName="location" placeholder="e.g., Aisle 1, Shelf A">
                </mat-form-field>

                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Expiry Date</mat-label>
                  <input matInput [matDatepicker]="expiryPicker" formControlName="expiryDate">
                  <mat-datepicker-toggle matSuffix [for]="expiryPicker"></mat-datepicker-toggle>
                  <mat-datepicker #expiryPicker></mat-datepicker>
                </mat-form-field>
              </div>
            </div>

            <!-- Product Image -->
            <div class="form-section">
              <h3 class="section-title">Product Image</h3>
              
              <div class="image-upload-section">
                <div class="image-preview" *ngIf="imagePreview">
                  <img [src]="imagePreview" alt="Product preview" class="preview-image">
                  <button mat-icon-button class="remove-image" (click)="removeImage()">
                    <mat-icon>close</mat-icon>
                  </button>
                </div>
                
                <div class="upload-area" *ngIf="!imagePreview" (click)="fileInput.click()">
                  <mat-icon class="upload-icon">cloud_upload</mat-icon>
                  <p class="upload-text">Click to upload product image</p>
                  <p class="upload-hint">Supported formats: JPG, PNG, WEBP (Max 5MB)</p>
                </div>
                
                <input #fileInput type="file" hidden accept="image/*" (change)="onImageSelected($event)">
                
                <div class="upload-actions" *ngIf="imagePreview">
                  <button mat-stroked-button type="button" (click)="fileInput.click()">
                    <mat-icon>edit</mat-icon>
                    Change Image
                  </button>
                </div>
              </div>
            </div>

            <!-- Settings -->
            <div class="form-section">
              <h3 class="section-title">Product Settings</h3>
              
              <div class="settings-row">
                <mat-checkbox formControlName="isActive">
                  Active (Available for sale)
                </mat-checkbox>
                
                <mat-checkbox formControlName="isFeatured">
                  Featured Product
                </mat-checkbox>
                
                <mat-checkbox formControlName="trackStock">
                  Track Stock Levels
                </mat-checkbox>
              </div>
            </div>

            <!-- Form Actions -->
            <div class="form-actions">
              <button mat-raised-button color="primary" type="submit" [disabled]="productForm.invalid || isLoading">
                <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
                <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">save</mat-icon>
                {{ isEditMode ? 'Update Product' : 'Save Product' }}
              </button>
              
              <button mat-stroked-button type="button" (click)="saveDraft()" [disabled]="isLoading">
                <mat-icon style="margin-right: 8px;">draft</mat-icon>
                Save as Draft
              </button>
              
              <button mat-button type="button" (click)="resetForm()">
                <mat-icon style="margin-right: 8px;">refresh</mat-icon>
                Reset Form
              </button>
            </div>
          </form>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .add-product-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      margin-bottom: 24px;
    }

    .header-left {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .back-button {
      min-width: auto;
      height: 40px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      font-size: 1rem;
      color: #6b7280;
      margin: 0;
    }


    .form-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      max-width: 1000px;
      margin: 0 auto;
    }

    .form-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 24px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .form-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.2rem;
      font-weight: 500;
    }

    .product-form {
      display: flex;
      flex-direction: column;
      gap: 32px;
    }

    .form-section {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .section-title {
      font-size: 1.1rem;
      font-weight: 600;
      color: #374151;
      margin: 0 0 8px 0;
      padding-bottom: 8px;
      border-bottom: 2px solid #e5e7eb;
    }

    .form-row {
      display: flex;
      gap: 16px;
      align-items: flex-start;
    }

    .full-width {
      width: 100%;
    }

    .half-width {
      flex: 1;
    }

    .third-width {
      flex: 1;
      min-width: 200px;
    }

    .image-upload-section {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .image-preview {
      position: relative;
      width: 200px;
      height: 200px;
      border-radius: 8px;
      overflow: hidden;
      border: 2px solid #e5e7eb;
    }

    .preview-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .remove-image {
      position: absolute;
      top: 8px;
      right: 8px;
      background: rgba(0,0,0,0.7);
      color: white;
    }

    .upload-area {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 300px;
      height: 200px;
      border: 2px dashed #d1d5db;
      border-radius: 8px;
      cursor: pointer;
      transition: border-color 0.2s ease;
      background: #fafafa;
    }

    .upload-area:hover {
      border-color: #6366f1;
      background: #f8faff;
    }

    .upload-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #6b7280;
      margin-bottom: 8px;
    }

    .upload-text {
      font-weight: 500;
      color: #374151;
      margin: 0 0 4px 0;
    }

    .upload-hint {
      font-size: 0.8rem;
      color: #6b7280;
      margin: 0;
    }

    .upload-actions {
      display: flex;
      gap: 12px;
    }

    .settings-row {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .form-actions {
      display: flex;
      gap: 12px;
      margin-top: 16px;
      padding-top: 24px;
      border-top: 1px solid #e5e7eb;
    }

    .form-actions button {
      height: 48px;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .add-product-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .form-row {
        flex-direction: column;
        gap: 12px;
      }

      .half-width, .third-width {
        width: 100%;
      }

      .page-title {
        font-size: 1.5rem;
      }

      .form-actions {
        flex-direction: column;
      }

      .upload-area {
        width: 100%;
      }

      .image-preview {
        width: 150px;
        height: 150px;
        align-self: center;
      }
    }
  `]
})
export class AddProductComponent implements OnInit {
  productForm: FormGroup;
  isLoading = false;
  imagePreview: string | null = null;
  selectedFile: File | null = null;
  currentShop: Shop | null = null;
  productCategories: ProductCategory[] = [];
  isEditMode = false;
  editingProductId: number | null = null;

  categories = [
    'Groceries',
    'Vegetables',
    'Fruits',
    'Dairy Products',
    'Bakery Items',
    'Beverages',
    'Snacks',
    'Personal Care',
    'Household Items',
    'Frozen Foods'
  ];

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private router: Router,
    private route: ActivatedRoute,
    private productService: ProductService,
    private shopProductService: ShopProductService,
    private shopService: ShopService,
    private categoryService: ProductCategoryService,
    private authService: AuthService
  ) {
    this.productForm = this.fb.group({
      name: ['', Validators.required],
      category: ['', Validators.required],
      brand: [''],
      description: [''],
      price: ['', [Validators.required, Validators.min(0.01)]],
      costPrice: [''],
      unit: ['', Validators.required],
      initialStock: ['', [Validators.required, Validators.min(0)]],
      minStock: [''],
      maxStock: [''],
      sku: [''],
      supplier: [''],
      location: [''],
      expiryDate: [''],
      isActive: [true],
      isFeatured: [false],
      trackStock: [true]
    });
  }

  ngOnInit(): void {
    // Check if we're in edit mode
    this.route.params.subscribe(params => {
      if (params['id']) {
        const numericId = parseInt(params['id'], 10);
        if (!isNaN(numericId)) {
          this.isEditMode = true;
          this.editingProductId = numericId;
          this.loadProductForEdit(this.editingProductId);
        } else {
          console.error('Invalid product ID:', params['id']);
          this.snackBar.open('Invalid product ID provided', 'Close', { duration: 3000 });
          this.router.navigate(['/shop-owner/products']);
        }
      }
    });

    this.loadInitialData();
    
    // Auto-generate SKU if not provided (only in add mode)
    if (!this.isEditMode) {
      this.productForm.get('name')?.valueChanges.subscribe(name => {
        if (name && !this.productForm.get('sku')?.value) {
          const sku = this.generateSKU(name);
          this.productForm.patchValue({ sku });
        }
      });
    }
  }

  private getShopId(): number {
    const user = localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser');
    if (user) {
      try {
        const userData = JSON.parse(user);
        // For shopowner1, use shop ID 11 (Test Grocery Store)
        if (userData.username === 'shopowner1') {
          return 11;
        }
        // For other shop owners, try to get from user data
        return userData.shopId || 1;
      } catch (e) {
        console.error('Error parsing user data:', e);
      }
    }
    return 11; // Default to shopowner1's shop
  }

  private loadInitialData(): void {
    this.isLoading = true;
    
    // Get the correct shop ID for the logged in user
    const shopId = this.getShopId();
    
    // For shop owners, use a default shop context instead of API call
    const defaultShop: Shop = {
      id: shopId,
      name: 'My Shop',
      description: 'Default shop for product management',
      shopId: 'DEFAULT001',
      slug: 'my-shop',
      ownerName: 'Shop Owner',
      ownerEmail: 'owner@myshop.com',
      ownerPhone: '+1234567890',
      businessName: 'My Business',
      businessType: BusinessType.GROCERY,
      addressLine1: '123 Main Street',
      city: 'Default City',
      state: 'Default State',
      postalCode: '12345',
      country: 'India',
      latitude: 0,
      longitude: 0,
      minOrderAmount: 100,
      deliveryRadius: 5,
      deliveryFee: 30,
      freeDeliveryAbove: 500,
      commissionRate: 15,
      status: ShopStatus.APPROVED,
      isActive: true,
      isVerified: true,
      isFeatured: false,
      rating: 0,
      totalOrders: 0,
      totalRevenue: 0,
      productCount: 0,
      createdBy: 'system',
      updatedBy: 'system',
      createdAt: new Date(),
      updatedAt: new Date(),
      images: [],
      documents: []
    };
    
    this.categoryService.getCategoryTree().subscribe({
      next: (categories) => {
        this.currentShop = defaultShop;
        this.productCategories = this.flattenCategories(categories);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        // Fallback to default categories if API fails
        this.currentShop = defaultShop;
        this.productCategories = this.getDefaultCategories();
        this.isLoading = false;
      }
    });
  }

  private loadProductForEdit(productId: number): void {
    // For demo purposes, load from mock data
    // In a real application, you would call an API to get the product details
    const mockProducts = [
      {
        id: 1,
        name: 'Organic Rice',
        category: 'Groceries',
        brand: 'Organic Farm',
        description: 'Premium quality organic rice',
        price: 120,
        stock: 50,
        unit: 'kg',
        sku: 'ORG-RICE-001',
        isActive: true,
        isFeatured: false,
        trackStock: true,
        image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRjNGNEY2Ii8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiM5Q0EzQUYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCI+UmljZTwvdGV4dD4KPC9zdmc+'
      },
      {
        id: 2,
        name: 'Fresh Tomatoes',
        category: 'Vegetables',
        brand: 'Fresh Farm',
        description: 'Farm fresh red tomatoes',
        price: 40,
        stock: 3,
        unit: 'kg',
        sku: 'FRS-TOM-002',
        isActive: true,
        isFeatured: false,
        trackStock: true,
        image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkVGMkYyIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiNEQzI2MjYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNiI+VG9tYXRvPC90ZXh0Pgo8L3N2Zz4='
      },
      {
        id: 3,
        name: 'Whole Wheat Bread',
        category: 'Bakery',
        brand: 'Healthy Bakery',
        description: 'Nutritious whole wheat bread',
        price: 35,
        stock: 25,
        unit: 'piece',
        sku: 'WW-BREAD-003',
        isActive: true,
        isFeatured: false,
        trackStock: true,
        image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkZGQkVCIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiNBRjY1MDkiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNiI+QnJlYWQ8L3RleHQ+Cjwvc3ZnPg=='
      },
      {
        id: 4,
        name: 'Fresh Milk',
        category: 'Dairy',
        brand: 'Pure Dairy',
        description: 'Fresh pasteurized milk',
        price: 60,
        stock: 0,
        unit: 'liter',
        sku: 'FRS-MILK-004',
        isActive: false,
        isFeatured: false,
        trackStock: true,
        image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkNGRkZGIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiM2Mzc1OEYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCI+TWlsazwvdGV4dD4KPC9zdmc+'
      }
    ];

    const product = mockProducts.find(p => p.id === productId);
    if (product) {
      this.productForm.patchValue({
        name: product.name,
        category: product.category,
        brand: product.brand,
        description: product.description,
        price: product.price,
        stock: product.stock,
        unit: product.unit,
        sku: product.sku,
        isActive: product.isActive,
        isFeatured: product.isFeatured,
        trackStock: product.trackStock
      });
      
      this.imagePreview = product.image;
    }
  }

  private getDefaultCategories(): ProductCategory[] {
    return this.categories.map((name, index) => ({
      id: index + 1,
      name: name,
      description: `${name} category`,
      slug: name.toLowerCase().replace(/\s+/g, '-'),
      parentId: undefined,
      parentName: undefined,
      fullPath: name,
      isActive: true,
      sortOrder: index,
      iconUrl: undefined,
      createdBy: 'system',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      level: 0,
      subcategories: [],
      hasSubcategories: false,
      isRootCategory: true,
      productCount: 0,
      subcategoryCount: 0
    }));
  }

  private flattenCategories(categories: ProductCategory[]): ProductCategory[] {
    const flattened: ProductCategory[] = [];
    
    const flatten = (cats: ProductCategory[]) => {
      cats.forEach(cat => {
        flattened.push(cat);
        if (cat.subcategories && cat.subcategories.length > 0) {
          flatten(cat.subcategories);
        }
      });
    };
    
    flatten(categories);
    return flattened;
  }

  private generateSKU(name: string): string {
    const prefix = name.substring(0, 3).toUpperCase();
    const timestamp = Date.now().toString().slice(-6);
    return `${prefix}${timestamp}`;
  }

  onImageSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      // Validate file size (5MB)
      if (file.size > 5 * 1024 * 1024) {
        this.snackBar.open('Image size must be less than 5MB', 'Close', { duration: 3000 });
        return;
      }

      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.snackBar.open('Please select a valid image file', 'Close', { duration: 3000 });
        return;
      }

      this.selectedFile = file;

      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imagePreview = e.target?.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  removeImage(): void {
    this.imagePreview = null;
    this.selectedFile = null;
  }

  onSubmit(): void {
    if (this.productForm.valid && this.currentShop) {
      this.isLoading = true;
      
      const formData = this.productForm.value;
      
      // Create master product request
      const masterProductRequest: MasterProductRequest = {
        name: formData.name,
        description: formData.description || '',
        sku: formData.sku,
        categoryId: formData.category,
        brand: formData.brand || '',
        baseUnit: formData.unit,
        status: formData.isActive ? ProductStatus.ACTIVE : ProductStatus.INACTIVE,
        isFeatured: formData.isFeatured || false,
        isGlobal: false // Shop-specific product
      };

      // Create the master product first
      this.productService.createMasterProduct(masterProductRequest)
        .pipe(
          switchMap(masterProduct => {
            // Create shop product request
            const shopProductRequest: ShopProductRequest = {
              masterProductId: masterProduct.id,
              price: formData.price,
              costPrice: formData.costPrice || 0,
              stockQuantity: formData.initialStock || 0,
              minStockLevel: formData.minStock || 0,
              maxStockLevel: formData.maxStock || 0,
              trackInventory: formData.trackStock,
              status: formData.isActive ? ShopProductStatus.ACTIVE : ShopProductStatus.INACTIVE,
              isAvailable: formData.isActive,
              isFeatured: formData.isFeatured || false,
              customName: formData.name !== masterProduct.name ? formData.name : undefined,
              customDescription: formData.description !== masterProduct.description ? formData.description : undefined
            };

            // Add product to shop
            return this.shopProductService.addProductToShop(this.currentShop!.id, shopProductRequest)
              .pipe(
                switchMap(shopProduct => {
                  // Upload image if selected
                  if (this.selectedFile) {
                    const imageFormData = new FormData();
                    imageFormData.append('images', this.selectedFile);
                    return this.productService.uploadShopProductImages(
                      this.currentShop!.id, 
                      shopProduct.id, 
                      imageFormData
                    ).pipe(
                      map(() => shopProduct) // Return shop product after image upload
                    );
                  }
                  return of(shopProduct);
                })
              );
          }),
          catchError(error => {
            console.error('Error creating product:', error);
            this.isLoading = false;
            
            let errorMessage = 'Failed to create product. Please try again.';
            if (error.error?.message) {
              errorMessage = error.error.message;
            } else if (error.message) {
              errorMessage = error.message;
            }
            
            this.snackBar.open(errorMessage, 'Close', {
              duration: 5000,
              panelClass: ['error-snackbar']
            });
            
            throw error;
          })
        )
        .subscribe({
          next: (shopProduct) => {
            this.isLoading = false;
            
            this.snackBar.open('Product created and added to your shop successfully!', 'Close', {
              duration: 3000,
              horizontalPosition: 'end',
              verticalPosition: 'top',
              panelClass: ['success-snackbar']
            });

            // Navigate back to products list
            this.router.navigate(['/shop-owner/products']);
          },
          error: () => {
            // Error already handled in catchError
          }
        });
    } else {
      if (!this.currentShop) {
        this.snackBar.open('Shop information not loaded. Please refresh the page.', 'Close', { duration: 5000 });
      } else {
        this.markAllFieldsAsTouched();
      }
    }
  }

  saveDraft(): void {
    console.log('Saving as draft:', this.productForm.value);
    this.snackBar.open('Product saved as draft', 'Close', { duration: 3000 });
  }

  resetForm(): void {
    this.productForm.reset();
    this.removeImage();
    this.productForm.patchValue({
      isActive: true,
      isFeatured: false,
      trackStock: true
    });
  }

  private markAllFieldsAsTouched(): void {
    Object.keys(this.productForm.controls).forEach(key => {
      this.productForm.get(key)?.markAsTouched();
    });
  }
}