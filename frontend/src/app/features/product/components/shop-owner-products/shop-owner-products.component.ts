import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { ShopProductService } from '../../../../core/services/shop-product.service';
import { ShopService } from '../../../../core/services/shop.service';
import { AuthService } from '../../../../core/services/auth.service';
import { MasterProduct, ShopProduct, ShopProductRequest, ShopProductStatus, ProductStatus } from '../../../../core/models/product.model';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

interface ProductItem {
  masterProduct: MasterProduct;
  shopProduct?: ShopProduct;
  isInShop: boolean;
  tempPrice?: number;
  tempStock?: number;
  tempAvailable?: boolean;
  isEditing: boolean;
  isSelected: boolean;
}

@Component({
  selector: 'app-shop-owner-products',
  template: `
    <div class="shop-owner-container">
      <!-- Header Section -->
      <div class="list-header">
        <div class="header-content">
          <h2 class="page-title">
            <mat-icon class="title-icon">add_shopping_cart</mat-icon>
            Select Products
          </h2>
          <p class="page-subtitle" *ngIf="userShop">
            Select and manage products for {{ userShop.name }}
          </p>
        </div>
        <div class="header-actions">
          <div class="nav-buttons">
            <button mat-stroked-button (click)="goBack()">
              <mat-icon>arrow_back</mat-icon>
              Back
            </button>
            <button mat-stroked-button [routerLink]="['/shops']">
              <mat-icon>store</mat-icon>
              All Shops
            </button>
            <button mat-stroked-button [routerLink]="['/products/my-shop']">
              <mat-icon>my_location</mat-icon>
              My Shop Products
            </button>
          </div>
          <div class="header-stats" *ngIf="userShop">
            <div class="stat-item">
              <span class="stat-number">{{ getTotalProducts() }}</span>
              <span class="stat-label">Total</span>
            </div>
            <div class="stat-item">
              <span class="stat-number">{{ getActiveProducts() }}</span>
              <span class="stat-label">In Shop</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Search and Filter Section -->
      <mat-card class="filter-card">
        <mat-card-content>
          <div class="filter-section">
            <mat-form-field appearance="outline" class="search-field">
              <mat-label>Search Products</mat-label>
              <input matInput 
                     [(ngModel)]="searchQuery" 
                     (input)="onSearchChange()"
                     placeholder="Search by name, SKU, or brand...">
              <mat-icon matSuffix>search</mat-icon>
            </mat-form-field>

            <mat-form-field appearance="outline" class="filter-field">
              <mat-label>Filter by Status</mat-label>
              <mat-select [(value)]="statusFilter" (selectionChange)="applyFilters()">
                <mat-option value="">All Products</mat-option>
                <mat-option value="in-shop">In My Shop</mat-option>
                <mat-option value="not-in-shop">Not in My Shop</mat-option>
                <mat-option value="active">Active Only</mat-option>
                <mat-option value="low-stock">Low Stock</mat-option>
              </mat-select>
            </mat-form-field>

            <mat-form-field appearance="outline" class="filter-field">
              <mat-label>Category</mat-label>
              <mat-select [(value)]="categoryFilter" (selectionChange)="applyFilters()">
                <mat-option value="">All Categories</mat-option>
                <mat-option *ngFor="let category of categories" [value]="category.id">
                  {{ category.name }}
                </mat-option>
              </mat-select>
            </mat-form-field>
          </div>

          <!-- Bulk Actions -->
          <div class="bulk-actions" *ngIf="getSelectedCount() > 0">
            <div class="selection-info">
              <mat-checkbox 
                [checked]="allFilteredSelected" 
                [indeterminate]="someFilteredSelected && !allFilteredSelected"
                (change)="toggleAllSelection($event.checked)">
                {{ getSelectedCount() }} selected
              </mat-checkbox>
            </div>
            
            <div class="bulk-buttons">
              <button mat-raised-button 
                      color="primary" 
                      (click)="bulkAddToShop()"
                      [disabled]="!canBulkAdd()">
                <mat-icon>add_shopping_cart</mat-icon>
                Add Selected to Shop
              </button>
              
              <button mat-raised-button 
                      color="accent" 
                      (click)="bulkUpdatePrices()"
                      [disabled]="!canBulkUpdate()">
                <mat-icon>attach_money</mat-icon>
                Update Prices
              </button>
              
              <button mat-stroked-button 
                      (click)="clearSelection()">
                <mat-icon>clear</mat-icon>
                Clear Selection
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Products List -->
      <mat-card class="products-card" *ngIf="!loading">
        <mat-card-content>
          <div class="products-list">
            <div *ngFor="let item of filteredProducts" 
                      class="product-list-item"
                      [class.in-shop]="item.isInShop"
                      [class.selected]="item.isSelected">
              
              <!-- Checkbox -->
              <div class="product-checkbox">
                <mat-checkbox [(ngModel)]="item.isSelected"></mat-checkbox>
              </div>

              <!-- Product Image -->
              <div class="product-image-container">
                <img *ngIf="item.masterProduct.primaryImageUrl" 
                     [src]="getImageUrl(item.masterProduct.primaryImageUrl)" 
                     [alt]="item.masterProduct.name"
                     class="product-image"
                     (error)="onImageError($event)" />
                <div *ngIf="!item.masterProduct.primaryImageUrl" class="product-image no-image">
                  <mat-icon>image_not_supported</mat-icon>
                </div>
              </div>

              <!-- Product Content -->
              <div class="product-content">
                <div class="product-main-info">
                  <h3 class="product-title">{{ item.masterProduct.name }}</h3>
                  <div class="product-sku">{{ item.masterProduct.sku }} | {{ item.masterProduct.brand }}</div>
                  <div class="product-category">{{ item.masterProduct.category?.name }}</div>
                </div>
                
                <div class="product-price-info">
                  <span class="price" *ngIf="item.isInShop">₹{{ item.shopProduct?.price || 0 }}</span>
                  <span class="price-placeholder" *ngIf="!item.isInShop">Set Price</span>
                </div>
                
                <div class="product-status-info">
                  <span class="status-badge" [ngClass]="item.isInShop ? 'in-shop' : 'available'">
                    {{ item.isInShop ? 'In Shop' : 'Available' }}
                  </span>
                  <span class="master-status">{{ item.masterProduct.status }}</span>
                </div>
              </div>

              <!-- Product Actions -->
              <div class="product-actions">
                <ng-container *ngIf="item.isInShop">
                  <button mat-icon-button 
                          *ngIf="!item.isEditing"
                          (click)="startEdit(item)"
                          matTooltip="Edit Price & Stock"
                          color="primary">
                    <mat-icon>edit</mat-icon>
                  </button>
                  
                  <ng-container *ngIf="item.isEditing">
                    <button mat-icon-button 
                            (click)="saveChanges(item)"
                            [disabled]="!isValidEdit(item)"
                            matTooltip="Save Changes"
                            color="primary">
                      <mat-icon>save</mat-icon>
                    </button>
                    <button mat-icon-button 
                            (click)="cancelEdit(item)"
                            matTooltip="Cancel">
                      <mat-icon>cancel</mat-icon>
                    </button>
                  </ng-container>

                  <button mat-icon-button 
                          color="warn"
                          (click)="removeFromShop(item)"
                          matTooltip="Remove from Shop">
                    <mat-icon>remove_shopping_cart</mat-icon>
                  </button>
                </ng-container>

                <ng-container *ngIf="!item.isInShop">
                  <button mat-icon-button 
                          color="primary"
                          (click)="addToShop(item)"
                          [disabled]="!isValidAdd(item)"
                          matTooltip="Add to My Shop">
                    <mat-icon>add_shopping_cart</mat-icon>
                  </button>
                </ng-container>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner diameter="50"></mat-spinner>
        <p>Loading products...</p>
      </div>

      <!-- Empty State -->
      <div *ngIf="!loading && filteredProducts.length === 0" class="empty-state">
        <mat-icon class="empty-icon">inventory</mat-icon>
        <h3>No Products Found</h3>
        <p *ngIf="searchQuery || statusFilter || categoryFilter">
          Try adjusting your search or filters
        </p>
        <p *ngIf="!searchQuery && !statusFilter && !categoryFilter">
          No master products are available yet
        </p>
        <button mat-raised-button 
                color="primary" 
                (click)="clearFilters()"
                *ngIf="searchQuery || statusFilter || categoryFilter">
          <mat-icon>clear</mat-icon>
          Clear Filters
        </button>
      </div>
    </div>
  `,
  styles: [`
    .shop-owner-container {
      padding: 24px;
      max-width: 1400px;
      margin: 0 auto;
      min-height: calc(100vh - 100px);
    }

    .list-header {
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

    .header-actions {
      display: flex;
      flex-direction: column;
      gap: 16px;
      align-items: flex-end;
    }

    .nav-buttons {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .header-stats {
      display: flex;
      gap: 16px;
    }

    .stat-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 8px 16px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 8px;
      min-width: 60px;
    }

    .stat-number {
      font-size: 20px;
      font-weight: bold;
      color: white;
      line-height: 1;
    }

    .stat-label {
      font-size: 12px;
      color: rgba(255, 255, 255, 0.8);
      margin-top: 2px;
    }

    .page-title {
      display: flex;
      align-items: center;
      margin: 0 0 8px 0;
      font-size: 28px;
      font-weight: 600;
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

    .header-stats {
      display: flex;
      gap: 16px;
    }

    .stat-card {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      border-radius: 8px;
      min-width: 120px;
    }

    .stat-card .mat-mdc-card-content {
      text-align: center;
      padding: 16px;
    }

    .stat-number {
      font-size: 2rem;
      font-weight: bold;
      color: white;
      line-height: 1;
    }

    .stat-label {
      font-size: 0.875rem;
      color: rgba(255, 255, 255, 0.8);
      margin-top: 4px;
    }

    .filter-card {
      margin-bottom: 24px;
      border-radius: 12px;
    }

    .filter-section {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr;
      gap: 16px;
      margin-bottom: 20px;
    }

    .search-field {
      grid-column: span 1;
    }

    .bulk-actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: #f8f9fa;
      border-radius: 8px;
      margin-top: 16px;
    }

    .bulk-buttons {
      display: flex;
      gap: 12px;
    }

    .products-card {
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .products-list {
      display: flex;
      flex-direction: column;
      gap: 0;
      padding: 0;
    }

    .product-list-item {
      display: flex;
      align-items: center;
      padding: 16px 20px;
      border-bottom: 1px solid #e5e7eb;
      background: white;
      transition: background-color 0.2s ease;
      min-height: 90px;
    }

    .product-list-item:hover {
      background-color: #f9fafb;
    }

    .product-list-item:last-child {
      border-bottom: none;
    }

    .product-list-item.in-shop {
      background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%);
    }

    .product-list-item.selected {
      background: linear-gradient(135deg, #fef3c7 0%, #fef3c7 100%);
    }

    .product-checkbox {
      display: flex;
      align-items: center;
      flex-shrink: 0;
      margin-right: 16px;
    }

    .product-image-container {
      flex-shrink: 0;
      width: 70px;
      height: 70px;
      margin-right: 16px;
    }

    .product-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 8px;
      border: 1px solid #e5e7eb;
    }

    .product-image.no-image {
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #999;
    }

    .product-image.no-image mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .product-content {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 24px;
    }

    .product-main-info {
      flex: 1;
      min-width: 200px;
    }

    .product-title {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
      color: #1f2937;
      line-height: 1.2;
      margin-bottom: 4px;
    }

    .product-sku {
      font-size: 13px;
      color: #6b7280;
      font-family: 'Courier New', monospace;
      margin-bottom: 2px;
    }

    .product-category {
      font-size: 12px;
      color: #9ca3af;
    }

    .product-price-info {
      flex-shrink: 0;
      min-width: 100px;
    }

    .price {
      font-size: 16px;
      font-weight: bold;
      color: #059669;
    }

    .price-placeholder {
      font-size: 14px;
      color: #9ca3af;
      font-style: italic;
    }

    .product-status-info {
      flex-shrink: 0;
      min-width: 100px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .status-badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 500;
      text-align: center;
    }

    .status-badge.in-shop {
      background-color: #dcfce7;
      color: #166534;
    }

    .status-badge.available {
      background-color: #fef3c7;
      color: #d97706;
    }

    .master-status {
      font-size: 11px;
      color: #6b7280;
    }

    .product-actions {
      display: flex;
      gap: 8px;
      align-items: center;
      flex-shrink: 0;
    }

    .current-settings, .shop-settings {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 16px;
      margin-top: 12px;
    }

    .setting-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .setting-row:last-child {
      margin-bottom: 0;
    }

    .setting-label {
      font-weight: 500;
      color: #666;
    }

    .setting-value {
      font-weight: 600;
    }

    .setting-value.price {
      color: #5E35B1;
      font-size: 1.1rem;
      font-weight: 600;
    }

    .setting-value.low-stock {
      color: #f44336;
    }

    .edit-grid, .add-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }

    .product-actions {
      padding: 12px 16px;
      background: #fafafa;
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
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

    @media (max-width: 768px) {
      .shop-owner-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        align-items: stretch;
      }

      .header-stats {
        justify-content: center;
      }

      .filter-section {
        grid-template-columns: 1fr;
        gap: 12px;
      }

      .bulk-actions {
        flex-direction: column;
        gap: 12px;
        align-items: stretch;
      }

      .bulk-buttons {
        justify-content: stretch;
      }

      .bulk-buttons button {
        flex: 1;
      }

      .products-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .edit-grid, .add-grid {
        grid-template-columns: 1fr;
        gap: 12px;
      }

      .product-actions {
        flex-direction: column;
      }

      .product-actions button {
        justify-content: center;
      }
    }
  `]
})
export class ShopOwnerProductsComponent implements OnInit {
  products: ProductItem[] = [];
  filteredProducts: ProductItem[] = [];
  categories: any[] = [];
  userShop?: Shop;
  loading = true;

  // Filters
  searchQuery = '';
  statusFilter = '';
  categoryFilter = '';

  constructor(
    private fb: FormBuilder,
    private productService: ProductService,
    private shopProductService: ShopProductService,
    private shopService: ShopService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    this.loadUserShop();
    this.loadMasterProducts();
    this.loadCategories();
  }

  private loadUserShop() {
    // For now, get the first shop for the current user (shop owner)
    // In a real application, you'd associate the user with their specific shop
    this.shopService.getShops({ page: 0, size: 1 }).subscribe({
      next: (response) => {
        if (response.content && response.content.length > 0) {
          this.userShop = response.content[0];
          this.loadShopProducts();
        } else {
          Swal.fire({
            title: 'No Shop Found',
            text: 'You need to have a shop to manage products',
            icon: 'warning',
            confirmButtonText: 'OK'
          });
        }
      },
      error: (error) => {
        console.error('Error loading user shop:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Could not load shop information',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadMasterProducts() {
    this.productService.getMasterProducts({ status: ProductStatus.ACTIVE }).subscribe({
      next: (response) => {
        const masterProducts = response.content || [];
        this.products = masterProducts.map(product => ({
          masterProduct: product,
          isInShop: false,
          isEditing: false,
          isSelected: false,
          tempPrice: 0,
          tempStock: 0,
          tempAvailable: true
        }));
        this.applyFilters();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading master products:', error);
        this.loading = false;
      }
    });
  }

  private loadShopProducts() {
    if (!this.userShop) return;

    this.shopProductService.getShopProducts(this.userShop.id).subscribe({
      next: (response) => {
        const shopProducts = response.content || [];
        
        // Update products array with shop product info
        this.products.forEach(item => {
          const shopProduct = shopProducts.find(sp => sp.masterProduct?.id === item.masterProduct.id);
          if (shopProduct) {
            item.shopProduct = shopProduct;
            item.isInShop = true;
            item.tempPrice = shopProduct.price;
            item.tempStock = shopProduct.stockQuantity;
            item.tempAvailable = shopProduct.isAvailable;
          }
        });
        
        this.applyFilters();
      },
      error: (error) => {
        console.error('Error loading shop products:', error);
      }
    });
  }

  private loadCategories() {
    // Load categories for filtering
    this.productService.getMasterProducts().subscribe({
      next: (response) => {
        const products = response.content || [];
        const categorySet = new Set();
        products.forEach(product => {
          if (product.category) {
            categorySet.add(JSON.stringify(product.category));
          }
        });
        this.categories = Array.from(categorySet).map(cat => JSON.parse(cat as string));
      }
    });
  }

  onSearchChange() {
    this.applyFilters();
  }

  applyFilters() {
    let filtered = [...this.products];

    // Search filter
    if (this.searchQuery.trim()) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(item => 
        item.masterProduct.name.toLowerCase().includes(query) ||
        item.masterProduct.sku.toLowerCase().includes(query) ||
        (item.masterProduct.brand && item.masterProduct.brand.toLowerCase().includes(query))
      );
    }

    // Status filter
    if (this.statusFilter) {
      switch (this.statusFilter) {
        case 'in-shop':
          filtered = filtered.filter(item => item.isInShop);
          break;
        case 'not-in-shop':
          filtered = filtered.filter(item => !item.isInShop);
          break;
        case 'active':
          filtered = filtered.filter(item => item.masterProduct.status === ProductStatus.ACTIVE);
          break;
        case 'low-stock':
          filtered = filtered.filter(item => item.isInShop && item.shopProduct && item.shopProduct.stockQuantity < 5);
          break;
      }
    }

    // Category filter
    if (this.categoryFilter) {
      filtered = filtered.filter(item => item.masterProduct.category?.id === +this.categoryFilter);
    }

    this.filteredProducts = filtered;
  }

  clearFilters() {
    this.searchQuery = '';
    this.statusFilter = '';
    this.categoryFilter = '';
    this.applyFilters();
  }

  get allFilteredSelected(): boolean {
    return this.filteredProducts.length > 0 && this.filteredProducts.every(item => item.isSelected);
  }

  get someFilteredSelected(): boolean {
    return this.filteredProducts.some(item => item.isSelected);
  }

  toggleAllSelection(selectAll: boolean) {
    this.filteredProducts.forEach(item => {
      item.isSelected = selectAll;
      if (selectAll && !item.isInShop && !item.tempPrice) {
        item.tempPrice = 0;
      }
    });
  }

  getSelectedCount(): number {
    return this.products.filter(item => item.isSelected).length;
  }

  clearSelection() {
    this.products.forEach(item => {
      item.isSelected = false;
    });
  }

  canBulkAdd(): boolean {
    const selectedNotInShop = this.products.filter(item => item.isSelected && !item.isInShop);
    return selectedNotInShop.length > 0 && selectedNotInShop.every(item => item.tempPrice && item.tempPrice > 0);
  }

  canBulkUpdate(): boolean {
    const selectedInShop = this.products.filter(item => item.isSelected && item.isInShop);
    return selectedInShop.length > 0;
  }

  getTotalProducts(): number {
    return this.products.filter(item => item.isInShop).length;
  }

  getActiveProducts(): number {
    return this.products.filter(item => 
      item.isInShop && 
      item.shopProduct && 
      item.shopProduct.status === ShopProductStatus.ACTIVE
    ).length;
  }

  goBack(): void {
    window.history.back();
  }

  startEdit(item: ProductItem) {
    item.isEditing = true;
    if (item.shopProduct) {
      item.tempPrice = item.shopProduct.price;
      item.tempStock = item.shopProduct.stockQuantity;
      item.tempAvailable = item.shopProduct.isAvailable;
    }
  }

  cancelEdit(item: ProductItem) {
    item.isEditing = false;
  }

  isValidEdit(item: ProductItem): boolean {
    return !!(item.tempPrice && item.tempPrice > 0);
  }

  isValidAdd(item: ProductItem): boolean {
    return !!(item.tempPrice && item.tempPrice > 0);
  }

  saveChanges(item: ProductItem) {
    if (!this.userShop || !item.shopProduct || !this.isValidEdit(item)) return;

    const request: ShopProductRequest = {
      masterProductId: item.masterProduct.id,
      price: item.tempPrice!,
      stockQuantity: item.tempStock || 0,
      isAvailable: item.tempAvailable !== false,
      status: item.shopProduct.status,
      trackInventory: item.shopProduct.trackInventory,
      isFeatured: item.shopProduct.isFeatured
    };

    this.shopProductService.updateShopProduct(this.userShop.id, item.shopProduct.id, request).subscribe({
      next: (updatedProduct) => {
        item.shopProduct = updatedProduct;
        item.isEditing = false;
        Swal.fire({
          title: 'Updated!',
          text: 'Product updated successfully',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      },
      error: (error) => {
        console.error('Error updating product:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to update product',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  addToShop(item: ProductItem) {
    if (!this.userShop || !this.isValidAdd(item)) return;

    const request: ShopProductRequest = {
      masterProductId: item.masterProduct.id,
      price: item.tempPrice!,
      stockQuantity: item.tempStock || 0,
      isAvailable: item.tempAvailable !== false,
      status: ShopProductStatus.ACTIVE,
      trackInventory: true,
      isFeatured: false
    };

    this.shopProductService.addProductToShop(this.userShop.id, request).subscribe({
      next: (shopProduct) => {
        item.shopProduct = shopProduct;
        item.isInShop = true;
        item.isSelected = false;
        Swal.fire({
          title: 'Added!',
          text: 'Product added to your shop successfully',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      },
      error: (error) => {
        console.error('Error adding product:', error);
        Swal.fire({
          title: 'Error!',
          text: error.error?.message || 'Failed to add product to shop',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  removeFromShop(item: ProductItem) {
    if (!this.userShop || !item.shopProduct) return;

    Swal.fire({
      title: 'Remove Product?',
      text: `Are you sure you want to remove "${item.masterProduct.name}" from your shop?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, remove it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && this.userShop && item.shopProduct) {
        this.shopProductService.removeProductFromShop(this.userShop.id, item.shopProduct.id).subscribe({
          next: () => {
            item.shopProduct = undefined;
            item.isInShop = false;
            item.isSelected = false;
            item.tempPrice = 0;
            item.tempStock = 0;
            Swal.fire({
              title: 'Removed!',
              text: 'Product removed from your shop',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          },
          error: (error) => {
            console.error('Error removing product:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Failed to remove product from shop',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  bulkAddToShop() {
    if (!this.userShop || !this.canBulkAdd()) return;

    const selectedItems = this.products.filter(item => item.isSelected && !item.isInShop);
    const requests = selectedItems.map(item => ({
      masterProductId: item.masterProduct.id,
      price: item.tempPrice!,
      stockQuantity: item.tempStock || 0,
      isAvailable: item.tempAvailable !== false,
      status: ShopProductStatus.ACTIVE,
      trackInventory: true,
      isFeatured: false
    }));

    const addPromises = requests.map(request => 
      this.shopProductService.addProductToShop(this.userShop!.id, request).toPromise()
    );

    Promise.allSettled(addPromises).then(results => {
      const successful = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      if (failed === 0) {
        Swal.fire({
          title: 'Success!',
          text: `Successfully added ${successful} products to your shop!`,
          icon: 'success',
          confirmButtonText: 'OK'
        });
        this.loadShopProducts(); // Refresh
        this.clearSelection();
      } else {
        Swal.fire({
          title: 'Partial Success',
          text: `Added ${successful} products successfully, ${failed} failed.`,
          icon: 'warning',
          confirmButtonText: 'OK'
        });
        this.loadShopProducts(); // Refresh
        this.clearSelection();
      }
    });
  }

  bulkUpdatePrices() {
    Swal.fire({
      title: 'Bulk Update Prices',
      input: 'number',
      inputLabel: 'New price for all selected products',
      inputPlaceholder: '0.00',
      inputAttributes: {
        min: '0.01',
        step: '0.01'
      },
      showCancelButton: true,
      confirmButtonText: 'Update Prices',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value || parseFloat(value) <= 0) {
          return 'Please enter a valid price greater than 0';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        const newPrice = parseFloat(result.value);
        const selectedInShop = this.products.filter(item => item.isSelected && item.isInShop);
        
        selectedInShop.forEach(item => {
          item.tempPrice = newPrice;
        });

        Swal.fire({
          title: 'Prices Updated!',
          text: `Set price of ₹${newPrice.toFixed(0)} for ${selectedInShop.length} products. Click "Save Changes" on each product to apply.`,
          icon: 'info',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  getShopProductStatusColor(status: string): 'primary' | 'accent' | 'warn' {
    switch (status) {
      case 'ACTIVE':
        return 'primary';
      case 'INACTIVE':
        return 'accent';
      case 'OUT_OF_STOCK':
      case 'DISCONTINUED':
        return 'warn';
      default:
        return 'accent';
    }
  }

  getImageUrl(imageUrl: string): string {
    return getImageUrlUtil(imageUrl);
  }

  onImageError(event: any): void {
    // Replace with a default placeholder image
    event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjVGNUY1Ii8+CjxwYXRoIGQ9Ik02MCA2MEgxNDBWMTQwSDYwVjYwWiIgZmlsbD0iI0UwRTBFMCIvPgo8Y2lyY2xlIGN4PSI4NSIgY3k9Ijg1IiByPSIxMCIgZmlsbD0iI0QwRDBEMCIvPgo8cGF0aCBkPSJNNjAgMTIwTDkwIDkwTDExMCAxMTBMMTQwIDgwVjE0MEg2MFYxMjBaIiBmaWxsPSIjRDBEMEQwIi8+Cjx0ZXh0IHg9IjEwMCIgeT0iMTcwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5IiBmb250LXNpemU9IjEyIiBmb250LWZhbWlseT0iQXJpYWwiPk5vIEltYWdlPC90ZXh0Pgo8L3N2Zz4K';
  }
}