import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { ProductCategoryService } from '@core/services/product-category.service';
import { environment } from '../../../../../environments/environment';
import { SwalService } from '@core/services/swal.service';
import { finalize } from 'rxjs/operators';

interface Category {
  id: number;
  name: string;
  nameTamil?: string;
  description: string;
  productCount: number;
  isActive: boolean;
  color: string;
  icon: string;
  iconUrl?: string;
  imageFile?: File;
  createdAt: Date;
  parentId?: number;
  subcategoryCount: number;
  subcategories?: Category[];
  expanded?: boolean;
  loadingSubcategories?: boolean;
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
            <div class="stat-value">{{ getSubcategoryTotal() }}</div>
            <div class="stat-label">Subcategories</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>inventory</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getTotalProducts() + uncategorizedCount }}</div>
            <div class="stat-label">Products</div>
            <div class="stat-sublabel" *ngIf="uncategorizedCount > 0">
              {{ uncategorizedCount }} without category
            </div>
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
              <div class="view-toggle" role="group" aria-label="Subgroup view">
                <button type="button" class="view-toggle-btn" [class.active]="viewMode === 'list'"
                        matTooltip="List view" (click)="setViewMode('list')">
                  <mat-icon>view_list</mat-icon>
                </button>
                <button type="button" class="view-toggle-btn" [class.active]="viewMode === 'card'"
                        matTooltip="Card view" (click)="setViewMode('card')">
                  <mat-icon>grid_view</mat-icon>
                </button>
              </div>
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
            <div *ngFor="let category of categories" class="category-card" [class.is-inactive]="!category.isActive">
              <!-- Big group tile - this is what customers see in the app -->
              <div class="category-tile" (click)="editCategory(category)">
                <img *ngIf="category.iconUrl"
                     [src]="getCategoryImageUrl(category.iconUrl)"
                     alt="{{ category.name }}"
                     class="category-image"
                     (error)="onImageError($event, category)">
                <div *ngIf="!category.iconUrl" class="category-tile-placeholder">
                  <mat-icon class="category-main-icon">{{ category.icon }}</mat-icon>
                  <span>No image yet</span>
                </div>
                <span class="status-badge" [class.on]="category.isActive">
                  {{ category.isActive ? 'Active' : 'Inactive' }}
                </span>
              </div>

              <div class="category-info">
                <h3 class="category-name" [title]="category.name">{{ category.name }}</h3>
                <div class="category-name-tamil" *ngIf="category.nameTamil">
                  {{ category.nameTamil }}
                </div>
                <div class="category-meta">
                  <span class="meta-item">{{ category.productCount || 0 }} products</span>
                </div>
                <p class="category-description"
                   *ngIf="category.description && category.description.toLowerCase() !== category.name.toLowerCase()">
                  {{ category.description }}
                </p>
              </div>

              <div class="category-actions">
                <button mat-icon-button class="action-btn" matTooltip="Edit" (click)="editCategory(category)">
                  <mat-icon>edit</mat-icon>
                </button>
                <button mat-icon-button class="action-btn" matTooltip="View products" (click)="viewProducts(category)">
                  <mat-icon>visibility</mat-icon>
                </button>
                <button mat-icon-button class="action-btn" [class.toggle-on]="category.isActive"
                        [matTooltip]="category.isActive ? 'Deactivate' : 'Activate'"
                        (click)="toggleCategoryStatus(category)">
                  <mat-icon>{{ category.isActive ? 'toggle_on' : 'toggle_off' }}</mat-icon>
                </button>
                <span class="actions-spacer"></span>
                <button mat-icon-button class="action-btn delete"
                        matTooltip="Delete"
                        (click)="deleteCategory(category)">
                  <mat-icon>delete_outline</mat-icon>
                </button>
              </div>

              <!-- Subgroups (subcategories) nested under this category -->
              <button type="button" class="subcategory-toggle" (click)="toggleSubcategories(category)">
                <mat-icon>{{ category.expanded ? 'expand_less' : 'expand_more' }}</mat-icon>
                <span *ngIf="category.subcategoryCount > 0">{{ category.subcategoryCount }} subgroup{{ category.subcategoryCount === 1 ? '' : 's' }}</span>
                <span *ngIf="category.subcategoryCount === 0">Add a subgroup</span>
              </button>

              <div class="subcategory-panel" *ngIf="category.expanded">
                <div class="subcategory-loading" *ngIf="category.loadingSubcategories">
                  <mat-spinner diameter="18"></mat-spinner>
                </div>

                <ng-container *ngIf="!category.loadingSubcategories">
                  <p class="no-subcategories" *ngIf="category.subcategories?.length === 0">
                    No subgroups yet.
                  </p>

                  <!-- List view: compact rows -->
                  <div class="subcategory-list" *ngIf="viewMode === 'list' && category.subcategories?.length">
                    <div class="subcategory-chip" *ngFor="let sub of category.subcategories">
                      <span>{{ sub.name }}</span>
                      <span class="sub-count">{{ sub.productCount || 0 }} products</span>
                      <button mat-icon-button class="sub-edit-btn" matTooltip="Edit subgroup" (click)="editCategory(sub)">
                        <mat-icon>edit</mat-icon>
                      </button>
                      <button mat-icon-button class="sub-delete-btn" matTooltip="Delete subgroup" (click)="deleteSubcategory(category, sub)">
                        <mat-icon>delete_outline</mat-icon>
                      </button>
                    </div>
                  </div>

                  <!-- Card view: same tile layout as root categories, scaled down -->
                  <div class="subcategory-grid" *ngIf="viewMode === 'card' && category.subcategories?.length">
                    <div class="subcategory-card" *ngFor="let sub of category.subcategories">
                      <div class="sub-tile">
                        <img *ngIf="sub.iconUrl" [src]="getCategoryImageUrl(sub.iconUrl)" [alt]="sub.name" class="sub-image">
                        <div *ngIf="!sub.iconUrl" class="sub-tile-placeholder">
                          <mat-icon>{{ sub.icon }}</mat-icon>
                        </div>
                      </div>
                      <div class="sub-info">
                        <h4 [title]="sub.name">{{ sub.name }}</h4>
                        <span class="sub-count">{{ sub.productCount || 0 }} products</span>
                      </div>
                      <div class="sub-actions">
                        <button mat-icon-button class="action-btn" matTooltip="Edit" (click)="editCategory(sub)">
                          <mat-icon>edit</mat-icon>
                        </button>
                        <button mat-icon-button class="action-btn delete" matTooltip="Delete" (click)="deleteSubcategory(category, sub)">
                          <mat-icon>delete_outline</mat-icon>
                        </button>
                      </div>
                    </div>
                  </div>

                  <button mat-stroked-button class="add-subcategory-btn" type="button" (click)="openAddSubcategoryDialog(category)">
                    <mat-icon>add</mat-icon>
                    Add Subgroup to {{ category.name }}
                  </button>
                </ng-container>
              </div>
            </div>
          </div>
        </mat-card>
      </div>

      <!-- Quick Add Form Modal Overlay -->
      <div class="modal-overlay" *ngIf="showQuickAdd" (click)="closeQuickAdd()"></div>
      <mat-card class="quick-add-card" *ngIf="showQuickAdd">
        <mat-card-header>
          <mat-card-title>{{ editingCategory ? 'Edit Category' : 'Add New Category' }}</mat-card-title>
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
                     (dragover)="onDragOver($event)"
                     (dragleave)="onDragLeave($event)"
                     (drop)="onDrop($event)"
                     [class.dragover]="isDragging">
                  <mat-icon class="upload-icon">cloud_upload</mat-icon>
                  <h3>Click to Upload Category Image</h3>
                  <p>or drag and drop</p>
                  <span class="file-info">PNG, JPG, GIF up to 5MB</span>
                  <div class="upload-choice-row">
                    <button mat-stroked-button type="button" (click)="fileInput.click()">
                      <mat-icon>folder_open</mat-icon>
                      Browse File
                    </button>
                    <button mat-stroked-button type="button" (click)="openImageSuggestions()">
                      <mat-icon>image_search</mat-icon>
                      Search Images
                    </button>
                    <button mat-stroked-button type="button" (click)="pasteImageFromClipboard()">
                      <mat-icon>content_paste</mat-icon>
                      Paste Image
                    </button>
                  </div>
                </div>

                <div class="image-preview-large" *ngIf="previewImageUrl">
                  <img [src]="previewImageUrl" alt="Category Preview">
                  <div class="image-actions">
                    <button mat-icon-button
                            class="change-image-btn"
                            type="button"
                            (click)="fileInput.click()"
                            matTooltip="Upload a different file">
                      <mat-icon>edit</mat-icon>
                    </button>
                    <button mat-icon-button
                            class="search-image-btn"
                            type="button"
                            (click)="openImageSuggestions()"
                            matTooltip="Search for a different image">
                      <mat-icon>image_search</mat-icon>
                    </button>
                    <button mat-icon-button
                            class="paste-image-btn"
                            type="button"
                            (click)="pasteImageFromClipboard()"
                            matTooltip="Paste image from clipboard">
                      <mat-icon>content_paste</mat-icon>
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
                <mat-label>Category Name (English)</mat-label>
                <input matInput formControlName="name" placeholder="Enter category name in English">
                <mat-icon matPrefix>category</mat-icon>
                <mat-error *ngIf="quickAddForm.get('name')?.hasError('required')">
                  Category name is required
                </mat-error>
              </mat-form-field>
            </div>

            <div class="form-row">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Category Name (Tamil)</mat-label>
                <input matInput formControlName="nameTamil" placeholder="தமிழில் வகைப் பெயரை உள்ளிடவும்">
                <mat-icon matPrefix>translate</mat-icon>
                <mat-hint>Used for display; filtering continues to use the English name</mat-hint>
                <mat-error *ngIf="quickAddForm.get('nameTamil')?.hasError('maxlength')">
                  Tamil name must be 100 characters or fewer
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
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Parent Category (optional)</mat-label>
                <mat-select formControlName="parentId">
                  <mat-option [value]="null">None &mdash; top-level category</mat-option>
                  <mat-option *ngFor="let cat of parentCategoryOptions" [value]="cat.id">
                    {{ cat.name }}
                  </mat-option>
                </mat-select>
                <mat-icon matPrefix>account_tree</mat-icon>
                <mat-hint>Group this under another category, e.g. put "Chips" under "Snacks"</mat-hint>
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

    <!-- Image Search Modal -->
    <div class="image-suggest-overlay" *ngIf="imageSuggestOpen" (click)="closeImageSuggestions()">
      <div class="image-suggest-dialog" (click)="$event.stopPropagation()">
        <div class="image-suggest-header">
          <h3>Search Category Images</h3>
          <button type="button" class="suggest-close-btn" (click)="closeImageSuggestions()">
            <mat-icon>close</mat-icon>
          </button>
        </div>

        <div class="image-suggest-search-row">
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Search term</mat-label>
            <input matInput [(ngModel)]="imageSuggestQuery" [ngModelOptions]="{standalone: true}"
                   (keyup.enter)="runImageSearch()" placeholder="e.g. dry fruits, dairy, snacks">
            <mat-icon matPrefix>search</mat-icon>
          </mat-form-field>
          <button mat-raised-button color="primary" type="button" [disabled]="loadingSuggestions" (click)="runImageSearch()">
            Search
          </button>
        </div>

        <div class="image-suggest-body">
          <div class="suggest-loading" *ngIf="loadingSuggestions">
            <mat-spinner diameter="32"></mat-spinner>
            <span>Searching images...</span>
          </div>

          <div class="suggest-grid" *ngIf="!loadingSuggestions && imageSuggestions.length">
            <div class="suggest-card" *ngFor="let s of imageSuggestions" (click)="useSuggestedImage(s)">
              <img [src]="s.thumb" [alt]="s.label" loading="lazy">
              <div class="suggest-label" [matTooltip]="s.label">{{ s.label }}</div>
              <button type="button"
                      class="suggest-use-btn"
                      [disabled]="downloadingSuggestionUrl === s.url"
                      (click)="useSuggestedImage(s); $event.stopPropagation()">
                <mat-icon>{{ downloadingSuggestionUrl === s.url ? 'hourglass_empty' : 'check' }}</mat-icon>
                {{ downloadingSuggestionUrl === s.url ? 'Using...' : 'Use This' }}
              </button>
            </div>
          </div>

          <div class="suggest-empty" *ngIf="!loadingSuggestions && !imageSuggestions.length">
            <mat-icon>image_not_supported</mat-icon>
            <p>{{ suggestError || 'Search for an image above to see results here.' }}</p>
          </div>
        </div>
      </div>
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
      background: #fff;
      min-height: 100vh;
      padding-bottom: 32px;
    }

    /* Modern Header */
    .page-header {
      /* Match the sidebar's brand green (#4ade80) instead of an unrelated shade */
      background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%);
      padding: 48px 32px;
      color: white;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-radius: 0 0 24px 24px;
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
      color: #16a34a;
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
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      padding: 24px 24px 0 24px;
    }

    .stat-card {
      background: white;
      border-radius: 12px;
      padding: 18px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      border: 1px solid #ECEFF1;
    }

    .stat-card.active {
      border-color: #16a34a;
    }

    .stat-icon {
      width: 44px;
      height: 44px;
      background: #E8F5E9;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .stat-icon mat-icon {
      font-size: 22px;
      width: 22px;
      height: 22px;
      color: #16a34a;
    }

    .stat-value {
      font-size: 26px;
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

    .stat-sublabel {
      font-size: 12px;
      color: #f59e0b;
      font-weight: 500;
      margin-top: 2px;
    }

    /* Categories Section */
    .categories-section {
      padding: 24px;
    }

    .modern-card {
      border-radius: 12px;
      box-shadow: none;
      border: 1px solid #ECEFF1;
      overflow: hidden;
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 20px;
      border-bottom: 1px solid #ECEFF1;
      background: white;
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
      align-items: center;
      gap: 8px;
    }

    .view-toggle {
      display: flex;
      background: #F5F7F5;
      border-radius: 8px;
      padding: 3px;
      margin-right: 4px;
    }

    .view-toggle-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      border: none;
      background: transparent;
      border-radius: 6px;
      color: #78909C;
      cursor: pointer;
      transition: background 0.15s ease, color 0.15s ease;
    }

    .view-toggle-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .view-toggle-btn:hover {
      color: #16a34a;
    }

    .view-toggle-btn.active {
      background: white;
      color: #16a34a;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12);
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
      padding: 20px;
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 20px;
    }

    .category-card {
      background: white;
      border-radius: 16px;
      border: 1px solid #ECEFF1;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
    }

    .category-card:hover {
      border-color: #16a34a;
      box-shadow: 0 8px 20px rgba(0,0,0,0.08);
      transform: translateY(-2px);
    }

    .category-card.is-inactive {
      background: #FAFBFC;
    }

    .category-card.is-inactive .category-tile,
    .category-card.is-inactive .category-name {
      opacity: 0.55;
    }

    /* Big group tile - matches how the customer app shows this category */
    .category-tile {
      position: relative;
      width: 100%;
      aspect-ratio: 1 / 1;
      background: linear-gradient(135deg, #f5f5f7 0%, #e8e8ea 100%);
      cursor: pointer;
    }

    .category-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }

    .category-tile-placeholder {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 6px;
      color: #9aa5b1;
    }

    .category-tile-placeholder span {
      font-size: 12px;
      font-weight: 500;
    }

    .category-main-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #b0bec5;
    }

    .status-badge {
      position: absolute;
      top: 10px;
      right: 10px;
      padding: 3px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      background: rgba(255,255,255,0.9);
      color: #90A4AE;
      backdrop-filter: blur(4px);
    }

    .status-badge.on {
      color: #16a34a;
    }

    .category-info {
      min-width: 0;
      padding: 12px 14px 4px 14px;
    }

    .category-name {
      font-size: 15px;
      font-weight: 700;
      margin: 0 0 2px 0;
      color: #1a1a1a;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .category-name-tamil {
      color: #546e7a;
      font-size: 13px;
      line-height: 1.35;
      margin-bottom: 3px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .category-meta {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 12.5px;
      color: #78909C;
    }

    .meta-dot {
      width: 3px;
      height: 3px;
      border-radius: 50%;
      background: #B0BEC5;
    }

    .status-text {
      font-weight: 600;
      color: #90A4AE;
    }

    .status-text.on {
      color: #16a34a;
    }

    .category-description {
      font-size: 13px;
      color: #607D8B;
      line-height: 1.4;
      margin: 0;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .category-actions {
      display: flex;
      align-items: center;
      gap: 4px;
      border-top: 1px solid #ECEFF1;
      padding-top: 8px;
      margin-top: auto;
    }

    .actions-spacer {
      flex: 1;
    }

    .action-btn {
      color: #607D8B;
      transition: background 0.15s ease, color 0.15s ease;
    }

    .action-btn ::ng-deep .mat-button-wrapper {
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .action-btn.toggle-on {
      color: #16a34a;
    }

    .action-btn:hover {
      color: #16a34a;
      background: #E8F5E9;
    }

    .action-btn.delete:hover {
      color: #e53935;
      background: #FFEBEE;
    }

    .subcategory-toggle {
      display: flex;
      align-items: center;
      gap: 6px;
      width: 100%;
      background: none;
      border: none;
      border-top: 1px solid #ECEFF1;
      padding: 8px 4px 0;
      margin-top: 4px;
      color: #607D8B;
      font-size: 13px;
      cursor: pointer;
      text-align: left;
    }

    .subcategory-toggle:hover {
      color: #16a34a;
    }

    .subcategory-toggle mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .subcategory-panel {
      padding: 8px 4px 0;
    }

    .subcategory-loading {
      display: flex;
      justify-content: center;
      padding: 8px 0;
    }

    .subcategory-list {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .subcategory-chip {
      display: flex;
      align-items: center;
      gap: 8px;
      background: #F5F7F5;
      border-radius: 8px;
      padding: 6px 10px;
      font-size: 13px;
    }

    .subcategory-chip span:first-child {
      flex: 1;
      font-weight: 500;
      color: #333;
    }

    .subcategory-chip .sub-count {
      color: #888;
      font-size: 11px;
    }

    .subcategory-chip .sub-edit-btn,
    .subcategory-chip .sub-delete-btn {
      width: 28px;
      height: 28px;
      line-height: 28px;
      flex-shrink: 0;
    }

    .subcategory-chip .sub-edit-btn mat-icon,
    .subcategory-chip .sub-delete-btn mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .subcategory-chip .sub-delete-btn {
      color: #90A4AE;
    }

    .subcategory-chip .sub-delete-btn:hover {
      color: #e53935;
    }

    /* Card view - mini version of the root category tile */
    .subcategory-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
      gap: 10px;
      margin-bottom: 8px;
    }

    .subcategory-card {
      background: #F9FAFB;
      border: 1px solid #ECEFF1;
      border-radius: 10px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      transition: border-color 0.15s ease;
    }

    .subcategory-card:hover {
      border-color: #16a34a;
    }

    .sub-tile {
      width: 100%;
      aspect-ratio: 1 / 1;
      background: #EEF1EE;
    }

    .sub-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }

    .sub-tile-placeholder {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #b0bec5;
    }

    .sub-tile-placeholder mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .sub-info {
      padding: 8px 8px 4px;
      min-width: 0;
    }

    .sub-info h4 {
      margin: 0 0 2px;
      font-size: 12.5px;
      font-weight: 700;
      color: #1a1a1a;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .sub-info .sub-count {
      font-size: 11px;
      color: #78909C;
    }

    .sub-actions {
      display: flex;
      justify-content: flex-end;
      padding: 0 4px 4px;
    }

    .sub-actions .action-btn {
      width: 26px;
      height: 26px;
      line-height: 26px;
    }

    .sub-actions .action-btn mat-icon {
      font-size: 15px;
      width: 15px;
      height: 15px;
    }

    .no-subcategories {
      color: #999;
      font-size: 12px;
      margin: 0 0 8px;
    }

    .add-subcategory-btn {
      align-self: flex-start;
      font-size: 12px;
      margin-top: 4px;
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
      color: #16a34a;
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
      border-color: #16a34a;
      background: #f0f4ff;
    }

    .upload-placeholder.dragover {
      border-color: #16a34a;
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

    .upload-choice-row {
      display: flex;
      justify-content: center;
      gap: 12px;
      margin-top: 16px;
    }

    .upload-choice-row button mat-icon {
      margin-right: 4px;
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
    .search-image-btn,
    .paste-image-btn,
    .remove-image-btn {
      background: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .change-image-btn mat-icon,
    .search-image-btn mat-icon,
    .paste-image-btn mat-icon {
      color: #16a34a;
    }

    .remove-image-btn mat-icon {
      color: #ef4444;
    }

    /* Image Search Modal */
    .image-suggest-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }

    .image-suggest-dialog {
      background: #fff;
      border-radius: 12px;
      width: 100%;
      max-width: 720px;
      max-height: 85vh;
      display: flex;
      flex-direction: column;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
    }

    .image-suggest-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 14px 20px;
      border-bottom: 1px solid #e5e7eb;
    }

    .image-suggest-header h3 {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
    }

    .suggest-close-btn {
      background: none;
      border: none;
      cursor: pointer;
      color: #6b7280;
      padding: 4px;
      border-radius: 6px;
      display: flex;
    }

    .suggest-close-btn:hover {
      background: #f3f4f6;
      color: #111827;
    }

    .image-suggest-search-row {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 16px 20px 0;
    }

    .image-suggest-search-row mat-form-field {
      flex: 1;
    }

    .image-suggest-body {
      padding: 0 20px 20px;
      overflow-y: auto;
    }

    .suggest-loading {
      display: flex;
      align-items: center;
      gap: 12px;
      justify-content: center;
      padding: 32px 0;
      color: #6b7280;
    }

    .suggest-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: 14px;
    }

    .suggest-card {
      border: 1px solid #e5e7eb;
      border-radius: 10px;
      padding: 10px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      align-items: center;
      cursor: pointer;
      transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .suggest-card:hover {
      border-color: #16a34a;
      box-shadow: 0 2px 10px rgba(0,0,0,0.08);
    }

    .suggest-card img {
      width: 100%;
      height: 120px;
      object-fit: contain;
      background: #f9fafb;
      border-radius: 6px;
    }

    .suggest-label {
      font-size: 12px;
      color: #374151;
      width: 100%;
      text-align: center;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .suggest-use-btn {
      display: flex;
      align-items: center;
      gap: 6px;
      background: #16a34a;
      color: #fff;
      border: none;
      border-radius: 8px;
      padding: 6px 14px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
    }

    .suggest-use-btn mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .suggest-use-btn:hover:not(:disabled) {
      background: #15803d;
    }

    .suggest-use-btn:disabled {
      opacity: 0.6;
      cursor: wait;
    }

    .suggest-empty {
      text-align: center;
      padding: 28px 0;
      color: #6b7280;
    }

    .suggest-empty mat-icon {
      font-size: 40px;
      width: 40px;
      height: 40px;
      color: #d1d5db;
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

  // Image search ("group of images to pick from", same idea as the bulk-edit product image picker)
  imageSuggestOpen = false;
  imageSuggestQuery = '';
  imageSuggestions: { label: string; thumb: string; url: string }[] = [];
  loadingSuggestions = false;
  suggestError: string | null = null;
  downloadingSuggestionUrl: string | null = null;
  // Set when a searched image is picked for a category that doesn't have an id yet (add mode) -
  // it's downloaded server-side right after the category is created.
  pickedImageUrl: string | null = null;

  categories: Category[] = [];

  // How expanded subgroup panels render: compact rows or a mini card grid.
  // Shared across every category card so switching once applies everywhere.
  viewMode: 'list' | 'card' = 'list';

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
  // Shop owner's products that have no category (shown next to the Products stat)
  uncategorizedCount = 0;
  // Category being edited in the modal (null = add mode)
  editingCategory: Category | null = null;

  constructor(
    private fb: FormBuilder,
    private dialog: MatDialog,
    private router: Router,
    private categoryService: ProductCategoryService,
    private swal: SwalService
  ) {
    this.quickAddForm = this.fb.group({
      name: ['', Validators.required],
      nameTamil: ['', Validators.maxLength(100)],
      description: [''],
      parentId: [null],
      icon: ['shopping_basket', Validators.required],
      color: ['#10b981', Validators.required]
    });
  }

  ngOnInit(): void {
    this.loadCategories();
    this.categoryService.getUncategorizedCount().subscribe({
      next: (count) => this.uncategorizedCount = count,
      error: () => this.uncategorizedCount = 0
    });
  }

  loadCategories(): void {
    this.loading = true;
    // No paginator on this page - load all root categories (default size is 10)
    this.categoryService.getCategories(undefined, undefined, undefined, 0, 500)
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
            nameTamil: cat.nameTamil || undefined,
            description: cat.description || '',
            productCount: cat.productCount || 0,
            isActive: cat.active !== false,
            color: this.getRandomColor(),
            icon: this.getCategoryIcon(cat.name),
            iconUrl: cat.iconUrl || cat.imageUrl || undefined,
            createdAt: new Date(cat.createdAt || Date.now()),
            parentId: cat.parentId || undefined,
            subcategoryCount: cat.subcategoryCount || 0
          }));
        },
        error: (error) => {
          console.error('Error loading categories:', error);
          this.swal.toast('Failed to load categories.', 'error');
          this.categories = [];
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
    this.editingCategory = null;
    this.quickAddForm.patchValue({ parentId: null });
    this.showQuickAdd = true;
  }

  /** Opens the add form pre-set to create a subgroup under the given category */
  openAddSubcategoryDialog(parent: Category): void {
    this.editingCategory = null;
    this.quickAddForm.reset({
      icon: 'shopping_basket',
      color: '#10b981',
      parentId: parent.id
    });
    this.resetImageUpload();
    this.showQuickAdd = true;
  }

  closeQuickAdd(): void {
    this.showQuickAdd = false;
    this.editingCategory = null;
    this.quickAddForm.reset({
      icon: 'shopping_basket',
      color: '#10b981',
      parentId: null
    });
    this.resetImageUpload();
  }

  /** Root categories available to pick as a parent group (a category can't be its own parent) */
  get parentCategoryOptions(): Category[] {
    return this.categories.filter(c => !this.editingCategory || c.id !== this.editingCategory.id);
  }

  setViewMode(mode: 'list' | 'card'): void {
    this.viewMode = mode;
  }

  deleteSubcategory(parent: Category, sub: Category): void {
    this.swal.confirmDelete(sub.name).then((result) => {
      if (!result.isConfirmed) return;
      this.categoryService.deleteCategory(sub.id).subscribe({
        next: () => {
          parent.subcategories = (parent.subcategories || []).filter(s => s.id !== sub.id);
          parent.subcategoryCount = Math.max(0, (parent.subcategoryCount || 1) - 1);
          this.swal.success('Deleted!', `Subgroup "${sub.name}" has been deleted.`);
        },
        error: (error) => {
          const message = error?.error?.message || error?.message || 'Failed to delete subgroup';
          this.swal.error('Delete Failed', message);
        }
      });
    });
  }

  getSubcategoryTotal(): number {
    return this.categories.reduce((sum, c) => sum + (c.subcategoryCount || 0), 0);
  }

  toggleSubcategories(category: Category): void {
    category.expanded = !category.expanded;
    if (category.expanded && !category.subcategories) {
      category.loadingSubcategories = true;
      this.categoryService.getSubcategories(category.id).subscribe({
        next: (subs: any[]) => {
          category.subcategories = (subs || []).map((sub: any) => ({
            id: sub.id,
            name: sub.name,
            nameTamil: sub.nameTamil || undefined,
            description: sub.description || '',
            productCount: sub.productCount || 0,
            isActive: sub.active !== false,
            color: this.getRandomColor(),
            icon: this.getCategoryIcon(sub.name),
            iconUrl: sub.iconUrl || sub.imageUrl || undefined,
            createdAt: new Date(sub.createdAt || Date.now()),
            parentId: category.id,
            subcategoryCount: sub.subcategoryCount || 0
          }));
          category.loadingSubcategories = false;
        },
        error: () => {
          category.subcategories = [];
          category.loadingSubcategories = false;
        }
      });
    }
  }

  submitQuickAdd(): void {
    if (this.quickAddForm.valid) {
      const formData = this.quickAddForm.value;

      if (this.editingCategory) {
        this.saveCategoryEdit(this.editingCategory, formData);
      } else {
        // Create always goes through the API (with or without an image)
        this.uploadCategoryWithImage(formData);
      }
    }
  }

  private saveCategoryEdit(category: Category, formData: any): void {
    this.loading = true;
    this.categoryService.updateCategory(category.id, {
      name: formData.name,
      nameTamil: formData.nameTamil?.trim() || undefined,
      description: formData.description || '',
      parentId: formData.parentId || undefined
    } as any).subscribe({
      next: (response: any) => {
        // The parent group may have changed (moved in/out of a subgroup), which
        // changes which list it belongs to - reload rather than patch in place.
        const finish = () => {
          this.loading = false;
          this.closeQuickAdd();
          this.loadCategories();
          this.swal.success('Saved!', 'Category updated successfully.');
        };

        // A new image was picked - upload it as a second step, then finish
        if (this.selectedImageFile) {
          this.categoryService.uploadCategoryImage(category.id, this.selectedImageFile).subscribe({
            next: () => finish(),
            error: (error) => {
              this.loading = false;
              this.closeQuickAdd();
              this.loadCategories();
              const message = error?.error?.message || error?.message || 'Category saved, but the image failed to upload';
              this.swal.error('Image Upload Failed', message);
            }
          });
          return;
        }

        finish();
      },
      error: (error) => {
        this.loading = false;
        const message = error?.error?.message || error?.message || 'Failed to update category';
        this.swal.error('Update Failed', message);
      }
    });
  }

  private uploadCategoryWithImage(categoryData: any): void {
    const formData = new FormData();
    formData.append('name', categoryData.name);
    formData.append('nameTamil', categoryData.nameTamil?.trim() || '');
    formData.append('description', categoryData.description || '');
    if (categoryData.parentId) {
      formData.append('parentId', categoryData.parentId.toString());
    }
    if (this.selectedImageFile) {
      formData.append('image', this.selectedImageFile);
    }

    const parentId = categoryData.parentId || null;

    const pickedImageUrl = this.pickedImageUrl;

    this.loading = true;
    this.categoryService.createCategoryWithImage(formData).subscribe({
      next: (response: any) => {
        const finalizeCreate = (iconUrl?: string) => {
          if (parentId) {
            // It's a subgroup, not a root category - it belongs under its parent's
            // card, not in the top-level grid. Bump the count and let the panel
            // refetch next time it's expanded.
            const parent = this.categories.find(c => c.id === parentId);
            if (parent) {
              parent.subcategoryCount = (parent.subcategoryCount || 0) + 1;
              parent.subcategories = undefined;
              parent.expanded = false;
            }
          } else {
            const newCategory: Category = {
              id: response.id,
              name: response.name,
              nameTamil: response.nameTamil || undefined,
              description: response.description || '',
              productCount: 0,
              isActive: response.isActive !== false,
              color: categoryData.color || this.getRandomColor(),
              icon: categoryData.icon || this.getCategoryIcon(response.name),
              iconUrl: iconUrl || response.iconUrl || undefined,
              createdAt: new Date(response.createdAt || Date.now()),
              parentId: undefined,
              subcategoryCount: 0
            };
            this.categories.unshift(newCategory);
          }

          this.closeQuickAdd();
          this.resetImageUpload();
          this.loading = false;

          this.swal.success('Success!', parentId ? 'Subgroup added successfully!' : 'Category added successfully!');
        };

        // A searched image was picked (no id existed yet to download it against) -
        // apply it now that the category exists.
        if (pickedImageUrl) {
          this.categoryService.applyCategoryImageFromUrl(response.id, pickedImageUrl).subscribe({
            next: (updated: any) => finalizeCreate(updated.iconUrl),
            error: () => {
              this.swal.toast('Category created, but the picked image could not be applied', 'warning');
              finalizeCreate();
            }
          });
        } else {
          finalizeCreate();
        }
      },
      error: (error) => {
        console.error('Error creating category with image:', error);
        this.loading = false;
        this.swal.error('Error', 'Failed to create category. Please try again.');
      }
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

  // Same button-triggered navigator.clipboard.read() pattern used in
  // Bulk Edit's "Paste Image" - there's no real OS paste-event listener,
  // clipboard access requires a user gesture like this click. Routes
  // through processImageFile() so it gets the same validation/preview and
  // save-on-submit behavior as a browsed or dropped file.
  async pasteImageFromClipboard(): Promise<void> {
    if (!navigator.clipboard?.read) {
      this.swal.error('Not Supported', 'Clipboard paste is not supported in this browser');
      return;
    }
    try {
      const items = await navigator.clipboard.read();
      for (const item of items) {
        const type = item.types.find(t => t.startsWith('image/'));
        if (type) {
          const blob = await item.getType(type);
          const ext = type.split('/')[1] || 'png';
          const file = new File([blob], `pasted-image.${ext}`, { type });
          this.processImageFile(file);
          return;
        }
      }
      this.swal.error('No Image Found', 'Copy an image first, then click Paste Image');
    } catch (error) {
      console.error('Clipboard paste failed:', error);
      this.swal.error('Paste Failed', 'Could not read image from clipboard. Your browser may require clipboard permission.');
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
    this.pickedImageUrl = null;

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
    this.pickedImageUrl = null;
  }

  private resetImageUpload(): void {
    this.previewImageUrl = null;
    this.selectedImageFile = null;
    this.pickedImageUrl = null;
  }

  openImageSuggestions(): void {
    this.imageSuggestOpen = true;
    this.imageSuggestQuery = this.quickAddForm.get('name')?.value?.trim() || '';
    this.imageSuggestions = [];
    this.suggestError = null;
    if (this.imageSuggestQuery) {
      this.runImageSearch();
    }
  }

  runImageSearch(): void {
    const query = this.imageSuggestQuery.trim();
    if (!query) {
      return;
    }
    this.loadingSuggestions = true;
    this.suggestError = null;
    this.imageSuggestions = [];
    this.categoryService.searchImages(query).subscribe({
      next: (results) => {
        this.imageSuggestions = results;
        this.loadingSuggestions = false;
      },
      error: (error) => {
        this.suggestError = error?.error?.message || 'Image search failed - try again';
        this.loadingSuggestions = false;
      }
    });
  }

  closeImageSuggestions(): void {
    this.imageSuggestOpen = false;
    this.imageSuggestions = [];
    this.suggestError = null;
  }

  useSuggestedImage(suggestion: { label: string; thumb: string; url: string }): void {
    if (this.editingCategory) {
      // Category already exists - download and apply immediately
      this.downloadingSuggestionUrl = suggestion.url;
      this.categoryService.applyCategoryImageFromUrl(this.editingCategory.id, suggestion.url).subscribe({
        next: (updated: any) => {
          this.editingCategory!.iconUrl = updated.iconUrl;
          this.previewImageUrl = this.getCategoryImageUrl(updated.iconUrl);
          this.selectedImageFile = null;
          this.pickedImageUrl = null;
          this.downloadingSuggestionUrl = null;
          this.closeImageSuggestions();
          this.swal.toast('Image updated', 'success');
        },
        error: (error) => {
          this.downloadingSuggestionUrl = null;
          this.suggestError = error?.error?.message || 'Could not use this image - try another one';
        }
      });
    } else {
      // New category has no id yet - remember the pick, download it once the category is created
      this.selectedImageFile = null;
      this.pickedImageUrl = suggestion.url;
      this.previewImageUrl = suggestion.thumb;
      this.closeImageSuggestions();
    }
  }

  editCategory(category: Category): void {
    this.editingCategory = category;
    this.quickAddForm.patchValue({
      name: category.name,
      nameTamil: category.nameTamil || '',
      description: category.description || '',
      parentId: category.parentId || null
    });
    // Show the category's current image as the starting preview
    this.previewImageUrl = category.iconUrl ? this.getCategoryImageUrl(category.iconUrl) : null;
    this.selectedImageFile = null;
    this.showQuickAdd = true;
  }

  viewProducts(category: Category): void {
    this.router.navigate(['/shop-owner/category-products'], {
      queryParams: { categoryId: category.id, categoryName: category.name }
    });
  }

  duplicateCategory(category: Category): void {
    // Create the copy through the API so it survives a refresh
    this.uploadCategoryWithImage({
      name: `${category.name} (Copy)`,
      nameTamil: category.nameTamil || '',
      description: category.description || ''
    });
  }

  toggleCategoryStatus(category: Category): void {
    const newStatus = !category.isActive;
    this.categoryService.updateCategoryStatus(category.id, newStatus).subscribe({
      next: () => {
        category.isActive = newStatus;
        this.swal.toast(`Category ${newStatus ? 'activated' : 'deactivated'} successfully`, 'success');
      },
      error: (error) => {
        const message = error?.error?.message || error?.message || 'Failed to update category status';
        this.swal.error('Update Failed', message);
      }
    });
  }

  deleteCategory(category: Category): void {
    this.swal.confirmDelete(category.name).then((result) => {
      if (result.isConfirmed) {
        this.categoryService.deleteCategory(category.id).subscribe({
          next: () => {
            this.categories = this.categories.filter(c => c.id !== category.id);
            this.swal.success('Deleted!', `Category "${category.name}" has been deleted.`);
          },
          error: (error) => {
            const message = error?.error?.message || error?.message || 'Failed to delete category';
            this.swal.error('Delete Failed', message);
          }
        });
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

    // If it's a relative path from our backend (strip the /api suffix - uploads
    // are served from the server root, not under /api)
    const baseUrl = environment.apiUrl.replace(/\/api\/?$/, '');
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
