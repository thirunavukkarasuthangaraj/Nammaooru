import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
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

      <!-- Product Categories - Large List -->
      <mat-card class="categories-main-card">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>category</mat-icon>
            Product Categories
          </mat-card-title>
          <mat-card-subtitle>Click any category to view all products in that category</mat-card-subtitle>
        </mat-card-header>
        <mat-card-content>
          <div *ngIf="loading" class="loading-container">
            <mat-spinner diameter="50"></mat-spinner>
            <p>Loading categories...</p>
          </div>
          <div *ngIf="!loading && categories.length === 0" class="empty-state">
            <mat-icon>category</mat-icon>
            <h3>No Categories Found</h3>
            <p>Get started by creating your first product category</p>
            <button mat-raised-button color="primary" routerLink="/products/categories/new">
              <mat-icon>add</mat-icon>
              Create First Category
            </button>
          </div>
          <div *ngIf="!loading && categories.length > 0" class="categories-large-list">
            <div *ngFor="let category of categories" 
                 class="category-large-item"
                 (click)="viewCategoryProducts(category)"
                 matRipple>
              <div class="category-main-info">
                <div class="category-icon">
                  <mat-icon>folder</mat-icon>
                </div>
                <div class="category-details">
                  <h3 class="category-title">{{ category.name }}</h3>
                  <p class="category-desc" *ngIf="category.description">{{ category.description }}</p>
                  <p class="category-desc" *ngIf="!category.description">No description available</p>
                </div>
              </div>
              <div class="category-stats">
                <div class="product-count-large">
                  <span class="count-number">{{ getCategoryProductCount(category) }}</span>
                  <span class="count-label">Products</span>
                </div>
                <mat-icon class="arrow-icon">chevron_right</mat-icon>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
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

    .categories-main-card {
      margin: 24px;
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      border: none;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px 40px;
      text-align: center;
    }

    .loading-container p {
      margin-top: 20px;
      color: #666;
      font-size: 16px;
    }

    .empty-state {
      text-align: center;
      padding: 60px 40px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 64px;
      height: 64px;
      width: 64px;
      color: #ddd;
      margin-bottom: 20px;
    }

    .empty-state h3 {
      margin: 16px 0 8px 0;
      font-size: 24px;
      color: #333;
    }

    .empty-state p {
      margin-bottom: 24px;
      font-size: 16px;
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

    .categories-large-list {
      display: flex;
      flex-direction: column;
      gap: 0;
    }

    .category-large-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 24px;
      border-bottom: 1px solid #f0f0f0;
      cursor: pointer;
      transition: all 0.3s ease;
      background: white;
    }

    .category-large-item:last-child {
      border-bottom: none;
    }

    .category-large-item:hover {
      background: #f8f9fa;
      transform: translateX(8px);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .category-main-info {
      display: flex;
      align-items: center;
      gap: 20px;
      flex: 1;
    }

    .category-icon {
      width: 60px;
      height: 60px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
    }

    .category-icon mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    .category-details {
      flex: 1;
    }

    .category-title {
      font-size: 20px;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #1a1a1a;
    }

    .category-desc {
      font-size: 14px;
      color: #666;
      margin: 0;
      line-height: 1.4;
    }

    .category-stats {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .product-count-large {
      text-align: center;
      padding: 8px 16px;
      background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
      border-radius: 12px;
      min-width: 80px;
    }

    .count-number {
      display: block;
      font-size: 18px;
      font-weight: 700;
      color: #1976d2;
    }

    .count-label {
      display: block;
      font-size: 12px;
      color: #1976d2;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .arrow-icon {
      color: #999;
      font-size: 24px;
      width: 24px;
      height: 24px;
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

      .stats-grid {
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      }

      .categories-main-card {
        margin: 16px;
      }

      .category-large-item {
        padding: 16px;
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .category-main-info {
        flex-direction: column;
        gap: 12px;
        text-align: center;
      }

      .category-large-item:hover {
        transform: none;
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
    private categoryService: ProductCategoryService,
    private router: Router
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

  viewCategoryProducts(category: ProductCategory): void {
    // Navigate to products page with category filter
    this.router.navigate(['/products/master'], { 
      queryParams: { categoryId: category.id, categoryName: category.name } 
    });
  }

  getCategoryProductCount(category: ProductCategory): number {
    // This would normally come from the API
    // For now, return a mock count
    const mockCounts: {[key: number]: number} = {
      1: 7,  // Grocery
      2: 2,  // Electronics  
      3: 3,  // Medicine
      4: 4,  // Clothing
      5: 2,  // Snacks
      6: 2   // Food & Beverages
    };
    return mockCounts[category.id] || 0;
  }
}