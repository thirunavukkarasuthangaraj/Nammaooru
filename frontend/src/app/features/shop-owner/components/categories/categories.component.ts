import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ProductCategoryService } from '@core/services/product-category.service';
import { SwalService } from '@core/services/swal.service';
import { finalize } from 'rxjs/operators';

interface Category {
  id: number;
  name: string;
  description: string;
  productCount: number;
  isActive: boolean;
  color: string;
  icon: string;
  iconUrl?: string;
  imageFile?: File;
  createdAt: Date;
}

@Component({
  selector: 'app-categories',
  template: `
    <div class="categories-container">
      <!-- Modern Header -->
      <div class="page-header">
        <div class="header-content">
          <div class="breadcrumb">
            <span class="breadcrumb-item">
              <mat-icon>dashboard</mat-icon>
              Dashboard
            </span>
            <mat-icon class="breadcrumb-separator">chevron_right</mat-icon>
            <span class="breadcrumb-item">Shop-owner</span>
            <mat-icon class="breadcrumb-separator">chevron_right</mat-icon>
            <span class="breadcrumb-item">Products</span>
            <mat-icon class="breadcrumb-separator">chevron_right</mat-icon>
            <span class="breadcrumb-item active">Categories</span>
          </div>
          <h1 class="page-title">Product Categories</h1>
          <p class="page-description">
            Organize your products into hierarchical categories
          </p>
        </div>
        <div class="header-actions">
          <button mat-raised-button class="action-button" (click)="openAddDialog()">
            <mat-icon>add_circle</mat-icon>
            Add Category
          </button>
        </div>
      </div>

      <!-- Statistics Cards -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>category</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getTotalCategories() }}</div>
            <div class="stat-label">Total Categories</div>
          </div>
        </div>
        
        <div class="stat-card active">
          <div class="stat-icon">
            <mat-icon>check_circle</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getActiveCategories() }}</div>
            <div class="stat-label">Active Categories</div>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>account_tree</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">0</div>
            <div class="stat-label">Subcategories</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>inventory</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getTotalProducts() }}</div>
            <div class="stat-label">Products</div>
          </div>
        </div>
      </div>

      <!-- Categories Content -->
      <div class="categories-section">
        <mat-card class="modern-card">
          <div class="card-header">
            <h3 class="card-title">
              <mat-icon>account_tree</mat-icon>
              Category Hierarchy
            </h3>
            <div class="card-actions">
              <button mat-icon-button matTooltip="Refresh" (click)="loadCategories()">
                <mat-icon>refresh</mat-icon>
              </button>
              <button mat-icon-button matTooltip="Add Category" (click)="openAddDialog()">
                <mat-icon>add</mat-icon>
              </button>
            </div>
          </div>

          <!-- Empty State -->
          <div *ngIf="categories.length === 0" class="empty-state">
            <div class="empty-icon">
              <mat-icon>category</mat-icon>
            </div>
            <h3>No Categories Found</h3>
            <p>Start organizing your products by creating categories</p>
            <button mat-raised-button color="primary" (click)="openAddDialog()">
              <mat-icon>add</mat-icon>
              Create First Category
            </button>
          </div>

          <!-- Categories Grid -->
          <div *ngIf="categories.length > 0" class="categories-grid">
            <div *ngFor="let category of categories" class="category-card">
              <div class="category-card-header">
                <div class="category-icon-wrapper" [style.background-color]="category.color + '20'">
                  <img *ngIf="category.iconUrl"
                       [src]="getCategoryImageUrl(category.iconUrl)"
                       alt="{{ category.name }}"
                       class="category-image"
                       (error)="onImageError($event, category)">
                  <mat-icon *ngIf="!category.iconUrl"
                           class="category-main-icon"
                           [style.color]="category.color">{{ category.icon }}</mat-icon>
                </div>
                <div class="category-badges">
                  <span class="badge" [class.active]="category.isActive" [class.inactive]="!category.isActive">
                    <mat-icon class="badge-icon">
                      {{ category.isActive ? 'check_circle' : 'cancel' }}
                    </mat-icon>
                    {{ category.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </div>
              </div>

              <div class="category-info">
                <h3 class="category-name">{{ category.name }}</h3>
                <p class="category-description">{{ category.description || 'No description available' }}</p>
              </div>

              <div class="category-stats">
                <div class="stat-item">
                  <mat-icon class="stat-icon">inventory</mat-icon>
                  <span class="stat-text">{{ category.productCount || 0 }} products</span>
                </div>
                <div class="stat-item">
                  <mat-icon class="stat-icon">schedule</mat-icon>
                  <span class="stat-text">{{ category.createdAt | date:'MMM dd' }}</span>
                </div>
              </div>

              <div class="category-actions">
                <button mat-button class="action-btn edit" (click)="editCategory(category)">
                  <mat-icon>edit</mat-icon>
                  Edit
                </button>
                <button mat-button class="action-btn view" (click)="viewProducts(category)">
                  <mat-icon>visibility</mat-icon>
                  Products
                </button>
                <button mat-button 
                        class="action-btn toggle" 
                        [class.activate]="!category.isActive"
                        [class.deactivate]="category.isActive"
                        (click)="toggleCategoryStatus(category)">
                  <mat-icon>{{ category.isActive ? 'pause' : 'play_arrow' }}</mat-icon>
                  {{ category.isActive ? 'Deactivate' : 'Activate' }}
                </button>
                <button mat-button 
                        class="action-btn delete" 
                        (click)="deleteCategory(category)" 
                        [disabled]="category.productCount > 0">
                  <mat-icon>delete</mat-icon>
                  Delete
                </button>
              </div>
            </div>
          </div>
        </mat-card>
      </div>

      <!-- Quick Add Form Modal Overlay -->
      <div class="modal-overlay" *ngIf="showQuickAdd" (click)="closeQuickAdd()"></div>
      <mat-card class="quick-add-card" *ngIf="showQuickAdd">
        <mat-card-header>
          <mat-card-title>Add New Category</mat-card-title>
          <button mat-icon-button (click)="closeQuickAdd()">
            <mat-icon>close</mat-icon>
          </button>
        </mat-card-header>
        <mat-card-content>
          <form [formGroup]="quickAddForm" (ngSubmit)="submitQuickAdd()" class="quick-form">
            <!-- Image Upload Section (Prominent) -->
            <div class="image-upload-section">
              <label class="section-label">
                <mat-icon>image</mat-icon>
                Category Image <span class="required">*</span>
              </label>
              <div class="image-upload-area">
                <input type="file"
                       #fileInput
                       (change)="onImageSelected($event)"
                       accept="image/*"
                       style="display: none;">

                <div class="upload-placeholder"
                     *ngIf="!previewImageUrl"
                     (click)="fileInput.click()"
                     (dragover)="onDragOver($event)"
                     (dragleave)="onDragLeave($event)"
                     (drop)="onDrop($event)"
                     [class.dragover]="isDragging">
                  <mat-icon class="upload-icon">cloud_upload</mat-icon>
                  <h3>Click to Upload Category Image</h3>
                  <p>or drag and drop</p>
                  <span class="file-info">PNG, JPG, GIF up to 5MB</span>
                </div>

                <div class="image-preview-large" *ngIf="previewImageUrl">
                  <img [src]="previewImageUrl" alt="Category Preview">
                  <div class="image-actions">
                    <button mat-icon-button
                            class="change-image-btn"
                            type="button"
                            (click)="fileInput.click()"
                            matTooltip="Change Image">
                      <mat-icon>edit</mat-icon>
                    </button>
                    <button mat-icon-button
                            class="remove-image-btn"
                            type="button"
                            (click)="removeImage()"
                            matTooltip="Remove Image">
                      <mat-icon>delete</mat-icon>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Category Details -->
            <div class="form-row">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Category Name</mat-label>
                <input matInput formControlName="name" placeholder="Enter category name">
                <mat-icon matPrefix>category</mat-icon>
                <mat-error *ngIf="quickAddForm.get('name')?.hasError('required')">
                  Category name is required
                </mat-error>
              </mat-form-field>
            </div>

            <div class="form-row">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Description</mat-label>
                <textarea matInput formControlName="description"
                         placeholder="Enter category description" rows="3"></textarea>
                <mat-icon matPrefix>description</mat-icon>
              </mat-form-field>
            </div>

            <div class="form-row">
              <mat-form-field appearance="outline" class="half-width">
                <mat-label>Icon (Fallback)</mat-label>
                <mat-select formControlName="icon">
                  <mat-option *ngFor="let icon of availableIcons" [value]="icon.value">
                    <mat-icon>{{ icon.value }}</mat-icon>
                    {{ icon.label }}
                  </mat-option>
                </mat-select>
                <mat-icon matPrefix>emoji_symbols</mat-icon>
              </mat-form-field>

              <mat-form-field appearance="outline" class="half-width">
                <mat-label>Theme Color</mat-label>
                <mat-select formControlName="color">
                  <mat-option *ngFor="let color of availableColors" [value]="color.value">
                    <div class="color-option">
                      <div class="color-swatch" [style.background-color]="color.value"></div>
                      {{ color.label }}
                    </div>
                  </mat-option>
                </mat-select>
                <mat-icon matPrefix>palette</mat-icon>
              </mat-form-field>
            </div>

            <div class="form-actions">
              <button mat-raised-button
                      color="primary"
                      type="submit"
                      [disabled]="quickAddForm.invalid || loading"
                      class="submit-btn">
                <mat-spinner *ngIf="loading" diameter="20" class="button-spinner"></mat-spinner>
                <mat-icon *ngIf="!loading">save</mat-icon>
                {{ loading ? 'Creating...' : 'Create Category' }}
              </button>
              <button mat-button type="button" (click)="closeQuickAdd()">
                Cancel
              </button>
            </div>
          </form>
        </mat-card-content>
      </mat-card>
    </div>

    <!-- Category Actions Menu -->
    <mat-menu #categoryMenu="matMenu">
      <ng-template matMenuContent let-category="category">
        <button mat-menu-item (click)="editCategory(category)">
          <mat-icon>edit</mat-icon>
          <span>Edit Category</span>
        </button>
        <button mat-menu-item (click)="viewProducts(category)">
          <mat-icon>inventory_2</mat-icon>
          <span>View Products ({{ category.productCount }})</span>
        </button>
        <button mat-menu-item (click)="duplicateCategory(category)">
          <mat-icon>content_copy</mat-icon>
          <span>Duplicate</span>
        </button>
        <mat-divider></mat-divider>
        <button mat-menu-item (click)="toggleCategoryStatus(category)">
          <mat-icon>{{ category.isActive ? 'visibility_off' : 'visibility' }}</mat-icon>
          <span>{{ category.isActive ? 'Deactivate' : 'Activate' }}</span>
        </button>
        <button mat-menu-item (click)="deleteCategory(category)" 
                [disabled]="category.productCount > 0" class="warn-menu-item">
          <mat-icon>delete</mat-icon>
          <span>Delete Category</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .categories-container {
      background: #f5f5f7;
      min-height: 100vh;
      padding-bottom: 32px;
    }

    /* Modern Header */
    .page-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 48px 32px;
      color: white;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 4px 20px rgba(102, 126, 234, 0.2);
    }

    .breadcrumb {
      display: flex;
      align-items: center;
      margin-bottom: 16px;
      font-size: 14px;
      opacity: 0.9;
    }

    .breadcrumb-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .breadcrumb-item mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .breadcrumb-separator {
      margin: 0 8px;
      opacity: 0.6;
    }

    .breadcrumb-item.active {
      font-weight: 500;
    }

    .page-title {
      font-size: 36px;
      font-weight: 700;
      margin: 0 0 8px 0;
      letter-spacing: -0.5px;
    }

    .page-description {
      font-size: 16px;
      opacity: 0.95;
      margin: 0;
    }

    .action-button {
      background: white;
      color: #667eea;
      font-weight: 600;
      padding: 10px 24px;
      border-radius: 8px;
      font-size: 15px;
    }

    .action-button mat-icon {
      margin-right: 8px;
    }

    /* Statistics Row */
    .stats-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 24px;
      padding: 32px;
      padding-bottom: 0;
    }

    .stat-card {
      background: white;
      border-radius: 16px;
      padding: 24px;
      display: flex;
      align-items: center;
      gap: 20px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }

    .stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
    }

    .stat-card.active {
      border-color: #4caf50;
      background: linear-gradient(135deg, #f1f8e9 0%, #fff 100%);
    }

    .stat-icon {
      width: 56px;
      height: 56px;
      background: linear-gradient(135deg, #667eea20 0%, #764ba220 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .stat-card.active .stat-icon {
      background: linear-gradient(135deg, #4caf5020 0%, #81c78420 100%);
    }

    .stat-icon mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
      color: #667eea;
    }

    .stat-card.active .stat-icon mat-icon {
      color: #4caf50;
    }

    .stat-value {
      font-size: 32px;
      font-weight: 700;
      line-height: 1;
      margin-bottom: 4px;
      color: #1a1a1a;
    }

    .stat-label {
      font-size: 14px;
      color: #888;
      font-weight: 500;
    }

    /* Categories Section */
    .categories-section {
      padding: 32px;
    }

    .modern-card {
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      border: none;
      overflow: hidden;
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px;
      border-bottom: 1px solid #e0e0e0;
      background: #fafafa;
    }

    .card-title {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 18px;
      font-weight: 600;
      margin: 0;
      color: #1a1a1a;
    }

    .card-actions {
      display: flex;
      gap: 8px;
    }

    /* Empty State */
    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 80px 20px;
      text-align: center;
    }

    .empty-icon {
      width: 120px;
      height: 120px;
      background: linear-gradient(135deg, #f5f5f7 0%, #e8e8ea 100%);
      border-radius: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 24px;
    }

    .empty-icon mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #ccc;
    }

    .empty-state h3 {
      font-size: 24px;
      margin: 0 0 8px 0;
      color: #333;
    }

    .empty-state p {
      font-size: 16px;
      color: #888;
      margin: 0 0 24px 0;
    }

    /* Categories Grid */
    .categories-grid {
      padding: 24px;
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 24px;
    }

    .category-card {
      background: white;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }

    .category-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
      border-color: #667eea;
    }

    .category-card-header {
      padding: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid #f0f0f0;
      background: linear-gradient(135deg, #f8f9fa 0%, #fff 100%);
    }

    .category-icon-wrapper {
      width: 80px;
      height: 80px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      position: relative;
    }

    .category-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .category-main-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .category-badges {
      display: flex;
      gap: 8px;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .badge.active {
      background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
      color: #4caf50;
    }

    .badge.inactive {
      background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
      color: #f44336;
    }

    .badge-icon {
      font-size: 14px !important;
      width: 14px !important;
      height: 14px !important;
    }

    .category-info {
      padding: 20px;
    }

    .category-name {
      font-size: 20px;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1a1a1a;
    }

    .category-description {
      font-size: 14px;
      color: #666;
      line-height: 1.5;
      margin: 0;
    }

    .category-stats {
      padding: 0 20px 16px 20px;
      display: flex;
      gap: 16px;
      flex-wrap: wrap;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 13px;
      color: #666;
    }

    .stat-icon {
      font-size: 16px !important;
      width: 16px !important;
      height: 16px !important;
      color: #999;
    }

    .category-actions {
      padding: 16px 20px;
      background: #fafafa;
      border-top: 1px solid #e0e0e0;
      display: flex;
      gap: 8px;
      justify-content: flex-end;
      flex-wrap: wrap;
    }

    .action-btn {
      border-radius: 6px;
      font-size: 12px;
      padding: 6px 12px;
      min-width: auto;
    }

    .action-btn.edit {
      color: #2196f3;
    }

    .action-btn.view {
      color: #9c27b0;
    }

    .action-btn.toggle.activate {
      color: #4caf50;
    }

    .action-btn.toggle.deactivate {
      color: #ff9800;
    }

    .action-btn.delete {
      color: #f44336;
    }

    .action-btn mat-icon {
      font-size: 16px !important;
      width: 16px !important;
      height: 16px !important;
      margin-right: 4px;
    }

    .add-category-card {
      border-radius: 12px;
      border: 2px dashed #d1d5db;
      background: #fafafa;
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 250px;
    }

    .add-category-card:hover {
      border-color: #6366f1;
      background: #f8faff;
    }

    .add-category-content {
      text-align: center;
      padding: 24px;
    }

    .add-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #6b7280;
      margin-bottom: 12px;
    }

    .add-category-content h3 {
      margin: 0 0 8px 0;
      color: #374151;
    }

    .add-category-content p {
      margin: 0;
      color: #6b7280;
      font-size: 0.9rem;
    }

    .stats-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 24px;
    }

    .stats-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 16px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .stats-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.1rem;
      font-weight: 500;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
    }

    .stat-box {
      text-align: center;
      padding: 16px;
      border-radius: 8px;
      background: #f8f9fa;
      position: relative;
    }

    .stat-box h3 {
      font-size: 1.8rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .stat-box p {
      margin: 0;
      color: #6b7280;
      font-size: 0.9rem;
    }

    .stat-box mat-icon {
      position: absolute;
      top: 8px;
      right: 8px;
      color: #6b7280;
      opacity: 0.5;
    }

    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      z-index: 999;
      animation: fadeIn 0.3s ease;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    .quick-add-card {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 90%;
      max-width: 600px;
      max-height: 90vh;
      overflow-y: auto;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
      z-index: 1000;
      background: white;
      animation: slideUp 0.3s ease;
    }

    @keyframes slideUp {
      from {
        transform: translate(-50%, -40%);
        opacity: 0;
      }
      to {
        transform: translate(-50%, -50%);
        opacity: 1;
      }
    }

    .quick-add-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 16px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .quick-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
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

    .color-option {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .color-swatch {
      width: 20px;
      height: 20px;
      border-radius: 50%;
      border: 2px solid #e5e7eb;
    }

    /* New Image Upload Section Styles */
    .image-upload-section {
      margin-bottom: 24px;
    }

    .section-label {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 15px;
      font-weight: 600;
      color: #333;
      margin-bottom: 12px;
    }

    .section-label mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      color: #667eea;
    }

    .required {
      color: #ef4444;
    }

    .image-upload-area {
      position: relative;
    }

    .upload-placeholder {
      border: 3px dashed #cbd5e1;
      border-radius: 12px;
      padding: 48px 32px;
      text-align: center;
      cursor: pointer;
      background: #f8fafc;
      transition: all 0.3s ease;
    }

    .upload-placeholder:hover {
      border-color: #667eea;
      background: #f0f4ff;
    }

    .upload-placeholder.dragover {
      border-color: #667eea;
      background: #e0e7ff;
      transform: scale(1.02);
    }

    .upload-icon {
      font-size: 64px !important;
      width: 64px !important;
      height: 64px !important;
      color: #94a3b8;
      margin-bottom: 16px;
    }

    .upload-placeholder h3 {
      margin: 0 0 8px 0;
      font-size: 20px;
      font-weight: 600;
      color: #334155;
    }

    .upload-placeholder p {
      margin: 0 0 8px 0;
      color: #64748b;
      font-size: 14px;
    }

    .file-info {
      display: block;
      font-size: 12px;
      color: #94a3b8;
    }

    .image-preview-large {
      position: relative;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 16px;
      background: white;
    }

    .image-preview-large img {
      width: 100%;
      max-height: 300px;
      object-fit: contain;
      border-radius: 8px;
    }

    .image-actions {
      position: absolute;
      top: 24px;
      right: 24px;
      display: flex;
      gap: 8px;
    }

    .change-image-btn,
    .remove-image-btn {
      background: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .change-image-btn mat-icon {
      color: #667eea;
    }

    .remove-image-btn mat-icon {
      color: #ef4444;
    }

    /* Original Image Upload Styles */
    .image-upload-label {
      display: block;
      font-size: 14px;
      font-weight: 500;
      color: #666;
      margin-bottom: 8px;
    }

    .image-upload-container {
      border: 2px dashed #ddd;
      border-radius: 8px;
      padding: 16px;
      text-align: center;
      position: relative;
      min-height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .image-preview {
      position: relative;
      display: inline-block;
    }

    .image-preview img {
      max-width: 150px;
      max-height: 100px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .remove-image-btn {
      position: absolute;
      top: -8px;
      right: -8px;
      background: #f44336;
      color: white;
      width: 24px;
      height: 24px;
    }

    .remove-image-btn mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .upload-btn {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .form-actions {
      display: flex;
      gap: 12px;
      margin-top: 8px;
    }

    .warn-menu-item {
      color: #dc2626 !important;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .categories-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .categories-grid {
        grid-template-columns: 1fr;
      }

      .stats-grid {
        grid-template-columns: 1fr 1fr;
      }

      .form-row {
        flex-direction: column;
        gap: 12px;
      }

      .half-width {
        width: 100%;
      }

      .page-title {
        font-size: 1.5rem;
      }
    }
  `]
})
export class CategoriesComponent implements OnInit {
  previewImageUrl: string | null = null;
  selectedImageFile: File | null = null;
  isDragging: boolean = false;

  categories: Category[] = [
    {
      id: 1,
      name: 'Groceries',
      description: 'Essential food items and cooking ingredients',
      productCount: 45,
      isActive: true,
      color: '#10b981',
      icon: 'shopping_basket',
      iconUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-15')
    },
    {
      id: 2,
      name: 'Vegetables',
      description: 'Fresh vegetables and leafy greens',
      productCount: 32,
      isActive: true,
      color: '#22c55e',
      icon: 'eco',
      iconUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-16')
    },
    {
      id: 3,
      name: 'Fruits',
      description: 'Fresh seasonal fruits',
      productCount: 28,
      isActive: true,
      color: '#f59e0b',
      icon: 'apple',
      iconUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-17')
    },
    {
      id: 4,
      name: 'Dairy Products',
      description: 'Milk, cheese, yogurt and dairy items',
      productCount: 15,
      isActive: true,
      color: '#3b82f6',
      icon: 'local_drink',
      iconUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-18')
    },
    {
      id: 5,
      name: 'Bakery Items',
      description: 'Fresh bread, cakes and baked goods',
      productCount: 12,
      isActive: true,
      color: '#8b5cf6',
      icon: 'cake',
      iconUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-19')
    },
    {
      id: 6,
      name: 'Personal Care',
      description: 'Health and hygiene products',
      productCount: 8,
      isActive: false,
      color: '#ec4899',
      icon: 'face',
      iconUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200&h=200&fit=crop',
      createdAt: new Date('2024-01-20')
    }
  ];

  showQuickAdd = false;
  quickAddForm: FormGroup;

  availableIcons = [
    { value: 'shopping_basket', label: 'Shopping Basket' },
    { value: 'eco', label: 'Eco/Nature' },
    { value: 'apple', label: 'Apple/Fruit' },
    { value: 'local_drink', label: 'Drinks' },
    { value: 'cake', label: 'Cake/Bakery' },
    { value: 'face', label: 'Personal Care' },
    { value: 'home', label: 'Household' },
    { value: 'fastfood', label: 'Fast Food' },
    { value: 'local_grocery_store', label: 'Grocery Store' },
    { value: 'restaurant', label: 'Restaurant' }
  ];

  availableColors = [
    { value: '#10b981', label: 'Green' },
    { value: '#22c55e', label: 'Light Green' },
    { value: '#f59e0b', label: 'Orange' },
    { value: '#3b82f6', label: 'Blue' },
    { value: '#8b5cf6', label: 'Purple' },
    { value: '#ec4899', label: 'Pink' },
    { value: '#ef4444', label: 'Red' },
    { value: '#06b6d4', label: 'Cyan' },
    { value: '#84cc16', label: 'Lime' },
    { value: '#f97316', label: 'Orange Red' }
  ];

  loading = false;

  constructor(
    private fb: FormBuilder,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private categoryService: ProductCategoryService,
    private swal: SwalService
  ) {
    this.quickAddForm = this.fb.group({
      name: ['', Validators.required],
      description: [''],
      icon: ['shopping_basket', Validators.required],
      color: ['#10b981', Validators.required]
    });
  }

  ngOnInit(): void {
    this.loadCategories();
  }

  loadCategories(): void {
    this.loading = true;
    this.categoryService.getCategories()
      .pipe(
        finalize(() => this.loading = false)
      )
      .subscribe({
        next: (response: any) => {
          // Map API response to Category interface
          const categories = Array.isArray(response) ? response : (response.content || []);
          this.categories = categories.map((cat: any) => ({
            id: cat.id,
            name: cat.name,
            description: cat.description || '',
            productCount: cat.productCount || 0,
            isActive: cat.active !== false,
            color: this.getRandomColor(),
            icon: this.getCategoryIcon(cat.name),
            iconUrl: cat.iconUrl || cat.imageUrl || undefined,
            createdAt: new Date(cat.createdAt || Date.now())
          }));
        },
        error: (error) => {
          console.error('Error loading categories:', error);
          this.snackBar.open('Failed to load categories. Showing sample data.', 'Close', { duration: 3000 });
          // Keep mock data on error
        }
      });
  }

  private getRandomColor(): string {
    const colors = [
      '#10b981', '#3b82f6', '#8b5cf6', '#f59e0b', 
      '#ef4444', '#06b6d4', '#84cc16', '#f97316'
    ];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  private getCategoryIcon(categoryName: string): string {
    const iconMap: { [key: string]: string } = {
      'groceries': 'shopping_basket',
      'electronics': 'devices',
      'fashion': 'style',
      'home': 'home',
      'kitchen': 'kitchen',
      'health': 'health_and_safety',
      'beauty': 'face_6',
      'sports': 'sports',
      'books': 'menu_book',
      'toys': 'toys'
    };
    
    const normalizedName = categoryName.toLowerCase();
    for (const [key, icon] of Object.entries(iconMap)) {
      if (normalizedName.includes(key)) {
        return icon;
      }
    }
    return 'category';
  }


  openAddDialog(): void {
    this.showQuickAdd = true;
  }

  closeQuickAdd(): void {
    this.showQuickAdd = false;
    this.quickAddForm.reset({
      icon: 'shopping_basket',
      color: '#10b981'
    });
    this.resetImageUpload();
  }

  submitQuickAdd(): void {
    if (this.quickAddForm.valid) {
      const formData = this.quickAddForm.value;

      // If there's an image, upload it first
      if (this.selectedImageFile) {
        this.uploadCategoryWithImage(formData);
      } else {
        this.createCategory(formData);
      }
    }
  }

  private uploadCategoryWithImage(categoryData: any): void {
    const formData = new FormData();
    formData.append('name', categoryData.name);
    formData.append('description', categoryData.description || '');
    if (this.selectedImageFile) {
      formData.append('image', this.selectedImageFile);
    }

    this.loading = true;
    this.categoryService.createCategoryWithImage(formData).subscribe({
      next: (response: any) => {
        const newCategory: Category = {
          id: response.id,
          name: response.name,
          description: response.description || '',
          productCount: 0,
          isActive: response.isActive !== false,
          color: categoryData.color || this.getRandomColor(),
          icon: categoryData.icon || this.getCategoryIcon(response.name),
          iconUrl: response.iconUrl || undefined,
          createdAt: new Date(response.createdAt || Date.now())
        };

        this.categories.unshift(newCategory);
        this.closeQuickAdd();
        this.resetImageUpload();
        this.loading = false;

        this.swal.success('Success!', 'Category added successfully with image!');
      },
      error: (error) => {
        console.error('Error creating category with image:', error);
        this.loading = false;
        this.swal.error('Error', 'Failed to create category. Please try again.');
      }
    });
  }

  private createCategory(categoryData: any): void {
    const newCategory: Category = {
      id: this.categories.length + 1,
      name: categoryData.name,
      description: categoryData.description || `Products related to ${categoryData.name}`,
      productCount: 0,
      isActive: true,
      color: categoryData.color,
      icon: categoryData.icon,
      createdAt: new Date()
    };

    this.categories.unshift(newCategory);
    this.closeQuickAdd();

    this.snackBar.open('Category added successfully!', 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: ['success-snackbar']
    });
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.processImageFile(input.files[0]);
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      const file = files[0];
      if (file.type.startsWith('image/')) {
        this.processImageFile(file);
      } else {
        this.swal.error('Invalid File', 'Please drop an image file');
      }
    }
  }

  private processImageFile(file: File): void {
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.swal.error('File Too Large', 'Image size should be less than 5MB');
      return;
    }

    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      this.swal.error('Invalid File Type', 'Please select a valid image file (JPEG, PNG, GIF, or WebP)');
      return;
    }

    this.selectedImageFile = file;

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      this.previewImageUrl = e.target?.result as string;
    };
    reader.readAsDataURL(file);
  }

  removeImage(): void {
    this.previewImageUrl = null;
    this.selectedImageFile = null;
  }

  private resetImageUpload(): void {
    this.previewImageUrl = null;
    this.selectedImageFile = null;
  }

  editCategory(category: Category): void {
    console.log('Edit category:', category);
    // Open edit dialog
  }

  viewProducts(category: Category): void {
    console.log('View products for category:', category);
    // Navigate to products filtered by category
  }

  duplicateCategory(category: Category): void {
    const duplicated: Category = {
      ...category,
      id: this.categories.length + 1,
      name: `${category.name} (Copy)`,
      productCount: 0,
      createdAt: new Date()
    };

    this.categories.unshift(duplicated);
    this.snackBar.open('Category duplicated successfully', 'Close', { duration: 3000 });
  }

  toggleCategoryStatus(category: Category): void {
    category.isActive = !category.isActive;
    const status = category.isActive ? 'activated' : 'deactivated';
    this.swal.toast(`Category ${status} successfully`, 'success');
  }

  deleteCategory(category: Category): void {
    if (category.productCount > 0) {
      this.swal.warning('Cannot Delete', 'This category contains products. Please remove all products first.');
      return;
    }

    this.swal.confirmDelete(category.name).then((result) => {
      if (result.isConfirmed) {
        const index = this.categories.indexOf(category);
        this.categories.splice(index, 1);
        this.swal.success('Deleted!', `Category "${category.name}" has been deleted.`);
      }
    });
  }

  getTotalCategories(): number {
    return this.categories.length;
  }

  getActiveCategories(): number {
    return this.categories.filter(cat => cat.isActive).length;
  }

  getTotalProducts(): number {
    return this.categories.reduce((total, cat) => total + cat.productCount, 0);
  }

  getAverageProducts(): number {
    const activeCategories = this.getActiveCategories();
    return activeCategories > 0 ? Math.round(this.getTotalProducts() / activeCategories) : 0;
  }

  getCategoryImageUrl(iconUrl: string): string {
    if (!iconUrl) {
      return '';
    }

    // If it's already a full URL (from sample data)
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return iconUrl;
    }

    // If it's a relative path from our backend
    const baseUrl = 'http://localhost:8080';
    if (iconUrl.startsWith('/')) {
      return baseUrl + iconUrl;
    }

    return baseUrl + '/' + iconUrl;
  }

  onImageError(event: Event, category: Category): void {
    // Hide the broken image and show the icon fallback
    const imgElement = event.target as HTMLImageElement;
    if (imgElement) {
      imgElement.style.display = 'none';
    }
    // Remove the iconUrl to show the icon fallback
    category.iconUrl = undefined;
  }
}