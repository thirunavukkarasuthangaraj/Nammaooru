import { Component, OnInit, Output, EventEmitter, Input } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { MasterProduct, MasterProductRequest, ProductCategory, ProductStatus } from '../../../../core/models/product.model';
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
                  <mat-label>Product Name</mat-label>
                  <input matInput formControlName="name" placeholder="Enter product name">
                  <mat-icon matSuffix>title</mat-icon>
                  <mat-error *ngIf="productForm.get('name')?.hasError('required')">
                    Product name is required
                  </mat-error>
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
                  </mat-select>
                  <mat-icon matSuffix>category</mat-icon>
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
          </form>
        </mat-card-content>

        <mat-card-actions class="form-actions">
          <button mat-button type="button" (click)="onCancel()" class="cancel-btn">
            <mat-icon>cancel</mat-icon>
            Cancel
          </button>
          <button mat-flat-button color="primary" type="submit" 
                  [disabled]="productForm.invalid || isLoading" 
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
      max-width: 900px;
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
  isLoading = false;
  isEditMode = false;

  constructor(
    private fb: FormBuilder,
    private productService: ProductService,
    private categoryService: ProductCategoryService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.productForm = this.createForm();
  }

  ngOnInit() {
    this.loadCategories();
    this.loadBrands();
    
    // Check if we have a route parameter for edit mode
    const routeId = this.route.snapshot.params['id'];
    if (routeId) {
      this.productId = +routeId;
      this.isEditMode = true;
      this.loadProduct();
    } else if (this.productId) {
      // Fallback to @Input productId
      this.isEditMode = true;
      this.loadProduct();
    }
  }

  private createForm(): FormGroup {
    return this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(255)]],
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
    this.categoryService.getCategories(undefined, true, undefined, 0, 100).subscribe({
      next: (response) => {
        this.categories = response.content || [];
        console.log('Categories loaded:', this.categories);
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load categories',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
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

    this.isLoading = true;
    this.productService.getMasterProduct(this.productId).subscribe({
      next: (product) => {
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

  onSubmit() {
    if (this.productForm.invalid) return;

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
        Swal.fire({
          title: 'Success!',
          text: `Product ${this.isEditMode ? 'updated' : 'created'} successfully!`,
          icon: 'success',
          confirmButtonText: 'OK'
        }).then(() => {
          // Navigate back to product list
          this.router.navigate(['/products/master']);
        });
        this.productSaved.emit(product);
        this.productForm.reset();
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

  onCancel() {
    this.cancelled.emit();
    this.productForm.reset();
    // Navigate back to product list
    this.router.navigate(['/products/master']);
  }
}