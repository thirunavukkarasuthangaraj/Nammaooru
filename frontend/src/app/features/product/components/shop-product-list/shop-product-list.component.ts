import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router, NavigationEnd } from '@angular/router';
import { filter, Subscription } from 'rxjs';
import { ShopProductService } from '../../../../core/services/shop-product.service';
import { ShopService } from '../../../../core/services/shop.service';
import { AuthService } from '../../../../core/services/auth.service';
import { ShopProduct } from '../../../../core/models/product.model';
import { Shop } from '../../../../core/models/shop.model';
import { User, UserRole } from '../../../../core/models/auth.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-product-list',
  template: `
    <div class="list-container">
      <!-- Back Button Section -->
      <div class="back-section">
        <button mat-stroked-button (click)="goBack()" class="back-button">
          <mat-icon>arrow_back</mat-icon>
          Back to All Shops
        </button>
      </div>

      <!-- Shop Details Section -->
      <div class="shop-header">
        <div class="shop-info-section">
          <div class="shop-avatar" *ngIf="shop">
            <img *ngIf="getShopLogo()" [src]="getShopLogo()" [alt]="shop.name" class="shop-logo" />
            <div *ngIf="!getShopLogo()" class="shop-logo-placeholder">
              <mat-icon>store</mat-icon>
            </div>
          </div>
          <div class="shop-details">
            <h1 class="shop-name">{{ shop?.name || 'Shop Products' }}</h1>
            <div class="shop-subtitle" *ngIf="shop">
              {{ getBusinessTypeDisplay(shop.businessType) }}
            </div>
            <div class="shop-meta" *ngIf="shop">
              <div class="shop-business">{{ shop.businessName || shop.ownerName }}</div>
            </div>
          </div>
        </div>
        
        <!-- Shop Photos Gallery -->
        <div class="shop-photos-section" *ngIf="getShopPhotos().length > 0">
          <h3 class="photos-title">
            <mat-icon class="photos-icon">photo_camera</mat-icon>
            Shop Photos
          </h3>
          <div class="photos-grid">
            <img *ngFor="let photo of getShopPhotos().slice(0, 4); let i = index" 
                 [src]="photo" 
                 [alt]="(shop?.name || 'Shop') + ' photo ' + (i+1)"
                 class="gallery-photo"
                 (click)="viewShopPhoto(photo)">
            <div *ngIf="getShopPhotos().length > 4" class="more-photos" (click)="viewAllPhotos()">
              <mat-icon>add</mat-icon>
              <span>{{ getShopPhotos().length - 4 }} more</span>
            </div>
          </div>
        </div>

        <div class="shop-stats" *ngIf="!loading">
          <div class="stat-card">
            <div class="stat-number">{{ products.length }}</div>
            <div class="stat-label">Total Products</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ getActiveProductsCount() }}</div>
            <div class="stat-label">Active</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ getLowStockCount() }}</div>
            <div class="stat-label">Low Stock</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ getTotalValue() | currency:'INR':'symbol':'1.0-0' }}</div>
            <div class="stat-label">Total Value</div>
          </div>
        </div>
      </div>

      <!-- Address Section -->
      <div class="address-section" *ngIf="shop">
        <mat-card class="address-card">
          <mat-card-content>
            <div class="address-header">
              <mat-icon class="address-icon">location_on</mat-icon>
              <h3>Shop Address</h3>
            </div>
            <div class="address-details">
              <p class="address-line">{{ shop.addressLine1 }}</p>
              <p class="address-city">{{ shop.city }}, {{ shop.state }} {{ shop.postalCode }}</p>
              <div class="contact-info" *ngIf="shop.ownerPhone || shop.ownerEmail">
                <span *ngIf="shop.ownerPhone" class="contact-item">
                  <mat-icon>phone</mat-icon>
                  {{ shop.ownerPhone }}
                </span>
                <span *ngIf="shop.ownerEmail" class="contact-item">
                  <mat-icon>email</mat-icon>
                  {{ shop.ownerEmail }}
                </span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Create Product Section -->
      <div class="create-product-section">
        <mat-card class="create-product-card">
          <mat-card-content>
            <div class="create-product-content">
              <div class="create-product-info">
                <h3>Add Products to Your Shop</h3>
                <p>Start building your product catalog by adding items to your shop</p>
              </div>
              <div class="create-product-actions">
                <button mat-raised-button color="primary" [routerLink]="['/products/shop', shopId, 'new']" class="create-single-btn">
                  <mat-icon>add</mat-icon>
                  Create New Product
                </button>
                <button mat-stroked-button [routerLink]="['/products/assign', shopId]" *ngIf="canBulkAssign()" class="bulk-assign-btn">
                  <mat-icon>playlist_add</mat-icon>
                  Bulk Assign Products
                </button>
                <button mat-stroked-button [routerLink]="['/products/shop-owner']" *ngIf="canSelectProducts()" class="select-products-btn">
                  <mat-icon>add_shopping_cart</mat-icon>
                  Select from Catalog
                </button>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <mat-card class="products-card" *ngIf="!loading">
        <mat-card-content>
          <div *ngIf="products.length === 0" class="empty-state">
            <div class="empty-illustration">
              <mat-icon class="empty-icon">inventory_2</mat-icon>
              <div class="empty-decoration">
                <mat-icon>add_shopping_cart</mat-icon>
                <mat-icon>local_offer</mat-icon>
                <mat-icon>trending_up</mat-icon>
              </div>
            </div>
            <div class="empty-content">
              <h3>No Products Added Yet</h3>
              <p class="empty-description">
                {{ isMyShop ? 'Your shop is empty! Start by selecting products and setting competitive prices to attract customers.' : 'This shop hasn\'t added any products yet. Help them get started by adding some popular items.' }}
              </p>
              <div class="empty-features">
                <div class="feature-item">
                  <mat-icon>add_shopping_cart</mat-icon>
                  <span>Select from master products</span>
                </div>
                <div class="feature-item">
                  <mat-icon>attach_money</mat-icon>
                  <span>Set competitive prices</span>
                </div>
                <div class="feature-item">
                  <mat-icon>inventory</mat-icon>
                  <span>Manage stock levels</span>
                </div>
              </div>
            </div>
            <div class="empty-actions">
              <button mat-raised-button color="primary" [routerLink]="['/products/shop-owner']" *ngIf="canSelectProducts()" class="primary-action">
                <mat-icon>add_shopping_cart</mat-icon>
                Select Products
              </button>
              <button mat-raised-button color="accent" [routerLink]="['/products/assign', shopId]" *ngIf="canBulkAssign()" class="secondary-action">
                <mat-icon>playlist_add</mat-icon>
                Bulk Assign Products
              </button>
              <button mat-stroked-button [routerLink]="['/products/shop', shopId, 'new']" class="tertiary-action">
                <mat-icon>add</mat-icon>
                Add Single Product
              </button>
            </div>
          </div>

          <!-- Products Section Header -->
          <div *ngIf="products.length > 0" class="products-section">
            <div class="products-header">
              <h2 class="products-title">Products ({{ products.length }})</h2>
              <div class="header-actions">
                <button mat-stroked-button (click)="refreshProducts()" class="refresh-button" [disabled]="loading">
                  <mat-icon>refresh</mat-icon>
                  Refresh
                </button>
                <button mat-raised-button color="primary" [routerLink]="['/products/shop', shopId, 'new']" class="add-product-btn">
                  <mat-icon>add</mat-icon>
                  Add Product
                </button>
              </div>
            </div>

            <!-- Products Table -->
            <div class="products-table-container">
              <table class="products-table">
                <thead>
                  <tr>
                    <th class="product-col">Product</th>
                    <th class="price-col">Price</th>
                    <th class="stock-col">Stock</th>
                    <th class="status-col">Status</th>
                    <th class="actions-col">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr *ngFor="let product of products" class="product-row">
                    <!-- Product Column -->
                    <td class="product-info">
                      <div class="product-display">
                        <div class="product-icon">
                          <img [src]="getProductImage(product)" 
                               [alt]="product.displayName" 
                               class="product-image"
                               (error)="onImageError($event)" />
                        </div>
                        <div class="product-details">
                          <div class="product-name">{{ product.displayName }}</div>
                          <div class="product-sku">{{ product.masterProduct.sku }}</div>
                          <div class="product-unit" *ngIf="getProductUnit(product)">
                            Unit: {{ getProductUnit(product) }}
                          </div>
                        </div>
                      </div>
                    </td>
                    
                    <!-- Price Column -->
                    <td class="price-info">
                      <div class="price-display">
                        <span class="price">{{ product.price | currency:'INR':'symbol':'1.0-0' }}</span>
                        <span class="unit-price" *ngIf="getUnitPriceDisplay(product)">
                          {{ getUnitPriceDisplay(product) }}
                        </span>
                      </div>
                    </td>
                    
                    <!-- Stock Column -->
                    <td class="stock-info">
                      <span class="stock-quantity" [ngClass]="getStockClass(product.stockQuantity)">
                        {{ product.stockQuantity }} in stock
                      </span>
                    </td>
                    
                    <!-- Status Column -->
                    <td class="status-info">
                      <span class="status-badge" [ngClass]="getStatusClass(product.status)">
                        {{ getStatusDisplay(product.status) }}
                      </span>
                    </td>
                    
                    <!-- Actions Column -->
                    <td class="actions-info">
                      <div class="action-buttons">
                        <button mat-icon-button [routerLink]="['/products/shop', shopId, product.id]" 
                                matTooltip="Edit Product" class="edit-btn">
                          <mat-icon>edit</mat-icon>
                        </button>
                        <button mat-icon-button (click)="removeProduct(product)" 
                                matTooltip="Delete Product" class="delete-btn">
                          <mat-icon>delete</mat-icon>
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <div *ngIf="loading" class="loading-container">
        <mat-spinner diameter="50"></mat-spinner>
        <p>Loading shop products...</p>
      </div>
    </div>
  `,
  styles: [`
    .list-container {
      padding: 16px;
      // max-width: 1200px;
      margin: 0 auto;
      min-height: calc(100vh - 100px);
    }

    .shop-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 16px;
      padding: 32px;
      margin-bottom: 16px;
      color: white;
      box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
    }

    .shop-info-section {
      display: flex;
      align-items: center;
      gap: 20px;
      margin-bottom: 16px;
    }

    .shop-avatar {
      flex-shrink: 0;
    }

    .shop-logo {
      width: 80px;
      height: 80px;
      border-radius: 16px;
      object-fit: cover;
      border: 3px solid rgba(255, 255, 255, 0.2);
    }

    .shop-logo-placeholder {
      width: 80px;
      height: 80px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 3px solid rgba(255, 255, 255, 0.2);
    }

    .shop-logo-placeholder mat-icon {
      font-size: 40px;
      width: 40px;
      height: 40px;
      color: rgba(255, 255, 255, 0.8);
    }

    .shop-details {
      flex: 1;
    }

    .shop-name {
      margin: 0 0 4px 0;
      font-size: 28px;
      font-weight: 700;
      color: white;
      line-height: 1.2;
    }

    .shop-subtitle {
      font-size: 18px;
      color: rgba(255, 255, 255, 0.95);
      font-weight: 500;
      margin-bottom: 8px;
      text-transform: capitalize;
    }

    .shop-meta {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .shop-business {
      font-size: 14px;
      color: rgba(255, 255, 255, 0.8);
      font-weight: 400;
    }

    .shop-location {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 14px;
      color: rgba(255, 255, 255, 0.8);
    }

    .shop-location mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .shop-type {
      margin-top: 4px;
    }

    .shop-stats {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      justify-content: center;
    }

    .stat-card {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      border-radius: 12px;
      padding: 16px 20px;
      text-align: center;
      min-width: 100px;
      backdrop-filter: blur(10px);
    }

    .stat-number {
      font-size: 24px;
      font-weight: 700;
      color: white;
      line-height: 1;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 12px;
      color: rgba(255, 255, 255, 0.8);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .business-type-grocery {
      background-color: rgba(16, 185, 129, 0.2) !important;
      color: #10b981 !important;
      border: 1px solid rgba(16, 185, 129, 0.3) !important;
    }

    .business-type-pharmacy {
      background-color: rgba(59, 130, 246, 0.2) !important;
      color: #3b82f6 !important;
      border: 1px solid rgba(59, 130, 246, 0.3) !important;
    }

    .business-type-restaurant {
      background-color: rgba(168, 85, 247, 0.2) !important;
      color: #a855f7 !important;
      border: 1px solid rgba(168, 85, 247, 0.3) !important;
    }

    .business-type-general {
      background-color: rgba(156, 163, 175, 0.2) !important;
      color: #6b7280 !important;
      border: 1px solid rgba(156, 163, 175, 0.3) !important;
    }

    .address-section {
      margin-bottom: 12px;
    }

    .address-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .address-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .address-header h3 {
      margin: 0;
      color: #1f2937;
      font-size: 18px;
      font-weight: 600;
    }

    .address-icon {
      color: #667eea;
    }

    .address-details {
      color: #4b5563;
    }

    .address-line {
      margin: 0 0 8px 0;
      font-size: 16px;
      font-weight: 500;
    }

    .address-city {
      margin: 0 0 16px 0;
      font-size: 14px;
    }

    .contact-info {
      display: flex;
      gap: 24px;
      flex-wrap: wrap;
    }

    .contact-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: #6b7280;
    }

    .contact-item mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
      color: #667eea;
    }

    .create-product-section {
      margin-bottom: 16px;
    }

    .create-product-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      border: 2px dashed #e5e7eb;
      background: #f9fafb;
    }

    .create-product-content {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 20px;
    }

    .create-product-info h3 {
      margin: 0 0 8px 0;
      color: #1f2937;
      font-size: 18px;
      font-weight: 600;
    }

    .create-product-info p {
      margin: 0;
      color: #6b7280;
      font-size: 14px;
    }

    .create-product-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .create-single-btn {
      background: #667eea !important;
      color: white !important;
      font-weight: 600 !important;
      padding: 12px 24px !important;
    }

    .bulk-assign-btn,
    .select-products-btn {
      border-color: #667eea !important;
      color: #667eea !important;
      font-weight: 500 !important;
      padding: 12px 20px !important;
    }

    .bulk-assign-btn:hover,
    .select-products-btn:hover {
      background: rgba(102, 126, 234, 0.1) !important;
    }

    .shop-photos-section {
      margin-bottom: 16px;
    }

    .photos-title {
      display: flex;
      align-items: center;
      gap: 8px;
      margin: 0 0 16px 0;
      font-size: 16px;
      font-weight: 600;
      color: rgba(255, 255, 255, 0.9);
    }

    .photos-icon {
      color: rgba(255, 255, 255, 0.8);
    }

    .photos-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
      gap: 12px;
      max-width: 600px;
    }

    .gallery-photo {
      width: 100%;
      height: 90px;
      border-radius: 12px;
      object-fit: cover;
      border: 2px solid rgba(255, 255, 255, 0.2);
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .gallery-photo:hover {
      border-color: rgba(255, 255, 255, 0.8);
      transform: scale(1.05);
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
    }

    .more-photos {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 100%;
      height: 90px;
      border: 2px dashed rgba(255, 255, 255, 0.4);
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.3s ease;
      background: rgba(255, 255, 255, 0.1);
      color: rgba(255, 255, 255, 0.8);
      font-size: 12px;
      font-weight: 500;
    }

    .more-photos:hover {
      border-color: rgba(255, 255, 255, 0.8);
      background: rgba(255, 255, 255, 0.2);
      color: white;
    }

    .more-photos mat-icon {
      margin-bottom: 4px;
      font-size: 20px;
      width: 20px;
      height: 20px;
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

    .action-buttons {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .products-card {
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
      padding: 80px 40px;
      color: #666;
      max-width: 600px;
      margin: 0 auto;
    }

    .empty-illustration {
      position: relative;
      margin-bottom: 32px;
    }

    .empty-icon {
      font-size: 120px;
      width: 120px;
      height: 120px;
      color: #e2e8f0;
      margin-bottom: 16px;
    }

    .empty-decoration {
      display: flex;
      justify-content: center;
      gap: 16px;
      margin-top: -20px;
    }

    .empty-decoration mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
      color: #cbd5e0;
      opacity: 0.6;
    }

    .empty-content h3 {
      margin: 0 0 16px 0;
      font-size: 24px;
      font-weight: 600;
      color: #2d3748;
    }

    .empty-description {
      margin-bottom: 32px;
      font-size: 16px;
      line-height: 1.6;
      color: #718096;
    }

    .empty-features {
      display: flex;
      justify-content: center;
      gap: 24px;
      margin-bottom: 40px;
      flex-wrap: wrap;
    }

    .feature-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: #4a5568;
    }

    .feature-item mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      color: #667eea;
    }

    .empty-actions {
      display: flex;
      gap: 16px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .primary-action {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
      color: white !important;
      border: none !important;
      padding: 12px 24px !important;
      font-weight: 600 !important;
      box-shadow: 0 4px 16px rgba(102, 126, 234, 0.3) !important;
    }

    .secondary-action {
      padding: 12px 24px !important;
      font-weight: 600 !important;
    }

    .tertiary-action {
      padding: 12px 24px !important;
      color: #667eea !important;
      border-color: #667eea !important;
    }

    .products-section {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .products-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 24px;
      border-bottom: 1px solid #e5e7eb;
      background: #f9fafb;
    }

    .products-title {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      color: #1f2937;
    }

    .add-product-btn {
      background: #3b82f6 !important;
      color: white !important;
      font-weight: 500 !important;
      box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3) !important;
    }

    .products-table-container {
      overflow-x: auto;
    }

    .products-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }

    .products-table thead {
      background: #f8fafc;
    }

    .products-table th {
      padding: 16px 20px;
      text-align: left;
      font-weight: 600;
      color: #374151;
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid #e5e7eb;
    }

    .products-table td {
      padding: 16px 20px;
      border-bottom: 1px solid #f3f4f6;
      vertical-align: middle;
    }

    .product-row {
      transition: background-color 0.2s ease;
    }

    .product-row:hover {
      background-color: #f9fafb;
    }

    .product-row:last-child td {
      border-bottom: none;
    }

    .product-col {
      width: 40%;
    }

    .price-col {
      width: 15%;
    }

    .stock-col {
      width: 15%;
    }

    .status-col {
      width: 15%;
    }

    .actions-col {
      width: 15%;
    }

    .product-display {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .product-icon {
      flex-shrink: 0;
      width: 40px;
      height: 40px;
      border-radius: 8px;
      overflow: hidden;
      background: #f3f4f6;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .product-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .product-details {
      flex: 1;
    }

    .product-name {
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 2px;
      line-height: 1.3;
    }

    .product-sku {
      font-size: 12px;
      color: #6b7280;
      font-family: 'Courier New', monospace;
    }

    .product-unit {
      font-size: 11px;
      color: #9ca3af;
      margin-top: 2px;
      font-weight: 500;
    }

    .price-display {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .unit-price {
      font-size: 11px;
      color: #6b7280;
      font-weight: 400;
    }

    .price {
      font-weight: 700;
      color: #059669;
      font-size: 16px;
    }

    .stock-quantity {
      font-size: 13px;
      color: #6b7280;
    }

    .stock-quantity.low-stock {
      color: #dc2626;
      font-weight: 600;
    }

    .stock-quantity.out-of-stock {
      color: #dc2626;
      font-weight: 600;
    }

    .status-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 16px;
      font-size: 12px;
      font-weight: 500;
      text-align: center;
    }

    .status-badge.status-active {
      background-color: #dcfce7;
      color: #166534;
    }

    .status-badge.status-inactive {
      background-color: #fee2e2;
      color: #dc2626;
    }

    .status-badge.status-out-of-stock {
      background-color: #fef3c7;
      color: #d97706;
    }

    .action-buttons {
      display: flex;
      gap: 4px;
    }

    .edit-btn {
      color: #3b82f6 !important;
    }

    .delete-btn {
      color: #dc2626 !important;
    }

    .edit-btn:hover {
      background-color: rgba(59, 130, 246, 0.1) !important;
    }

    .delete-btn:hover {
      background-color: rgba(220, 38, 38, 0.1) !important;
    }

    @media (max-width: 768px) {
      .list-container {
        padding: 16px;
      }

      .list-header {
        flex-direction: column;
        align-items: stretch;
        gap: 16px;
        padding: 20px;
      }

      .header-actions {
        justify-content: center;
      }

      .header-actions {
        flex-direction: column;
        align-items: stretch;
      }

      .nav-buttons, .action-buttons {
        justify-content: center;
      }

      .products-table-container {
        overflow-x: auto;
      }

      .products-table {
        min-width: 600px;
      }

      .products-header {
        flex-direction: column;
        gap: 12px;
        align-items: stretch;
      }

      .add-product-btn {
        width: 100%;
        justify-content: center;
      }

      .product-display {
        gap: 8px;
      }

      .product-icon {
        width: 32px;
        height: 32px;
      }

      .product-name {
        font-size: 13px;
      }

      .product-sku {
        font-size: 11px;
      }

      .price {
        font-size: 14px;
      }

      .products-table th,
      .products-table td {
        padding: 12px 8px;
      }

      .create-product-content {
        flex-direction: column;
        text-align: center;
        gap: 16px;
      }

      .create-product-actions {
        justify-content: center;
        width: 100%;
      }

      .photos-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 8px;
      }

      .gallery-photo {
        height: 70px;
      }

      .back-button {
        justify-content: center;
        width: 100%;
      }

      .contact-info {
        justify-content: center;
      }
    }
  `]
})
export class ShopProductListComponent implements OnInit, OnDestroy {
  products: ShopProduct[] = [];
  shop: Shop | null = null;
  loading = true;
  shopId!: number;
  isMyShop = false;
  currentUser: User | null = null;
  private navigationSubscription: Subscription = new Subscription();

  constructor(
    private shopProductService: ShopProductService,
    private shopService: ShopService,
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit() {
    this.currentUser = this.authService.getCurrentUser();
    
    // Check if this is the "My Shop Products" route
    this.isMyShop = this.router.url.includes('/products/my-shop');
    
    if (this.isMyShop && this.currentUser?.role === UserRole.SHOP_OWNER) {
      // Load current user's shop
      this.loadMyShop();
    } else {
      // Regular shop product list
      this.shopId = +this.route.snapshot.params['shopId'];
      this.loadShop();
      this.loadProducts();
    }

    // Listen for navigation events to refresh data when returning from edit mode
    this.navigationSubscription = this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe((event) => {
        // Check if we're navigating back to this list page from an edit page
        if (event.url.includes(`/products/shops/${this.shopId}`) && 
            !event.url.includes('/edit') && 
            !event.url.includes('/new') &&
            event.url === event.urlAfterRedirects) {
          console.log('Detected navigation back to product list, refreshing data...');
          this.refreshProducts();
        }
      });
  }

  ngOnDestroy() {
    if (this.navigationSubscription) {
      this.navigationSubscription.unsubscribe();
    }
  }

  private loadMyShop() {
    this.loading = true;
    this.shopService.getMyShop().subscribe({
      next: (shop) => {
        this.shop = shop;
        this.shopId = shop.id;
        this.loadProducts();
      },
      error: (error) => {
        console.error('Error loading my shop:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load your shop. You may not have a shop assigned to your account.',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.loading = false;
      }
    });
  }

  private loadShop() {
    this.shopService.getShop(this.shopId).subscribe({
      next: (shop) => {
        this.shop = shop;
      },
      error: (error) => {
        console.error('Error loading shop:', error);
      }
    });
  }

  private loadProducts() {
    this.loading = true;
    this.shopProductService.getShopProducts(this.shopId).subscribe({
      next: (response) => {
        console.log('Shop products loaded from API:', response);
        this.products = response.content || [];
        console.log('First product data:', this.products[0]);
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shop products:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shop products',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.loading = false;
      }
    });
  }

  refreshProducts() {
    console.log('Force refreshing products...');
    this.products = []; // Clear current data to force refresh
    
    // Add a small delay to ensure any pending operations complete
    setTimeout(() => {
      this.loadProducts();
    }, 500);
  }

  canBulkAssign(): boolean {
    // Show bulk assign only for ADMIN users
    return this.currentUser?.role === 'ADMIN';
  }

  canSelectProducts(): boolean {
    // Both ADMIN and SHOP_OWNER can select products
    return this.currentUser?.role === 'ADMIN' || this.currentUser?.role === 'SHOP_OWNER';
  }

  isShopOwner(): boolean {
    return this.currentUser?.role === 'SHOP_OWNER';
  }

  goBack(): void {
    window.history.back();
  }

  getProductImage(product: any): string {
    console.log('getProductImage called for product:', product.displayName, {
      shopImages: product.images,
      masterProductImages: product.masterProduct?.images,
      primaryImageUrl: product.primaryImageUrl,
      masterProductPrimaryImageUrl: product.masterProduct?.primaryImageUrl
    });

    // Check for direct primaryImageUrl first (most common)
    if (product.primaryImageUrl) {
      const imageUrl = product.primaryImageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }

    // Check master product primaryImageUrl
    if (product.masterProduct?.primaryImageUrl) {
      const imageUrl = product.masterProduct.primaryImageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    // Check if product has shop-specific images array
    if (product.images && product.images.length > 0) {
      const primaryImage = product.images.find((img: any) => img.isPrimary) || product.images[0];
      const imageUrl = primaryImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    // Fallback to master product images array
    if (product.masterProduct?.images && product.masterProduct.images.length > 0) {
      const primaryImage = product.masterProduct.images.find((img: any) => img.isPrimary) || product.masterProduct.images[0];
      const imageUrl = primaryImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    // Default placeholder - using a proper placeholder service
    console.log('No images found, using placeholder for:', product.displayName);
    // Use a more appealing default product image
    return 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=40&h=40&fit=crop&crop=center';
  }

  onImageError(event: any): void {
    console.log('Image failed to load, using fallback');
    event.target.src = 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=40&h=40&fit=crop&crop=center';
  }

  getStatusColor(status: string): 'primary' | 'accent' | 'warn' {
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

  getStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'status-active';
      case 'INACTIVE':
        return 'status-inactive';
      case 'OUT_OF_STOCK':
        return 'status-out-of-stock';
      case 'DISCONTINUED':
        return 'status-inactive';
      default:
        return 'status-inactive';
    }
  }

  removeProduct(product: ShopProduct) {
    Swal.fire({
      title: 'Are you sure?',
      text: `Do you want to remove "${product.displayName}" from this shop?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, remove it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.shopProductService.removeProductFromShop(this.shopId, product.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Removed!',
              text: 'Product removed from shop successfully',
              icon: 'success',
              confirmButtonText: 'OK'
            });
            this.loadProducts(); // Reload the list
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

  getActiveProductsCount(): number {
    return this.products.filter(p => p.status === 'ACTIVE').length;
  }

  getLowStockCount(): number {
    return this.products.filter(p => p.stockQuantity < 5).length;
  }

  getTotalValue(): number {
    return this.products.reduce((total, product) => {
      // Use price * stock quantity for each product
      const productValue = (product.price || 0) * (product.stockQuantity || 0);
      return total + productValue;
    }, 0);
  }

  getStockClass(stockQuantity: number): string {
    if (stockQuantity === 0) {
      return 'out-of-stock';
    } else if (stockQuantity < 5) {
      return 'low-stock';
    }
    return '';
  }

  getStatusDisplay(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'DISCONTINUED':
        return 'Discontinued';
      default:
        return status || 'Unknown';
    }
  }

  getShopLogo(): string | null {
    if (!this.shop || !this.shop.images || this.shop.images.length === 0) {
      return null;
    }
    
    // Find the primary logo image
    const logoImage = this.shop.images.find(img => img.imageType === 'LOGO' && img.isPrimary);
    if (logoImage) {
      const imageUrl = logoImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    return null;
  }

  getBusinessTypeDisplay(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'Grocery';
      case 'SUPERMARKET': return 'Supermarket';
      case 'PHARMACY': return 'Pharmacy';
      case 'RESTAURANT': return 'Restaurant';
      case 'CAFE': return 'Cafe';
      case 'BAKERY': return 'Bakery';
      case 'ELECTRONICS': return 'Electronics';
      case 'CLOTHING': return 'Clothing';
      case 'HARDWARE': return 'Hardware';
      case 'GENERAL': return 'General';
      default: return type || 'General';
    }
  }

  getBusinessTypeClass(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'business-type-grocery';
      case 'SUPERMARKET': return 'business-type-grocery'; // Same styling as grocery
      case 'PHARMACY': return 'business-type-pharmacy';
      case 'RESTAURANT': return 'business-type-restaurant';
      case 'CAFE': return 'business-type-restaurant'; // Same styling as restaurant
      case 'BAKERY': return 'business-type-restaurant'; // Same styling as restaurant
      case 'ELECTRONICS': return 'business-type-general';
      case 'CLOTHING': return 'business-type-general';
      case 'HARDWARE': return 'business-type-general';
      case 'GENERAL': return 'business-type-general';
      default: return 'business-type-general';
    }
  }

  getShopPhotos(): string[] {
    if (!this.shop || !this.shop.images || this.shop.images.length === 0) {
      return [];
    }
    
    // Get all gallery images
    const photos = this.shop.images
      .filter(img => img.imageType === 'GALLERY')
      .map(img => {
        const imageUrl = img.imageUrl;
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          return imageUrl;
        }
        return `http://localhost:8082${imageUrl}`;
      });
    
    return photos;
  }

  getShopBanner(): string | null {
    if (!this.shop || !this.shop.images || this.shop.images.length === 0) {
      return null;
    }
    
    // Find the banner image
    const bannerImage = this.shop.images.find(img => img.imageType === 'BANNER');
    if (bannerImage) {
      const imageUrl = bannerImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    return null;
  }

  viewShopPhoto(photoUrl: string) {
    // Open photo in a modal or new tab
    window.open(photoUrl, '_blank');
  }

  viewAllPhotos() {
    // You can implement a photo gallery modal here
    // For now, just show all photos in a simple way
    const photos = this.getShopPhotos();
    photos.forEach((photo, index) => {
      setTimeout(() => {
        window.open(photo, '_blank');
      }, index * 100); // Small delay between opening photos
    });
  }

  getProductUnit(product: any): string {
    // Get unit information from master product or custom attributes
    if (product.masterProduct?.baseUnit) {
      const weight = product.masterProduct.baseWeight || 1;
      return `${weight} ${product.masterProduct.baseUnit}`;
    }
    
    // Default units based on business type
    if (this.shop?.businessType === 'GROCERY') {
      // Common grocery units
      if (product.displayName?.toLowerCase().includes('rice') || 
          product.displayName?.toLowerCase().includes('flour') ||
          product.displayName?.toLowerCase().includes('sugar')) {
        return '1 kg';
      }
      if (product.displayName?.toLowerCase().includes('oil') || 
          product.displayName?.toLowerCase().includes('milk')) {
        return '1 liter';
      }
    }
    
    if (this.shop?.businessType === 'PHARMACY') {
      // Common pharmacy units
      if (product.displayName?.toLowerCase().includes('tablet') || 
          product.displayName?.toLowerCase().includes('capsule')) {
        return '10 tablets';
      }
      if (product.displayName?.toLowerCase().includes('syrup')) {
        return '100 ml';
      }
    }
    
    return '1 piece'; // Default unit
  }

  getUnitPriceDisplay(product: any): string {
    const unit = this.getProductUnit(product);
    
    // Parse the unit to calculate per unit price
    if (unit.includes('kg')) {
      const weight = parseFloat(unit) || 1;
      const perKgPrice = product.price / weight;
      return `₹${perKgPrice.toFixed(0)}/kg`;
    }
    
    if (unit.includes('gram') || unit.includes('gm')) {
      const weight = parseFloat(unit) || 1;
      const perKgPrice = (product.price / weight) * 1000;
      return `₹${perKgPrice.toFixed(0)}/kg`;
    }
    
    if (unit.includes('liter') || unit.includes('litre')) {
      const volume = parseFloat(unit) || 1;
      const perLiterPrice = product.price / volume;
      return `₹${perLiterPrice.toFixed(0)}/liter`;
    }
    
    if (unit.includes('ml')) {
      const volume = parseFloat(unit) || 1;
      const perLiterPrice = (product.price / volume) * 1000;
      return `₹${perLiterPrice.toFixed(0)}/liter`;
    }
    
    if (unit.includes('tablet') || unit.includes('capsule')) {
      const count = parseFloat(unit) || 1;
      const perTabletPrice = product.price / count;
      return `₹${perTabletPrice.toFixed(1)}/tablet`;
    }
    
    // For piece-based items, no need for per-unit display
    return '';
  }
}