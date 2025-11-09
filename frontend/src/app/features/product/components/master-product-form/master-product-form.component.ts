import { Component, OnInit, Output, EventEmitter, Input, ChangeDetectorRef } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { ProductService } from '../../../../core/services/product.service';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { MasterProduct, MasterProductRequest, ProductCategory, ProductStatus, ProductImage } from '../../../../core/models/product.model';
import { API_ENDPOINTS } from '../../../../core/constants/app.constants';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-master-product-form',
  template: `
    <div class="form-wrapper">
      <mat-card class="form-card">
        <mat-card-header class="form-header">
          <div mat-card-avatar class="form-avatar">
            <mat-icon>inventory</mat-icon>
          </div>
          <mat-card-title>{{ isEditMode ? 'Edit Product' : 'Create New Product' }}</mat-card-title>
          <mat-card-subtitle>{{ isEditMode ? 'Update product information' : 'Add a new product to your inventory' }}</mat-card-subtitle>
        </mat-card-header>

        <mat-card-content class="form-content">
          <form [formGroup]="productForm" (ngSubmit)="onSubmit()" class="product-form">
            
            <!-- Basic Information Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">info</mat-icon>
                Basic Information
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Product Name (English)</mat-label>
                  <input matInput formControlName="name" placeholder="Enter product name in English">
                  <mat-icon matSuffix>title</mat-icon>
                  <mat-error *ngIf="productForm.get('name')?.hasError('required')">
                    Product name is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Product Name (Tamil)</mat-label>
                  <input matInput formControlName="nameTamil" placeholder="தயவுசெய்து பொருளின் பெயரை உள்ளிடவும்">
                  <mat-icon matSuffix>translate</mat-icon>
                  <mat-hint>Optional - Enter product name in Tamil</mat-hint>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>SKU</mat-label>
                  <input matInput formControlName="sku" placeholder="Enter SKU">
                  <mat-icon matSuffix>qr_code</mat-icon>
                  <mat-error *ngIf="productForm.get('sku')?.hasError('required')">
                    SKU is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Category</mat-label>
                  <mat-select formControlName="categoryId">
                    <mat-option *ngFor="let category of categories" [value]="category.id">
                      {{ category.name }}
                    </mat-option>
                    <mat-option *ngIf="categories.length === 0" value="" disabled>
                      No categories available
                    </mat-option>
                  </mat-select>
                  <mat-icon matSuffix>category</mat-icon>
                  <mat-hint *ngIf="categories.length === 0" class="no-categories-hint">
                    <a routerLink="/products/categories/new" target="_blank">Create categories first</a>
                  </mat-hint>
                  <mat-error *ngIf="productForm.get('categoryId')?.hasError('required')">
                    Category is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Brand</mat-label>
                  <mat-select formControlName="brand">
                    <mat-option value="">None</mat-option>
                    <mat-option *ngFor="let brand of brands" [value]="brand">
                      {{ brand }}
                    </mat-option>
                  </mat-select>
                  <mat-icon matSuffix>business</mat-icon>
                </mat-form-field>
              </div>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Description</mat-label>
                <textarea matInput formControlName="description" rows="3" placeholder="Enter product description"></textarea>
                <mat-icon matSuffix>description</mat-icon>
              </mat-form-field>
            </div>

            <!-- Product Details Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">inventory_2</mat-icon>
                Product Details
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Barcode</mat-label>
                  <input matInput formControlName="barcode" placeholder="Enter barcode">
                  <mat-icon matSuffix>barcode</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Status</mat-label>
                  <mat-select formControlName="status">
                    <mat-option value="ACTIVE">
                      <mat-icon class="status-icon active">check_circle</mat-icon>
                      Active
                    </mat-option>
                    <mat-option value="INACTIVE">
                      <mat-icon class="status-icon inactive">pause_circle</mat-icon>
                      Inactive
                    </mat-option>
                    <mat-option value="DISCONTINUED">
                      <mat-icon class="status-icon discontinued">cancel</mat-icon>
                      Discontinued
                    </mat-option>
                  </mat-select>
                  <mat-icon matSuffix>toggle_on</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Base Unit</mat-label>
                  <input matInput formControlName="baseUnit" placeholder="kg, ltr, pcs">
                  <mat-icon matSuffix>straighten</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Base Weight</mat-label>
                  <input matInput formControlName="baseWeight" type="number" step="0.01" placeholder="0.00">
                  <mat-icon matSuffix>scale</mat-icon>
                </mat-form-field>
              </div>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Specifications</mat-label>
                <textarea matInput formControlName="specifications" rows="3" placeholder="Enter product specifications"></textarea>
                <mat-icon matSuffix>settings</mat-icon>
              </mat-form-field>
            </div>

            <!-- Settings Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">tune</mat-icon>
                Settings
              </h3>
              
              <div class="checkbox-group">
                <mat-checkbox formControlName="isFeatured" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">star</mat-icon>
                    <div>
                      <div class="checkbox-title">Featured Product</div>
                      <div class="checkbox-subtitle">Show this product prominently</div>
                    </div>
                  </div>
                </mat-checkbox>

                <mat-checkbox formControlName="isGlobal" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">public</mat-icon>
                    <div>
                      <div class="checkbox-title">Global Product</div>
                      <div class="checkbox-subtitle">Available to all shops</div>
                    </div>
                  </div>
                </mat-checkbox>
              </div>
            </div>

            <!-- Product Images Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">photo_library</mat-icon>
                Product Images
              </h3>
              
              <!-- Image Selection for new products -->
              <div *ngIf="!isEditMode" class="image-selection-section">
                <div class="image-upload-info">
                  <mat-chip color="primary" selected>
                    <mat-icon matChipLeadingIcon>info</mat-icon>
                    Select images - they'll be uploaded when you save the product
                  </mat-chip>
                </div>
                
                <div class="file-selection-area" 
                     [class.drag-over]="isDragOver"
                     (dragover)="onDragOver($event)"
                     (dragleave)="onDragLeave($event)"
                     (drop)="onDrop($event)"
                     (click)="fileInput.click()">
                  
                  <input #fileInput
                         type="file"
                         multiple
                         accept="image/*"
                         (change)="onFilesSelected($event)"
                         style="display: none;">
                  
                  <div class="upload-content">
                    <mat-icon class="upload-icon">cloud_upload</mat-icon>
                    <h4>Select images for your product</h4>
                    <p>Drag & drop or click to choose images</p>
                  </div>
                </div>
                
                <!-- Selected Images Preview -->
                <div *ngIf="selectedFiles.length > 0" class="selected-images-preview">
                  <h4>Selected Images ({{ selectedFiles.length }})</h4>
                  <div class="preview-grid">
                    <div *ngFor="let file of selectedFiles; let i = index" class="preview-item">
                      <img [src]="getFilePreview(file)" 
                           [alt]="file.name"
                           class="preview-image">
                      <div class="preview-info">
                        <span class="file-name">{{ file.name }}</span>
                        <button mat-icon-button 
                                color="warn"
                                (click)="removeSelectedFile(i)"
                                matTooltip="Remove image">
                          <mat-icon>close</mat-icon>
                        </button>
                      </div>
                      <div class="primary-badge" *ngIf="i === 0">
                        <mat-chip color="primary" selected>Primary</mat-chip>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Image Upload for existing products -->
              <div *ngIf="isEditMode && productId">
                <app-product-image-upload
                  title="Master Product Images"
                  [productId]="productId"
                  productType="master"
                  [images]="productImages"
                  (imagesChange)="onImagesChange($event)"
                  (imagesUploaded)="onImagesUploaded($event)">
                </app-product-image-upload>
              </div>
            </div>
          </form>
        </mat-card-content>

        <mat-card-actions class="form-actions">
          <button mat-button type="button" (click)="onCancel()" class="cancel-btn">
            <mat-icon>cancel</mat-icon>
            Cancel
          </button>
          <button mat-flat-button color="primary" type="submit" 
                  [disabled]="isLoading" 
                  (click)="onSubmit()" 
                  class="submit-btn">
            <mat-spinner diameter="20" *ngIf="isLoading" class="loading-spinner"></mat-spinner>
            <mat-icon *ngIf="!isLoading">{{ isEditMode ? 'update' : 'add' }}</mat-icon>
            {{ isLoading ? 'Saving...' : (isEditMode ? 'Update Product' : 'Create Product') }}
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .form-wrapper {
      min-height: 100vh;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: flex-start;
      justify-content: center;
    }

    .form-card {
      width: 100%;
      // max-width: 900px;
      margin: 20px auto;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
      overflow: hidden;
    }

    .form-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 24px;
    }

    .form-header .mat-mdc-card-title {
      color: white !important;
      font-size: 1.5rem;
      font-weight: 600;
    }

    .form-header .mat-mdc-card-subtitle {
      color: rgba(255, 255, 255, 0.8) !important;
      margin-top: 8px;
    }

    .form-avatar {
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      width: 48px;
      height: 48px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 16px;
    }

    .form-avatar mat-icon {
      color: white;
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    .form-content {
      padding: 32px;
      background: #fafafa;
    }

    .product-form {
      display: flex;
      flex-direction: column;
      gap: 32px;
    }

    .form-section {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
      border: 1px solid #e0e0e0;
    }

    .section-title {
      display: flex;
      align-items: center;
      margin: 0 0 24px 0;
      color: #333;
      font-size: 1.1rem;
      font-weight: 600;
    }

    .section-icon {
      margin-right: 12px;
      color: #667eea;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }

    .form-field {
      width: 100%;
    }

    .form-field.full-width {
      grid-column: 1 / -1;
    }

    .mat-mdc-form-field {
      font-size: 14px;
    }

    .mat-mdc-form-field-outline {
      border-radius: 8px;
    }

    .mat-mdc-text-field-wrapper {
      padding: 0 16px;
    }

    .status-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      margin-right: 8px;
      vertical-align: middle;
    }

    .status-icon.active {
      color: #4caf50;
    }

    .status-icon.inactive {
      color: #ff9800;
    }

    .status-icon.discontinued {
      color: #f44336;
    }

    .checkbox-group {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .feature-checkbox {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 8px;
      padding: 16px;
      transition: all 0.2s ease;
    }

    .feature-checkbox:hover {
      background: #e8f0fe;
      border-color: #1976d2;
    }

    .checkbox-content {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .checkbox-icon {
      color: #667eea;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .checkbox-title {
      font-weight: 600;
      color: #333;
      margin-bottom: 4px;
    }

    .checkbox-subtitle {
      font-size: 12px;
      color: #666;
    }

    .form-actions {
      background: white;
      padding: 24px 32px;
      border-top: 1px solid #e0e0e0;
      display: flex;
      gap: 16px;
      justify-content: flex-end;
    }

    .cancel-btn {
      padding: 8px 24px;
      border-radius: 8px;
      color: #666;
      border: 1px solid #ddd;
    }

    .cancel-btn:hover {
      background: #f5f5f5;
    }

    .submit-btn {
      padding: 8px 32px;
      border-radius: 8px;
      font-weight: 600;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .submit-btn:disabled {
      background: #ccc;
      color: #666;
    }

    .loading-spinner {
      margin-right: 8px;
    }

    .no-categories-hint {
      color: #ff9800 !important;
      font-size: 12px;
    }

    .no-categories-hint a {
      color: #ff9800;
      text-decoration: underline;
      font-weight: 500;
    }

    .no-categories-hint a:hover {
      color: #f57c00;
    }

    .image-selection-section {
      width: 100%;
    }

    .image-upload-info {
      margin-bottom: 16px;
    }

    .file-selection-area {
      border: 2px dashed #ddd;
      border-radius: 8px;
      padding: 40px 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      background: #fafafa;
      margin-bottom: 20px;
    }

    .file-selection-area:hover, .file-selection-area.drag-over {
      border-color: #667eea;
      background: #f5f7ff;
    }

    .upload-content {
      pointer-events: none;
    }

    .upload-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      color: #999;
      margin-bottom: 16px;
    }

    .upload-content h4 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .upload-content p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .selected-images-preview {
      margin-top: 20px;
    }

    .selected-images-preview h4 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .preview-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: 16px;
    }

    .preview-item {
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      overflow: hidden;
      background: #fff;
      position: relative;
    }

    .preview-image {
      width: 100%;
      height: 120px;
      object-fit: cover;
      display: block;
    }

    .preview-info {
      padding: 8px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .file-name {
      font-size: 12px;
      color: #666;
      flex: 1;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      margin-right: 8px;
    }

    .primary-badge {
      position: absolute;
      top: 8px;
      left: 8px;
    }

    .submit-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    /* Responsive Design */
    @media (max-width: 768px) {
      .form-wrapper {
        padding: 10px;
      }

      .form-card {
        margin: 10px;
        border-radius: 12px;
      }

      .form-content {
        padding: 20px;
      }

      .form-section {
        padding: 20px;
      }

      .form-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .form-actions {
        padding: 20px;
        flex-direction: column-reverse;
      }

      .cancel-btn,
      .submit-btn {
        width: 100%;
        justify-content: center;
      }
    }

    /* Focus states */
    .mat-mdc-form-field.mat-focused .mat-mdc-form-field-outline-thick {
      color: #667eea;
    }

    .mat-mdc-form-field.mat-focused .mat-mdc-floating-label {
      color: #667eea;
    }
  `]
})
export class MasterProductFormComponent implements OnInit {
  @Input() productId?: number;
  @Output() productSaved = new EventEmitter<MasterProduct>();
  @Output() cancelled = new EventEmitter<void>();

  productForm: FormGroup;
  categories: ProductCategory[] = [];
  brands: string[] = [];
  productImages: ProductImage[] = [];
  selectedFiles: File[] = [];
  isDragOver = false;
  isLoading = false;
  isEditMode = false;

  constructor(
    private fb: FormBuilder,
    private productService: ProductService,
    private categoryService: ProductCategoryService,
    private route: ActivatedRoute,
    private router: Router,
    private http: HttpClient,
    private cdr: ChangeDetectorRef
  ) {
    this.productForm = this.createForm();
  }

  ngOnInit() {
    // Check if we have a route parameter for edit mode
    const routeId = this.route.snapshot.params['id'];
    if (routeId) {
      this.productId = +routeId;
      this.isEditMode = true;
    } else if (this.productId) {
      // Fallback to @Input productId
      this.isEditMode = true;
    }
    
    // Load categories first, then load product if in edit mode
    this.loadCategories();
    this.loadBrands();
  }

  private createForm(): FormGroup {
    return this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(255)]],
      nameTamil: ['', [Validators.maxLength(255)]],
      description: [''],
      sku: ['', [Validators.required, Validators.maxLength(50)]],
      barcode: [''],
      categoryId: [null, Validators.required],
      brand: [''],
      baseUnit: [''],
      baseWeight: [null, [Validators.min(0)]],
      specifications: [''],
      status: [ProductStatus.ACTIVE],
      isFeatured: [false],
      isGlobal: [false]
    });
  }

  private loadCategories() {
    console.log('Loading categories...');
    
    // Try the root categories method first (simpler)
    this.categoryService.getRootCategories(true).subscribe({
      next: (categories) => {
        this.categories = categories || [];
        console.log('Root categories loaded successfully:', this.categories.length, 'categories found');
        console.log('Categories:', this.categories);
        
        if (this.categories.length === 0) {
          console.warn('No root categories found. Trying all categories...');
          this.loadCategoriesAlternative();
        } else {
          // Categories loaded successfully, now load product if in edit mode
          this.onCategoriesLoaded();
        }
      },
      error: (error) => {
        console.error('Error loading root categories:', error);
        console.log('Trying paginated categories method...');
        this.loadCategoriesAlternative();
      }
    });
  }

  private loadCategoriesAlternative() {
    // Try the paginated method with simple parameters
    this.categoryService.getCategories(undefined, true, undefined, 0, 100).subscribe({
      next: (response) => {
        this.categories = response.content || [];
        console.log('Categories loaded (paginated method):', this.categories.length, 'categories found');
        console.log('Categories data:', this.categories);
        
        if (this.categories.length === 0) {
          console.warn('No categories available. Please create categories first.');
          // Try loading all categories (including inactive)
          this.loadAllCategories();
        } else {
          // Categories loaded successfully, now load product if in edit mode
          this.onCategoriesLoaded();
        }
      },
      error: (error) => {
        console.error('Error loading categories (paginated):', error);
        console.log('Trying to load all categories...');
        this.loadAllCategories();
      }
    });
  }

  private loadAllCategories() {
    // Final fallback - try without active filter
    this.categoryService.getCategories(undefined, undefined, undefined, 0, 100).subscribe({
      next: (response) => {
        this.categories = response.content || [];
        console.log('All categories loaded (final fallback):', this.categories.length, 'categories found');
        
        if (this.categories.length === 0) {
          console.warn('No categories available at all. Using sample categories for testing.');
          // Temporary: Add sample categories for testing
          this.addSampleCategories();
        } else {
          // Categories loaded successfully, now load product if in edit mode
          this.onCategoriesLoaded();
        }
      },
      error: (error) => {
        console.error('Error loading categories (final fallback):', error);
        console.log('All category loading methods failed. Using sample categories.');
        this.addSampleCategories();
      }
    });
  }

  private addSampleCategories() {
    // Temporary sample categories for testing
    this.categories = [
      { 
        id: 1, 
        name: 'Electronics', 
        slug: 'electronics', 
        isActive: true, 
        description: 'Electronic devices and gadgets',
        fullPath: 'Electronics',
        createdBy: 'system',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        productCount: 0,
        subcategoryCount: 0,
        hasSubcategories: false,
        isRootCategory: true
      } as ProductCategory,
      { 
        id: 2, 
        name: 'Computers', 
        slug: 'computers', 
        isActive: true, 
        description: 'Laptops, desktops, and accessories',
        fullPath: 'Computers',
        createdBy: 'system',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        productCount: 0,
        subcategoryCount: 0,
        hasSubcategories: false,
        isRootCategory: true
      } as ProductCategory,
      { 
        id: 3, 
        name: 'Mobile Phones', 
        slug: 'mobile-phones', 
        isActive: true, 
        description: 'Smartphones and mobile accessories',
        fullPath: 'Mobile Phones',
        createdBy: 'system',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        productCount: 0,
        subcategoryCount: 0,
        hasSubcategories: false,
        isRootCategory: true
      } as ProductCategory,
      { 
        id: 4, 
        name: 'Home & Garden', 
        slug: 'home-garden', 
        isActive: true, 
        description: 'Home improvement and garden supplies',
        fullPath: 'Home & Garden',
        createdBy: 'system',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        productCount: 0,
        subcategoryCount: 0,
        hasSubcategories: false,
        isRootCategory: true
      } as ProductCategory
    ];
    console.log('Added sample categories for testing:', this.categories);
    // Categories loaded, now load product if in edit mode
    this.onCategoriesLoaded();
  }

  private onCategoriesLoaded() {
    console.log('Categories loaded, checking if we need to load product data...');
    if (this.isEditMode && this.productId) {
      console.log('Loading product data for editing...');
      this.loadProduct();
    }
  }

  private loadBrands() {
    this.productService.getAllBrands().subscribe({
      next: (brands) => {
        this.brands = brands || [];
        console.log('Brands loaded:', this.brands);
      },
      error: (error) => {
        console.error('Error loading brands:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load brands',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadProduct() {
    if (!this.productId) return;

    console.log('Loading product with ID:', this.productId);
    console.log('Available categories:', this.categories.length);
    
    this.isLoading = true;
    this.productService.getMasterProduct(this.productId).subscribe({
      next: (product) => {
        console.log('Product data received:', product);
        console.log('Product categoryId:', product.categoryId);
        
        // Check if the category exists in our loaded categories
        const categoryExists = this.categories.find(cat => cat.id === product.categoryId);
        console.log('Category exists in dropdown:', categoryExists ? 'Yes' : 'No', categoryExists);
        
        this.productForm.patchValue({
          name: product.name,
          description: product.description,
          sku: product.sku,
          barcode: product.barcode,
          categoryId: product.categoryId,
          brand: product.brand,
          baseUnit: product.baseUnit,
          baseWeight: product.baseWeight,
          specifications: product.specifications,
          status: product.status,
          isFeatured: product.isFeatured,
          isGlobal: product.isGlobal
        });
        
        // Force trigger change detection for the category dropdown
        setTimeout(() => {
          const categoryControl = this.productForm.get('categoryId');
          if (categoryControl && product.categoryId) {
            // Ensure the categoryId is set correctly
            categoryControl.setValue(product.categoryId);
            categoryControl.updateValueAndValidity();
            console.log('Category control value after force set:', categoryControl.value);
            console.log('Category control valid:', categoryControl.valid);
            
            // Also trigger change detection on the component
            this.cdr.detectChanges();
          }
        }, 100);
        
        // Log form status for debugging
        console.log('Form value after patch:', this.productForm.value);
        console.log('Form valid:', this.productForm.valid);
        
        // Check individual field errors
        Object.keys(this.productForm.controls).forEach(key => {
          const control = this.productForm.get(key);
          if (control && control.errors) {
            console.log(`Field '${key}' has errors:`, control.errors);
          }
        });
        
        // Load product images
        this.loadProductImages();
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading product:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load product',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.isLoading = false;
      }
    });
  }

  private loadProductImages() {
    if (!this.productId) return;

    const url = `${API_ENDPOINTS.BASE_URL}/products/images/master/${this.productId}`;
    this.http.get<any>(url).subscribe({
      next: (response) => {
        this.productImages = response.data || [];
        console.log('Product images loaded:', this.productImages);
      },
      error: (error) => {
        console.error('Error loading product images:', error);
        this.productImages = [];
      }
    });
  }

  onSubmit() {
    // Log form state for debugging
    console.log('Form submission attempted');
    console.log('Form valid:', this.productForm.valid);
    console.log('Form value:', this.productForm.value);
    
    if (this.productForm.invalid) {
      // Mark all fields as touched to show validation errors
      Object.keys(this.productForm.controls).forEach(key => {
        const control = this.productForm.get(key);
        control?.markAsTouched();
      });
      
      // Show error message
      Swal.fire({
        title: 'Validation Error',
        text: 'Please fill in all required fields correctly',
        icon: 'warning',
        confirmButtonText: 'OK'
      });
      return;
    }

    this.isLoading = true;
    const formValue = this.productForm.value;
    
    const request: MasterProductRequest = {
      name: formValue.name,
      description: formValue.description || undefined,
      sku: formValue.sku,
      barcode: formValue.barcode || undefined,
      categoryId: formValue.categoryId,
      brand: formValue.brand || undefined,
      baseUnit: formValue.baseUnit || undefined,
      baseWeight: formValue.baseWeight || undefined,
      specifications: formValue.specifications || undefined,
      status: formValue.status,
      isFeatured: formValue.isFeatured,
      isGlobal: formValue.isGlobal
    };

    const operation = this.isEditMode 
      ? this.productService.updateMasterProduct(this.productId!, request)
      : this.productService.createMasterProduct(request);

    operation.subscribe({
      next: (product) => {
        if (this.isEditMode) {
          // For edit mode, show success and navigate back
          Swal.fire({
            title: 'Success!',
            text: 'Product updated successfully!',
            icon: 'success',
            confirmButtonText: 'OK'
          }).then(() => {
            this.router.navigate(['/products/master']);
          });
          this.productSaved.emit(product);
          this.productForm.reset();
        } else {
          // For create mode, upload selected images if any
          this.productId = product.id;
          if (this.selectedFiles.length > 0) {
            this.uploadSelectedImages(product.id).then(() => {
              Swal.fire({
                title: 'Success!',
                text: `Product created successfully with ${this.selectedFiles.length} image${this.selectedFiles.length > 1 ? 's' : ''}!`,
                icon: 'success',
                confirmButtonText: 'OK'
              }).then(() => {
                this.router.navigate(['/products/master']);
              });
            }).catch(() => {
              Swal.fire({
                title: 'Product Created!',
                text: 'Product created but image upload failed. You can upload images later by editing the product.',
                icon: 'warning',
                confirmButtonText: 'OK'
              }).then(() => {
                this.router.navigate(['/products/master']);
              });
            });
          } else {
            Swal.fire({
              title: 'Success!',
              text: 'Product created successfully!',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.router.navigate(['/products/master']);
            });
          }
          this.productSaved.emit(product);
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error saving product:', error);
        let errorMessage = `Failed to ${this.isEditMode ? 'update' : 'create'} product`;
        if (error.error?.message) {
          errorMessage = error.error.message;
        }
        Swal.fire({
          title: 'Error!',
          text: errorMessage,
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.isLoading = false;
      }
    });
  }

  onImagesChange(images: ProductImage[]) {
    this.productImages = images;
  }

  onImagesUploaded(images: ProductImage[]) {
    // Images uploaded successfully
    // The productImages array is already updated via onImagesChange
    Swal.fire({
      title: 'Success!',
      text: `${images.length} image${images.length > 1 ? 's' : ''} uploaded successfully!`,
      icon: 'success',
      timer: 2000,
      showConfirmButton: false
    });
  }

  // File handling methods for new product creation
  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;

    const files = event.dataTransfer?.files;
    if (files) {
      this.handleFileSelection(Array.from(files));
    }
  }

  onFilesSelected(event: any): void {
    const files = event.target.files;
    if (files) {
      this.handleFileSelection(Array.from(files));
    }
  }

  private handleFileSelection(files: File[]): void {
    const validFiles = files.filter(file => this.validateFile(file));
    this.selectedFiles = [...this.selectedFiles, ...validFiles];
  }

  private validateFile(file: File): boolean {
    // Check file type
    if (!file.type.startsWith('image/')) {
      Swal.fire({
        title: 'Invalid File',
        text: `${file.name} is not a valid image file`,
        icon: 'error',
        confirmButtonText: 'OK'
      });
      return false;
    }

    // Check file size (5MB limit)
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      Swal.fire({
        title: 'File Too Large',
        text: `${file.name} is too large (max 5MB)`,
        icon: 'error',
        confirmButtonText: 'OK'
      });
      return false;
    }

    return true;
  }

  getFilePreview(file: File): string {
    return URL.createObjectURL(file);
  }

  removeSelectedFile(index: number): void {
    this.selectedFiles.splice(index, 1);
  }

  private async uploadSelectedImages(productId: number): Promise<void> {
    if (this.selectedFiles.length === 0) return;

    const formData = new FormData();
    this.selectedFiles.forEach(file => {
      formData.append('images', file);
    });

    const url = `${API_ENDPOINTS.BASE_URL}/products/images/master/${productId}`;

    return new Promise((resolve, reject) => {
      this.http.post<any>(url, formData).subscribe({
        next: (response) => {
          this.selectedFiles = []; // Clear selected files
          resolve();
        },
        error: (error) => {
          console.error('Error uploading images:', error);
          reject(error);
        }
      });
    });
  }

  onCancel() {
    this.cancelled.emit();
    this.productForm.reset();
    this.selectedFiles = []; // Clear selected files
    // Navigate back to product list
    this.router.navigate(['/products/master']);
  }
}