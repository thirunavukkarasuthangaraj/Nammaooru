import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

interface Product {
  id: number;
  name: string;
  category: string;
  price: number;
  stock: number;
  unit: string;
  status: 'active' | 'inactive' | 'out_of_stock';
  image: string;
  lastUpdated: Date;
  totalSales: number;
  lowStockThreshold: number;
}

@Component({
  selector: 'app-my-products',
  template: `
    <div class="my-products-container">
      <!-- Header Section -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">My Products</h1>
          <p class="page-subtitle">Manage your shop's product inventory and pricing</p>
        </div>
        <div class="header-actions">
          <button mat-raised-button color="primary" routerLink="/shop-owner/products/add">
            <mat-icon>add</mat-icon>
            Add Product
          </button>
          <button mat-stroked-button (click)="openBulkUpload()">
            <mat-icon>cloud_upload</mat-icon>
            Bulk Upload
          </button>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="stats-cards">
        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon total">
                <mat-icon>inventory_2</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getTotalProducts() }}</h3>
                <p>Total Products</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon active">
                <mat-icon>check_circle</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getActiveProducts() }}</h3>
                <p>Active Products</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon warning">
                <mat-icon>warning</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getLowStockProducts() }}</h3>
                <p>Low Stock</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon value">
                <mat-icon>currency_rupee</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getInventoryValue() | currency:'INR':'symbol':'1.0-0' }}</h3>
                <p>Inventory Value</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Filters and Search -->
      <mat-card class="filters-card">
        <mat-card-content>
          <div class="filters-section">
            <div class="search-filters">
              <mat-form-field appearance="outline" class="search-field">
                <mat-label>Search products</mat-label>
                <input matInput [formControl]="searchControl" placeholder="Search by name, category...">
                <mat-icon matPrefix>search</mat-icon>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Category</mat-label>
                <mat-select [(value)]="selectedCategory" (selectionChange)="applyFilters()">
                  <mat-option value="">All Categories</mat-option>
                  <mat-option *ngFor="let category of categories" [value]="category">
                    {{ category }}
                  </mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Status</mat-label>
                <mat-select [(value)]="selectedStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Status</mat-option>
                  <mat-option value="active">Active</mat-option>
                  <mat-option value="inactive">Inactive</mat-option>
                  <mat-option value="out_of_stock">Out of Stock</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="view-options">
              <mat-button-toggle-group [(value)]="viewMode">
                <mat-button-toggle value="table">
                  <mat-icon>table_view</mat-icon>
                </mat-button-toggle>
                <mat-button-toggle value="grid">
                  <mat-icon>grid_view</mat-icon>
                </mat-button-toggle>
              </mat-button-toggle-group>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Products Table View -->
      <mat-card class="products-table-card" *ngIf="viewMode === 'table'">
        <mat-card-content>
          <div class="table-container">
            <table mat-table [dataSource]="dataSource" matSort class="products-table">
              <!-- Image Column -->
              <ng-container matColumnDef="image">
                <th mat-header-cell *matHeaderCellDef>Product</th>
                <td mat-cell *matCellDef="let product">
                  <div class="product-cell">
                    <img [src]="product.image" [alt]="product.name" class="product-image">
                    <div class="product-info">
                      <h4>{{ product.name }}</h4>
                      <p>{{ product.category }}</p>
                    </div>
                  </div>
                </td>
              </ng-container>

              <!-- Price Column -->
              <ng-container matColumnDef="price">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Price</th>
                <td mat-cell *matCellDef="let product">
                  <div class="price-cell">
                    <span class="price">₹{{ product.price }}</span>
                    <span class="unit">per {{ product.unit }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Stock Column -->
              <ng-container matColumnDef="stock">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Stock</th>
                <td mat-cell *matCellDef="let product">
                  <div class="stock-cell">
                    <span class="stock-value" [class.low-stock]="product.stock <= product.lowStockThreshold">
                      {{ product.stock }} {{ product.unit }}
                    </span>
                    <span class="stock-status" *ngIf="product.stock <= product.lowStockThreshold">
                      Low Stock
                    </span>
                  </div>
                </td>
              </ng-container>

              <!-- Status Column -->
              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef>Status</th>
                <td mat-cell *matCellDef="let product">
                  <span class="status-badge" [class]="'status-' + product.status">
                    {{ getStatusLabel(product.status) }}
                  </span>
                </td>
              </ng-container>

              <!-- Sales Column -->
              <ng-container matColumnDef="sales">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Total Sales</th>
                <td mat-cell *matCellDef="let product">
                  <span class="sales-value">{{ product.totalSales }}</span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef>Actions</th>
                <td mat-cell *matCellDef="let product">
                  <div class="action-buttons">
                    <button mat-icon-button [matMenuTriggerFor]="actionMenu" [matMenuTriggerData]="{product: product}">
                      <mat-icon>more_vert</mat-icon>
                    </button>
                  </div>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
            </table>

            <mat-paginator [pageSizeOptions]="[10, 25, 50, 100]" showFirstLastButtons></mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Products Grid View -->
      <div class="products-grid" *ngIf="viewMode === 'grid'">
        <mat-card class="product-card" *ngFor="let product of dataSource.filteredData">
          <div class="product-image-container">
            <img [src]="product.image" [alt]="product.name" class="product-grid-image">
            <span class="product-status-badge" [class]="'status-' + product.status">
              {{ getStatusLabel(product.status) }}
            </span>
          </div>
          <mat-card-content>
            <h3 class="product-title">{{ product.name }}</h3>
            <p class="product-category">{{ product.category }}</p>
            <div class="product-details">
              <div class="price-section">
                <span class="product-price">₹{{ product.price }}</span>
                <span class="product-unit">per {{ product.unit }}</span>
              </div>
              <div class="stock-section">
                <span class="stock-label">Stock:</span>
                <span class="stock-amount" [class.low-stock]="product.stock <= product.lowStockThreshold">
                  {{ product.stock }} {{ product.unit }}
                </span>
              </div>
            </div>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button color="primary" (click)="editProduct(product)">
              <mat-icon>edit</mat-icon>
              Edit
            </button>
            <button mat-button (click)="updateStock(product)">
              <mat-icon>inventory</mat-icon>
              Stock
            </button>
            <button mat-icon-button [matMenuTriggerFor]="gridActionMenu" [matMenuTriggerData]="{product: product}">
              <mat-icon>more_vert</mat-icon>
            </button>
          </mat-card-actions>
        </mat-card>
      </div>
    </div>

    <!-- Action Menu -->
    <mat-menu #actionMenu="matMenu">
      <ng-template matMenuContent let-product="product">
        <button mat-menu-item (click)="editProduct(product)">
          <mat-icon>edit</mat-icon>
          <span>Edit Product</span>
        </button>
        <button mat-menu-item (click)="updateStock(product)">
          <mat-icon>inventory</mat-icon>
          <span>Update Stock</span>
        </button>
        <button mat-menu-item (click)="updatePrice(product)">
          <mat-icon>local_offer</mat-icon>
          <span>Update Price</span>
        </button>
        <button mat-menu-item (click)="viewSales(product)">
          <mat-icon>trending_up</mat-icon>
          <span>View Sales</span>
        </button>
        <mat-divider></mat-divider>
        <button mat-menu-item (click)="toggleStatus(product)" [class.warn]="product.status === 'active'">
          <mat-icon>{{ product.status === 'active' ? 'visibility_off' : 'visibility' }}</mat-icon>
          <span>{{ product.status === 'active' ? 'Deactivate' : 'Activate' }}</span>
        </button>
      </ng-template>
    </mat-menu>

    <mat-menu #gridActionMenu="matMenu">
      <ng-template matMenuContent let-product="product">
        <button mat-menu-item (click)="updatePrice(product)">
          <mat-icon>local_offer</mat-icon>
          <span>Update Price</span>
        </button>
        <button mat-menu-item (click)="viewSales(product)">
          <mat-icon>trending_up</mat-icon>
          <span>View Sales</span>
        </button>
        <button mat-menu-item (click)="toggleStatus(product)">
          <mat-icon>{{ product.status === 'active' ? 'visibility_off' : 'visibility' }}</mat-icon>
          <span>{{ product.status === 'active' ? 'Deactivate' : 'Activate' }}</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .my-products-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      font-size: 1rem;
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .stats-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .stat-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .stat-icon.total { background: linear-gradient(135deg, #667eea, #764ba2); }
    .stat-icon.active { background: linear-gradient(135deg, #4facfe, #00f2fe); }
    .stat-icon.warning { background: linear-gradient(135deg, #fa709a, #fee140); }
    .stat-icon.value { background: linear-gradient(135deg, #a8edea, #fed6e3); }

    .stat-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0;
      color: #1f2937;
    }

    .stat-details p {
      font-size: 0.9rem;
      color: #6b7280;
      margin: 0;
    }

    .filters-card {
      margin-bottom: 16px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .filters-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .search-filters {
      display: flex;
      gap: 16px;
      align-items: center;
      flex: 1;
    }

    .search-field {
      min-width: 300px;
    }

    .products-table-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .table-container {
      overflow-x: auto;
    }

    .products-table {
      width: 100%;
      min-width: 800px;
    }

    .product-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .product-image {
      width: 48px;
      height: 48px;
      border-radius: 8px;
      object-fit: cover;
    }

    .product-info h4 {
      margin: 0 0 2px 0;
      font-size: 0.9rem;
      font-weight: 600;
      color: #1f2937;
    }

    .product-info p {
      margin: 0;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .price-cell {
      display: flex;
      flex-direction: column;
    }

    .price {
      font-weight: 600;
      color: #1f2937;
    }

    .unit {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .stock-cell {
      display: flex;
      flex-direction: column;
    }

    .stock-value {
      font-weight: 500;
      color: #1f2937;
    }

    .stock-value.low-stock {
      color: #dc2626;
    }

    .stock-status {
      font-size: 0.7rem;
      color: #dc2626;
      font-weight: 500;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 16px;
      font-size: 0.8rem;
      font-weight: 500;
      text-transform: uppercase;
    }

    .status-badge.status-active {
      background: #dcfce7;
      color: #16a34a;
    }

    .status-badge.status-inactive {
      background: #f3f4f6;
      color: #6b7280;
    }

    .status-badge.status-out_of_stock {
      background: #fef2f2;
      color: #dc2626;
    }

    .sales-value {
      font-weight: 500;
      color: #1f2937;
    }

    .products-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 16px;
    }

    .product-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .product-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 16px rgba(0,0,0,0.15);
    }

    .product-image-container {
      position: relative;
      height: 160px;
      overflow: hidden;
      border-radius: 12px 12px 0 0;
    }

    .product-grid-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .product-status-badge {
      position: absolute;
      top: 8px;
      right: 8px;
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.7rem;
      font-weight: 500;
      text-transform: uppercase;
    }

    .product-title {
      font-size: 1rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .product-category {
      font-size: 0.8rem;
      color: #6b7280;
      margin: 0 0 12px 0;
    }

    .product-details {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .product-price {
      font-size: 1.1rem;
      font-weight: 600;
      color: #1f2937;
    }

    .product-unit {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .stock-section {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .stock-label {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .stock-amount {
      font-size: 0.8rem;
      font-weight: 500;
      color: #1f2937;
    }

    .stock-amount.low-stock {
      color: #dc2626;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .my-products-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .stats-cards {
        grid-template-columns: 1fr 1fr;
      }

      .filters-section {
        flex-direction: column;
        align-items: stretch;
      }

      .search-filters {
        flex-direction: column;
        gap: 12px;
      }

      .search-field {
        min-width: auto;
        width: 100%;
      }

      .products-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class MyProductsComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['image', 'price', 'stock', 'status', 'sales', 'actions'];
  dataSource = new MatTableDataSource<Product>();
  searchControl = new FormControl();
  
  viewMode: 'table' | 'grid' = 'table';
  selectedCategory = '';
  selectedStatus = '';

  categories = ['Groceries', 'Vegetables', 'Fruits', 'Dairy', 'Bakery', 'Beverages'];

  // Mock data
  products: Product[] = [
    {
      id: 1,
      name: 'Organic Rice',
      category: 'Groceries',
      price: 120,
      stock: 50,
      unit: 'kg',
      status: 'active',
      image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRjNGNEY2Ii8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiM5Q0EzQUYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCI+UmljZTwvdGV4dD4KPC9zdmc+',
      lastUpdated: new Date(),
      totalSales: 245,
      lowStockThreshold: 10
    },
    {
      id: 2,
      name: 'Fresh Tomatoes',
      category: 'Vegetables',
      price: 40,
      stock: 3,
      unit: 'kg',
      status: 'active',
      image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkVGMkYyIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiNEQzI2MjYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNiI+VG9tYXRvPC90ZXh0Pgo8L3N2Zz4=',
      lastUpdated: new Date(),
      totalSales: 189,
      lowStockThreshold: 5
    },
    {
      id: 3,
      name: 'Whole Wheat Bread',
      category: 'Bakery',
      price: 35,
      stock: 25,
      unit: 'piece',
      status: 'active',
      image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkZGQkVCIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiNBRjY1MDkiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNiI+QnJlYWQ8L3RleHQ+Cjwvc3ZnPg==',
      lastUpdated: new Date(),
      totalSales: 156,
      lowStockThreshold: 8
    },
    {
      id: 4,
      name: 'Fresh Milk',
      category: 'Dairy',
      price: 60,
      stock: 0,
      unit: 'liter',
      status: 'out_of_stock',
      image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTUwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDE1MCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNTAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRkNGRkZGIi8+Cjx0ZXh0IHg9Ijc1IiB5PSI3NSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiM2Mzc1OEYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxOCI+TWlsazwvdGV4dD4KPC9zdmc+',
      lastUpdated: new Date(),
      totalSales: 203,
      lowStockThreshold: 5
    }
  ];

  constructor(
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router
  ) {
    this.dataSource.data = this.products;
  }

  ngOnInit(): void {
    this.setupSearch();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  private setupSearch(): void {
    this.searchControl.valueChanges
      .pipe(
        debounceTime(300),
        distinctUntilChanged()
      )
      .subscribe(value => {
        this.applyFilters();
      });
  }

  applyFilters(): void {
    this.dataSource.filterPredicate = (data: Product, filter: string) => {
      const searchTerm = this.searchControl.value?.toLowerCase() || '';
      const matchesSearch = data.name.toLowerCase().includes(searchTerm) || 
                           data.category.toLowerCase().includes(searchTerm);
      const matchesCategory = !this.selectedCategory || data.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus || data.status === this.selectedStatus;
      
      return matchesSearch && matchesCategory && matchesStatus;
    };
    
    this.dataSource.filter = Math.random().toString(); // Trigger filter
  }

  getTotalProducts(): number {
    return this.products.length;
  }

  getActiveProducts(): number {
    return this.products.filter(p => p.status === 'active').length;
  }

  getLowStockProducts(): number {
    return this.products.filter(p => p.stock <= p.lowStockThreshold).length;
  }

  getInventoryValue(): number {
    return this.products.reduce((total, product) => total + (product.price * product.stock), 0);
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'out_of_stock': return 'Out of Stock';
      default: return status;
    }
  }

  editProduct(product: Product): void {
    console.log('Edit product:', product);
    this.router.navigate(['/shop-owner/products/edit', product.id]);
  }

  updateStock(product: Product): void {
    console.log('Update stock for:', product);
    // Open stock update dialog
  }

  updatePrice(product: Product): void {
    console.log('Update price for:', product);
    // Open price update dialog
  }

  viewSales(product: Product): void {
    console.log('View sales for:', product);
    // Navigate to sales analytics
  }

  toggleStatus(product: Product): void {
    const newStatus = product.status === 'active' ? 'inactive' : 'active';
    product.status = newStatus;
    
    this.snackBar.open(
      `Product ${newStatus === 'active' ? 'activated' : 'deactivated'} successfully`,
      'Close',
      { duration: 3000 }
    );
  }

  openBulkUpload(): void {
    console.log('Open bulk upload');
    // Navigate to bulk upload page
  }
}