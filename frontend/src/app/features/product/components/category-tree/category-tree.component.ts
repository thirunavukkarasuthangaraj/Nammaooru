import { Component, Input } from '@angular/core';
import { ProductCategory } from '../../../../core/models/product.model';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-category-tree',
  template: `
    <div class="category-tree">
      <div *ngFor="let category of categories" class="category-node">
        <div class="category-item" [class.has-subcategories]="category.hasSubcategories">
          <div class="category-content">
            <img *ngIf="category.iconUrl" [src]="getImageUrl(category.iconUrl)" class="category-image" alt="{{ category.name }}">
            <mat-icon class="category-icon" *ngIf="!category.iconUrl">
              {{ category.hasSubcategories ? 'folder' : 'label' }}
            </mat-icon>

            <div class="category-info">
              <div class="category-name">{{ category.name }}</div>
              <div class="category-meta" *ngIf="category.productCount > 0 || category.subcategoryCount > 0">
                <span *ngIf="category.productCount > 0" class="product-count">
                  {{ category.productCount }} products
                </span>
                <span *ngIf="category.subcategoryCount > 0" class="subcategory-count">
                  {{ category.subcategoryCount }} subcategories
                </span>
              </div>
            </div>
          </div>
          
          <div class="category-actions" *ngIf="showActions">
            <mat-chip [color]="category.isActive ? 'primary' : 'warn'"
                     [class.selected]="category.isActive"
                     class="status-chip">
              {{ category.isActive ? 'Active' : 'Inactive' }}
            </mat-chip>
            
            <button mat-icon-button 
                    [routerLink]="['/products/categories', category.id]"
                    matTooltip="Edit Category"
                    *ngIf="!readonly">
              <mat-icon>edit</mat-icon>
            </button>
          </div>
        </div>
        
        <div class="subcategories" *ngIf="category.subcategories && category.subcategories.length > 0">
          <app-category-tree 
            [categories]="category.subcategories"
            [readonly]="readonly"
            [showActions]="showActions">
          </app-category-tree>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .category-tree {
      padding-left: 0;
    }

    .category-node {
      margin-bottom: 8px;
    }

    .category-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      background: #fff;
      border: 1px solid #e0e0e0;
      border-radius: 6px;
      transition: all 0.2s ease;
    }

    .category-item:hover {
      background: #f9f9f9;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .category-item.has-subcategories {
      border-left: 4px solid #3f51b5;
    }

    .category-content {
      display: flex;
      align-items: center;
      gap: 12px;
      flex: 1;
    }

    .category-icon {
      color: #666;
      font-size: 20px;
      height: 20px;
      width: 20px;
    }

    .category-image {
      width: 40px;
      height: 40px;
      object-fit: cover;
      border-radius: 6px;
      border: 1px solid #e0e0e0;
    }

    .category-info {
      flex: 1;
    }

    .category-name {
      font-weight: 500;
      margin-bottom: 4px;
      color: #333;
    }

    .category-meta {
      font-size: 12px;
      color: #666;
    }

    .category-meta span {
      margin-right: 12px;
    }

    .product-count {
      background: #e8f5e8;
      color: #2e7d32;
      padding: 2px 6px;
      border-radius: 10px;
    }

    .subcategory-count {
      background: #e3f2fd;
      color: #1976d2;
      padding: 2px 6px;
      border-radius: 10px;
    }

    .category-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .status-chip {
      font-size: 11px;
      height: 24px;
    }

    .subcategories {
      margin-top: 8px;
      padding-left: 32px;
      position: relative;
    }

    .subcategories::before {
      content: '';
      position: absolute;
      left: 16px;
      top: 0;
      bottom: 0;
      width: 1px;
      background: #e0e0e0;
    }

    @media (max-width: 768px) {
      .category-item {
        padding: 8px;
        flex-direction: column;
        align-items: stretch;
        gap: 8px;
      }

      .category-content {
        gap: 8px;
      }

      .category-actions {
        justify-content: flex-end;
      }

      .subcategories {
        padding-left: 16px;
      }

      .subcategories::before {
        left: 8px;
      }
    }
  `]
})
export class CategoryTreeComponent {
  @Input() categories: ProductCategory[] = [];
  @Input() readonly = false;
  @Input() showActions = true;

  getImageUrl(iconUrl: string | null): string {
    if (!iconUrl) {
      return '';
    }
    // If the iconUrl is already a full URL, return it as is
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return iconUrl;
    }
    // Otherwise, prepend the backend URL with cache-busting timestamp
    const timestamp = new Date().getTime();
    // Extract base URL from apiUrl (remove /api suffix)
    const baseUrl = environment.apiUrl.replace('/api', '');
    return `${baseUrl}${iconUrl}?t=${timestamp}`;
  }
}