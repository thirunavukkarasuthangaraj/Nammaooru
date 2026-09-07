import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

interface CategoryOption {
  id: number;
  name: string;
}

interface DisplayProduct {
  id: number;
  name: string;
  price: number;
  stockQuantity: number;
  isAvailable: boolean;
  imageUrl?: string;
}

@Component({
  selector: 'app-category-products',
  template: `
    <div class="page-container">
      <div class="page-header">
        <button mat-icon-button (click)="goBack()">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <div class="header-text">
          <h1>{{ selectedCategoryId ? selectedCategoryName : 'All Products' }}</h1>
          <p>{{ isLoading ? 'Loading...' : (products.length + ' product' + (products.length === 1 ? '' : 's')) }}</p>
        </div>
      </div>

      <div class="filter-bar">
        <button type="button"
                class="filter-chip"
                [class.active]="!selectedCategoryId"
                (click)="selectCategory(null)">
          All
        </button>
        <button type="button"
                class="filter-chip"
                *ngFor="let cat of categories"
                [class.active]="selectedCategoryId === cat.id"
                (click)="selectCategory(cat)">
          {{ cat.name }}
        </button>
      </div>

      <div class="loading-row" *ngIf="isLoading">
        <mat-spinner diameter="32"></mat-spinner>
      </div>

      <div class="empty-state" *ngIf="!isLoading && products.length === 0">
        <mat-icon>inventory_2</mat-icon>
        <h3>No products here</h3>
        <p>{{ selectedCategoryId ? 'This category has no products yet.' : 'You have no products yet.' }}</p>
      </div>

      <div class="product-grid" *ngIf="!isLoading && products.length > 0">
        <div class="product-card" *ngFor="let product of products" (click)="editProduct(product)">
          <img [src]="getImageUrl(product.imageUrl)" class="product-thumb" onerror="this.style.visibility='hidden'" />
          <div class="product-info">
            <div class="product-name" [title]="product.name">{{ product.name }}</div>
            <div class="product-meta">
              <span class="product-price">&#8377;{{ product.price }}</span>
              <span class="product-stock" [class.low]="product.stockQuantity <= 5">Stock: {{ product.stockQuantity }}</span>
            </div>
            <span class="status-badge" [class.on]="product.isAvailable">{{ product.isAvailable ? 'Active' : 'Inactive' }}</span>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .page-container { padding: 24px; max-width: 1100px; margin: 0 auto; }
    .page-header { display: flex; align-items: center; gap: 12px; margin-bottom: 20px; }
    .header-text h1 { font-size: 22px; font-weight: 700; margin: 0; color: #222; }
    .header-text p { margin: 2px 0 0; color: #777; font-size: 13px; }

    .filter-bar {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 20px;
    }
    .filter-chip {
      border: 1px solid #dcdcdc;
      background: #fff;
      color: #555;
      border-radius: 20px;
      padding: 6px 16px;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .filter-chip:hover { border-color: #16a34a; color: #16a34a; }
    .filter-chip.active { background: #16a34a; border-color: #16a34a; color: #fff; }

    .loading-row { display: flex; justify-content: center; padding: 60px 0; }

    .empty-state {
      text-align: center;
      padding: 60px 20px;
      color: #888;
    }
    .empty-state mat-icon { font-size: 48px; width: 48px; height: 48px; color: #ccc; }
    .empty-state h3 { margin: 12px 0 4px; color: #555; }
    .empty-state p { margin: 0; font-size: 13px; }

    .product-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
      gap: 14px;
    }
    .product-card {
      display: flex;
      flex-direction: column;
      gap: 8px;
      border: 1px solid #eee;
      border-radius: 10px;
      padding: 10px;
      cursor: pointer;
      transition: box-shadow 0.15s ease, border-color 0.15s ease;
    }
    .product-card:hover { box-shadow: 0 2px 10px rgba(0,0,0,0.08); border-color: #ddd; }
    .product-thumb {
      width: 100%;
      height: 120px;
      object-fit: cover;
      border-radius: 8px;
      background: #f2f2f2;
    }
    .product-name {
      font-weight: 600;
      font-size: 14px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .product-meta {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: #666;
    }
    .product-price { font-weight: 700; color: #16a34a; }
    .product-stock.low { color: #e53935; }
    .status-badge {
      align-self: flex-start;
      font-size: 11px;
      padding: 2px 8px;
      border-radius: 10px;
      background: #eee;
      color: #888;
    }
    .status-badge.on { background: #E8F5E9; color: #16a34a; }
  `]
})
export class CategoryProductsComponent implements OnInit {
  categories: CategoryOption[] = [];
  products: DisplayProduct[] = [];
  isLoading = false;

  selectedCategoryId: number | null = null;
  selectedCategoryName = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private categoryService: ProductCategoryService,
    private productService: ShopOwnerProductService
  ) {}

  ngOnInit(): void {
    this.categoryService.getCategories(undefined, true, undefined, 0, 200).subscribe({
      next: (response: any) => {
        const list = Array.isArray(response) ? response : (response?.content || []);
        this.categories = list.map((c: any) => ({ id: c.id, name: c.name }));
      },
      error: () => this.categories = []
    });

    this.route.queryParams.subscribe(params => {
      const categoryId = params['categoryId'] ? Number(params['categoryId']) : null;
      const categoryName = params['categoryName'] || '';
      this.selectedCategoryId = categoryId;
      this.selectedCategoryName = categoryName;
      this.loadProducts();
    });
  }

  selectCategory(cat: CategoryOption | null): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: cat ? { categoryId: cat.id, categoryName: cat.name } : {},
      replaceUrl: true
    });
  }

  private loadProducts(): void {
    this.isLoading = true;
    this.productService.getMyProducts(this.selectedCategoryId || undefined, 0, 500).subscribe({
      next: (page) => {
        this.products = (page.content || []).map((p: any) => ({
          id: p.id,
          name: p.displayName || p.customName || p.masterProduct?.name || 'Unnamed product',
          price: p.price || 0,
          stockQuantity: p.stockQuantity || 0,
          isAvailable: p.isAvailable !== false,
          imageUrl: p.primaryImageUrl || undefined
        }));
        this.isLoading = false;
      },
      error: () => {
        this.products = [];
        this.isLoading = false;
      }
    });
  }

  getImageUrl(url?: string): string {
    return getImageUrlUtil(url);
  }

  editProduct(product: DisplayProduct): void {
    // Full edit/pricing/stock tools live on the main My Products screen
    this.router.navigate(['/shop-owner/my-products'], {
      queryParams: this.selectedCategoryName ? { category: this.selectedCategoryName } : {}
    });
  }

  goBack(): void {
    this.router.navigate(['/shop-owner/categories']);
  }
}
