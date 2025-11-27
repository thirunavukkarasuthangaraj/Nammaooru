import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router, ActivatedRoute } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { MasterProduct, ProductFilters } from '../../../../core/models/product.model';
import Swal from 'sweetalert2';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-master-product-list',
  template: `
    <div class="master-products-container">
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
            <span class="breadcrumb-item active">Master Products</span>
            <mat-icon class="breadcrumb-separator" *ngIf="selectedCategoryName">chevron_right</mat-icon>
            <span class="breadcrumb-item active" *ngIf="selectedCategoryName">{{ selectedCategoryName }}</span>
          </div>
          <h1 class="page-title">
            <span *ngIf="!selectedCategoryName">Master Products</span>
            <span *ngIf="selectedCategoryName">{{ selectedCategoryName }} Products</span>
          </h1>
          <p class="page-description">
            <span *ngIf="!selectedCategoryName">Manage your complete product catalog</span>
            <span *ngIf="selectedCategoryName">Products in {{ selectedCategoryName }} category</span>
          </p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button color="accent" routerLink="/products/dashboard" *ngIf="selectedCategoryName" class="back-button">
            <mat-icon>arrow_back</mat-icon>
            Back to Categories
          </button>
          <button mat-raised-button class="action-button" routerLink="/products/master/new">
            <mat-icon>add_circle</mat-icon>
            New Product
          </button>
        </div>
      </div>

      <!-- Statistics Cards -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>inventory</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getTotalProducts() }}</div>
            <div class="stat-label">Total Products</div>
          </div>
        </div>
        
        <div class="stat-card active">
          <div class="stat-icon">
            <mat-icon>check_circle</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getActiveProducts() }}</div>
            <div class="stat-label">Active Products</div>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>category</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getCategories() }}</div>
            <div class="stat-label">Categories</div>
          </div>
        </div>

        <div class="stat-card featured">
          <div class="stat-icon">
            <mat-icon>star</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getFeaturedProducts() }}</div>
            <div class="stat-label">Featured</div>
          </div>
        </div>
      </div>

      <!-- Filters Section -->
      <mat-card class="filter-card">
        <div class="filter-header">
          <h3 class="filter-title">
            <mat-icon>filter_list</mat-icon>
            <span *ngIf="!selectedCategoryName">Filters</span>
            <span *ngIf="selectedCategoryName">Filters - {{ selectedCategoryName }} Category</span>
          </h3>
          <button mat-button class="clear-filters" (click)="clearFilters()" *ngIf="hasActiveFilters()">
            <mat-icon>clear</mat-icon>
            Clear All
          </button>
        </div>
        <div class="filter-content">
          <mat-form-field appearance="outline" class="search-field">
            <mat-label>Search Products</mat-label>
            <input matInput [(ngModel)]="searchQuery" (input)="applyFilters()" placeholder="Search by name, SKU, or brand...">
            <mat-icon matPrefix>search</mat-icon>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="filter-field">
            <mat-label>Category</mat-label>
            <mat-select [(value)]="categoryFilter" (selectionChange)="applyFilters()">
              <mat-option value="">All Categories</mat-option>
              <mat-option *ngFor="let cat of categories" [value]="cat">{{ cat }}</mat-option>
            </mat-select>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="filter-field">
            <mat-label>Brand</mat-label>
            <mat-select [(value)]="brandFilter" (selectionChange)="applyFilters()">
              <mat-option value="">All Brands</mat-option>
              <mat-option *ngFor="let brand of brands" [value]="brand">{{ brand }}</mat-option>
            </mat-select>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="filter-field">
            <mat-label>Status</mat-label>
            <mat-select [(value)]="statusFilter" (selectionChange)="applyFilters()">
              <mat-option value="">All Status</mat-option>
              <mat-option value="ACTIVE">
                <span class="status-option active">Active</span>
              </mat-option>
              <mat-option value="INACTIVE">
                <span class="status-option inactive">Inactive</span>
              </mat-option>
            </mat-select>
          </mat-form-field>
        </div>
      </mat-card>

      <!-- Products Table Card -->
      <mat-card class="table-card">
        <div class="table-header">
          <h3 class="table-title">Products List</h3>
          <div class="table-actions">
            <button mat-icon-button matTooltip="Refresh" (click)="loadProducts()">
              <mat-icon>refresh</mat-icon>
            </button>
            <button mat-icon-button matTooltip="Export">
              <mat-icon>download</mat-icon>
            </button>
          </div>
        </div>

        <div class="table-container" *ngIf="!loading">
          <table mat-table [dataSource]="dataSource" class="products-table" matSort>
            <!-- Image Column -->
            <ng-container matColumnDef="image">
              <th mat-header-cell *matHeaderCellDef>Image</th>
              <td mat-cell *matCellDef="let product">
                <div class="product-image" *ngIf="product.primaryImageUrl">
                  <img [src]="getImageUrl(product.primaryImageUrl)" 
                       [alt]="product.name"
                       (error)="onImageError($event)">
                </div>
                <div class="product-image no-image" *ngIf="!product.primaryImageUrl">
                  <mat-icon>image</mat-icon>
                </div>
              </td>
            </ng-container>

            <!-- Name Column -->
            <ng-container matColumnDef="name">
              <th mat-header-cell *matHeaderCellDef mat-sort-header>Product Details</th>
              <td mat-cell *matCellDef="let product">
                <div class="product-details">
                  <div class="product-name">
                    {{ product.name }}
                    <span class="tamil-name" *ngIf="product.nameTamil"> • {{ product.nameTamil }}</span>
                  </div>
                  <div class="product-meta">
                    <span class="meta-item">
                      <mat-icon class="meta-icon">label</mat-icon>
                      {{ product.sku }}
                    </span>
                    <span class="meta-item" *ngIf="product.brand">
                      <mat-icon class="meta-icon">business</mat-icon>
                      {{ product.brand }}
                    </span>
                  </div>
                  <div class="product-description">{{ product.description || 'No description available' }}</div>
                </div>
              </td>
            </ng-container>

            <!-- Category Column -->
            <ng-container matColumnDef="category">
              <th mat-header-cell *matHeaderCellDef>Category</th>
              <td mat-cell *matCellDef="let product">
                <span class="category-badge" *ngIf="product.category">
                  {{ product.category.name }}
                </span>
                <span class="no-category" *ngIf="!product.category">-</span>
              </td>
            </ng-container>

            <!-- Status Column -->
            <ng-container matColumnDef="status">
              <th mat-header-cell *matHeaderCellDef>Status</th>
              <td mat-cell *matCellDef="let product">
                <span class="status-badge" [class.active]="product.status === 'ACTIVE'" 
                      [class.inactive]="product.status === 'INACTIVE'">
                  <mat-icon class="status-icon">
                    {{ product.status === 'ACTIVE' ? 'check_circle' : 'cancel' }}
                  </mat-icon>
                  {{ product.status }}
                </span>
              </td>
            </ng-container>

            <!-- Actions Column -->
            <ng-container matColumnDef="actions">
              <th mat-header-cell *matHeaderCellDef>Actions</th>
              <td mat-cell *matCellDef="let product">
                <div class="action-buttons">
                  <button mat-icon-button 
                          [routerLink]="['/products/master', product.id]" 
                          matTooltip="Edit Product"
                          class="edit-button">
                    <mat-icon>edit</mat-icon>
                  </button>
                  <button mat-icon-button 
                          (click)="duplicateProduct(product)" 
                          matTooltip="Duplicate"
                          class="duplicate-button">
                    <mat-icon>content_copy</mat-icon>
                  </button>
                  <button mat-icon-button 
                          (click)="deleteProduct(product)" 
                          matTooltip="Delete"
                          class="delete-button">
                    <mat-icon>delete</mat-icon>
                  </button>
                </div>
              </td>
            </ng-container>

            <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
            <tr mat-row *matRowDef="let row; columns: displayedColumns;" class="product-row"></tr>

            <!-- No Data Row -->
            <tr class="mat-row no-data-row" *matNoDataRow>
              <td class="mat-cell" [attr.colspan]="displayedColumns.length">
                <div class="empty-state">
                  <mat-icon class="empty-icon">inventory_2</mat-icon>
                  <h3>No Products Found</h3>
                  <p>Try adjusting your filters or add a new product</p>
                </div>
              </td>
            </tr>
          </table>
        </div>

        <!-- Loading State -->
        <div class="loading-state" *ngIf="loading">
          <mat-spinner diameter="60"></mat-spinner>
          <h3>Loading Products</h3>
          <p>Please wait while we fetch your products...</p>
        </div>

        <mat-paginator
          [length]="totalElements"
          [pageSizeOptions]="[10, 25, 50, 100]"
          [pageSize]="10"
          showFirstLastButtons>
        </mat-paginator>
      </mat-card>
    </div>
  `,
  styles: [`
    .master-products-container {
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
      color: white;
      text-decoration: none;
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

    .back-button {
      margin-right: 12px;
      background: rgba(255, 255, 255, 0.1);
      color: white;
      border-color: rgba(255, 255, 255, 0.3);
    }

    .back-button mat-icon {
      margin-right: 8px;
    }

    .back-button:hover {
      background: rgba(255, 255, 255, 0.2);
      border-color: rgba(255, 255, 255, 0.5);
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 12px;
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

    .stat-card.featured {
      border-color: #ffc107;
      background: linear-gradient(135deg, #fff8e1 0%, #fff 100%);
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

    .stat-card.featured .stat-icon {
      background: linear-gradient(135deg, #ffc10720 0%, #ffeb3b20 100%);
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

    .stat-card.featured .stat-icon mat-icon {
      color: #ffc107;
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

    /* Filter Card */
    .filter-card {
      margin: 0 32px 24px 32px;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      border: none;
      padding: 24px;
    }

    .filter-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .filter-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 18px;
      font-weight: 600;
      margin: 0;
      color: #1a1a1a;
    }

    .filter-title mat-icon {
      color: #667eea;
    }

    .clear-filters {
      color: #f44336;
    }

    .filter-content {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1fr;
      gap: 16px;
    }

    .search-field {
      grid-column: span 1;
    }

    .filter-field {
      width: 100%;
    }

    .status-option {
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 600;
    }

    .status-option.active {
      background: #e8f5e9;
      color: #4caf50;
    }

    .status-option.inactive {
      background: #ffebee;
      color: #f44336;
    }

    /* Table Card */
    .table-card {
      margin: 0 32px;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      border: none;
      overflow: hidden;
    }

    .table-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px;
      border-bottom: 1px solid #e0e0e0;
      background: #fafafa;
    }

    .table-title {
      font-size: 18px;
      font-weight: 600;
      margin: 0;
      color: #1a1a1a;
    }

    .table-actions {
      display: flex;
      gap: 8px;
    }

    .table-container {
      overflow-x: auto;
    }

    .products-table {
      width: 100%;
      background: white;
    }

    .products-table th {
      font-weight: 600;
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #666;
      background: #fafafa;
      padding: 16px !important;
    }

    .products-table td {
      padding: 16px !important;
      border-bottom: 1px solid #f0f0f0;
    }

    .product-row:hover {
      background: #f8f9fa;
    }

    /* Product Image */
    .product-image {
      width: 60px;
      height: 60px;
      border-radius: 8px;
      overflow: hidden;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .product-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .product-image.no-image {
      background: linear-gradient(135deg, #f5f5f7 0%, #e8e8ea 100%);
      color: #bbb;
    }

    .product-image.no-image mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    /* Product Details */
    .product-details {
      max-width: 400px;
    }

    .product-name {
      font-size: 16px;
      font-weight: 600;
      color: #1a1a1a;
      margin-bottom: 4px;
    }

    .tamil-name {
      font-size: 14px;
      font-weight: 500;
      color: #667eea;
      margin-left: 4px;
    }

    .product-meta {
      display: flex;
      gap: 16px;
      margin-bottom: 8px;
    }

    .meta-item {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 13px;
      color: #666;
    }

    .meta-icon {
      font-size: 14px !important;
      width: 14px !important;
      height: 14px !important;
      color: #999;
    }

    .product-description {
      font-size: 13px;
      color: #888;
      line-height: 1.4;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
    }

    /* Category Badge */
    .category-badge {
      display: inline-block;
      padding: 6px 12px;
      background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
      color: #1976d2;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }

    .no-category {
      color: #bbb;
    }

    /* Status Badge */
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .status-badge.active {
      background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
      color: #4caf50;
    }

    .status-badge.inactive {
      background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
      color: #f44336;
    }

    .status-icon {
      font-size: 14px !important;
      width: 14px !important;
      height: 14px !important;
    }

    /* Action Buttons */
    .action-buttons {
      display: flex;
      gap: 4px;
    }

    .edit-button {
      color: #2196f3;
    }

    .duplicate-button {
      color: #ff9800;
    }

    .delete-button {
      color: #f44336;
    }

    /* Empty State */
    .empty-state {
      padding: 60px 20px;
      text-align: center;
      color: #888;
    }

    .empty-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin: 0 auto 16px;
      color: #ddd;
    }

    .empty-state h3 {
      font-size: 20px;
      margin: 0 0 8px 0;
      color: #666;
    }

    .empty-state p {
      margin: 0;
      color: #999;
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

    /* No Data Row */
    .no-data-row {
      height: 200px;
    }

    .no-data-row .mat-cell {
      text-align: center;
      padding: 40px !important;
    }

    /* Responsive Design */
    @media (max-width: 1200px) {
      .filter-content {
        grid-template-columns: 1fr 1fr;
      }
      
      .search-field {
        grid-column: span 2;
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
      
      .filter-card, .table-card {
        margin: 0 16px 16px 16px;
      }
      
      .filter-content {
        grid-template-columns: 1fr;
      }
      
      .search-field {
        grid-column: span 1;
      }
      
      .table-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
    }
  `]
})
export class MasterProductListComponent implements OnInit {
  displayedColumns: string[] = ['image', 'name', 'category', 'status', 'actions'];
  dataSource = new MatTableDataSource<MasterProduct>();
  loading = false;
  products: MasterProduct[] = [];
  totalElements = 0;

  // Filters
  searchQuery = '';
  categoryFilter = '';
  brandFilter = '';
  statusFilter = '';
  categories: string[] = [];
  brands: string[] = [];
  selectedCategoryName = '';
  selectedCategoryId: any = null;
  
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private productService: ProductService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit() {
    // Check for category filter from query parameters
    this.route.queryParams.subscribe(params => {
      if (params['categoryName']) {
        this.categoryFilter = params['categoryName'];
        this.selectedCategoryName = params['categoryName'];
        this.selectedCategoryId = params['categoryId'];
      } else {
        this.selectedCategoryName = '';
        this.selectedCategoryId = null;
      }
      this.loadProducts();
    });
  }

  ngAfterViewInit() {
    this.setupTableFeatures();

    // Listen to paginator events for server-side pagination
    if (this.paginator) {
      this.paginator.page.subscribe(() => {
        this.loadProducts();
      });
    }
  }

  private setupTableFeatures() {
    if (this.sort) {
      this.dataSource.sort = this.sort;
    }
    // Don't connect paginator to dataSource for server-side pagination
  }

  loadProducts() {
    this.loading = true;

    // Create filters object for API call with pagination
    const filters: any = {
      page: this.paginator ? this.paginator.pageIndex : 0,
      size: this.paginator ? this.paginator.pageSize : 10
    };

    if (this.selectedCategoryId) {
      filters.categoryId = this.selectedCategoryId;
    }
    if (this.selectedCategoryName) {
      filters.categoryName = this.selectedCategoryName;
    }

    this.productService.getMasterProducts(filters).subscribe({
      next: (response) => {
        this.products = response.content || [];
        this.totalElements = response.totalElements || 0;
        this.dataSource.data = this.products;
        this.extractFilters();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.loading = false;
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load products',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  extractFilters() {
    // Extract unique categories
    const categorySet = new Set<string>();
    const brandSet = new Set<string>();
    
    this.products.forEach(product => {
      if (product.category?.name) {
        categorySet.add(product.category.name);
      }
      if (product.brand) {
        brandSet.add(product.brand);
      }
    });
    
    this.categories = Array.from(categorySet).sort();
    this.brands = Array.from(brandSet).sort();
  }

  applyFilters() {
    // Reset to first page when filters change
    if (this.paginator) {
      this.paginator.pageIndex = 0;
    }
    // Reload data from server with new filters
    this.loadProducts();
  }

  clearFilters() {
    this.searchQuery = '';
    this.categoryFilter = '';
    this.brandFilter = '';
    this.statusFilter = '';
    this.applyFilters();
  }

  hasActiveFilters(): boolean {
    return !!(this.searchQuery || this.categoryFilter || this.brandFilter || this.statusFilter);
  }

  getTotalProducts(): number {
    return this.products.length;
  }

  getActiveProducts(): number {
    return this.products.filter(p => p.status === 'ACTIVE').length;
  }

  getCategories(): number {
    return this.categories.length;
  }

  getFeaturedProducts(): number {
    // This would need a featured flag in the product model
    return this.products.filter(p => p.isFeatured).length || 0;
  }

  deleteProduct(product: MasterProduct) {
    Swal.fire({
      title: 'Delete Product?',
      text: `Are you sure you want to delete "${product.name}"?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#f44336',
      cancelButtonColor: '#666',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.productService.deleteMasterProduct(product.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Deleted!',
              text: 'Product has been deleted.',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
            this.loadProducts();
          },
          error: (error) => {
            console.error('Error deleting product:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to delete product',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  duplicateProduct(product: MasterProduct) {
    const duplicatedProduct = {
      ...product,
      id: 0,
      name: `${product.name} (Copy)`,
      sku: `${product.sku}-COPY-${Date.now()}`
    };
    
    this.productService.createMasterProduct(duplicatedProduct).subscribe({
      next: (newProduct) => {
        Swal.fire({
          title: 'Duplicated!',
          text: 'Product has been duplicated successfully.',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
        this.loadProducts();
      },
      error: (error) => {
        console.error('Error duplicating product:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to duplicate product',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  getImageUrl(imageUrl: string): string {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Use imageBaseUrl (fixed) for serving static images (without /api prefix)
    return `${environment.imageBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}${imageUrl}`;
  }

  onImageError(event: any): void {
    event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjVGNUY1Ii8+CjxwYXRoIGQ9Ik02MCA2MEgxNDBWMTQwSDYwVjYwWiIgZmlsbD0iI0UwRTBFMCIvPgo8Y2lyY2xlIGN4PSI4NSIgY3k9Ijg1IiByPSIxMCIgZmlsbD0iI0QwRDBEMCIvPgo8cGF0aCBkPSJNNjAgMTIwTDkwIDkwTDExMCAxMTBMMTQwIDgwVjE0MEg2MFYxMjBaIiBmaWxsPSIjRDBEMEQwIi8+Cjx0ZXh0IHg9IjEwMCIgeT0iMTcwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5IiBmb250LXNpemU9IjEyIiBmb250LWZhbWlseT0iQXJpYWwiPk5vIEltYWdlPC90ZXh0Pgo8L3N2Zz4K';
  }

  onFiltersChange(filters: ProductFilters) {
    // Handle filter changes if using the app-product-filters component
  }
}
