import { Component, OnInit, ViewChild } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatPaginator, PageEvent } from '@angular/material/paginator';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { ProductCategory } from '../../../../core/models/product.model';
import Swal from 'sweetalert2';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-category-list',
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
          <button mat-raised-button class="action-button" routerLink="/products/categories/new">
            <mat-icon>add_circle</mat-icon>
            New Category
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
            <div class="stat-value">{{ getSubcategories() }}</div>
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
              <button mat-icon-button matTooltip="Expand All" (click)="expandAll()">
                <mat-icon>unfold_more</mat-icon>
              </button>
              <button mat-icon-button matTooltip="Collapse All" (click)="collapseAll()">
                <mat-icon>unfold_less</mat-icon>
              </button>
            </div>
          </div>

          <!-- Loading State -->
          <div *ngIf="loading" class="loading-state">
            <mat-spinner diameter="60"></mat-spinner>
            <h3>Loading Categories</h3>
            <p>Please wait while we fetch your categories...</p>
          </div>

          <!-- Empty State -->
          <div *ngIf="!loading && categories.length === 0" class="empty-state">
            <div class="empty-icon">
              <mat-icon>category</mat-icon>
            </div>
            <h3>No Categories Found</h3>
            <p>Start organizing your products by creating categories</p>
            <button mat-raised-button color="primary" routerLink="/products/categories/new">
              <mat-icon>add</mat-icon>
              Create First Category
            </button>
          </div>

          <!-- Categories Grid -->
          <div *ngIf="!loading && categories.length > 0">
            <div class="categories-grid">
              <div *ngFor="let category of categories" class="category-card">
              <div class="category-card-header">
                <div class="category-icon-wrapper" [class.has-image]="category.iconUrl">
                  <img *ngIf="category.iconUrl && isImageUrl(category.iconUrl)"
                       [src]="getCategoryImageUrl(category.iconUrl)"
                       [alt]="category.name"
                       class="category-image"
                       (error)="onImageError($event)">
                  <span *ngIf="category.iconUrl && !isImageUrl(category.iconUrl)" class="category-emoji">{{ category.iconUrl }}</span>
                  <mat-icon *ngIf="!category.iconUrl" class="category-main-icon">folder</mat-icon>
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
                <p class="category-tamil" *ngIf="category.nameTamil">{{ category.nameTamil }}</p>
                <p class="category-slug">{{ category.slug }}</p>
                <p class="category-description">{{ category.description || 'No description available' }}</p>
              </div>

              <div class="category-stats">
                <div class="stat-item">
                  <mat-icon class="stat-icon">inventory</mat-icon>
                  <span class="stat-text">{{ category.productCount || 0 }} products</span>
                </div>
                <div class="stat-item" *ngIf="category.subcategoryCount > 0">
                  <mat-icon class="stat-icon">account_tree</mat-icon>
                  <span class="stat-text">{{ category.subcategoryCount }} subcategories</span>
                </div>
              </div>

              <!-- Subcategories -->
              <div class="subcategories" *ngIf="category.subcategories && category.subcategories.length > 0">
                <div class="subcategories-header">
                  <mat-icon>subdirectory_arrow_right</mat-icon>
                  <span>Subcategories</span>
                </div>
                <div class="subcategory-list">
                  <div *ngFor="let sub of category.subcategories" class="subcategory-item">
                    <mat-icon class="sub-icon">folder_open</mat-icon>
                    <span class="sub-name">{{ sub.name }}</span>
                    <span class="sub-count">({{ sub.productCount || 0 }})</span>
                  </div>
                </div>
              </div>

              <div class="category-actions">
                <button mat-button class="action-btn edit" [routerLink]="['/products/categories', category.id]">
                  <mat-icon>edit</mat-icon>
                  Edit
                </button>
                <button mat-button 
                        class="action-btn toggle" 
                        [class.activate]="!category.isActive"
                        [class.deactivate]="category.isActive"
                        (click)="toggleStatus(category)">
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

            <!-- Pagination -->
            <div class="pagination-wrapper">
              <mat-paginator
                [length]="totalCategories"
                [pageSize]="pageSize"
                [pageSizeOptions]="[10, 20, 50]"
                [showFirstLastButtons]="true"
                (page)="onPageChange($event)">
              </mat-paginator>
            </div>
          </div>
        </mat-card>
      </div>
    </div>
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

    /* Loading State */
    .loading-state {
      padding: 80px 20px;
      text-align: center;
    }

    .loading-state h3 {
      margin: 24px 0 8px 0;
      font-size: 20px;
      color: #333;
    }

    .loading-state p {
      color: #888;
      margin: 0;
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
      width: 60px;
      height: 60px;
      background: linear-gradient(135deg, #667eea20 0%, #764ba220 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }

    .category-icon-wrapper.has-image {
      background: #f8f9fa;
      padding: 0;
    }

    .category-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 12px;
    }

    .category-emoji {
      font-size: 32px;
      line-height: 1;
    }

    .category-main-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #667eea;
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

    .category-tamil {
      font-size: 16px;
      color: #4a90d9;
      margin: 0 0 8px 0;
      font-weight: 500;
    }

    .category-slug {
      font-size: 13px;
      color: #888;
      margin: 0 0 12px 0;
      font-family: 'Courier New', monospace;
      background: #f5f5f5;
      padding: 4px 8px;
      border-radius: 4px;
      display: inline-block;
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

    .subcategories {
      padding: 16px 20px;
      background: #f8f9fa;
      border-top: 1px solid #e0e0e0;
    }

    .subcategories-header {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #666;
      margin-bottom: 12px;
    }

    .subcategory-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .subcategory-item {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      background: white;
      border-radius: 12px;
      font-size: 12px;
      color: #666;
      border: 1px solid #e0e0e0;
    }

    .sub-icon {
      font-size: 14px !important;
      width: 14px !important;
      height: 14px !important;
      color: #999;
    }

    .sub-name {
      font-weight: 500;
    }

    .sub-count {
      color: #888;
      font-size: 11px;
    }

    .category-actions {
      padding: 16px 20px;
      background: #fafafa;
      border-top: 1px solid #e0e0e0;
      display: flex;
      gap: 8px;
      justify-content: flex-end;
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

    /* Pagination */
    .pagination-wrapper {
      padding: 24px;
      border-top: 1px solid #e0e0e0;
      background: #fafafa;
      display: flex;
      justify-content: flex-end;
    }

    ::ng-deep .mat-mdc-paginator {
      background: transparent;
    }

    /* Responsive Design */
    @media (max-width: 1024px) {
      .categories-grid {
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      }
      
      .stats-row {
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      }
    }

    @media (max-width: 768px) {
      .page-header {
        flex-direction: column;
        text-align: center;
        gap: 24px;
      }
      
      .stats-row {
        grid-template-columns: 1fr;
        padding: 16px;
      }
      
      .categories-section {
        padding: 16px;
      }
      
      .categories-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }
      
      .card-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
      
      .category-actions {
        flex-direction: column;
        gap: 8px;
      }
      
      .action-btn {
        justify-content: center;
        width: 100%;
      }
    }
  `]
})
export class CategoryListComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  categories: ProductCategory[] = [];
  loading = false;
  pageSize = 10;
  pageIndex = 0;
  totalCategories = 0;

  constructor(
    private dialog: MatDialog,
    private categoryService: ProductCategoryService
  ) {}

  ngOnInit() {
    this.loadCategories();
  }

  loadCategories() {
    this.loading = true;
    console.log('Loading categories with pageIndex:', this.pageIndex, 'pageSize:', this.pageSize);

    this.categoryService.getCategories(undefined, undefined, undefined, this.pageIndex, this.pageSize).subscribe({
      next: (response) => {
        console.log('Categories response:', response);
        this.categories = response.content || [];
        this.totalCategories = response.totalElements || 0;
        this.loading = false;
        console.log('Loaded categories:', this.categories.length, 'Total:', this.totalCategories);
      },
      error: (error) => {
        console.error('Error loading categories:', error);
        this.loading = false;
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load categories',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  onPageChange(event: PageEvent) {
    console.log('Page change event:', event);
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    console.log('New pageIndex:', this.pageIndex, 'New pageSize:', this.pageSize);
    this.loadCategories();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  getTotalCategories(): number {
    return this.totalCategories;
  }

  getActiveCategories(): number {
    return this.categories.filter(c => c.isActive).length;
  }

  getSubcategories(): number {
    return this.categories.reduce((sum, cat) => sum + (cat.subcategoryCount || 0), 0);
  }

  getTotalProducts(): number {
    return this.categories.reduce((sum, cat) => sum + (cat.productCount || 0), 0);
  }

  toggleStatus(category: ProductCategory) {
    const action = category.isActive ? 'deactivate' : 'activate';
    const title = category.isActive ? 'Deactivate Category?' : 'Activate Category?';
    const text = `Are you sure you want to ${action} "${category.name}"?`;

    Swal.fire({
      title,
      text,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: category.isActive ? '#f44336' : '#4caf50',
      cancelButtonColor: '#666',
      confirmButtonText: `Yes, ${action}!`,
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        const updatedCategory = { ...category, isActive: !category.isActive };
        this.categoryService.updateCategory(category.id, updatedCategory).subscribe({
          next: () => {
            category.isActive = !category.isActive;
            Swal.fire({
              title: 'Updated!',
              text: `Category ${action}d successfully.`,
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          },
          error: (error) => {
            console.error('Error updating category:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to ${action} category`,
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  deleteCategory(category: ProductCategory) {
    if (category.productCount > 0) {
      Swal.fire({
        title: 'Cannot Delete!',
        text: `Category "${category.name}" has ${category.productCount} products. Move or delete products first.`,
        icon: 'warning',
        confirmButtonText: 'OK'
      });
      return;
    }

    Swal.fire({
      title: 'Delete Category?',
      text: `Are you sure you want to delete "${category.name}"? This action cannot be undone.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#f44336',
      cancelButtonColor: '#666',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.categoryService.deleteCategory(category.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Deleted!',
              text: 'Category has been deleted.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
            this.loadCategories();
          },
          error: (error) => {
            console.error('Error deleting category:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to delete category',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  expandAll() {
    // Implementation for expanding all categories if using mat-expansion-panel
  }

  collapseAll() {
    // Implementation for collapsing all categories if using mat-expansion-panel
  }

  isImageUrl(url: string): boolean {
    if (!url) return false;

    // Check if it's a URL (http/https) or a relative path
    const isUrl = url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/');

    // Check if it has an image extension
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    const hasImageExtension = imageExtensions.some(ext => url.toLowerCase().endsWith(ext));

    return isUrl && hasImageExtension;
  }

  getCategoryImageUrl(iconUrl: string): string {
    if (!iconUrl) return '';

    // If it's already a full URL, return it
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return iconUrl;
    }

    // If it's a relative URL starting with /, use imageBaseUrl (frontend domain)
    if (iconUrl.startsWith('/')) {
      return `${environment.imageBaseUrl}${iconUrl}`;
    }

    return iconUrl;
  }

  onImageError(event: Event): void {
    // Handle image load errors by showing a placeholder icon
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';

    // Optionally, you can replace with a default image
    // img.src = '/assets/images/default-category.png';
  }
}