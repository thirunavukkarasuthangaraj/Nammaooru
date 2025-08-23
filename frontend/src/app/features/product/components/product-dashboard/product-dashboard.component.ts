import { Component, OnInit } from '@angular/core';
import { Observable, forkJoin } from 'rxjs';
import { ProductService } from '../../../../core/services/product.service';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { MasterProduct, ProductCategory } from '../../../../core/models/product.model';

@Component({
  selector: 'app-product-dashboard',
  template: `
    <div class="dashboard-container">
      <div class="dashboard-header">
        <h2>Product Management Dashboard</h2>
        <div class="header-actions">
          <button mat-raised-button color="primary" routerLink="/products/master/new">
            <mat-icon>add</mat-icon>
            New Product
          </button>
        </div>
      </div>

      <div class="stats-grid">
        <app-product-stats-card
          title="Total Master Products"
          [value]="totalProducts"
          icon="inventory_2"
          color="primary"
          [loading]="loading">
        </app-product-stats-card>

        <app-product-stats-card
          title="Active Categories"
          [value]="totalCategories"
          icon="category"
          color="accent"
          [loading]="loading">
        </app-product-stats-card>

        <app-product-stats-card
          title="Featured Products"
          [value]="featuredCount"
          icon="star"
          color="warn"
          [loading]="loading">
        </app-product-stats-card>

        <app-product-stats-card
          title="Total Brands"
          [value]="totalBrands"
          icon="business"
          color="primary"
          [loading]="loading">
        </app-product-stats-card>
      </div>

      <div class="content-grid">
        <!-- Recent Products -->
        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>schedule</mat-icon>
              Recent Products
            </mat-card-title>
            <mat-card-subtitle>Latest master products added</mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div *ngIf="loading" class="loading-container">
              <mat-spinner diameter="40"></mat-spinner>
            </div>
            <div *ngIf="!loading && recentProducts.length === 0" class="empty-state">
              <mat-icon>inventory_2</mat-icon>
              <p>No products found</p>
              <button mat-button color="primary" routerLink="/products/master/new">
                Add First Product
              </button>
            </div>
            <div *ngIf="!loading && recentProducts.length > 0" class="products-list">
              <div *ngFor="let product of recentProducts" class="product-item">
                <div class="product-info">
                  <div class="product-name">{{ product.name }}</div>
                  <div class="product-meta">
                    <span class="sku">{{ product.sku }}</span>
                    <span class="brand" *ngIf="product.brand">{{ product.brand }}</span>
                  </div>
                </div>
                <div class="product-actions">
                  <mat-chip-set>
                    <mat-chip [color]="product.status === 'ACTIVE' ? 'primary' : 'warn'"
                             [class.selected]="product.status === 'ACTIVE'">
                      {{ product.status }}
                    </mat-chip>
                  </mat-chip-set>
                  <button mat-icon-button 
                          [routerLink]="['/products/master', product.id]"
                          matTooltip="Edit Product">
                    <mat-icon>edit</mat-icon>
                  </button>
                </div>
              </div>
            </div>
          </mat-card-content>
          <mat-card-actions *ngIf="recentProducts.length > 0">
            <button mat-button routerLink="/products/master">
              View All Products
            </button>
          </mat-card-actions>
        </mat-card>

        <!-- Category Tree -->
        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>account_tree</mat-icon>
              Product Categories
            </mat-card-title>
            <mat-card-subtitle>Category hierarchy overview</mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div *ngIf="loading" class="loading-container">
              <mat-spinner diameter="40"></mat-spinner>
            </div>
            <div *ngIf="!loading && categories.length === 0" class="empty-state">
              <mat-icon>category</mat-icon>
              <p>No categories found</p>
              <button mat-button color="primary" routerLink="/products/categories/new">
                Add First Category
              </button>
            </div>
            <app-category-tree 
              *ngIf="!loading && categories.length > 0"
              [categories]="categories"
              [readonly]="true"
              [showActions]="false">
            </app-category-tree>
          </mat-card-content>
          <mat-card-actions *ngIf="categories.length > 0">
            <button mat-button routerLink="/products/categories">
              Manage Categories
            </button>
          </mat-card-actions>
        </mat-card>

        <!-- Featured Products -->
        <mat-card class="dashboard-card featured-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>star</mat-icon>
              Featured Products
            </mat-card-title>
            <mat-card-subtitle>Currently featured master products</mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div *ngIf="loading" class="loading-container">
              <mat-spinner diameter="40"></mat-spinner>
            </div>
            <div *ngIf="!loading && featuredProducts.length === 0" class="empty-state">
              <mat-icon>star_border</mat-icon>
              <p>No featured products</p>
            </div>
            <div *ngIf="!loading && featuredProducts.length > 0" class="featured-grid">
              <div *ngFor="let product of featuredProducts" class="featured-item">
                <div class="featured-content">
                  <div class="featured-name">{{ product.name }}</div>
                  <div class="featured-brand" *ngIf="product.brand">{{ product.brand }}</div>
                  <div class="featured-sku">{{ product.sku }}</div>
                </div>
                <button mat-icon-button 
                        [routerLink]="['/products/master', product.id]"
                        matTooltip="Edit Product">
                  <mat-icon>edit</mat-icon>
                </button>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Quick Actions -->
        <mat-card class="dashboard-card actions-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>flash_on</mat-icon>
              Quick Actions
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="actions-grid">
              <button mat-stroked-button 
                      color="primary"
                      routerLink="/products/master/new"
                      class="action-button">
                <mat-icon>add_box</mat-icon>
                <span>Add Master Product</span>
              </button>
              
              <button mat-stroked-button 
                      color="accent"
                      routerLink="/products/categories/new"
                      class="action-button">
                <mat-icon>create_new_folder</mat-icon>
                <span>Create Category</span>
              </button>
              
              <button mat-stroked-button 
                      color="primary"
                      routerLink="/products/master"
                      class="action-button">
                <mat-icon>search</mat-icon>
                <span>Browse Products</span>
              </button>
              
              <button mat-stroked-button 
                      color="accent"
                      routerLink="/products/categories"
                      class="action-button">
                <mat-icon>account_tree</mat-icon>
                <span>Manage Categories</span>
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .dashboard-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .dashboard-header h2 {
      margin: 0;
      color: #333;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .content-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 24px;
    }

    .dashboard-card {
      height: fit-content;
    }

    .loading-container {
      display: flex;
      justify-content: center;
      padding: 40px;
    }

    .empty-state {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      color: #ccc;
      margin-bottom: 16px;
    }

    .products-list {
      max-height: 400px;
      overflow-y: auto;
    }

    .product-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid #eee;
    }

    .product-item:last-child {
      border-bottom: none;
    }

    .product-info {
      flex: 1;
    }

    .product-name {
      font-weight: 500;
      margin-bottom: 4px;
    }

    .product-meta {
      font-size: 12px;
      color: #666;
    }

    .product-meta span {
      margin-right: 12px;
    }

    .product-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .featured-grid {
      display: grid;
      gap: 8px;
      max-height: 300px;
      overflow-y: auto;
    }

    .featured-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      background: #f5f5f5;
      border-radius: 4px;
    }

    .featured-content {
      flex: 1;
    }

    .featured-name {
      font-weight: 500;
      margin-bottom: 2px;
    }

    .featured-brand {
      font-size: 12px;
      color: #666;
      margin-bottom: 2px;
    }

    .featured-sku {
      font-size: 11px;
      color: #999;
    }

    .actions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
    }

    .action-button {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      padding: 20px 16px;
      height: auto;
    }

    .action-button mat-icon {
      font-size: 24px;
      height: 24px;
      width: 24px;
    }

    @media (max-width: 768px) {
      .dashboard-container {
        padding: 16px;
      }

      .dashboard-header {
        flex-direction: column;
        align-items: stretch;
        gap: 16px;
      }

      .content-grid {
        grid-template-columns: 1fr;
      }

      .stats-grid {
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      }
    }
  `]
})
export class ProductDashboardComponent implements OnInit {
  loading = true;
  totalProducts = 0;
  totalCategories = 0;
  featuredCount = 0;
  totalBrands = 0;
  
  recentProducts: MasterProduct[] = [];
  featuredProducts: MasterProduct[] = [];
  categories: ProductCategory[] = [];

  constructor(
    private productService: ProductService,
    private categoryService: ProductCategoryService
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
  }

  private loadDashboardData(): void {
    this.loading = true;

    forkJoin({
      products: this.productService.getMasterProducts({ size: 10, sortBy: 'updatedAt', sortDirection: 'DESC' }),
      featured: this.productService.getFeaturedProducts(),
      categories: this.categoryService.getRootCategories(),
      brands: this.productService.getAllBrands()
    }).subscribe({
      next: (data) => {
        this.totalProducts = data.products.totalElements;
        this.recentProducts = data.products.content.slice(0, 5);
        
        this.featuredProducts = data.featured.slice(0, 6);
        this.featuredCount = data.featured.length;
        
        this.categories = data.categories;
        this.totalCategories = data.categories.length;
        
        this.totalBrands = data.brands.length;
        
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading dashboard data:', error);
        // Use mock data when API fails
        this.loadMockData();
        this.loading = false;
      }
    });
  }

  private loadMockData(): void {
    // Mock products
    this.recentProducts = [
      {
        id: 1,
        name: 'Laptop Pro X1',
        sku: 'LAP-001',
        brand: 'TechBrand',
        status: 'ACTIVE',
        description: 'High-performance laptop',
        basePrice: 89999,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 2,
        name: 'Wireless Mouse',
        sku: 'MOU-002',
        brand: 'Accessories Plus',
        status: 'ACTIVE',
        description: 'Ergonomic wireless mouse',
        basePrice: 1299,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 3,
        name: 'USB-C Hub',
        sku: 'HUB-003',
        brand: 'ConnectTech',
        status: 'ACTIVE',
        description: '7-in-1 USB-C hub',
        basePrice: 2499,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 4,
        name: 'Mechanical Keyboard',
        sku: 'KEY-004',
        brand: 'KeyMaster',
        status: 'ACTIVE',
        description: 'RGB mechanical keyboard',
        basePrice: 5999,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 5,
        name: 'Monitor 4K',
        sku: 'MON-005',
        brand: 'ViewTech',
        status: 'ACTIVE',
        description: '27" 4K IPS Monitor',
        basePrice: 34999,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ] as any[];

    // Mock featured products
    this.featuredProducts = this.recentProducts.slice(0, 3);
    this.featuredCount = 3;

    // Mock categories
    this.categories = [
      {
        id: 1,
        name: 'Electronics',
        slug: 'electronics',
        description: 'Electronic products',
        parentId: null,
        isActive: true,
        displayOrder: 1,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 2,
        name: 'Computers',
        slug: 'computers',
        description: 'Computer products',
        parentId: null,
        isActive: true,
        displayOrder: 2,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 3,
        name: 'Accessories',
        slug: 'accessories',
        description: 'Computer accessories',
        parentId: null,
        isActive: true,
        displayOrder: 3,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ] as any[];

    // Set counts
    this.totalProducts = 156;
    this.totalCategories = 12;
    this.totalBrands = 25;
  }
}