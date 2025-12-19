import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { ShopProductService } from '../../../../core/services/shop-product.service';
import { ShopService } from '../../../../core/services/shop.service';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { MasterProduct, ShopProductRequest, ShopProductStatus, ProductImage, MasterProductRequest, ProductCategory } from '../../../../core/models/product.model';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

@Component({
  selector: 'app-shop-product-form',
  template: `
    <div class="form-wrapper">
      <mat-card class="form-card">
        <mat-card-header class="form-header">
          <div class="header-content">
            <button mat-icon-button (click)="onCancel()" class="back-button" type="button">
              <mat-icon>arrow_back</mat-icon>
            </button>
            <div class="header-info">
              <div mat-card-avatar class="form-avatar">
                <mat-icon>{{ isEditMode ? 'edit' : 'add_shopping_cart' }}</mat-icon>
              </div>
              <div class="header-text">
                <mat-card-title>{{ isEditMode ? 'Edit Shop Product' : 'Add New Product' }}</mat-card-title>
                <mat-card-subtitle>{{ isEditMode ? 'Update product pricing and inventory' : 'Create a new master product and add it to your shop' }}</mat-card-subtitle>
              </div>
            </div>
          </div>
        </mat-card-header>

        <mat-card-content class="form-content">
          <form [formGroup]="shopProductForm" (ngSubmit)="onSubmit()" class="product-form">
            
            <!-- Shop Info (Read-only) -->
            <div class="form-section" *ngIf="shop">
              <h3 class="section-title">
                <mat-icon class="section-icon">store</mat-icon>
                Shop Information
              </h3>
              <div class="shop-info">
                <mat-chip-set>
                  <mat-chip color="primary" selected>{{ shop.name }}</mat-chip>
                  <mat-chip color="accent" selected>{{ shop.businessType }}</mat-chip>
                </mat-chip-set>
              </div>
            </div>

            <!-- Master Product Selection (Edit Mode) -->
            <div class="form-section" *ngIf="isEditMode && selectedMasterProduct">
              <h3 class="section-title">
                <mat-icon class="section-icon">inventory</mat-icon>
                Master Product Information
              </h3>
              
              <div class="master-product-info">
                <mat-card class="product-preview-card">
                  <mat-card-header>
                    <div mat-card-avatar class="product-avatar">
                      <img *ngIf="selectedMasterProduct.primaryImageUrl" 
                           [src]="getImageUrl(selectedMasterProduct.primaryImageUrl)" 
                           [alt]="selectedMasterProduct.name"
                           (error)="onImageError($event)">
                      <mat-icon *ngIf="!selectedMasterProduct.primaryImageUrl">inventory</mat-icon>
                    </div>
                    <mat-card-title>{{ selectedMasterProduct.name }}</mat-card-title>
                    <mat-card-subtitle>{{ selectedMasterProduct.brand || 'No brand' }} • SKU: {{ selectedMasterProduct.sku }}</mat-card-subtitle>
                  </mat-card-header>
                  <mat-card-content>
                    <div class="product-details">
                      <div class="detail-item">
                        <span class="detail-label">Category:</span>
                        <span>{{ selectedMasterProduct.category?.name || 'No category' }}</span>
                      </div>
                      <div class="detail-item">
                        <span class="detail-label">Base Unit:</span>
                        <span>{{ selectedMasterProduct.baseWeight || 1 }} {{ selectedMasterProduct.baseUnit || 'piece' }}</span>
                      </div>
                      <div class="detail-item" *ngIf="selectedMasterProduct.description">
                        <span class="detail-label">Description:</span>
                        <span>{{ selectedMasterProduct.description }}</span>
                      </div>
                    </div>
                  </mat-card-content>
                </mat-card>
              </div>
            </div>

            <!-- Master Product Information (Create Mode) -->
            <div class="form-section" *ngIf="!isEditMode">
              <h3 class="section-title">
                <mat-icon class="section-icon">inventory</mat-icon>
                Product Information
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Product Name *</mat-label>
                  <input matInput formControlName="productName" placeholder="Enter product name">
                  <mat-icon matSuffix>title</mat-icon>
                  <mat-error *ngIf="shopProductForm.get('productName')?.hasError('required')">
                    Product name is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>SKU *</mat-label>
                  <input matInput formControlName="sku" placeholder="Enter SKU">
                  <mat-icon matSuffix>qr_code</mat-icon>
                  <mat-error *ngIf="shopProductForm.get('sku')?.hasError('required')">
                    SKU is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Brand</mat-label>
                  <input matInput formControlName="brand" placeholder="Enter brand name">
                  <mat-icon matSuffix>business</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Category *</mat-label>
                  <mat-select formControlName="categoryId">
                    <mat-option value="">Select category...</mat-option>
                    <mat-option *ngFor="let category of categories" [value]="category.id">
                      {{ category.name }}
                    </mat-option>
                  </mat-select>
                  <mat-icon matSuffix>category</mat-icon>
                  <mat-error *ngIf="shopProductForm.get('categoryId')?.hasError('required')">
                    Category is required
                  </mat-error>
                </mat-form-field>
              </div>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Product Description</mat-label>
                <textarea matInput formControlName="productDescription" rows="3" placeholder="Describe the product..."></textarea>
                <mat-icon matSuffix>description</mat-icon>
              </mat-form-field>
            </div>

            <!-- Unit & Measurement Section -->
            <div class="form-section" *ngIf="!isEditMode">
              <h3 class="section-title">
                <mat-icon class="section-icon">straighten</mat-icon>
                Unit & Measurement
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Unit Type</mat-label>
                  <mat-select formControlName="unitType">
                    <mat-option value="piece">Piece/Item</mat-option>
                    <mat-option value="kg">Kilogram (kg)</mat-option>
                    <mat-option value="gram">Gram (g)</mat-option>
                    <mat-option value="liter">Liter (L)</mat-option>
                    <mat-option value="ml">Milliliter (ml)</mat-option>
                    <mat-option value="meter">Meter (m)</mat-option>
                    <mat-option value="box">Box/Pack</mat-option>
                    <mat-option value="dozen">Dozen</mat-option>
                  </mat-select>
                  <mat-icon matSuffix>straighten</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Unit Size/Weight</mat-label>
                  <input matInput formControlName="unitSize" type="number" placeholder="e.g., 1, 500, 250">
                  <mat-icon matSuffix>fitness_center</mat-icon>
                  <mat-hint>Enter the quantity per unit</mat-hint>
                </mat-form-field>
              </div>
            </div>

            <!-- Product Images Section -->
            <div class="form-section" *ngIf="!isEditMode">
              <h3 class="section-title">
                <mat-icon class="section-icon">photo_camera</mat-icon>
                Product Images
              </h3>
              
              <div class="image-upload-area">
                <div class="upload-placeholder" *ngIf="selectedFiles.length === 0">
                  <mat-icon class="upload-icon">cloud_upload</mat-icon>
                  <p>Click to upload product images</p>
                  <span class="upload-hint">Supports: JPG, PNG (Max 5MB)</span>
                  <input type="file" accept="image/*" multiple (change)="onFileSelected($event)" hidden #fileInput>
                  <button mat-stroked-button color="primary" type="button" (click)="fileInput.click()">
                    <mat-icon>add_photo_alternate</mat-icon>
                    Choose Images
                  </button>
                </div>
                
                <div class="selected-images" *ngIf="selectedFiles.length > 0">
                  <div class="image-preview" *ngFor="let file of selectedFiles; let i = index">
                    <img [src]="file.preview" [alt]="file.name">
                    <button mat-icon-button color="warn" (click)="removeFile(i)" class="remove-btn" type="button">
                      <mat-icon>close</mat-icon>
                    </button>
                    <span class="file-name">{{ file.name }}</span>
                  </div>
                  <button mat-stroked-button color="primary" type="button" (click)="fileInput.click()" class="add-more-btn">
                    <mat-icon>add</mat-icon>
                    Add More
                  </button>
                  <input type="file" accept="image/*" multiple (change)="onFileSelected($event)" hidden #fileInput>
                </div>
              </div>
            </div>

            <!-- Pricing Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">attach_money</mat-icon>
                Pricing Information
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Selling Price *</mat-label>
                  <input matInput formControlName="price" type="number" step="0.01" min="0" placeholder="0.00">
                  <span matTextPrefix>₹</span>
                  <mat-icon matSuffix>sell</mat-icon>
                  <mat-error *ngIf="shopProductForm.get('price')?.hasError('required')">
                    Price is required
                  </mat-error>
                  <mat-error *ngIf="shopProductForm.get('price')?.hasError('min')">
                    Price must be positive
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Original Price</mat-label>
                  <input matInput formControlName="originalPrice" type="number" step="0.01" min="0" placeholder="0.00">
                  <span matTextPrefix>₹</span>
                  <mat-icon matSuffix>local_offer</mat-icon>
                  <mat-hint>MSRP or original price</mat-hint>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Cost Price</mat-label>
                  <input matInput formControlName="costPrice" type="number" step="0.01" min="0" placeholder="0.00">
                  <span matTextPrefix>₹</span>
                  <mat-icon matSuffix>receipt</mat-icon>
                  <mat-hint>Your cost for this product</mat-hint>
                </mat-form-field>

                <!-- Profit Margin Display -->
                <div class="profit-display" *ngIf="getProfit() !== null">
                  <mat-card class="profit-card">
                    <mat-card-content>
                      <div class="profit-info">
                        <span class="profit-label">Profit Margin:</span>
                        <span class="profit-value" [class.positive]="getProfit()! > 0" [class.negative]="getProfit()! < 0">
                          ₹{{ getProfit() | number:'1.2-2' }} ({{ getProfitPercentage()?.toFixed(1) }}%)
                        </span>
                      </div>
                    </mat-card-content>
                  </mat-card>
                </div>
              </div>
            </div>

            <!-- Inventory Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">inventory_2</mat-icon>
                Inventory Management
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Stock Quantity</mat-label>
                  <input matInput formControlName="stockQuantity" type="number" min="0" placeholder="0">
                  <mat-icon matSuffix>inventory</mat-icon>
                  <mat-hint>Current inventory count</mat-hint>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Minimum Stock Level</mat-label>
                  <input matInput formControlName="minStockLevel" type="number" min="0" placeholder="0">
                  <mat-icon matSuffix>warning</mat-icon>
                  <mat-hint>Reorder when stock reaches this level</mat-hint>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Maximum Stock Level</mat-label>
                  <input matInput formControlName="maxStockLevel" type="number" min="0" placeholder="0">
                  <mat-icon matSuffix>storage</mat-icon>
                  <mat-hint>Maximum inventory to maintain</mat-hint>
                </mat-form-field>
              </div>

              <div class="checkbox-group">
                <mat-checkbox formControlName="trackInventory" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">track_changes</mat-icon>
                    <div>
                      <div class="checkbox-title">Track Inventory</div>
                      <div class="checkbox-subtitle">Monitor stock levels and get low stock alerts</div>
                    </div>
                  </div>
                </mat-checkbox>
              </div>
            </div>

            <!-- Product Settings -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">settings</mat-icon>
                Product Settings
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Status</mat-label>
                  <mat-select formControlName="status">
                    <mat-option value="ACTIVE">Active</mat-option>
                    <mat-option value="INACTIVE">Inactive</mat-option>
                    <mat-option value="OUT_OF_STOCK">Out of Stock</mat-option>
                    <mat-option value="DISCONTINUED">Discontinued</mat-option>
                  </mat-select>
                  <mat-icon matSuffix>flag</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Display Order</mat-label>
                  <input matInput formControlName="displayOrder" type="number" min="0" placeholder="0">
                  <mat-icon matSuffix>sort</mat-icon>
                  <mat-hint>Lower numbers appear first</mat-hint>
                </mat-form-field>
              </div>

              <div class="checkbox-group">
                <mat-checkbox formControlName="isAvailable" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">visibility</mat-icon>
                    <div>
                      <div class="checkbox-title">Available for Sale</div>
                      <div class="checkbox-subtitle">Show this product on your storefront</div>
                    </div>
                  </div>
                </mat-checkbox>

                <mat-checkbox formControlName="isFeatured" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">star</mat-icon>
                    <div>
                      <div class="checkbox-title">Featured Product</div>
                      <div class="checkbox-subtitle">Highlight this product in your shop</div>
                    </div>
                  </div>
                </mat-checkbox>
              </div>
            </div>

            <!-- Customization Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">edit</mat-icon>
                Shop Customization (Optional)
              </h3>
              
              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Custom Name</mat-label>
                <input matInput formControlName="customName" placeholder="Override product name for your shop">
                <mat-icon matSuffix>title</mat-icon>
                <mat-hint>Leave empty to use master product name</mat-hint>
              </mat-form-field>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Custom Description</mat-label>
                <textarea matInput formControlName="customDescription" rows="3" placeholder="Add shop-specific description..."></textarea>
                <mat-icon matSuffix>description</mat-icon>
                <mat-hint>Additional description for your customers</mat-hint>
              </mat-form-field>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Tags</mat-label>
                <input matInput formControlName="tags" placeholder="tag1, tag2, tag3">
                <mat-icon matSuffix>local_offer</mat-icon>
                <mat-hint>Comma-separated tags for better searchability</mat-hint>
              </mat-form-field>
            </div>

            <!-- Shop Product Images Section -->
            <div class="form-section" *ngIf="isEditMode && productId">
              <h3 class="section-title">
                <mat-icon class="section-icon">photo_camera</mat-icon>
                Shop Product Images
              </h3>
              <div class="image-section-info">
                <mat-chip-set>
                  <mat-chip color="primary">Shop-specific images</mat-chip>
                  <mat-chip color="accent">Override master product images</mat-chip>
                </mat-chip-set>
              </div>
              
              <app-product-image-upload
                title="Shop Product Images"
                [productId]="productId"
                [shopId]="shopId"
                productType="shop"
                [images]="productImages"
                (imagesChange)="onImagesChange($event)"
                (imagesUploaded)="onImagesUploaded($event)">
              </app-product-image-upload>
            </div>

          </form>
        </mat-card-content>

        <mat-card-actions class="form-actions">
          <button mat-button type="button" (click)="onCancel()" class="cancel-btn">
            <mat-icon>cancel</mat-icon>
            Cancel
          </button>
          <button mat-flat-button color="primary" type="submit" 
                  [disabled]="!canSubmit() || isLoading" 
                  (click)="onSubmit()" 
                  class="submit-btn">
            <mat-spinner diameter="20" *ngIf="isLoading" class="loading-spinner"></mat-spinner>
            <mat-icon *ngIf="!isLoading">{{ isEditMode ? 'update' : 'add_circle' }}</mat-icon>
            {{ isLoading ? (isEditMode ? 'Updating Product...' : 'Creating Product...') : (isEditMode ? 'Update Product' : 'Create Product') }}
          </button>
          
          <!-- Debug info (remove in production) -->
          <div class="debug-info" *ngIf="!canSubmit() && !isLoading" style="margin-top: 8px; font-size: 12px; color: #dc3545;">
            Form Status: {{ shopProductForm.valid ? 'Valid' : 'Invalid' }}
            <span *ngIf="!shopProductForm.valid"> - Missing: {{ getInvalidFields() }}</span>
          </div>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .form-wrapper {
      min-height: 100vh;
      padding: 20px;
      background: linear-gradient(135deg, #4CAF50 0%, #66BB6A 100%);
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
      background: #4CAF50;
      color: white;
      padding: 24px;
    }

    .header-content {
      display: flex;
      align-items: center;
      gap: 16px;
      width: 100%;
    }

    .back-button {
      color: white !important;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 50%;
      transition: all 0.3s ease;
    }

    .back-button:hover {
      background: rgba(255, 255, 255, 0.2);
      transform: scale(1.05);
    }

    .header-info {
      display: flex;
      align-items: center;
      gap: 16px;
      flex: 1;
    }

    .header-text {
      flex: 1;
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
      color: #4CAF50;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }

    .form-field {
      width: 100%;
    }

    .full-width {
      grid-column: 1 / -1;
    }

    .shop-info {
      margin-bottom: 16px;
    }

    .product-preview {
      margin-top: 16px;
    }

    .preview-card {
      border: 2px solid #667eea;
      border-radius: 8px;
    }

    .profit-display {
      grid-column: 1 / -1;
    }

    .profit-card {
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      border-radius: 8px;
    }

    .profit-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .profit-label {
      font-weight: 600;
      color: #495057;
    }

    .profit-value {
      font-size: 1.2rem;
      font-weight: bold;
    }

    .profit-value.positive {
      color: #28a745;
    }

    .profit-value.negative {
      color: #dc3545;
    }

    .checkbox-group {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .feature-checkbox {
      padding: 12px;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      background: #f8f9fa;
    }

    .checkbox-content {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .checkbox-icon {
      color: #4CAF50;
    }

    .checkbox-title {
      font-weight: 600;
      margin-bottom: 4px;
    }

    .checkbox-subtitle {
      font-size: 0.875rem;
      color: #666;
    }

    .form-actions {
      padding: 24px 32px;
      background: white;
      display: flex;
      gap: 16px;
      justify-content: flex-end;
      border-top: 1px solid #e0e0e0;
    }

    .cancel-btn {
      min-width: 120px;
    }

    .submit-btn {
      min-width: 160px;
    }

    .loading-spinner {
      margin-right: 8px;
    }

    @media (max-width: 768px) {
      .form-wrapper {
        padding: 10px;
      }

      .form-card {
        margin: 10px;
        border-radius: 12px;
      }

      .form-header {
        padding: 16px;
      }

      .header-content {
        gap: 12px;
      }

      .header-info {
        gap: 12px;
      }

      .form-avatar {
        width: 40px !important;
        height: 40px !important;
      }

      .form-avatar mat-icon {
        font-size: 20px !important;
        width: 20px !important;
        height: 20px !important;
      }

      .form-header .mat-mdc-card-title {
        font-size: 1.2rem !important;
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

      .product-details {
        gap: 6px;
      }

      .detail-item {
        flex-direction: column;
        gap: 2px;
      }

      .detail-label {
        min-width: auto;
        font-size: 12px;
      }
    }

    .image-section-info {
      margin-bottom: 16px;
    }

    .master-product-info {
      margin-bottom: 16px;
    }

    .product-preview-card {
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      border: 2px solid #667eea;
      border-radius: 12px;
    }

    .product-avatar {
      width: 60px !important;
      height: 60px !important;
      border-radius: 8px !important;
      background: white !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      overflow: hidden !important;
    }

    .product-avatar img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 8px;
    }

    .product-avatar mat-icon {
      color: #667eea;
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .product-details {
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin-top: 12px;
    }

    .detail-item {
      display: flex;
      gap: 8px;
      font-size: 14px;
    }

    .detail-label {
      font-weight: 600;
      color: #495057;
      min-width: 80px;
    }

    .detail-item span:not(.detail-label) {
      color: #6c757d;
      flex: 1;
    }

    .image-upload-area {
      border: 2px dashed #e0e0e0;
      border-radius: 12px;
      padding: 24px;
      background: #fafafa;
      text-align: center;
    }

    .upload-placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
    }

    .upload-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #667eea;
      opacity: 0.7;
    }

    .upload-placeholder p {
      margin: 0;
      font-size: 16px;
      color: #495057;
      font-weight: 500;
    }

    .upload-hint {
      font-size: 12px;
      color: #6c757d;
    }

    .selected-images {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
      gap: 16px;
      margin-top: 20px;
    }

    .image-preview {
      position: relative;
      border-radius: 8px;
      overflow: hidden;
      background: white;
      border: 1px solid #e0e0e0;
    }

    .image-preview img {
      width: 100%;
      height: 120px;
      object-fit: cover;
    }

    .image-preview .remove-btn {
      position: absolute;
      top: 4px;
      right: 4px;
      background: rgba(255, 255, 255, 0.9);
      width: 24px;
      height: 24px;
    }

    .image-preview .remove-btn mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .file-name {
      display: block;
      padding: 4px 8px;
      font-size: 11px;
      color: #495057;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      background: white;
    }
  `]
})
export class ShopProductFormComponent implements OnInit {
  shopProductForm: FormGroup;
  masterProducts: MasterProduct[] = [];
  categories: ProductCategory[] = [];
  selectedMasterProduct: MasterProduct | null = null;
  shop: Shop | null = null;
  productImages: ProductImage[] = [];
  selectedFiles: any[] = [];
  isLoading = false;
  isEditMode = false;
  shopId!: number;
  productId?: number;

  constructor(
    private fb: FormBuilder,
    private productService: ProductService,
    private shopProductService: ShopProductService,
    private shopService: ShopService,
    private categoryService: ProductCategoryService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.shopProductForm = this.createForm();
  }

  ngOnInit() {
    // Get route parameters
    this.shopId = +this.route.snapshot.params['shopId'];
    const routeProductId = this.route.snapshot.params['productId'];
    
    if (routeProductId) {
      this.productId = +routeProductId;
      this.isEditMode = true;
    }

    this.loadShop();
    this.loadCategories();
    
    if (this.isEditMode && this.productId) {
      this.loadMasterProducts();
      this.loadShopProduct();
    }
  }

  private createForm(): FormGroup {
    const baseForm = {
      price: ['', [Validators.required, Validators.min(0.01)]],
      originalPrice: ['', [Validators.min(0)]],
      costPrice: ['', [Validators.min(0)]],
      stockQuantity: [0, [Validators.min(0)]],
      minStockLevel: ['', [Validators.min(0)]],
      maxStockLevel: ['', [Validators.min(0)]],
      trackInventory: [true],
      status: [ShopProductStatus.ACTIVE],
      isAvailable: [true],
      isFeatured: [false],
      customName: [''],
      customDescription: [''],
      tags: [''],
      displayOrder: [0, [Validators.min(0)]]
    };

    if (this.isEditMode) {
      return this.fb.group({
        ...baseForm,
        masterProductId: [null] // Remove required validation for now, will be set when data loads
      });
    } else {
      return this.fb.group({
        ...baseForm,
        productName: ['', Validators.required],
        sku: ['', Validators.required],
        brand: [''],
        categoryId: [null, Validators.required],
        productDescription: [''],
        unitType: ['piece'],
        unitSize: [1, [Validators.min(0.01)]]
      });
    }
  }

  private loadShop() {
    this.shopService.getShop(this.shopId).subscribe({
      next: (shop) => {
        this.shop = shop;
      },
      error: (error) => {
        console.error('Error loading shop:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shop information',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadMasterProducts() {
    this.productService.getMasterProducts().subscribe({
      next: (response) => {
        this.masterProducts = response.content || [];
      },
      error: (error) => {
        console.error('Error loading master products:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load master products',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadCategories() {
    this.categoryService.getRootCategories(true).subscribe({
      next: (categories: ProductCategory[]) => {
        this.categories = categories || [];
      },
      error: (error: any) => {
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

  private loadShopProduct() {
    if (!this.productId) return;

    this.isLoading = true;
    this.shopProductService.getShopProduct(this.shopId, this.productId).subscribe({
      next: (shopProduct) => {
        this.selectedMasterProduct = shopProduct.masterProduct;
        this.shopProductForm.patchValue({
          masterProductId: shopProduct.masterProduct?.id,
          price: shopProduct.price,
          originalPrice: shopProduct.originalPrice,
          costPrice: shopProduct.costPrice,
          stockQuantity: shopProduct.stockQuantity,
          minStockLevel: shopProduct.minStockLevel,
          maxStockLevel: shopProduct.maxStockLevel,
          trackInventory: shopProduct.trackInventory,
          status: shopProduct.status,
          isAvailable: shopProduct.isAvailable,
          isFeatured: shopProduct.isFeatured,
          customName: shopProduct.customName,
          customDescription: shopProduct.customDescription,
          tags: shopProduct.tags,
          displayOrder: shopProduct.displayOrder
        });
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading shop product:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shop product',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.isLoading = false;
      }
    });
  }

  onMasterProductChange(productId: number) {
    this.selectedMasterProduct = this.masterProducts.find(p => p.id === productId) || null;
  }

  getProfit(): number | null {
    const price = this.shopProductForm.get('price')?.value;
    const costPrice = this.shopProductForm.get('costPrice')?.value;
    
    if (price && costPrice) {
      return price - costPrice;
    }
    return null;
  }

  getProfitPercentage(): number | null {
    const price = this.shopProductForm.get('price')?.value;
    const costPrice = this.shopProductForm.get('costPrice')?.value;
    
    if (price && costPrice && costPrice > 0) {
      return ((price - costPrice) / costPrice) * 100;
    }
    return null;
  }

  onSubmit() {
    console.log('onSubmit called', {
      isEditMode: this.isEditMode,
      formValid: this.shopProductForm.valid,
      formValue: this.shopProductForm.value,
      canSubmit: this.canSubmit()
    });

    // Use canSubmit() logic instead of direct form validation
    if (!this.canSubmit()) {
      console.log('Cannot submit - canSubmit returned false');
      return;
    }

    this.isLoading = true;
    const formValue = this.shopProductForm.value;
    
    if (this.isEditMode) {
      console.log('Calling updateShopProduct');
      this.updateShopProduct(formValue);
    } else {
      console.log('Calling createMasterProductAndAssignToShop');
      this.createMasterProductAndAssignToShop(formValue);
    }
  }

  private updateShopProduct(formValue: any) {
    console.log('updateShopProduct called with:', formValue);
    console.log('selectedMasterProduct:', this.selectedMasterProduct);
    console.log('shopId:', this.shopId, 'productId:', this.productId);
    
    // Ensure we have the master product ID from the selected master product
    const masterProductId = this.selectedMasterProduct?.id || formValue.masterProductId;
    
    console.log('masterProductId resolved to:', masterProductId);
    
    if (!masterProductId) {
      console.error('No master product ID found');
      Swal.fire({
        title: 'Error!',
        text: 'Master product information is missing. Please refresh the page and try again.',
        icon: 'error',
        confirmButtonText: 'OK'
      });
      this.isLoading = false;
      return;
    }

    const request: ShopProductRequest = {
      masterProductId: masterProductId,
      price: parseFloat(formValue.price),
      originalPrice: formValue.originalPrice ? parseFloat(formValue.originalPrice) : undefined,
      costPrice: formValue.costPrice ? parseFloat(formValue.costPrice) : undefined,
      stockQuantity: formValue.stockQuantity || 0,
      minStockLevel: formValue.minStockLevel || undefined,
      maxStockLevel: formValue.maxStockLevel || undefined,
      trackInventory: formValue.trackInventory,
      status: formValue.status,
      isAvailable: formValue.isAvailable,
      isFeatured: formValue.isFeatured,
      customName: formValue.customName || undefined,
      customDescription: formValue.customDescription || undefined,
      tags: formValue.tags || undefined,
      displayOrder: formValue.displayOrder || undefined
    };

    console.log('Updating shop product with request:', request);
    console.log('Making API call to updateShopProduct...');

    this.shopProductService.updateShopProduct(this.shopId, this.productId!, request).subscribe({
      next: (shopProduct) => {
        Swal.fire({
          title: 'Success!',
          text: 'Product updated successfully!',
          icon: 'success',
          confirmButtonText: 'OK'
        }).then(() => {
          this.router.navigate(['/products/shop', this.shopId]);
        });
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error updating shop product:', error);
        let errorMessage = 'Failed to update product';
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

  private createMasterProductAndAssignToShop(formValue: any) {
    // First, create the master product
    const masterProductRequest: MasterProductRequest = {
      name: formValue.productName,
      sku: formValue.sku,
      description: formValue.productDescription || '',
      brand: formValue.brand || '',
      categoryId: formValue.categoryId,
      baseUnit: formValue.unitType || 'piece',
      baseWeight: formValue.unitSize || 1
    };

    this.productService.createMasterProduct(masterProductRequest).subscribe({
      next: (masterProduct) => {
        // Master product created successfully
        console.log('Master product created:', masterProduct);
        
        // Upload images if any are selected
        if (this.selectedFiles && this.selectedFiles.length > 0) {
          this.uploadProductImages(masterProduct.id, () => {
            // After images are uploaded, assign product to shop
            this.assignMasterProductToShop(masterProduct.id, formValue);
          });
        } else {
          // No images to upload, directly assign to shop
          this.assignMasterProductToShop(masterProduct.id, formValue);
        }
      },
      error: (error) => {
        console.error('Error creating master product:', error);
        let errorMessage = 'Failed to create master product';
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

  private assignMasterProductToShop(masterProductId: number, formValue: any) {
    const shopProductRequest: ShopProductRequest = {
      masterProductId: masterProductId,
      price: parseFloat(formValue.price),
      originalPrice: formValue.originalPrice ? parseFloat(formValue.originalPrice) : undefined,
      costPrice: formValue.costPrice ? parseFloat(formValue.costPrice) : undefined,
      stockQuantity: formValue.stockQuantity || 0,
      minStockLevel: formValue.minStockLevel || undefined,
      maxStockLevel: formValue.maxStockLevel || undefined,
      trackInventory: formValue.trackInventory,
      status: formValue.status,
      isAvailable: formValue.isAvailable,
      isFeatured: formValue.isFeatured,
      customName: formValue.customName || undefined,
      customDescription: formValue.customDescription || undefined,
      tags: formValue.tags || undefined,
      displayOrder: formValue.displayOrder || undefined
    };

    this.shopProductService.addProductToShop(this.shopId, shopProductRequest).subscribe({
      next: (shopProduct) => {
        const hasImages = this.selectedFiles && this.selectedFiles.length > 0;
        Swal.fire({
          title: 'Success!',
          text: hasImages ? 
            `Product created with ${this.selectedFiles.length} image(s) and added to your shop successfully!` :
            'Product created and added to your shop successfully!',
          icon: 'success',
          confirmButtonText: 'OK'
        }).then(() => {
          this.router.navigate(['/products/shop', this.shopId]);
        });
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error adding product to shop:', error);
        
        // Handle specific "Product already exists" error
        if (error.error?.statusCode === '9999' || error.error?.message?.includes('already exists')) {
          Swal.fire({
            title: 'Product Already Exists',
            text: 'This product is already available in your shop. Would you like to view existing shop products or select a different product?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'View Shop Products',
            cancelButtonText: 'Select Different Product',
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#6c757d'
          }).then((result) => {
            if (result.isConfirmed) {
              // Navigate to shop products list
              this.router.navigate(['/products/shop', this.shopId]);
            } else {
              // Stay on form to select different product
              // Reset form except for shop-specific fields
              this.shopProductForm.patchValue({
                productName: '',
                sku: '',
                brand: '',
                categoryId: null,
                productDescription: ''
              });
            }
          });
        } else {
          // Handle other errors with generic message
          let errorMessage = 'Failed to add product to shop';
          if (error.error?.message) {
            errorMessage = error.error.message;
          }
          Swal.fire({
            title: 'Error!',
            text: errorMessage,
            icon: 'error',
            confirmButtonText: 'OK'
          });
        }
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
      text: `${images.length} shop image${images.length > 1 ? 's' : ''} uploaded successfully!`,
      icon: 'success',
      timer: 2000,
      showConfirmButton: false
    });
  }

  onCancel() {
    this.router.navigate(['/products/shop', this.shopId]);
  }

  onFileSelected(event: any) {
    const files = event.target.files;
    
    if (files && files.length > 0) {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          Swal.fire({
            title: 'Error!',
            text: `File ${file.name} is too large. Maximum size is 5MB.`,
            icon: 'error',
            confirmButtonText: 'OK'
          });
          continue;
        }
        
        // Validate file type
        if (!file.type.startsWith('image/')) {
          Swal.fire({
            title: 'Error!',
            text: `File ${file.name} is not an image.`,
            icon: 'error',
            confirmButtonText: 'OK'
          });
          continue;
        }
        
        // Create preview
        const reader = new FileReader();
        reader.onload = (e: any) => {
          this.selectedFiles.push({
            file: file,
            name: file.name,
            preview: e.target.result
          });
        };
        reader.readAsDataURL(file);
      }
    }
  }

  removeFile(index: number) {
    this.selectedFiles.splice(index, 1);
  }

  canSubmit(): boolean {
    console.log('canSubmit check:', {
      isEditMode: this.isEditMode,
      isLoading: this.isLoading,
      selectedMasterProduct: this.selectedMasterProduct,
      priceValid: this.shopProductForm.get('price')?.valid,
      priceValue: this.shopProductForm.get('price')?.value,
      formValid: this.shopProductForm.valid
    });

    if (this.isEditMode) {
      // For edit mode, just check if price is valid (more lenient)
      const priceControl = this.shopProductForm.get('price');
      const hasValidPrice = priceControl?.valid === true;
      const hasPrice = priceControl?.value && parseFloat(priceControl.value) > 0;
      
      return (hasValidPrice || hasPrice) && !this.isLoading;
    } else {
      // For create mode, all required fields must be valid
      return this.shopProductForm.valid && !this.isLoading;
    }
  }

  getInvalidFields(): string {
    const invalidFields: string[] = [];
    
    Object.keys(this.shopProductForm.controls).forEach(key => {
      const control = this.shopProductForm.get(key);
      if (control && control.invalid && control.errors) {
        if (control.errors['required']) {
          invalidFields.push(key);
        }
      }
    });
    
    return invalidFields.join(', ');
  }

  private uploadProductImages(masterProductId: number, onComplete: () => void) {
    if (!this.selectedFiles || this.selectedFiles.length === 0) {
      onComplete();
      return;
    }

    console.log(`Uploading ${this.selectedFiles.length} images for master product ${masterProductId}`);
    
    // Create FormData for image upload
    const formData = new FormData();
    
    // Add each image file with the correct field name expected by backend
    this.selectedFiles.forEach((fileObj, index) => {
      formData.append('images', fileObj.file);
      console.log(`Adding image ${index + 1}: ${fileObj.file.name} (${fileObj.file.size} bytes, type: ${fileObj.file.type})`);
    });
    
    // Add alt texts (optional - backend expects array)
    const altTexts: string[] = this.selectedFiles.map((fileObj, index) => 
      fileObj.name.replace(/\.[^/.]+$/, "") // Remove file extension for alt text
    );
    altTexts.forEach(altText => {
      formData.append('altTexts', altText);
    });

    console.log('FormData contents:');
    formData.forEach((value, key) => {
      console.log(`${key}:`, value);
    });

    // Upload images to the master product
    this.productService.uploadMasterProductImages(masterProductId, formData).subscribe({
      next: (uploadedImages) => {
        console.log('Images uploaded successfully:', uploadedImages);
        Swal.fire({
          title: 'Images Uploaded!',
          text: `${uploadedImages.length} image(s) uploaded successfully`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
        onComplete();
      },
      error: (error) => {
        console.error('Error uploading images:', error);
        console.error('Error details:', error.error);
        
        let errorMessage = 'Image upload failed. Product was created successfully.';
        if (error.error?.message) {
          errorMessage = `Image upload failed: ${error.error.message}`;
        }
        
        // Continue with product creation even if image upload fails
        Swal.fire({
          title: 'Warning!',
          text: errorMessage + ' You can add images later by editing the product.',
          icon: 'warning',
          confirmButtonText: 'OK'
        });
        onComplete();
      }
    });
  }

  getImageUrl(imageUrl: string): string {
    return getImageUrlUtil(imageUrl);
  }

  onImageError(event: any): void {
    console.log('Image failed to load, using fallback');
    event.target.src = 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=60&h=60&fit=crop&crop=center';
  }
}