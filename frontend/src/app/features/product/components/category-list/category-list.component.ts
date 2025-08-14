import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { ProductCategory } from '../../../../core/models/product.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-category-list',
  template: `
    <div class="category-container">
      <div class="category-header">
        <div class="header-content">
          <h2 class="page-title">
            <mat-icon class="title-icon">category</mat-icon>
            Product Categories
          </h2>
          <p class="page-subtitle">Manage your product category hierarchy</p>
        </div>
        <div class="header-actions">
          <button mat-fab color="primary" routerLink="/products/categories/new" matTooltip="Add New Category">
            <mat-icon>add</mat-icon>
          </button>
        </div>
      </div>

      <div class="categories-content">
        <mat-card class="categories-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>account_tree</mat-icon>
              Category Hierarchy
            </mat-card-title>
            <mat-card-subtitle>All categories organized in a tree structure</mat-card-subtitle>
          </mat-card-header>
          
          <mat-card-content>
            <div *ngIf="loading" class="loading-container">
              <mat-spinner diameter="40"></mat-spinner>
              <p>Loading categories...</p>
            </div>

            <div *ngIf="!loading && categories.length === 0" class="empty-state">
              <mat-icon class="empty-icon">folder_open</mat-icon>
              <h3>No Categories Found</h3>
              <p>Start by creating your first product category</p>
              <button mat-raised-button color="primary" routerLink="/products/categories/new">
                <mat-icon>add</mat-icon>
                Create First Category
              </button>
            </div>

            <div *ngIf="!loading && categories.length > 0" class="categories-tree">
              <div *ngFor="let category of categories" class="category-item">
                <mat-expansion-panel class="category-panel">
                  <mat-expansion-panel-header>
                    <mat-panel-title>
                      <div class="category-title">
                        <mat-icon class="category-icon">folder</mat-icon>
                        <span class="category-name">{{ category.name }}</span>
                        <mat-chip-set class="category-chips">
                          <mat-chip [color]="category.isActive ? 'primary' : 'warn'" selected>
                            {{ category.isActive ? 'Active' : 'Inactive' }}
                          </mat-chip>
                          <mat-chip color="accent" selected>
                            {{ category.productCount }} products
                          </mat-chip>
                        </mat-chip-set>
                      </div>
                    </mat-panel-title>
                    <mat-panel-description>
                      {{ category.description || 'No description available' }}
                    </mat-panel-description>
                  </mat-expansion-panel-header>

                  <div class="category-details">
                    <div class="category-info">
                      <div class="info-row">
                        <strong>Slug:</strong> {{ category.slug }}
                      </div>
                      <div class="info-row">
                        <strong>Full Path:</strong> {{ category.fullPath }}
                      </div>
                      <div class="info-row">
                        <strong>Created:</strong> {{ category.createdAt | date:'short' }}
                      </div>
                      <div class="info-row">
                        <strong>Products:</strong> {{ category.productCount }}
                      </div>
                      <div class="info-row" *ngIf="category.subcategoryCount > 0">
                        <strong>Subcategories:</strong> {{ category.subcategoryCount }}
                      </div>
                    </div>

                    <div class="category-actions">
                      <button mat-button color="primary" [routerLink]="['/products/categories', category.id]">
                        <mat-icon>edit</mat-icon>
                        Edit
                      </button>
                      <button mat-button color="accent" (click)="toggleStatus(category)">
                        <mat-icon>{{ category.isActive ? 'pause' : 'play_arrow' }}</mat-icon>
                        {{ category.isActive ? 'Deactivate' : 'Activate' }}
                      </button>
                      <button mat-button color="warn" (click)="deleteCategory(category)" [disabled]="category.productCount > 0">
                        <mat-icon>delete</mat-icon>
                        Delete
                      </button>
                    </div>
                  </div>

                  <div *ngIf="category.subcategories && category.subcategories.length > 0" class="subcategories">
                    <h4>Subcategories</h4>
                    <div *ngFor="let subcategory of category.subcategories" class="subcategory-item">
                      <mat-icon>subdirectory_arrow_right</mat-icon>
                      <span>{{ subcategory.name }}</span>
                      <mat-chip [color]="subcategory.isActive ? 'primary' : 'warn'" selected>
                        {{ subcategory.isActive ? 'Active' : 'Inactive' }}
                      </mat-chip>
                    </div>
                  </div>
                </mat-expansion-panel>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .category-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
      min-height: calc(100vh - 100px);
    }

    .category-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
      padding: 24px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 12px;
      color: white;
    }

    .header-content {
      flex: 1;
    }

    .page-title {
      display: flex;
      align-items: center;
      margin: 0 0 8px 0;
      font-size: 28px;
      font-weight: 600;
      color: white;
    }

    .title-icon {
      margin-right: 12px;
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .page-subtitle {
      margin: 0;
      opacity: 0.9;
      font-size: 16px;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .categories-content {
      margin-top: 24px;
    }

    .categories-card {
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 60px;
      color: #666;
    }

    .loading-container p {
      margin-top: 16px;
    }

    .empty-state {
      text-align: center;
      padding: 60px;
      color: #666;
    }

    .empty-icon {
      font-size: 72px;
      width: 72px;
      height: 72px;
      color: #ddd;
      margin-bottom: 16px;
    }

    .empty-state h3 {
      margin: 16px 0 8px 0;
      color: #333;
    }

    .empty-state p {
      margin-bottom: 24px;
    }

    .categories-tree {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .category-item {
      border-radius: 8px;
      overflow: hidden;
    }

    .category-panel {
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .category-title {
      display: flex;
      align-items: center;
      gap: 12px;
      width: 100%;
    }

    .category-icon {
      color: #667eea;
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .category-name {
      font-weight: 600;
      font-size: 16px;
    }

    .category-chips {
      margin-left: auto;
    }

    .category-details {
      padding: 16px;
      background: #f8f9fa;
      border-radius: 8px;
      margin: 16px 0;
    }

    .category-info {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
      margin-bottom: 16px;
    }

    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 4px 0;
      font-size: 14px;
    }

    .info-row strong {
      color: #333;
      margin-right: 8px;
    }

    .category-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .subcategories {
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #e0e0e0;
    }

    .subcategories h4 {
      margin: 0 0 12px 0;
      color: #333;
      font-size: 14px;
      font-weight: 600;
    }

    .subcategory-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 0;
      font-size: 14px;
    }

    .subcategory-item mat-icon {
      color: #999;
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    @media (max-width: 768px) {
      .category-container {
        padding: 16px;
      }

      .category-header {
        flex-direction: column;
        align-items: stretch;
        gap: 16px;
        padding: 20px;
      }

      .header-actions {
        justify-content: center;
      }

      .page-title {
        font-size: 24px;
      }

      .category-info {
        grid-template-columns: 1fr;
      }

      .category-actions {
        justify-content: center;
      }

      .category-title {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }

      .category-chips {
        margin-left: 0;
      }
    }
  `]
})
export class CategoryListComponent implements OnInit {
  categories: ProductCategory[] = [];
  loading = true;

  constructor(
    private categoryService: ProductCategoryService,
    private dialog: MatDialog
  ) {}

  ngOnInit() {
    this.loadCategories();
  }

  private loadCategories() {
    this.loading = true;
    this.categoryService.getCategories(undefined, undefined, undefined, 0, 100).subscribe({
      next: (response) => {
        this.categories = response.content || [];
        this.loading = false;
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
        this.loading = false;
      }
    });
  }

  toggleStatus(category: ProductCategory) {
    this.categoryService.updateCategoryStatus(category.id, !category.isActive).subscribe({
      next: (updatedCategory) => {
        const index = this.categories.findIndex(c => c.id === category.id);
        if (index !== -1) {
          this.categories[index] = updatedCategory;
        }
        Swal.fire({
          title: 'Success!',
          text: `Category ${updatedCategory.isActive ? 'activated' : 'deactivated'} successfully`,
          icon: 'success',
          confirmButtonText: 'OK'
        });
      },
      error: (error) => {
        console.error('Error updating category status:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to update category status',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  deleteCategory(category: ProductCategory) {
    if (category.productCount > 0) {
      Swal.fire({
        title: 'Cannot Delete!',
        text: 'Cannot delete category with existing products',
        icon: 'warning',
        confirmButtonText: 'OK'
      });
      return;
    }

    Swal.fire({
      title: 'Are you sure?',
      text: `Do you want to delete the category "${category.name}"? This action cannot be undone.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.categoryService.deleteCategory(category.id).subscribe({
          next: () => {
            this.categories = this.categories.filter(c => c.id !== category.id);
            Swal.fire({
              title: 'Deleted!',
              text: 'Category deleted successfully',
              icon: 'success',
              confirmButtonText: 'OK'
            });
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
}