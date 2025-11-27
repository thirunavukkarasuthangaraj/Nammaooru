import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { ShopProductService } from '../../../../core/services/shop-product.service';
import { ShopService } from '../../../../core/services/shop.service';
import { MasterProduct, ShopProductRequest, ShopProductStatus, ProductStatus } from '../../../../core/models/product.model';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

interface ProductSelection {
  product: MasterProduct;
  selected: boolean;
  price?: number;
  stockQuantity?: number;
  isAvailable?: boolean;
  alreadyInShop: boolean;
  shopProductId?: number;
}

@Component({
  selector: 'app-bulk-product-assignment',
  template: `
    <div class="bulk-assignment-container">
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
            <span class="breadcrumb-item active">Bulk Assignment</span>
          </div>
          <h1 class="page-title">
            Bulk Product Assignment
          </h1>
          <p class="page-description">
            Efficiently assign multiple products to your shops with custom pricing
          </p>
        </div>
        <div class="header-illustration">
          <mat-icon class="illustration-icon">category</mat-icon>
        </div>
      </div>

      <!-- Shop Selection Card -->
      <div class="shop-selection-section" *ngIf="!shopId">
        <mat-card class="modern-card shop-selector-card">
          <div class="card-header">
            <div class="card-icon-wrapper">
              <mat-icon class="card-icon">store</mat-icon>
            </div>
            <div class="card-title-section">
              <h2 class="card-title">Select Target Shop</h2>
              <p class="card-subtitle">Choose the shop where you want to add products</p>
            </div>
          </div>
          
          <mat-card-content>
            <mat-form-field appearance="outline" class="modern-field">
              <mat-label>Select Shop</mat-label>
              <mat-select [(value)]="selectedShopId" (selectionChange)="onShopChange($event.value)">
                <mat-option *ngFor="let shop of shops" [value]="shop.id">
                  <div class="shop-option">
                    <span class="shop-name">{{ shop.name }}</span>
                    <span class="shop-type">{{ shop.businessType }}</span>
                  </div>
                </mat-option>
              </mat-select>
              <mat-icon matPrefix>business</mat-icon>
            </mat-form-field>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Products Selection Section -->
      <div class="products-section" *ngIf="selectedShopId">
        <!-- Statistics Cards -->
        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-icon">
              <mat-icon>inventory_2</mat-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ productSelections.length }}</div>
              <div class="stat-label">Total Products</div>
            </div>
          </div>
          
          <div class="stat-card selected">
            <div class="stat-icon">
              <mat-icon>check_circle</mat-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ getSelectedCount() }}</div>
              <div class="stat-label">Selected</div>
            </div>
          </div>
          
          <div class="stat-card already-added">
            <div class="stat-icon">
              <mat-icon>store_mall_directory</mat-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ getAlreadyInShopCount() }}</div>
              <div class="stat-label">Already in Shop</div>
            </div>
          </div>
          
          <div class="stat-card" *ngIf="selectedShop">
            <div class="stat-icon">
              <mat-icon>store</mat-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ selectedShop.name }}</div>
              <div class="stat-label">Target Shop</div>
            </div>
          </div>
        </div>

        <!-- Action Toolbar -->
        <mat-card class="modern-card toolbar-card">
          <div class="toolbar-content">
            <div class="toolbar-left">
              <mat-checkbox 
                [checked]="allSelected" 
                [indeterminate]="someSelected && !allSelected"
                (change)="toggleAllSelection($event.checked)"
                class="select-all-checkbox">
                <span class="checkbox-label">
                  Select All Products
                  <span class="selection-count">({{ getSelectedCount() }} of {{ productSelections.length }})</span>
                </span>
              </mat-checkbox>
            </div>
            
            <div class="toolbar-actions">
              <button mat-stroked-button 
                      class="toolbar-button"
                      [disabled]="getSelectedCount() === 0"
                      (click)="showBulkPriceDialog()">
                <mat-icon>payments</mat-icon>
                Set Bulk Price
              </button>
              
              <button mat-raised-button 
                      color="primary"
                      class="toolbar-button primary-action"
                      [disabled]="getSelectedCount() === 0 || isLoading"
                      (click)="assignSelectedProducts()">
                <mat-spinner diameter="18" *ngIf="isLoading"></mat-spinner>
                <mat-icon *ngIf="!isLoading">add_shopping_cart</mat-icon>
                {{ isLoading ? 'Adding...' : 'Add to Shop' }}
              </button>
            </div>
          </div>
        </mat-card>

        <!-- Search and Filter Bar -->
        <div class="filter-bar">
          <mat-form-field appearance="outline" class="search-field">
            <mat-label>Search Products</mat-label>
            <input matInput [(ngModel)]="searchQuery" (input)="filterProducts()" placeholder="Search by name, SKU, or brand...">
            <mat-icon matPrefix>search</mat-icon>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="filter-field">
            <mat-label>Category</mat-label>
            <mat-select [(value)]="categoryFilter" (selectionChange)="filterProducts()">
              <mat-option value="">All Categories</mat-option>
              <mat-option *ngFor="let cat of categories" [value]="cat.id">{{ cat.name }}</mat-option>
            </mat-select>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="filter-field">
            <mat-label>Status</mat-label>
            <mat-select [(value)]="statusFilter" (selectionChange)="filterProducts()">
              <mat-option value="">All Status</mat-option>
              <mat-option value="ACTIVE">Active</mat-option>
              <mat-option value="INACTIVE">Inactive</mat-option>
            </mat-select>
          </mat-form-field>
        </div>

        <!-- Products List -->
        <div class="products-list-container" *ngIf="!loading">
          <div class="products-list">
            <div *ngFor="let item of filteredSelections" 
                 class="product-list-item"
                 [class.selected]="item.selected"
                 [class.already-in-shop]="item.alreadyInShop">
              
              <!-- Checkbox -->
              <div class="product-checkbox">
                <mat-checkbox 
                  [(ngModel)]="item.selected"
                  [disabled]="item.alreadyInShop"
                  (change)="updateSelectionState()">
                </mat-checkbox>
              </div>

              <!-- Product Image -->
              <div class="product-image">
                <img *ngIf="item.product.primaryImageUrl" 
                     [src]="getImageUrl(item.product.primaryImageUrl)" 
                     [alt]="item.product.name"
                     (error)="onImageError($event)" />
                <div *ngIf="!item.product.primaryImageUrl" class="no-image">
                  <mat-icon>image_not_supported</mat-icon>
                </div>
              </div>

              <!-- Product Details -->
              <div class="product-details">
                <div class="product-main">
                  <h3 class="product-name">{{ item.product.name }}</h3>
                  <div class="product-meta">
                    <span class="product-sku">{{ item.product.sku }}</span>
                    <span class="product-brand" *ngIf="item.product.brand">{{ item.product.brand }}</span>
                  </div>
                  <div class="product-description" *ngIf="item.product.description">
                    {{ item.product.description }}
                  </div>
                </div>
              </div>

              <!-- Category & Status -->
              <div class="product-badges">
                <span class="badge category" *ngIf="item.product.category">{{ item.product.category.name }}</span>
                <span class="badge status" [class.active]="item.product.status === 'ACTIVE'" [class.inactive]="item.product.status !== 'ACTIVE'">
                  {{ item.product.status }}
                </span>
                <span class="badge already-added" *ngIf="item.alreadyInShop">
                  <mat-icon>check_circle</mat-icon>
                  Already Added
                </span>
              </div>

              <!-- Pricing Section (shown when selected) -->
              <div class="product-pricing" *ngIf="item.selected && !item.alreadyInShop">
                <div class="pricing-inputs">
                  <mat-form-field appearance="outline" class="price-input">
                    <mat-label>Price</mat-label>
                    <input matInput 
                           type="number" 
                           step="1" 
                           min="1"
                           [(ngModel)]="item.price" 
                           placeholder="0">
                    <span matTextPrefix>₹</span>
                  </mat-form-field>

                  <mat-form-field appearance="outline" class="stock-input">
                    <mat-label>Stock</mat-label>
                    <input matInput 
                           type="number" 
                           min="0"
                           [(ngModel)]="item.stockQuantity" 
                           placeholder="0">
                  </mat-form-field>

                  <mat-slide-toggle [(ngModel)]="item.isAvailable" class="availability-toggle">
                    Available
                  </mat-slide-toggle>
                </div>
              </div>

              <!-- Already in shop message -->
              <div class="product-pricing-placeholder already-in-shop-msg" *ngIf="item.alreadyInShop">
                <div class="already-added-indicator">
                  <mat-icon>check_circle</mat-icon>
                  <span>Already added to this shop</span>
                  <button mat-stroked-button size="small" [routerLink]="['/products/shop', selectedShopId, item.shopProductId]" class="edit-existing-btn">
                    <mat-icon>edit</mat-icon>
                    Edit
                  </button>
                </div>
              </div>

              <!-- Empty pricing space when not selected -->
              <div class="product-pricing-placeholder" *ngIf="!item.selected && !item.alreadyInShop">
                <span class="select-hint">Select to set pricing</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Loading State -->
        <div *ngIf="loading" class="loading-state">
          <mat-spinner diameter="60"></mat-spinner>
          <h3>Loading Products</h3>
          <p>Please wait while we fetch the master products...</p>
        </div>

        <!-- Empty State -->
        <div *ngIf="!loading && filteredSelections.length === 0" class="empty-state">
          <div class="empty-icon">
            <mat-icon>inventory_2</mat-icon>
          </div>
          <h3>No Products Found</h3>
          <p *ngIf="searchQuery || categoryFilter || statusFilter">
            Try adjusting your filters or search criteria
          </p>
          <p *ngIf="!searchQuery && !categoryFilter && !statusFilter">
            No master products available. Create some products first.
          </p>
          <button mat-raised-button color="primary" routerLink="/products/master/new">
            <mat-icon>add</mat-icon>
            Create Master Product
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .bulk-assignment-container {
      padding: 0;
      background: #f5f5f7;
      min-height: 100vh;
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
      font-size: 32px;
      font-weight: 700;
      margin: 0 0 8px 0;
      letter-spacing: -0.5px;
    }

    .page-description {
      font-size: 16px;
      opacity: 0.95;
      margin: 0;
    }

    .header-illustration {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 120px;
      height: 120px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 20px;
      backdrop-filter: blur(10px);
    }

    .illustration-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: rgba(255, 255, 255, 0.9);
    }

    /* Shop Selection */
    .shop-selection-section {
      padding: 32px;
    }

    .modern-card {
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      border: none;
      overflow: hidden;
    }

    .shop-selector-card {
      max-width: 600px;
      margin: 0 auto;
    }

    .card-header {
      display: flex;
      align-items: center;
      padding: 24px;
      background: linear-gradient(135deg, #f5f5f7 0%, #fff 100%);
      border-bottom: 1px solid #e0e0e0;
    }

    .card-icon-wrapper {
      width: 56px;
      height: 56px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 16px;
    }

    .card-icon {
      color: white;
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    .card-title {
      font-size: 20px;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1a1a1a;
    }

    .card-subtitle {
      font-size: 14px;
      color: #666;
      margin: 0;
    }

    .modern-field {
      width: 100%;
    }

    .modern-field .mat-mdc-form-field-flex {
      background: #f8f8fa;
      border-radius: 12px;
    }

    .shop-option {
      display: flex;
      justify-content: space-between;
      align-items: center;
      width: 100%;
    }

    .shop-name {
      font-weight: 500;
    }

    .shop-type {
      font-size: 12px;
      color: #888;
      background: #f0f0f0;
      padding: 4px 8px;
      border-radius: 6px;
    }

    /* Products Section */
    .products-section {
      padding: 32px;
    }

    /* Statistics Row */
    .stats-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 24px;
      margin-bottom: 32px;
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
    }

    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .stat-card.selected {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }

    .stat-card.already-added {
      background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);
      color: white;
    }

    .stat-icon {
      width: 56px;
      height: 56px;
      background: rgba(102, 126, 234, 0.1);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .stat-card.selected .stat-icon {
      background: rgba(255, 255, 255, 0.2);
    }

    .stat-icon mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
      color: #667eea;
    }

    .stat-card.selected .stat-icon mat-icon {
      color: white;
    }

    .stat-value {
      font-size: 28px;
      font-weight: 700;
      line-height: 1;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 14px;
      color: #888;
    }

    .stat-card.selected .stat-label {
      color: rgba(255, 255, 255, 0.9);
    }

    /* Toolbar Card */
    .toolbar-card {
      margin-bottom: 24px;
      padding: 16px 24px;
    }

    .toolbar-content {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .select-all-checkbox {
      font-size: 15px;
    }

    .checkbox-label {
      margin-left: 8px;
    }

    .selection-count {
      color: #888;
      font-size: 14px;
      margin-left: 8px;
    }

    .toolbar-actions {
      display: flex;
      gap: 12px;
    }

    .toolbar-button {
      border-radius: 8px;
      padding: 8px 20px;
      font-weight: 500;
    }

    .toolbar-button mat-icon {
      margin-right: 8px;
    }

    .primary-action {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }

    /* Filter Bar */
    .filter-bar {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr;
      gap: 16px;
      margin-bottom: 32px;
    }

    .search-field {
      grid-column: span 1;
    }

    /* Products List */
    .products-list-container {
      background: white;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      overflow: hidden;
    }

    .products-list {
      display: flex;
      flex-direction: column;
    }

    .product-list-item {
      display: grid;
      grid-template-columns: 40px 80px 1fr 200px 300px;
      align-items: center;
      gap: 16px;
      padding: 16px 20px;
      border-bottom: 1px solid #f0f0f2;
      transition: all 0.2s ease;
      min-height: 80px;
    }

    .product-list-item:last-child {
      border-bottom: none;
    }

    .product-list-item:hover {
      background: #f8f9fa;
    }

    .product-list-item.selected {
      background: linear-gradient(135deg, #f8f9ff 0%, #fff 100%);
      border-left: 4px solid #667eea;
    }

    .product-list-item.already-in-shop {
      background: linear-gradient(135deg, #fff8e1 0%, #fff 100%);
      border-left: 4px solid #ff9800;
      opacity: 0.8;
    }

    .product-list-item.already-in-shop .product-checkbox {
      opacity: 0.5;
    }

    .product-checkbox {
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .product-image {
      width: 70px;
      height: 70px;
      border-radius: 8px;
      overflow: hidden;
      background: #f5f5f7;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .product-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .product-image .no-image {
      color: #bbb;
      display: flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      height: 100%;
    }

    .product-image .no-image mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .product-details {
      min-width: 0;
      flex: 1;
    }

    .product-main {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .product-name {
      font-size: 16px;
      font-weight: 600;
      margin: 0;
      color: #1a1a1a;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .product-meta {
      display: flex;
      gap: 12px;
      align-items: center;
    }

    .product-sku {
      font-size: 12px;
      color: #666;
      font-family: 'Courier New', monospace;
      background: #f0f0f2;
      padding: 2px 6px;
      border-radius: 4px;
    }

    .product-brand {
      font-size: 12px;
      color: #888;
    }

    .product-description {
      font-size: 13px;
      color: #666;
      line-height: 1.4;
      margin-top: 4px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .product-badges {
      display: flex;
      flex-direction: column;
      gap: 6px;
      align-items: flex-start;
    }

    .badge {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 10px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      white-space: nowrap;
    }

    .badge.category {
      background: #e3f2fd;
      color: #1976d2;
    }

    .badge.status.active {
      background: #e8f5e9;
      color: #4caf50;
    }

    .badge.status.inactive {
      background: #ffebee;
      color: #f44336;
    }

    .badge.already-added {
      background: #fff3e0;
      color: #ff9800;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .badge.already-added mat-icon {
      font-size: 12px;
      width: 12px;
      height: 12px;
    }

    .product-pricing {
      display: flex;
      align-items: center;
    }

    .pricing-inputs {
      display: flex;
      gap: 12px;
      align-items: center;
    }

    .price-input, .stock-input {
      width: 100px;
    }

    .price-input {
      width: 120px;
    }

    .availability-toggle {
      margin-left: 12px;
    }

    .product-pricing-placeholder {
      display: flex;
      align-items: center;
      justify-content: center;
      color: #999;
      font-style: italic;
      font-size: 13px;
    }

    .already-in-shop-msg {
      background: #fff3e0;
      border-radius: 8px;
      padding: 12px;
      color: #f57c00;
      font-style: normal;
    }

    .already-added-indicator {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 500;
    }

    .already-added-indicator mat-icon {
      color: #ff9800;
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .edit-existing-btn {
      margin-left: auto;
      font-size: 12px;
      padding: 4px 12px;
      color: #ff9800;
      border-color: #ff9800;
    }

    .edit-existing-btn:hover {
      background: rgba(255, 152, 0, 0.1);
    }

    /* Loading State */
    .loading-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
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
      background: white;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
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

    /* Responsive Design */
    @media (max-width: 1024px) {
      .product-list-item {
        grid-template-columns: 40px 60px 1fr 150px 250px;
        gap: 12px;
      }
      
      .product-image {
        width: 60px;
        height: 60px;
      }
      
      .pricing-inputs {
        gap: 8px;
      }
      
      .price-input, .stock-input {
        width: 80px;
      }
      
      .stats-row {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 768px) {
      .page-header {
        flex-direction: column;
        text-align: center;
        padding: 32px 20px;
      }
      
      .header-illustration {
        margin-top: 24px;
      }
      
      .filter-bar {
        grid-template-columns: 1fr;
      }
      
      .toolbar-content {
        flex-direction: column;
        gap: 16px;
        align-items: stretch;
      }
      
      .toolbar-actions {
        justify-content: stretch;
      }
      
      .toolbar-button {
        flex: 1;
      }
      
      .product-list-item {
        grid-template-columns: 30px 50px 1fr;
        gap: 8px;
        padding: 12px 16px;
        min-height: 70px;
      }
      
      .product-image {
        width: 50px;
        height: 50px;
      }
      
      .product-badges,
      .product-pricing,
      .product-pricing-placeholder {
        display: none;
      }
      
      .product-name {
        font-size: 14px;
      }
      
      .product-description {
        -webkit-line-clamp: 1;
      }
      
      .products-section {
        padding: 20px 16px;
      }
    }

    @media (max-width: 480px) {
      .product-list-item {
        grid-template-columns: 24px 40px 1fr;
        gap: 6px;
        padding: 10px 12px;
        min-height: 60px;
      }
      
      .product-image {
        width: 40px;
        height: 40px;
      }
      
      .product-name {
        font-size: 13px;
      }
      
      .product-meta {
        flex-direction: column;
        gap: 2px;
        align-items: flex-start;
      }
      
      .product-sku, .product-brand {
        font-size: 11px;
      }
    }
  `]
})
export class BulkProductAssignmentComponent implements OnInit {
  productSelections: ProductSelection[] = [];
  filteredSelections: ProductSelection[] = [];
  shops: Shop[] = [];
  selectedShopId?: number;
  selectedShop?: Shop;
  shopId?: number;
  loading = false;
  isLoading = false;
  
  // Filters
  searchQuery = '';
  categoryFilter = '';
  statusFilter = '';
  categories: any[] = [];

  constructor(
    private fb: FormBuilder,
    private productService: ProductService,
    private shopProductService: ShopProductService,
    private shopService: ShopService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit() {
    this.route.params.subscribe(params => {
      if (params['shopId']) {
        const numericId = parseInt(params['shopId'], 10);
        if (!isNaN(numericId)) {
          this.shopId = numericId;
          this.selectedShopId = this.shopId;
          this.loadShopDetails();
          this.loadMasterProducts();
        } else {
          console.error('Invalid shop ID:', params['shopId']);
          this.router.navigate(['/products/bulk-assignment']);
        }
      } else {
        this.loadShops();
      }
    });
  }

  loadShops() {
    this.shopService.getShops({ page: 0, size: 100 }).subscribe({
      next: (response) => {
        this.shops = response.content || [];
      },
      error: (error) => {
        console.error('Error loading shops:', error);
      }
    });
  }

  loadShopDetails() {
    if (this.selectedShopId) {
      this.shopService.getShop(this.selectedShopId).subscribe({
        next: (shop: Shop) => {
          this.selectedShop = shop;
        },
        error: (error: any) => {
          console.error('Error loading shop details:', error);
        }
      });
    }
  }

  loadMasterProducts() {
    this.loading = true;
    
    // Load master products and existing shop products in parallel
    Promise.all([
      this.productService.getMasterProducts({ status: ProductStatus.ACTIVE }).toPromise(),
      this.shopProductService.getShopProducts(this.selectedShopId!).toPromise()
    ]).then(([masterResponse, shopResponse]) => {
      const masterProducts = masterResponse?.content || [];
      const shopProducts = shopResponse?.content || [];
      
      // Create a set of master product IDs that are already in the shop
      const existingProductIds = new Set(
        shopProducts.map((sp: any) => sp.masterProduct?.id).filter(Boolean)
      );
      
      // Create product selections with already-in-shop status
      this.productSelections = masterProducts.map(product => {
        const alreadyInShop = existingProductIds.has(product.id);
        const shopProduct = shopProducts.find((sp: any) => sp.masterProduct?.id === product.id);
        
        return {
          product,
          selected: false,
          price: 0,
          stockQuantity: 0,
          isAvailable: true,
          alreadyInShop: alreadyInShop || false,
          shopProductId: shopProduct?.id
        };
      });
      
      // Extract categories
      const categorySet = new Set();
      masterProducts.forEach(product => {
        if (product.category) {
          categorySet.add(JSON.stringify(product.category));
        }
      });
      this.categories = Array.from(categorySet).map(cat => JSON.parse(cat as string));
      
      this.filterProducts();
      this.loading = false;
    }).catch(error => {
      console.error('Error loading products:', error);
      this.loading = false;
    });
  }

  onShopChange(shopId: number) {
    this.selectedShopId = shopId;
    this.loadShopDetails();
    this.loadMasterProducts();
  }

  filterProducts() {
    let filtered = [...this.productSelections];
    
    if (this.searchQuery.trim()) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(item => 
        item.product.name.toLowerCase().includes(query) ||
        item.product.sku.toLowerCase().includes(query) ||
        (item.product.brand && item.product.brand.toLowerCase().includes(query))
      );
    }
    
    if (this.categoryFilter) {
      filtered = filtered.filter(item => item.product.category?.id === +this.categoryFilter);
    }
    
    if (this.statusFilter) {
      filtered = filtered.filter(item => item.product.status === this.statusFilter);
    }
    
    this.filteredSelections = filtered;
  }

  get allSelected(): boolean {
    const selectableItems = this.filteredSelections.filter(item => !item.alreadyInShop);
    return selectableItems.length > 0 && selectableItems.every(item => item.selected);
  }

  get someSelected(): boolean {
    return this.filteredSelections.some(item => item.selected && !item.alreadyInShop);
  }

  toggleAllSelection(selectAll: boolean) {
    this.filteredSelections.forEach(item => {
      if (!item.alreadyInShop) { // Only select products not already in shop
        item.selected = selectAll;
        if (selectAll && !item.price) {
          item.price = 0;
        }
      }
    });
  }

  updateSelectionState() {
    // This method is called when individual checkboxes change
  }

  getSelectedCount(): number {
    return this.productSelections.filter(item => item.selected).length;
  }

  getAlreadyInShopCount(): number {
    return this.productSelections.filter(item => item.alreadyInShop).length;
  }

  clearSelection() {
    this.productSelections.forEach(item => {
      item.selected = false;
      item.price = 0;
      item.stockQuantity = 0;
      item.isAvailable = true;
      // Don't reset alreadyInShop as it's a persistent property
    });
  }

  canAssignProducts(): boolean {
    const selectedItems = this.productSelections.filter(item => item.selected && !item.alreadyInShop);
    return selectedItems.length > 0 && selectedItems.every(item => item.price && item.price > 0);
  }

  showBulkPriceDialog() {
    Swal.fire({
      title: 'Set Bulk Price',
      input: 'number',
      inputLabel: 'Enter price for all selected products',
      inputPlaceholder: 'Enter price in ₹',
      inputAttributes: {
        min: '1',
        step: '1'
      },
      showCancelButton: true,
      confirmButtonText: 'Apply Price',
      confirmButtonColor: '#667eea',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value || parseFloat(value) <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        const price = parseFloat(result.value);
        this.productSelections.forEach(item => {
          if (item.selected) {
            item.price = price;
          }
        });
        Swal.fire({
          title: 'Price Applied!',
          text: `Price of ₹${price} set for all selected products`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      }
    });
  }

  assignSelectedProducts() {
    if (!this.selectedShopId || !this.canAssignProducts()) return;

    this.isLoading = true;
    const selectedItems = this.productSelections.filter(item => item.selected && !item.alreadyInShop);
    
    const requests: ShopProductRequest[] = selectedItems.map(item => ({
      masterProductId: item.product.id,
      price: item.price!,
      stockQuantity: item.stockQuantity || 0,
      isAvailable: item.isAvailable !== false,
      status: ShopProductStatus.ACTIVE,
      trackInventory: true,
      isFeatured: false
    }));

    // Add products one by one
    const addPromises = requests.map(request => 
      this.shopProductService.addProductToShop(this.selectedShopId!, request).toPromise()
    );

    Promise.allSettled(addPromises).then(results => {
      this.isLoading = false;
      const successful = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      if (failed === 0) {
        Swal.fire({
          title: 'Success!',
          text: `Successfully added ${successful} products to the shop`,
          icon: 'success',
          confirmButtonText: 'OK',
          confirmButtonColor: '#667eea'
        }).then(() => {
          this.router.navigate(['/products/shop', this.selectedShopId]);
        });
      } else {
        Swal.fire({
          title: 'Partial Success',
          text: `Added ${successful} products, ${failed} failed`,
          icon: 'warning',
          confirmButtonText: 'OK'
        });
      }
      
      this.clearSelection();
    });
  }

  getImageUrl(imageUrl: string): string {
    return getImageUrlUtil(imageUrl);
  }

  onImageError(event: any): void {
    event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjVGNUY1Ii8+CjxwYXRoIGQ9Ik02MCA2MEgxNDBWMTQwSDYwVjYwWiIgZmlsbD0iI0UwRTBFMCIvPgo8Y2lyY2xlIGN4PSI4NSIgY3k9Ijg1IiByPSIxMCIgZmlsbD0iI0QwRDBEMCIvPgo8cGF0aCBkPSJNNjAgMTIwTDkwIDkwTDExMCAxMTBMMTQwIDgwVjE0MEg2MFYxMjBaIiBmaWxsPSIjRDBEMEQwIi8+Cjx0ZXh0IHg9IjEwMCIgeT0iMTcwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5IiBmb250LXNpemU9IjEyIiBmb250LWZhbWlseT0iQXJpYWwiPk5vIEltYWdlPC90ZXh0Pgo8L3N2Zz4K';
  }
}